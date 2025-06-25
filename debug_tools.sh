#!/bin/bash

echo "[+] AAweRT Tool Diagnostic Script"
echo "================================="

# Check if we're running in Git Bash
echo "[+] Checking environment..."
echo "  Shell: $SHELL"
echo "  PATH: $PATH"
echo "  PWD: $PWD"

# List of required tools
TOOLS=("subfinder" "amass" "assetfinder" "httpx" "katana" "hakrawler" "gau" "ffuf" "dirsearch" "nuclei" "nikto" "s3scanner" "jq")

echo ""
echo "[+] Checking tool availability..."

for tool in "${TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "  ✓ $tool is available"
        # Try to get version
        if "$tool" --version >/dev/null 2>&1; then
            version=$("$tool" --version 2>/dev/null | head -1)
            echo "    Version: $version"
        elif "$tool" -version >/dev/null 2>&1; then
            version=$("$tool" -version 2>/dev/null | head -1)
            echo "    Version: $version"
        else
            echo "    Version: Unknown"
        fi
    else
        echo "  ✗ $tool is NOT available"
    fi
done

echo ""
echo "[+] Testing basic tool execution..."

# Test subfinder
echo "[+] Testing subfinder..."
if command -v subfinder >/dev/null 2>&1; then
    echo "  Running: subfinder -version"
    subfinder -version 2>&1 | head -3
else
    echo "  subfinder not found"
fi

# Test amass
echo "[+] Testing amass..."
if command -v amass >/dev/null 2>&1; then
    echo "  Running: amass -version"
    amass -version 2>&1 | head -3
else
    echo "  amass not found"
fi

# Test assetfinder
echo "[+] Testing assetfinder..."
if command -v assetfinder >/dev/null 2>&1; then
    echo "  Running: assetfinder -version"
    assetfinder -version 2>&1 | head -3
else
    echo "  assetfinder not found"
fi

echo ""
echo "[+] Testing file operations..."
TEST_FILE="test_output.txt"
echo "test content" > "$TEST_FILE"
if [ -f "$TEST_FILE" ]; then
    echo "  ✓ File creation works"
    rm "$TEST_FILE"
else
    echo "  ✗ File creation failed"
fi

echo ""
echo "[+] Diagnostic complete!" 