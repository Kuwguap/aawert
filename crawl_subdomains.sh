#!/bin/bash

TARGET="$1"
RESULTS_DIR="./results"

echo "[+] Crawling Live Subdomains for $TARGET"

if [ ! -f "$RESULTS_DIR/live_subdomains.txt" ]; then
  echo "Error: $RESULTS_DIR/live_subdomains.txt not found. Run live subdomain check first."
  exit 1
fi

echo "  [+] Crawling with Katana..."
cat "$RESULTS_DIR/live_subdomains.txt" | katana -o "$RESULTS_DIR/katana_crawl_results.txt"

echo "  [+] Crawling with Hakrawler..."
cat "$RESULTS_DIR/live_subdomains.txt" | while read -r subdomain; do
  echo "    [+] Crawling $subdomain with Hakrawler..."
  hakrawler "https://$subdomain" | grep -Eo 'https?://[^"]+' >> "$RESULTS_DIR/hakrawler_crawl_results.txt" 2>/dev/null
  hakrawler "http://$subdomain" | grep -Eo 'https?://[^"]+' >> "$RESULTS_DIR/hakrawler_crawl_results.txt" 2>/dev/null
done

echo "[+] Combining and Deduplicating Crawled Subdomains..."
cat "$RESULTS_DIR/"*_crawl_results.txt | sort -u >> "$RESULTS_DIR/all_subdomains.txt"

echo "[+] Crawling Complete. Updated subdomain list in $RESULTS_DIR/all_subdomains.txt"