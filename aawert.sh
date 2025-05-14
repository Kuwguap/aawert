#!/bin/bash

INPUT="$1"
RESULTS_DIR="./results"

if [ -z "$INPUT" ]; then
  echo "Usage: ./aaweRT.sh <target_domain OR -l <url_list_file> OR -w <subdomain_wordlist_file>>"
  exit 1
fi

TARGET=""
SUBDOMAIN_LIST_FILE=""

case "$INPUT" in
  -l)
    if [ -z "$2" ]; then
      echo "Usage: ./aaweRT.sh -l <url_list_file>"
      exit 1
    fi
    SUBDOMAIN_LIST_FILE="$2"
    echo "[+] Using URL list from: $SUBDOMAIN_LIST_FILE"
    ;;
  -w)
    if [ -z "$2" ]; then
      echo "Usage: ./aaweRT.sh -w <subdomain_wordlist_file>"
      exit 1
    fi
    SUBDOMAIN_LIST_FILE="$2"
    echo "[+] Using subdomain wordlist from: $SUBDOMAIN_LIST_FILE"
    ;;
  *)
    TARGET="$INPUT"
    echo "[+] Starting AAweRT for target domain: $TARGET"
    ;;
esac

echo "[+] Starting AAweRT - An Awesome Reconnaissance Tool"
echo "================================================================"

# Phase 1: Subdomain Enumeration (Conditional based on input)
if [ -n "$TARGET" ]; then
  echo "[+] Phase 1: Subdomain Enumeration"
  ./subdomain_enumeration.sh "$TARGET"
  echo "--------------------------------------------------------------=="
  SUBDOMAIN_FILE="$RESULTS_DIR/all_subdomains.txt"
elif [ -n "$SUBDOMAIN_LIST_FILE" ]; then
  echo "[+] Skipping Subdomain Enumeration, using provided list."
  cp "$SUBDOMAIN_LIST_FILE" "$RESULTS_DIR/all_subdomains.txt"
  SUBDOMAIN_FILE="$RESULTS_DIR/all_subdomains.txt"
fi

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