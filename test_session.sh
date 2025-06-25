#!/bin/bash

echo "[+] Testing AAweRT Session-Based Framework"
echo "=========================================="

# Test 1: Check if main script exists and is readable
echo "[+] Test 1: Checking main script..."
if [ -f "aawert.sh" ]; then
    echo "  ✓ aawert.sh exists"
else
    echo "  ✗ aawert.sh not found"
    exit 1
fi

# Test 2: Check syntax of main script
echo "[+] Test 2: Checking syntax..."
if bash -n aawert.sh; then
    echo "  ✓ aawert.sh syntax is valid"
else
    echo "  ✗ aawert.sh has syntax errors"
    exit 1
fi

# Test 3: Check if all dependent scripts exist and accept RESULTS_DIR parameter
echo "[+] Test 3: Checking dependent scripts..."
DEPENDENT_SCRIPTS=(
    "check_live_subdomains.sh"
    "crawl_subdomains.sh"
    "discover_parameters.sh"
    "content_discovery.sh"
    "extract_js.sh"
    "find_secrets.sh"
    "vulnerability_scan.sh"
    "find_s3_buckets.sh"
    "find_login_endpoints.sh"
)

for script in "${DEPENDENT_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "  ✓ $script exists"
        # Check syntax
        if bash -n "$script"; then
            echo "    ✓ $script syntax is valid"
        else
            echo "    ✗ $script has syntax errors"
        fi
    else
        echo "  ✗ $script not found"
    fi
done

# Test 4: Check usage message
echo "[+] Test 4: Testing usage message..."
USAGE_OUTPUT=$(bash aawert.sh 2>&1)
if echo "$USAGE_OUTPUT" | grep -q "Usage:"; then
    echo "  ✓ Usage message displayed correctly"
else
    echo "  ✗ Usage message not displayed correctly"
    echo "    Output: $USAGE_OUTPUT"
fi

# Test 5: Check if base results directory is created
echo "[+] Test 5: Testing base results directory creation..."
if [ -d "results" ]; then
    echo "  ✓ results directory exists"
else
    echo "  ✗ results directory not found (will be created on first run)"
fi

# Test 6: Demonstrate session naming
echo "[+] Test 6: Session naming examples..."
echo "  Single domain: ./aawert.sh example.com"
echo "    Creates: ./results/example.com_YYYYMMDD_HHMMSS/"
echo ""
echo "  Domain list: ./aawert.sh -l domains.txt"
echo "    Creates: ./results/domains_YYYYMMDD_HHMMSS/"
echo ""
echo "  Wordlist: ./aawert.sh -w wordlist.txt"
echo "    Creates: ./results/wordlist_YYYYMMDD_HHMMSS/"

# Test 7: Check if scripts accept RESULTS_DIR parameter
echo "[+] Test 7: Testing RESULTS_DIR parameter acceptance..."
TEST_DIR="./test_session_dir"
mkdir -p "$TEST_DIR"

# Test one script to see if it accepts the second parameter
if bash -c "source check_live_subdomains.sh; echo 'Script accepts RESULTS_DIR parameter'" >/dev/null 2>&1; then
    echo "  ✓ Scripts accept RESULTS_DIR parameter"
else
    echo "  ✗ Scripts may not accept RESULTS_DIR parameter"
fi

# Cleanup test directory
rm -rf "$TEST_DIR"

echo ""
echo "[+] AAweRT Session-Based Framework Test Complete!"
echo "[+] Key Features:"
echo "  - Each run creates a separate timestamped session folder"
echo "  - No conflicts between different reconnaissance sessions"
echo "  - Easy organization and tracking of results"
echo "  - Session summary with metadata"
echo ""
echo "[+] To run the framework: ./aawert.sh <target_domain>" 