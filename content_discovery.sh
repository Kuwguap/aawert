#!/bin/bash

TARGET="$1"
RESULTS_DIR="./results"
WORDLIST="/path/to/your/wordlist.txt" # Replace with your wordlist path

echo "[+] Starting Content Discovery for $TARGET"

if [ ! -f "$RESULTS_DIR/live_subdomains.txt" ]; then
  echo "Error: $RESULTS_DIR/live_subdomains.txt not found. Run live subdomain check first."
  exit 1
fi

echo "  [+] Running ffuf on main domain..."
ffuf -w "$WORDLIST" -u "https://$TARGET/FUZZ" -recursion -o "$RESULTS_DIR/ffuf_main.txt"

echo "  [+] Running dirsearch on main domain..."
python3 dirsearch.py -u "https://$TARGET" -w "$WORDLIST" -r -o "$RESULTS_DIR/dirsearch_main.txt"

echo "  [+] Running ffuf on live subdomains..."
cat "$RESULTS_DIR/live_subdomains.txt" | while read -r subdomain; do
  echo "    [+] Running ffuf on https://$subdomain..."
  ffuf -w "$WORDLIST" -u "https://$subdomain/FUZZ" -recursion -o "$RESULTS_DIR/ffuf_$subdomain.txt"
done

echo "  [+] Running dirsearch on live subdomains..."
cat "$RESULTS_DIR/live_subdomains.txt" | while read -r subdomain; do
  echo "    [+] Running dirsearch on https://$subdomain..."
  python3 dirsearch.py -u "https://$subdomain" -w "$WORDLIST" -r -o "$RESULTS_DIR/dirsearch_$subdomain.txt"
done

echo "[+] Content Discovery Complete. Results in $RESULTS_DIR/"*discovery*.txt"