#!/bin/bash

TARGET="$1"
RESULTS_DIR="./results"

echo "[+] Starting Subdomain Enumeration for $TARGET"

# Run Subfinder
echo "  [+] Running Subfinder..."
subfinder -d "$TARGET" -o "$RESULTS_DIR/subfinder_results.txt" -v 2>>"$RESULTS_DIR/subfinder_error.log"

if [ $? -ne 0 ]; then
  echo "  [!] Subfinder encountered an error. Check $RESULTS_DIR/subfinder_error.log"
fi

# Run Amass
echo "  [+] Running Amass..."
amass enum -d "$TARGET" -o "$RESULTS_DIR/amass_raw_output.txt" 2>>"$RESULTS_DIR/amass_error.log"

if [ $? -ne 0 ]; then
  echo "  [!] Amass encountered an error. Check $RESULTS_DIR/amass_error.log"
fi

# Process Amass output to extract subdomains
echo "[+] Starting Amass filtering"
echo "  [+] Processing Amass output..."
if [ -f "$RESULTS_DIR/amass_raw_output.txt" ]; then
  cat "$RESULTS_DIR/amass_raw_output.txt" |
    ( iconv -f ISO-8859-1 -t utf-8 || iconv -f UTF-8 -t utf-8 ) |
    while IFS= read -r line; do
      if [[ "$line" == *"(FQDN)"* ]]; then
        # Extract parts before and after the first "(FQDN)"
        first_part=$(echo "$line" | cut -d '(' -f 1 | tr -d ' ')
        second_part=$(echo "$line" | cut -d '>' -f 2 | cut -d '(' -f 1 | tr -d ' ')

        if [ -n "$first_part" ] && echo "$first_part" | grep -q ".$TARGET"; then
          echo "$first_part"
        fi
        if [ -n "$second_part" ] && echo "$second_part" | grep -q ".$TARGET"; then
          echo "$second_part"
        fi
      fi
    done | sort -u > "$RESULTS_DIR/amass_results.txt"
else
  echo "  [!] Amass raw output file not found."
  echo "  [!] Creating an empty amass_results.txt to avoid errors"
  touch "$RESULTS_DIR/amass_results.txt"
fi
echo "  [+] Amass filtering finished."

# Run Assetfinder
echo "  [+] Running Assetfinder..."
assetfinder "$TARGET" > "$RESULTS_DIR/assetfinder_results.txt" 2>>"$RESULTS_DIR/assetfinder_error.log"
if [ $? -ne 0 ]; then
  echo "  [!] Assetfinder encountered an error. Check $RESULTS_DIR/assetfinder_error.log"
fi

# Run Findomain
echo "  [+] Running Findomain..."
findomain -t "$TARGET" -o "$RESULTS_DIR/findomain_results.txt" 2>>"$RESULTS_DIR/findomain_error.log"
if [ $? -ne 0 ]; then
  echo "  [!] Findomain encountered an error. Check $RESULTS_DIR/findomain_error.log"
fi

# Combine and Deduplicate Subdomains
echo "[+] Combining and Deduplicating Subdomains..."
cat "$RESULTS_DIR/"*_results.txt | sort -u > "$RESULTS_DIR/all_subdomains.txt"

echo "[+] Subdomain Enumeration Complete. Results in $RESULTS_DIR/all_subdomains.txt"
