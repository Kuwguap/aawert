#!/bin/bash

TARGET="$1"
RESULTS_DIR="./results"

echo "[+] Extracting JavaScript Files for $TARGET"

if [ ! -f "$RESULTS_DIR/live_subdomains.txt" ]; then
  echo "Error: $RESULTS_DIR/live_subdomains.txt not found. Run live subdomain check first."
  exit 1
fi

echo "  [+] Fetching and Grepping for .js files..."
cat "$RESULTS_DIR/live_subdomains.txt" | while read -r subdomain; do
  echo "    [+] Processing $subdomain..."
  curl -s "https://$subdomain" 2>/dev/null | grep -Eo 'https?://[^"]*?.js' >> "$RESULTS_DIR/js_files.txt"
  curl -s "http://$subdomain" 2>/dev/null | grep -Eo 'https?://[^"]*?.js' >> "$RESULTS_DIR/js_files.txt"
done

sort -u "$RESULTS_DIR/js_files.txt" -o "$RESULTS_DIR/js_files.txt"

echo "[+] JavaScript File Extraction Complete. Results in $RESULTS_DIR/js_files.txt"