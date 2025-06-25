#!/bin/bash

TARGET="$1"
RESULTS_DIR="./results"
SECRETFINDER_PATH="/home/kali/Desktop/Tools/SecretFinder/SecretFinder.py" # Replace with the actual path to SecretFinder.py
OUTPUT_FILE="$RESULTS_DIR/secretfinder_results.txt"

echo "[+] Finding potential secrets in JavaScript files for $TARGET using SecretFinder"

if [ ! -f "$RESULTS_DIR/js_files.txt" ]; then
  echo "Error: $RESULTS_DIR/js_files.txt not found. Run JavaScript extraction first."
  exit 1
fi

echo "[+] Running SecretFinder..."

echo "" > "$OUTPUT_FILE" # Clear the output file

cat "$RESULTS_DIR/js_files.txt" | while IFS= read -r JS_FILE; do
  echo "  [+] Scanning: $JS_FILE"
  python3 "$SECRETFINDER_PATH" -i "$JS_FILE" -o cli >> "$OUTPUT_FILE"
done

echo "[+] SecretFinder scan complete. Results in $OUTPUT_FILE"
