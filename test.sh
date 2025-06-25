#!/bin/bash
TARGET="oppo.com"
RESULTS_DIR="./results"
NUCLEI_TEMPLATES="/Desktop/Tools/nuclei-templates"
SUBDOMAINS_ALIVE="$RESULTS_DIR/live_subdomains.txt"
SCRIPT_PATH="$0"

echo "[+] Starting Vulnerability Scan for $TARGET"

if [ ! -f "$SUBDOMAINS_ALIVE" ]; then
  echo "Error: $SUBDOMAINS_ALIVE not found. Run live subdomain check first."
  exit 1
fi

echo "  [+] Scanning main domain with Nuclei (cves,osint,tech)..."
nuclei -list "https://$TARGET" -o "$RESULTS_DIR/nuclei_main_cves_osint_tech.txt"

echo "  [+] Scanning main domain with Nikto..."
nikto -h "https://$TARGET" -output "$RESULTS_DIR/nikto_main_report.txt"

echo "  [+] Scanning live subdomains with Nuclei (cves,osint,tech)..."
cat "$SUBDOMAINS_ALIVE" | while read -r subdomain; do
  echo "    [+] Scanning $subdomain with Nuclei (cves,osint,tech)..."
  nuclei -list "https://$subdomain" -o "$RESULTS_DIR/nuclei_$subdomain_cves_osint_tech.txt"
  echo "    [+] Scanning $subdomain with Nikto..."
  nikto -h "https://$subdomain" -output "$RESULTS_DIR/nikto_$subdomain_report.txt"
done

echo "[+] Vulnerability Scan Complete. Results are in $RESULTS_DIR/"*scan*.txt and $RESULTS_DIR/"*report*.txt"
