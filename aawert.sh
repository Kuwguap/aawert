#!/bin/bash

INPUT="$1"
BASE_RESULTS_DIR="./results"

# Create base results directory if it doesn't exist
mkdir -p "$BASE_RESULTS_DIR"

if [ -z "$INPUT" ]; then
  echo "Usage: ./aawert.sh <target_domain OR -l <domain_list_file> OR -w <subdomain_wordlist_file>>"
  exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check tool availability and provide feedback
check_tool() {
    local tool_name="$1"
    if command_exists "$tool_name"; then
        echo "  ✓ $tool_name is available"
        return 0
    else
        echo "  ✗ $tool_name is NOT available"
        return 1
    fi
}

TARGET=""
DOMAIN_LIST_FILE=""
SUBDOMAIN_WORDLIST_FILE=""
SESSION_NAME=""
SESSION_DIR=""

case "$INPUT" in
  -l)
    if [ -z "$2" ]; then
      echo "Usage: ./aawert.sh -l <domain_list_file>"
      exit 1
    fi
    DOMAIN_LIST_FILE="$2"
    if [ ! -f "$DOMAIN_LIST_FILE" ]; then
      echo "Error: Domain list file '$DOMAIN_LIST_FILE' not found."
      exit 1
    fi
    # Create session name from filename
    SESSION_NAME=$(basename "$DOMAIN_LIST_FILE" | sed 's/\.[^.]*$//')
    SESSION_DIR="$BASE_RESULTS_DIR/$SESSION_NAME"
    echo "[+] Using domain list from: $DOMAIN_LIST_FILE for enumeration."
    echo "[+] Creating session: $SESSION_NAME"
    ;;
  -w)
    if [ -z "$2" ]; then
      echo "Usage: ./aawert.sh -w <subdomain_wordlist_file>"
      exit 1
    fi
    SUBDOMAIN_WORDLIST_FILE="$2"
    if [ ! -f "$SUBDOMAIN_WORDLIST_FILE" ]; then
      echo "Error: Subdomain wordlist file '$SUBDOMAIN_WORDLIST_FILE' not found."
      exit 1
    fi
    # Create session name from filename
    SESSION_NAME=$(basename "$SUBDOMAIN_WORDLIST_FILE" | sed 's/\.[^.]*$//')
    SESSION_DIR="$BASE_RESULTS_DIR/$SESSION_NAME"
    echo "[+] Using subdomain wordlist from: $SUBDOMAIN_WORDLIST_FILE"
    echo "[+] Creating session: $SESSION_NAME"
    ;;
  *)
    TARGET="$INPUT"
    # Create session name from target domain
    SESSION_NAME="$TARGET"
    SESSION_DIR="$BASE_RESULTS_DIR/$SESSION_NAME"
    echo "[+] Starting AAweRT for target domain: $TARGET"
    echo "[+] Creating session: $SESSION_NAME"
    ;;
esac

# Create session directory with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SESSION_DIR="${SESSION_DIR}_${TIMESTAMP}"
mkdir -p "$SESSION_DIR"

# Set the results directory for this session
RESULTS_DIR="$SESSION_DIR"

echo "[+] Session directory created: $SESSION_DIR"
echo "[+] Starting AAweRT - An Awesome Reconnaissance Tool"
echo "================================================================"

# Check tool availability before starting
echo "[+] Checking tool availability..."
TOOLS_AVAILABLE=true

echo "  Subdomain Enumeration Tools:"
check_tool "subfinder" || TOOLS_AVAILABLE=false
check_tool "amass" || TOOLS_AVAILABLE=false
check_tool "assetfinder" || TOOLS_AVAILABLE=false

echo "  HTTP Tools:"
check_tool "httpx" || TOOLS_AVAILABLE=false

echo "  Crawling Tools:"
check_tool "katana" || TOOLS_AVAILABLE=false
check_tool "hakrawler" || TOOLS_AVAILABLE=false

echo "  Discovery Tools:"
check_tool "gau" || TOOLS_AVAILABLE=false
check_tool "ffuf" || TOOLS_AVAILABLE=false
check_tool "dirsearch" || TOOLS_AVAILABLE=false

echo "  Security Tools:"
check_tool "nuclei" || TOOLS_AVAILABLE=false
check_tool "nikto" || TOOLS_AVAILABLE=false
check_tool "s3scanner" || TOOLS_AVAILABLE=false
check_tool "jq" || TOOLS_AVAILABLE=false

if [ "$TOOLS_AVAILABLE" = false ]; then
    echo ""
    echo "[!] Warning: Some tools are missing. This may affect the results."
    echo "[!] Run './install_tools.sh' to install missing tools."
    echo "[!] Continuing with available tools..."
    echo ""
fi

# Phase 1: Subdomain Enumeration (Run each tool for all domains)
echo "[+] Phase 1: Subdomain Enumeration"

# Clear previous results
rm -f "$RESULTS_DIR/subfinder_results.txt"
rm -f "$RESULTS_DIR/amass_raw_output.txt"
rm -f "$RESULTS_DIR/amass_results.txt"
rm -f "$RESULTS_DIR/assetfinder_results.txt"
rm -f "$RESULTS_DIR/findomain_results.txt"
rm -f "$RESULTS_DIR/all_subdomains.txt"

DOMAINS_TO_ENUMERATE=()

if [ -n "$TARGET" ]; then
  DOMAINS_TO_ENUMERATE+=("$TARGET")
elif [ -n "$DOMAIN_LIST_FILE" ]; then
  while IFS= read -r domain; do
    # Skip empty lines and comments
    if [[ -n "$domain" && ! "$domain" =~ ^[[:space:]]*# ]]; then
      DOMAINS_TO_ENUMERATE+=("$domain")
    fi
  done < "$DOMAIN_LIST_FILE"
fi

if [ ${#DOMAINS_TO_ENUMERATE[@]} -eq 0 ]; then
  echo "Error: No valid domains to enumerate."
  exit 1
fi

echo "[+] Domains to enumerate: ${DOMAINS_TO_ENUMERATE[*]}"

# Run Subfinder for all domains (sequential, append)
if command_exists subfinder; then
    echo "[+] Running Subfinder for all targets..."
    rm -f "$RESULTS_DIR/subfinder_results.txt"
    for domain in "${DOMAINS_TO_ENUMERATE[@]}"; do
      echo "  [+] Scanning: $domain"
      subfinder -d "$domain" >> "$RESULTS_DIR/subfinder_results.txt" 2>>"$RESULTS_DIR/subfinder_error.log"
    done
else
    echo "[!] Skipping Subfinder (not available)"
fi

# Run Amass for all domains (sequential, append)
if command_exists amass; then
    echo "[+] Running Amass for all targets..."
    rm -f "$RESULTS_DIR/amass_raw_output.txt"
    for domain in "${DOMAINS_TO_ENUMERATE[@]}"; do
      echo "  [+] Scanning: $domain"
      amass enum -d "$domain" >> "$RESULTS_DIR/amass_raw_output.txt" 2>>"$RESULTS_DIR/amass_error.log"
    done

    # Process Amass output (once all Amass scans are done)
    echo "[+] Processing Amass output..."
    if [ -f "$RESULTS_DIR/amass_raw_output.txt" ]; then
      cat "$RESULTS_DIR/amass_raw_output.txt" |
        ( iconv -f ISO-8859-1 -t utf-8 || iconv -f UTF-8 -t utf-8 ) |
        grep "(FQDN)" | cut -d '(' -f 1 | tr -d ' ' | sort -u > "$RESULTS_DIR/amass_results.txt"
    else
      echo "  [!] Warning: Amass raw output file not found."
    fi
else
    echo "[!] Skipping Amass (not available)"
fi

# Run Assetfinder for all domains (sequential, append)
if command_exists assetfinder; then
    echo "[+] Running Assetfinder for all targets..."
    rm -f "$RESULTS_DIR/assetfinder_results.txt"
    for domain in "${DOMAINS_TO_ENUMERATE[@]}"; do
      echo "  [+] Scanning: $domain"
      assetfinder "$domain" >> "$RESULTS_DIR/assetfinder_results.txt" 2>>"$RESULTS_DIR/assetfinder_error.log"
    done
else
    echo "[!] Skipping Assetfinder (not available)"
fi

# Combine and Deduplicate Subdomains
echo "[+] Combining and Deduplicating Subdomains..."
cat "$RESULTS_DIR/"*_results.txt 2>/dev/null | sort -u > "$RESULTS_DIR/all_subdomains.txt"

# Check if we got any results
if [ -s "$RESULTS_DIR/all_subdomains.txt" ]; then
    echo "[+] Subdomain Enumeration Complete. Found $(wc -l < "$RESULTS_DIR/all_subdomains.txt") subdomains."
else
    echo "[!] Warning: No subdomains found. This may be due to missing tools or network issues."
fi

echo "[+] Results in $RESULTS_DIR/all_subdomains.txt"

# Set the correct file path for subdomains
SUBDOMAIN_FILE="$RESULTS_DIR/all_subdomains.txt"

# Phase 2: Check Live Subdomains
if [ -f "$SUBDOMAIN_FILE" ] && [ -s "$SUBDOMAIN_FILE" ]; then
  if command_exists httpx; then
    echo "[+] Phase 2: Check Live Subdomains"
    # Copy subdomains to the expected file name for check_live_subdomains.sh
    cp "$SUBDOMAIN_FILE" "$RESULTS_DIR/data1.txt"
    ./check_live_subdomains.sh "$TARGET" "$RESULTS_DIR"
    echo "--------------------------------------------------------------=="
    LIVE_SUBDOMAIN_FILE="$RESULTS_DIR/live_subdomains_target.txt"
  else
    echo "[!] Skipping Phase 2: httpx not available"
    LIVE_SUBDOMAIN_FILE=""
  fi
else
  echo "Warning: No subdomain list found or file is empty. Skipping live check."
  LIVE_SUBDOMAIN_FILE=""
fi

# Phase 3: Crawl Subdomains
if [ -f "$LIVE_SUBDOMAIN_FILE" ] && [ -s "$LIVE_SUBDOMAIN_FILE" ]; then
  if command_exists katana || command_exists hakrawler; then
    echo "[+] Phase 3: Crawl Subdomains"
    ./crawl_subdomains.sh "$TARGET" "$RESULTS_DIR"
    echo "--------------------------------------------------------------=="
  else
    echo "[!] Skipping Phase 3: katana and hakrawler not available"
  fi
fi

# Phase 4: Discover Parameters
if [ -f "$LIVE_SUBDOMAIN_FILE" ] && [ -s "$LIVE_SUBDOMAIN_FILE" ]; then
  if command_exists gau; then
    echo "[+] Phase 4: Discover Parameters"
    ./discover_parameters.sh "$TARGET" "$RESULTS_DIR"
    echo "--------------------------------------------------------------=="
  else
    echo "[!] Skipping Phase 4: gau not available"
  fi
fi

# Phase 5: Content Discovery
if [ -f "$LIVE_SUBDOMAIN_FILE" ] && [ -s "$LIVE_SUBDOMAIN_FILE" ]; then
  if command_exists ffuf || command_exists dirsearch; then
    echo "[+] Phase 5: Content Discovery"
    ./content_discovery.sh "$TARGET" "$RESULTS_DIR"
    echo "--------------------------------------------------------------=="
  else
    echo "[!] Skipping Phase 5: ffuf and dirsearch not available"
  fi
fi

# Phase 6: Extract JavaScript Files
if [ -f "$LIVE_SUBDOMAIN_FILE" ] && [ -s "$LIVE_SUBDOMAIN_FILE" ]; then
  if command_exists httpx; then
    echo "[+] Phase 6: Extract JavaScript Files"
    ./extract_js.sh "$TARGET" "$RESULTS_DIR"
    echo "--------------------------------------------------------------=="
  else
    echo "[!] Skipping Phase 6: httpx not available"
  fi
fi

# Phase 7: Find Secrets in JavaScript Files
if [ -f "$RESULTS_DIR/js_files.txt" ] && [ -s "$RESULTS_DIR/js_files.txt" ]; then
  echo "[+] Phase 7: Find Secrets in JavaScript Files"
  ./find_secrets.sh "$TARGET" "$RESULTS_DIR"
  echo "--------------------------------------------------------------=="
fi

# Phase 8: Vulnerability Scan
if [ -f "$LIVE_SUBDOMAIN_FILE" ] && [ -s "$LIVE_SUBDOMAIN_FILE" ]; then
  if command_exists nuclei || command_exists nikto; then
    echo "[+] Phase 8: Vulnerability Scan"
    ./vulnerability_scan.sh "$TARGET" "$RESULTS_DIR"
    echo "--------------------------------------------------------------=="
  else
    echo "[!] Skipping Phase 8: nuclei and nikto not available"
  fi
fi

# Phase 9: Find S3 Buckets
if [ -f "$SUBDOMAIN_FILE" ] && [ -s "$SUBDOMAIN_FILE" ]; then
  if command_exists s3scanner; then
    echo "[+] Phase 9: Find S3 Buckets"
    ./find_s3_buckets.sh "$TARGET" "$RESULTS_DIR"
    echo "--------------------------------------------------------------=="
  else
    echo "[!] Skipping Phase 9: s3scanner not available"
  fi
fi

# Phase 10: Find Login Endpoints
if [ -f "$LIVE_SUBDOMAIN_FILE" ] && [ -s "$LIVE_SUBDOMAIN_FILE" ]; then
  if command_exists ffuf || command_exists dirsearch; then
    echo "[+] Phase 10: Find Login Endpoints"
    ./find_login_endpoints.sh "$TARGET" "$RESULTS_DIR"
    echo "--------------------------------------------------------------=="
  else
    echo "[!] Skipping Phase 10: ffuf and dirsearch not available"
  fi
fi

# Create a session summary
echo "[+] Creating session summary..."
cat > "$SESSION_DIR/session_summary.txt" << EOF
AAweRT Session Summary
=====================
Session Name: $SESSION_NAME
Session Directory: $SESSION_DIR
Timestamp: $(date)
Target(s): ${DOMAINS_TO_ENUMERATE[*]}

Tools Available:
$(for tool in subfinder amass assetfinder httpx katana hakrawler gau ffuf dirsearch nuclei nikto s3scanner jq; do
    if command_exists "$tool"; then
        echo "- $tool: Available"
    else
        echo "- $tool: NOT AVAILABLE"
    fi
done)

Files Generated:
- all_subdomains.txt: Combined subdomain enumeration results
- live_subdomains_target.txt: Live subdomains with HTTP responses
- parameters.txt: Discovered parameters
- js_files.txt: Extracted JavaScript files
- secretfinder_results.txt: Secrets found in JavaScript files
- Various scan results from ffuf, dirsearch, nuclei, nikto, etc.

Session completed at: $(date)
EOF

echo "[+] AAweRT Run Complete. Results are in: $SESSION_DIR"
echo "[+] Session summary saved to: $SESSION_DIR/session_summary.txt"

if [ "$TOOLS_AVAILABLE" = false ]; then
    echo ""
    echo "[!] Some tools were missing during this run."
    echo "[!] For better results, install missing tools: ./install_tools.sh"
fi
