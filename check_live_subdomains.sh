#!/bin/bash

TARGET="$1"
RESULTS_DIR="./results"

echo "[+] Checking Live Subdomains for $TARGET"

echo "  [+] Probing subdomains with httpx..."
cat "$RESULTS_DIR/data1.txt" | httpx -status-code -server -o "$RESULTS_DIR/http_probe_results_raw.txt"

echo "[+] Converting httpx results to UTF-8..."
( iconv -f ISO-8859-1 -t utf-8 "$RESULTS_DIR/http_probe_results_raw.txt" -o "$RESULTS_DIR/http_probe_results.txt" || iconv -f UTF-8 -t utf-8 "$RESULTS_DIR/http_probe_results.txt")

echo "[+] Filtering live subdomains (status 200 and 3xx) using target-based logic..."
if [ -f "$RESULTS_DIR/http_probe_results.txt" ]; then
  cat "$RESULTS_DIR/http_probe_results.txt" |
    while IFS= read -r line; do
      # Remove ANSI escape codes
      cleaned_line=$(echo "$line" | sed -e 's/\x1B\[[0-9;]*[a-zA-Z]//g' -e 's/\x1B\][0-9;]*[a-zA-Z]//g')

      # Extract URL ending just before [200] or [3xx]
      url=$(echo "$cleaned_line" | grep -oP 'h[^ ]+(?= \[200\]| \[3\d{2}\])')
      status=$(echo "$cleaned_line" | grep -oP '\[(200|3\d{2})\]')

      if [[ -n "$url" ]]; then
        echo "$url" >> "$RESULTS_DIR/live_subdomains_target.txt"
      fi
    done
fi

echo "[+] Live Subdomain Check Complete. Results in $RESULTS_DIR/live_subdomains.txt and $RESULTS_DIR/http_probe_results.txt"
