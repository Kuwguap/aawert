#!/bin/bash

TARGET="$1"
RESULTS_DIR="./results"

echo "[+] Starting Subdomain Enumeration for $TARGET"

# Run Subfinder
echo "  [+] Running Subfinder..."
subfinder -d "$TARGET" -o "$RESULTS_DIR/subfinder_results.txt"

# Run Amass
echo "  [+] Running Amass..."
amass enum -d "$TARGET" -o "$RESULTS_DIR/amass_results.txt"

# Run Assetfinder
echo "  [+] Running Assetfinder..."
assetfinder "$TARGET" > "$RESULTS_DIR/assetfinder_results.txt"

# Run Findomain
echo "  [+] Running Findomain..."
findomain -t "$TARGET" -o "$RESULTS_DIR/findomain_results.txt"

# Run Chaos-DNS (requires API key, adjust accordingly)
echo "  [+] Running Chaos-DNS..."
# chaos -d "$TARGET" -o "$RESULTS_DIR/chaos_dns_results.txt" # Uncomment and configure if you have the CLI

# Combine and Deduplicate Subdomains
echo "[+] Combining and Deduplicating Subdomains..."
cat "$RESULTS_DIR/"*_results.txt | sort -u > "$RESULTS_DIR/all_subdomains.txt"

echo "[+] Subdomain Enumeration Complete. Results in $RESULTS_DIR/all_subdomains.txt"