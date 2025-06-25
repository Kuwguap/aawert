#!/bin/bash

INPUT="$1"
RESULTS_DIR="./results"

if [ -z "$INPUT" ]; then
  echo "Usage: ./aaweRT.sh <target_domain OR -l <domain_list_file> OR -w <subdomain_wordlist_file>>"
  exit 1
fi

TARGET=""
DOMAIN_LIST_FILE=""
SUBDOMAIN_WORDLIST_FILE=""

case "$INPUT" in
  -l)
    if [ -z "$2" ]; then
      echo "Usage: ./aaweRT.sh -l <domain_list_file>"
      exit 1
    fi
    DOMAIN_LIST_FILE="$2"
    echo "[+] Using domain list from: $DOMAIN_LIST_FILE for enumeration."
    ;;
  -w)
    # ... (wordlist handling) ...
    ;;
  *)
    TARGET="$INPUT"
    echo "[+] Starting AAweRT for target domain: $TARGET"
    ;;
esac

echo "[+] Starting AAweRT - An Awesome Reconnaissance Tool"
echo "================================================================"

# Phase 1: Subdomain Enumeration (Run each tool for all domains)
echo "[+] Phase 1: Subdomain Enumeration"
#rm -f "$RESULTS_DIR/subfinder_results.txt"
#rm -f "$RESULTS_DIR/amass_raw_output.txt"
#rm -f "$RESULTS_DIR/amass_results.txt"
#rm -f "$RESULTS_DIR/assetfinder_results.txt"
#rm -f "$RESULTS_DIR/findomain_results.txt"
#rm -f "$RESULTS_DIR/all_subdomains.txt" # Clear the final combined file

DOMAINS_TO_ENUMERATE=()

if [ -n "$TARGET" ]; then
  DOMAINS_TO_ENUMERATE+=("$TARGET")
elif [ -n "$DOMAIN_LIST_FILE" ]; then
  while IFS= read -r domain; do
    DOMAINS_TO_ENUMERATE+=("$domain")
  done < "$DOMAIN_LIST_FILE"
fi

# Run Subfinder for all domains
echo "[+] Running Subfinder for all targets..."
rm -f "$RESULTS_DIR/subfinder_results.txt" # Clear the file before the loop
for domain in "${DOMAINS_TO_ENUMERATE[@]}"; do
  echo "  [+] Scanning: $domain"
  subfinder -d "$domain" -o "$RESULTS_DIR/subfinder_results.txt" -v 2>>"$RESULTS_DIR/subfinder_error.log" &
done
wait

# Run Amass for all domains
echo "[+] Running Amass for all targets..."
rm -f "$RESULTS_DIR/amass_raw_output.txt" # Clear the file before the loop
for domain in "${DOMAINS_TO_ENUMERATE[@]}"; do
  echo "  [+] Scanning: $domain"
  amass enum -d "$domain" -o "$RESULTS_DIR/amass_raw_output.txt" 2>>"$RESULTS_DIR/amass_error.log" &
done
wait

# Process Amass output (once all Amass scans are done)
echo "[+] Processing Amass output..."
if [ -f "$RESULTS_DIR/amass_raw_output.txt" ]; then
  cat "$RESULTS_DIR/amass_raw_output.txt" |
    ( iconv -f ISO-8859-1 -t utf-8 || iconv -f UTF-8 -t utf-8 ) |
    grep "(FQDN)" | cut -d '(' -f 1 | tr -d ' ' | sort -u > "$RESULTS_DIR/amass_results.txt"
else
  echo "  [!] Warning: Amass raw output file not found."
fi

# Run Assetfinder for all domains
echo "[+] Running Assetfinder for all targets..."
for domain in "${DOMAINS_TO_ENUMERATE[@]}"; do
  echo "  [+] Scanning: $domain"
  assetfinder "$domain" >> "$RESULTS_DIR/assetfinder_results.txt" 2>>"$RESULTS_DIR/assetfinder_error.log" &
done
wait

# Combine and Deduplicate Subdomains
echo "[+] Combining and Deduplicating Subdomains..."
cat "$RESULTS_DIR/"*_results.txt | sort -u > "$RESULTS_DIR/all_subdomains.txt"

echo "[+] Subdomain Enumeration Complete. Results in $RESULTS_DIR/all_subdomains.txt"

# Phase 2: Check Live Subdomains
if [ -f "$SUBDOMAIN_FILE" ]; then
  echo "[+] Phase 2: Check Live Subdomains"
  ./check_live_subdomains.sh "$TARGET" # Still uses target for httpx if available, adjust if needed
  echo "--------------------------------------------------------------=="
  LIVE_SUBDOMAIN_FILE="$RESULTS_DIR/live_subdomains.txt"
else
  echo "Warning: No subdomain list found. Skipping live check."
  LIVE_SUBDOMAIN_FILE=""
fi

# Phase 3: Crawl Subdomains
if [ -f "$LIVE_SUBDOMAIN_FILE" ]; then
  echo "[+] Phase 3: Crawl Subdomains"
  ./crawl_subdomains.sh "$TARGET" # Still uses target for crawling, adjust if needed
  echo "--------------------------------------------------------------=="
fi

# Phase 4: Discover Parameters
if [ -f "$LIVE_SUBDOMAIN_FILE" ]; then
  echo "[+] Phase 4: Discover Parameters"
  ./discover_parameters.sh "$TARGET" # Still uses target for gau, adjust if needed
  echo "--------------------------------------------------------------=="
fi

# Phase 5: Content Discovery
if [ -f "$LIVE_SUBDOMAIN_FILE" ]; then
  echo "[+] Phase 5: Content Discovery"
  ./content_discovery.sh "$TARGET" # Still uses target for ffuf/dirsearch, adjust if needed
  echo "--------------------------------------------------------------=="
fi

# Phase 6: Extract JavaScript Files
if [ -f "$LIVE_SUBDOMAIN_FILE" ]; then
  echo "[+] Phase 6: Extract JavaScript Files"
  ./extract_js.sh "$TARGET" # Still uses target for curl, adjust if needed
  echo "--------------------------------------------------------------=="
fi

# Phase 7: Find Secrets in JavaScript Files
if [ -f "$RESULTS_DIR/js_files.txt" ]; then
  echo "[+] Phase 7: Find Secrets in JavaScript Files"
  ./find_secrets.sh "$TARGET"
  echo "--------------------------------------------------------------=="
fi

# Phase 8: Vulnerability Scan (Revised)
if [ -f "$LIVE_SUBDOMAIN_FILE" ]; then
  echo "[+] Phase 8: Vulnerability Scan"
  ./vulnerability_scan.sh "$TARGET"
  echo "--------------------------------------------------------------=="
fi

# Phase 9: Find S3 Buckets
if [ -f "$SUBDOMAIN_FILE" ]; then
  echo "[+] Phase 9: Find S3 Buckets"
  ./find_s3_buckets.sh "$TARGET"
  echo "--------------------------------------------------------------=="
fi

# Phase 10: Find Login Endpoints
if [ -f "$LIVE_SUBDOMAIN_FILE" ]; then
  echo "[+] Phase 10: Find Login Endpoints"
  ./find_login_endpoints.sh "$TARGET"
  echo "--------------------------------------------------------------=="
fi

echo "[+] AAweRT Run Complete. Results are in the ./results directory."
