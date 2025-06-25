#!/bin/bash

echo "[+] Testing AAweRT Framework"
echo "============================"

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

# Test 3: Check if all dependent scripts exist
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

# Test 5: Check if results directory is created
echo "[+] Test 5: Testing results directory creation..."
if [ -d "results" ]; then
    echo "  ✓ results directory exists"
else
    echo "  ✗ results directory not found (will be created on first run)"
fi

echo ""
echo "[+] AAweRT Framework Test Complete!"
echo "[+] To run the framework: ./aawert.sh <target_domain>" 