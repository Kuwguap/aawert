#!/bin/bash

TARGET="$1"
RESULTS_DIR="./results"
WORDLIST="/path/to/your/login_wordlist.txt" # Replace with your login wordlist path

echo "[+] Finding Login Endpoints for $TARGET"

if [ ! -f "$RESULTS_DIR/live_subdomains.txt" ]; then
  echo "Error: $RESULTS_DIR/live_subdomains.txt not found. Run live subdomain check first."
  exit 1
fi

echo "  [+] Running ffuf for login paths on main domain..."
ffuf -w "$WORDLIST" -u "https://$TARGET/FUZZ" -o "$RESULTS_DIR/ffuf_login_main.txt"

echo "  [+] Running dirsearch for login paths on main domain..."
python3 dirsearch.py -u "https://$TARGET" -w "$WORDLIST" -o "$RESULTS_DIR/dirsearch_login_main.txt"

echo "  [+] Running ffuf for login paths on live subdomains..."
cat "$RESULTS_DIR/live_subdomains.txt" | while read -r subdomain; do
  echo "    [+] Running ffuf on https://$subdomain..."
  ffuf -w "$WORDLIST" -u "https://$subdomain/FUZZ" -o "$RESULTS_DIR/ffuf_login_$subdomain.txt"
done

echo "  [+] Running dirsearch for login paths on live subdomains..."
cat "$RESULTS_DIR/live_subdomains.txt" | while read -r subdomain; do
  echo "    [+] Running dirsearch on https://$subdomain..."
  python3 dirsearch.py -u "https://$subdomain" -w "$WORDLIST" -o "$RESULTS_DIR/dirsearch_login_$subdomain.txt"
done

echo "  [+] Grepping JavaScript files for login keywords..."
grep -i -E '(login|signin|auth|password|username|api/auth)' "$RESULTS_DIR/js_files.txt" > "$RESULTS_DIR/login_endpoints_from_js.txt"

echo "[+] Login Endpoint Finding Complete. Results in $RESULTS_DIR/"*login*.txt"