#!/bin/bash

TARGET="$1"
RESULTS_DIR="./results"
ALIVE_SUBDOMAINS="$RESULTS_DIR/alive_subdomains_for_js.txt"
JS_FILES_OUTPUT="$RESULTS_DIR/js_files.txt"

echo "[+] Extracting JavaScript Files for $TARGET"

# Check if all_subdomains.txt exists and get live (200) subdomains
if [ -f "$RESULTS_DIR/all_subdomains.txt" ]; then
    echo "  [+] Checking Live Subdomains (Status 200) with httpx..."
    cat "$RESULTS_DIR/all_subdomains.txt" | httpx -silent -status-code -mc 200 -o "$ALIVE_SUBDOMAINS"
else
    echo "Warning: $RESULTS_DIR/all_subdomains.txt not found."
    touch "$ALIVE_SUBDOMAINS"
fi

# Include URLs from parameters.txt
if [ -f "$RESULTS_DIR/parameters.txt" ]; then
    echo "  [+] Adding parameters.txt to the list..."
    cat "$RESULTS_DIR/parameters.txt" >> "$ALIVE_SUBDOMAINS"
    sort -u -o "$ALIVE_SUBDOMAINS" "$ALIVE_SUBDOMAINS"
fi

echo "  [+] Fetching and Grepping for .js files using httpx..."

if [ -f "$ALIVE_SUBDOMAINS" ]; then
    grep -oE 'https?://[^"\'>]*\.js' "$ALIVE_SUBDOMAINS" | sort -u > "$JS_FILES_OUTPUT"
    #rm "$JS_FILES_TEMP"
else
    echo "Warning: $ALIVE_SUBDOMAINS is empty."
    touch "$JS_FILES_OUTPUT"
fi

echo "[+] JavaScript File Extraction Complete. Results in $JS_FILES_OUTPUT"
