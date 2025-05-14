#!/bin/bash

TARGET="$1"
RESULTS_DIR="./results"

echo "[+] Finding Secrets in JavaScript Files for $TARGET"

if [ ! -f "$RESULTS_DIR/js_files.txt" ]; then
  echo "Error: $RESULTS_DIR/js_files.txt not found. Run JavaScript extraction first."
  exit 1
fi

echo "  [+] Running secret-finder..."
secret-finder -i "$RESULTS_DIR/js_files.txt" -o "$RESULTS_DIR/secrets.txt"

echo "[+] Secret Finding Complete. Results in $RESULTS_DIR/secrets.txt"