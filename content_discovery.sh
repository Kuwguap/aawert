#!/bin/bash

#TARGET="$1"
RESULTS_DIR="./results"
WORDLIST="/home/kali/Desktop/Tools/SecLists-master/Discovery/Web-Content/directory-list-2.3-medium.txt" # Replace with your wo>

echo "[+] Starting Content Discovery for $TARGET"

if [ ! -f "$RESULTS_DIR/live_subdomains_target.txt" ]; then
    echo "Error: $RESULTS_DIR/live_subdomains_target.txt not found. Run live subdomain check first."
    exit 1
fi

# Function to process ffuf output
process_ffuf_output() {
    local input_file="$1"
    local output_file="$2"
    cat "$input_file" | jq -r '.results[] | select(.status == 200) | .url' > "$output_file"
}

echo "  [+] Running ffuf on main domain..."
cat "$RESULTS_DIR/domains.txt" | while read -r TARGET; do
ffuf -w "$WORDLIST" -u "https://$TARGET/FUZZ" -recursion -o "$RESULTS_DIR/ffuf_main_raw.json"
process_ffuf_output "$RESULTS_DIR/ffuf_main_raw.json" "$RESULTS_DIR/ffuf_main.txt"
#rm "$RESULTS_DIR/ffuf_main_raw.json"
done # Closing the ffuf on main domain loop

echo "  [+] Running dirsearch on main domain..."
cat "$RESULTS_DIR/domains.txt" | while read -r TARGET; do
dirsearch -u "https://$TARGET" -w "$WORDLIST" -r -o "$RESULTS_DIR/dirsearch_main_raw.txt"
dirsearch -u "http://$TARGET" -w "$WORDLIST" -r -o "$RESULTS_DIR/dirsearch_main_raw.txt"
cat "$RESULTS_DIR/dirsearch_main_raw.txt" |
    while IFS= read -r line; do
        if [[ "$line" == *"$TARGET"* ]]; then
            if [[ "$line" == *"[200]"* ]]; then
                echo "$line" | awk '{print $3}'
            elif [[ "$line" == *"REDIRECTS TO:"* ]]; then
                local redirect_url=$(echo "$line" | awk '{print $NF}')
                if [[ "$redirect_url" == *"$TARGET"* ]]; then
                    echo "$line" | awk '{print $3}'
                fi
            fi
        fi
    done > "$RESULTS_DIR/dirsearch_main.txt"
#rm "$RESULTS_DIR/dirsearch_main_raw.txt"
done # Closing the dirsearch on main domain loop

echo "  [+] Running ffuf on live subdomains..."
cat "$RESULTS_DIR/live_subdomains_target.txt" | while read -r subdomain; do
    echo "    [+] Running ffuf on https://$subdomain..."
    ffuf -w "$WORDLIST" -u "https://$subdomain/FUZZ" -recursion -o "$RESULTS_DIR/ffuf_${subdomain//./_}_raw.json"
    process_ffuf_output "$RESULTS_DIR/ffuf_${subdomain//./_}_raw.json" "$RESULTS_DIR/ffuf_$subdomain.txt"
    #rm "$RESULTS_DIR/ffuf_${subdomain//./_}_raw.json"
done # Closing the ffuf on live subdomains loop

echo "  [+] Running dirsearch on live subdomains..."
cat "$RESULTS_DIR/live_subdomains_target.txt" | while read -r subdomain; do
    echo "    [+] Running dirsearch on https://$subdomain..."
    dirsearch -u "https://$subdomain" -w "$WORDLIST" -r -o "$RESULTS_DIR/dirsearch_${subdomain//./_}_raw.txt"
    dirsearch -u "http://$subdomain" -w "$WORDLIST" -r -o "$RESULTS_DIR/dirsearch_${subdomain//./_}_raw.txt"
    cat "$RESULTS_DIR/dirsearch_${subdomain//./_}_raw.txt" |
        while IFS= read -r line; do
            if [[ "$line" == *"$subdomain"* ]]; then
                if [[ "$line" == *"[200]"* ]]; then
                    echo "$line" | awk '{print $3}'
                elif [[ "$line" == *"REDIRECTS TO:"* ]]; then
                    local redirect_url=$(echo "$line" | awk '{print $NF}')
                    if [[ "$redirect_url" == *"$TARGET"* ]]; then
                        echo "$line" | awk '{print $3}'
                    fi
                fi
            fi
        done > "$RESULTS_DIR/dirsearch_$subdomain.txt"
   # rm "$RESULTS_DIR/dirsearch_${subdomain//./_}_raw.txt"
done # Closing the dirsearch on live subdomains loop

# Add a final 'done' here if there were any other unclosed loops.
