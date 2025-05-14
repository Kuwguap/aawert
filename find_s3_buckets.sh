#!/bin/bash

TARGET="$1"
RESULTS_DIR="./results"

echo "[+] Finding S3 Buckets for $TARGET"

if [ ! -f "$RESULTS_DIR/all_subdomains.txt" ]; then
  echo "Error: $RESULTS_DIR/all_subdomains.txt not found. Run subdomain enumeration first."
  exit 1
fi

echo "  [+] Running s3scanner..."
s3scanner --domain "$TARGET" --output "$RESULTS_DIR/s3_buckets_domain.txt"

echo "  [+] Running s3scanner on subdomains..."
cat "$RESULTS_DIR/all_subdomains.txt" | s3scanner --output "$RESULTS_DIR/s3_buckets_subdomains.txt"

echo "[+] S3 Bucket Finding Complete. Results in $RESULTS_DIR/s3_buckets*.txt"