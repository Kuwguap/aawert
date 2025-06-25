#!/bin/bash

TARGET="$1"
RESULTS_DIR="${2:-./results}"
WORDLIST="/home/kali/Desktop/Tools/SecLists-master/Discovery/Web-Content/directory-list-2.3-medium.txt" # Replace with your wordlist path

echo "[+] Starting Content Discovery for $TARGET"

if [ ! -f "$RESULTS_DIR/live_subdomains_target.txt" ]; then
    echo "Error: $RESULTS_DIR/live_subdomains_target.txt not found. Run live subdomain check first."
    exit 1
fi

# Function to process ffuf output and filter for target domain
process_ffuf_output() {
    local input_file="$1"
    local output_file="$2"
    local target_domain="$3"
    
    echo "    [+] Processing ffuf results and filtering for $target_domain..."
    cat "$input_file" | jq -r '.results[] | select(.status == 200) | .url' | while IFS= read -r url; do
        # Check if the URL contains the target domain (case insensitive)
        if [[ "$url" =~ $target_domain ]]; then
            echo "$url" >> "$output_file"
        fi
    done
}

# Function to filter dirsearch results for target domain
filter_dirsearch_results() {
    local input_file="$1"
    local output_file="$2"
    local target_domain="$3"
    
    echo "    [+] Filtering dirsearch results for $target_domain..."
    cat "$input_file" | while IFS= read -r line; do
        if [[ "$line" == *"$target_domain"* ]]; then
            if [[ "$line" == *"[200]"* ]]; then
                url=$(echo "$line" | awk '{print $3}')
                # Double-check the URL contains the target domain
                if [[ "$url" =~ $target_domain ]]; then
                    echo "$url" >> "$output_file"
                fi
            elif [[ "$line" == *"REDIRECTS TO:"* ]]; then
                redirect_url=$(echo "$line" | awk '{print $NF}')
                if [[ "$redirect_url" == *"$target_domain"* ]]; then
                    url=$(echo "$line" | awk '{print $3}')
                    # Double-check the URL contains the target domain
                    if [[ "$url" =~ $target_domain ]]; then
                        echo "$url" >> "$output_file"
                    fi
                fi
            fi
        fi
    done
}

echo "  [+] Running ffuf on main domain..."
if [ -n "$TARGET" ]; then
    ffuf -w "$WORDLIST" -u "https://$TARGET/FUZZ" -recursion -o "$RESULTS_DIR/ffuf_main_raw.json"
    process_ffuf_output "$RESULTS_DIR/ffuf_main_raw.json" "$RESULTS_DIR/ffuf_main.txt" "$TARGET"
    #rm "$RESULTS_DIR/ffuf_main_raw.json"
fi

echo "  [+] Running dirsearch on main domain..."
if [ -n "$TARGET" ]; then
    dirsearch -u "https://$TARGET" -w "$WORDLIST" -r -o "$RESULTS_DIR/dirsearch_main_raw.txt"
    dirsearch -u "http://$TARGET" -w "$WORDLIST" -r -o "$RESULTS_DIR/dirsearch_main_raw.txt"
    filter_dirsearch_results "$RESULTS_DIR/dirsearch_main_raw.txt" "$RESULTS_DIR/dirsearch_main.txt" "$TARGET"
    #rm "$RESULTS_DIR/dirsearch_main_raw.txt"
fi

echo "  [+] Running ffuf on live subdomains..."
cat "$RESULTS_DIR/live_subdomains_target.txt" | while read -r subdomain; do
    echo "    [+] Running ffuf on https://$subdomain..."
    ffuf -w "$WORDLIST" -u "https://$subdomain/FUZZ" -recursion -o "$RESULTS_DIR/ffuf_${subdomain//./_}_raw.json"
    process_ffuf_output "$RESULTS_DIR/ffuf_${subdomain//./_}_raw.json" "$RESULTS_DIR/ffuf_$subdomain.txt" "$subdomain"
    #rm "$RESULTS_DIR/ffuf_${subdomain//./_}_raw.json"
done

echo "  [+] Running dirsearch on live subdomains..."
cat "$RESULTS_DIR/live_subdomains_target.txt" | while read -r subdomain; do
    echo "    [+] Running dirsearch on https://$subdomain..."
    dirsearch -u "https://$subdomain" -w "$WORDLIST" -r -o "$RESULTS_DIR/dirsearch_${subdomain//./_}_raw.txt"
    dirsearch -u "http://$subdomain" -w "$WORDLIST" -r -o "$RESULTS_DIR/dirsearch_${subdomain//./_}_raw.txt"
    filter_dirsearch_results "$RESULTS_DIR/dirsearch_${subdomain//./_}_raw.txt" "$RESULTS_DIR/dirsearch_$subdomain.txt" "$subdomain"
   # rm "$RESULTS_DIR/dirsearch_${subdomain//./_}_raw.txt"
done

# Show statistics
echo "[+] Content Discovery Statistics:"
echo "  - Main domain ffuf results: $(wc -l < "$RESULTS_DIR/ffuf_main.txt" 2>/dev/null || echo "0")"
echo "  - Main domain dirsearch results: $(wc -l < "$RESULTS_DIR/dirsearch_main.txt" 2>/dev/null || echo "0")"

# Count subdomain results
subdomain_count=0
for file in "$RESULTS_DIR"/ffuf_*.txt "$RESULTS_DIR"/dirsearch_*.txt; do
    if [[ "$file" != *"main"* ]] && [ -f "$file" ]; then
        count=$(wc -l < "$file" 2>/dev/null || echo "0")
        subdomain_count=$((subdomain_count + count))
    fi
done
echo "  - Subdomain results: $subdomain_count"

echo "[+] Content Discovery Complete. Results in $RESULTS_DIR/"
