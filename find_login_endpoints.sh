#!/bin/bash

RESULTS_DIR="./results"
WORDLIST="/home/kali/Desktop/Tools/SecLists-master/Discovery/Web-Content/burp-parameter-names.txt" # Replace with your wordlist
#TARGET="example.com" #Added a target, the script requires it.

echo "[+] Finding Login Endpoints for $TARGET"

if [ ! -f "$RESULTS_DIR/live_subdomains_target.txt" ]; then
  echo "Error: $RESULTS_DIR/live_subdomains_target.txt not found. Run live subdomain check first."
  exit 1
fi

echo "  [+] Running ffuf for login paths on main domain..."
cat "$RESULTS_DIR/domains.txt" | while read -r TARGET; do
  ffuf -w "$WORDLIST" -u "https://$TARGET/FUZZ" -o "$RESULTS_DIR/ffuf_login_main.txt"

  echo "  [+] Running dirsearch for login paths on main domain..."
  dirsearch -u "https://$TARGET" -w "$WORDLIST" -o "$RESULTS_DIR/dirsearch_login_main.txt"
  
  done #Added the missing done here

echo "  [+] Running ffuf for login paths on live subdomains..."
cat "$RESULTS_DIR/live_subdomains.txt" | while read -r subdomain; do
  echo "    [+] Running ffuf on https://$subdomain..."
  ffuf -w "$WORDLIST" -u "https://$subdomain/FUZZ" -o "$RESULTS_DIR/ffuf_login_$subdomain.txt"
done

echo "  [+] Running dirsearch for login paths on live subdomains..."
cat "$RESULTS_DIR/live_subdomains.txt" | while read -r subdomain; do
  echo "    [+] Running dirsearch on https://$subdomain..."
  dirsearch -u "https://$subdomain" -w "$WORDLIST" -o "$RESULTS_DIR/dirsearch_login_$subdomain.txt"
done

echo "  [+] Grepping JavaScript files for login keywords..."
grep -i -E '(login|signin|auth|password|username|api/auth)' "$RESULTS_DIR/js_files.txt" > "$RESULTS_DIR/login_endpoints_from_js.txt"
