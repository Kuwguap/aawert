#!/bin/bash

TARGET="$1"
RESULTS_DIR="${2:-./results}"

echo "[+] Discovering Parameters for $TARGET"

if [ ! -f "$RESULTS_DIR/all_subdomains.txt" ]; then
  echo "Error: $RESULTS_DIR/all_subdomains.txt not found. Run live subdomain check first."
  exit 1
fi

echo "  [+] Running gau..."
cat "$RESULTS_DIR/all_subdomains.txt" | gau > "$RESULTS_DIR/parameters_raw.txt"

# Count raw URLs before filtering
raw_count=$(wc -l < "$RESULTS_DIR/parameters_raw.txt" 2>/dev/null || echo "0")

# Filter parameters to only include URLs containing the target domain
echo "  [+] Filtering parameters to only include $TARGET URLs..."
cat "$RESULTS_DIR/parameters_raw.txt" | while IFS= read -r url; do
    # Check if the URL contains the target domain (case insensitive)
    if [[ "$url" =~ $TARGET ]]; then
        echo "$url" >> "$RESULTS_DIR/parameters.txt"
    fi
done

# Clean up raw file
rm -f "$RESULTS_DIR/parameters_raw.txt"

# Show statistics
echo "[+] Parameter Discovery Statistics:"
echo "  - Raw URLs found: $raw_count"
echo "  - Filtered URLs: $(wc -l < "$RESULTS_DIR/parameters.txt" 2>/dev/null || echo "0")"

echo "[+] Parameter Discovery Complete. Results in $RESULTS_DIR/parameters.txt"
