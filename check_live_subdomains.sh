#!/bin/bash

TARGET="$1"
RESULTS_DIR="./results"

echo "[+] Checking Live Subdomains for $TARGET"

if [ ! -f "$RESULTS_DIR/all_subdomains.txt" ]; then
  echo "Error: $RESULTS_DIR/all_subdomains.txt not found. Run subdomain enumeration first."
  exit 1
fi

echo "  [+] Probing subdomains with httpx..."
cat "$RESULTS_DIR/all_subdomains.txt" | httpx -status-code -title -server -o "$RESULTS_DIR/http_probe_results.txt"

echo "[+] Filtering live subdomains (status 200 and 3xx)..."
awk '$2 == 200 || $2 ~ /^3../ { print $1 }' "$RESULTS_DIR/http_probe_results.txt" > "$RESULTS_DIR/live_subdomains.txt"

echo "[+] Live Subdomain Check Complete. Results in $RESULTS_DIR/live_subdomains.txt and $RESULTS_DIR/http_probe_results.txt"