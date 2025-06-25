#!/bin/bash

TARGET="$1"
RESULTS_DIR="${2:-./results}"
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

echo "  [+] Fetching and Grepping for .js files..."

if [ -f "$ALIVE_SUBDOMAINS" ]; then
    # Extract all JavaScript URLs first
    grep -oE 'https?://[^"\'>]*\.js' "$ALIVE_SUBDOMAINS" | sort -u > "$RESULTS_DIR/js_files_raw.txt"
    
    # Count raw JavaScript URLs before filtering
    raw_js_count=$(wc -l < "$RESULTS_DIR/js_files_raw.txt" 2>/dev/null || echo "0")
    
    # Filter JavaScript URLs to only include those containing the target domain
    echo "  [+] Filtering JavaScript URLs to only include $TARGET..."
    cat "$RESULTS_DIR/js_files_raw.txt" | while IFS= read -r js_url; do
        # Check if the URL contains the target domain (case insensitive)
        if [[ "$js_url" =~ $TARGET ]]; then
            echo "$js_url" >> "$JS_FILES_OUTPUT"
        fi
    done
    
    # Clean up raw file
    rm -f "$RESULTS_DIR/js_files_raw.txt"
    
    # Show statistics
    echo "[+] JavaScript Extraction Statistics:"
    echo "  - Raw JavaScript URLs found: $raw_js_count"
    echo "  - Filtered JavaScript URLs: $(wc -l < "$JS_FILES_OUTPUT" 2>/dev/null || echo "0")"
else
    echo "Warning: $ALIVE_SUBDOMAINS is empty."
    touch "$JS_FILES_OUTPUT"
fi

echo "[+] JavaScript File Extraction Complete. Results in $JS_FILES_OUTPUT"
