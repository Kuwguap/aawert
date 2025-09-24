# Make all scripts executable
chmod +x *_v2.sh

# Install all dependencies
./install_aawert_v2.sh

# Create AI configuration
cp ai_config.json.example ai_config.json
# Edit ai_config.json and add your Gemini API key

# Full reconnaissance with AI analysis
./aawert_v2.sh --ai example.com
./aawert_v2.sh --ai -l domains.txt
./aawert_v2.sh --ai -w wordlist.txt

# Full reconnaissance with custom timeout
./aawert_v2.sh -t 600 example.com  # 10 minute timeout
./aawert_v2.sh --ai -t 600 example.com  # AI analysis with 10 minute timeout

# Standalone phases with timeouts
./aawert_v2.sh --standalone subdomain example.com
./aawert_v2.sh --standalone ai example.com

# Individual improved scripts with timeouts
./subdomain_enumeration_v2.sh example.com ./results
./check_live_subdomains_v2.sh example.com ./results
./crawl_subdomains_v2.sh example.com ./results
./discover_parameters_v2.sh example.com ./results
./content_discovery_v2.sh example.com ./results
./extract_js_v2.sh example.com ./results
./find_secrets_v2.sh example.com ./results
./find_s3_buckets_v2.sh example.com ./results
./find_login_endpoints_v2.sh example.com ./results
./take_screenshots_v2.sh example.com ./results
./ai_analysis_v2.sh example.com ./results

# AI analysis only
./ai_analysis_v2.sh -f ./results/example.com_20241201_143022 -r ./results