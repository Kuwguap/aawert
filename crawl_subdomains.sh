#!/bin/bash

TARGET="$1"
RESULTS_DIR="${2:-./results}"

echo "[+] Crawling Live Subdomains for $TARGET"

if [ ! -f "$RESULTS_DIR/live_subdomains_target.txt" ]; then
  echo "Error: $RESULTS_DIR/live_subdomains_target.txt not found. Run live subdomain check first."
  exit 1
fi

# Function to filter URLs to only include those containing the target domain
filter_target_urls() {
    local target_domain="$1"
    local input_file="$2"
    local output_file="$3"
    
    echo "    [+] Filtering URLs to only include $target_domain..."
    cat "$input_file" | while IFS= read -r url; do
        # Check if the URL contains the target domain (case insensitive)
        if [[ "$url" =~ $target_domain ]]; then
            echo "$url" >> "$output_file"
        fi
    done
}

echo "  [+] Crawling with Katana..."
cat "$RESULTS_DIR/live_subdomains_target.txt" | katana -o "$RESULTS_DIR/katana_crawl_results_raw.txt"

# Filter Katana results to only include target domain URLs
filter_target_urls "$TARGET" "$RESULTS_DIR/katana_crawl_results_raw.txt" "$RESULTS_DIR/katana_crawl_results.txt"

echo "  [+] Crawling with Hakrawler..."
cat "$RESULTS_DIR/live_subdomains_target.txt" | while read -r subdomain; do
  echo "    [+] Crawling $subdomain with Hakrawler..."
  hakrawler -subs "$TARGET" "https://$subdomain" | grep -Eo 'https?://[^"]+' >> "$RESULTS_DIR/hakrawler_crawl_results_raw.txt" 2>/dev/null
  hakrawler -subs "$TARGET" "http://$subdomain" | grep -Eo 'https?://[^"]+' >> "$RESULTS_DIR/hakrawler_crawl_results_raw.txt" 2>/dev/null
done

# Filter Hakrawler results to only include target domain URLs
filter_target_urls "$TARGET" "$RESULTS_DIR/hakrawler_crawl_results_raw.txt" "$RESULTS_DIR/hakrawler_crawl_results.txt"

echo "[+] Combining and Deduplicating Crawled Subdomains..."
cat "$RESULTS_DIR/"*_crawl_results.txt | sort -u >> "$RESULTS_DIR/all_subdomains.txt"

# Clean up raw files
rm -f "$RESULTS_DIR/"*_crawl_results_raw.txt

# Show statistics
echo "[+] Crawling Statistics:"
echo "  - Katana found URLs: $(wc -l < "$RESULTS_DIR/katana_crawl_results.txt" 2>/dev/null || echo "0")"
echo "  - Hakrawler found URLs: $(wc -l < "$RESULTS_DIR/hakrawler_crawl_results.txt" 2>/dev/null || echo "0")"
echo "  - Total unique URLs after filtering: $(wc -l < "$RESULTS_DIR/all_subdomains.txt" 2>/dev/null || echo "0")"

echo "[+] Crawling Complete. Updated subdomain list in $RESULTS_DIR/all_subdomains.txt"

