#!/bin/bash

TARGET="$1"
RESULTS_DIR="${2:-./results}"

echo "[+] Discovering Parameters for $TARGET"

if [ ! -f "$RESULTS_DIR/all_subdomains.txt" ]; then
  echo "Error: $RESULTS_DIR/all_subdomains.txt not found. Run live subdomain check first."
  exit 1
fi

echo "  [+] Running gau..."
cat "$RESULTS_DIR/all_subdomains.txt" | gau > "$RESULTS_DIR/parameters.txt"

echo "[+] Parameter Discovery Complete. Results in $RESULTS_DIR/parameters.txt"
