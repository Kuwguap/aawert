#!/bin/bash

echo "[+] AAweRT Tool Installation Script for Windows"
echo "==============================================="

# Check if we're in Git Bash
if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "cygwin" ]]; then
    echo "This script is designed for Windows with Git Bash"
    exit 1
fi

echo "[+] Detected Windows environment with Git Bash"
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Go tools
install_go_tool() {
    local tool_name="$1"
    local install_name="$2"
    
    if command_exists "$tool_name"; then
        echo "  ✓ $tool_name is already installed"
        return 0
    fi
    
    echo "  [+] Installing $tool_name..."
    if command_exists go; then
        go install -v "$install_name@latest"
        if [ $? -eq 0 ]; then
            echo "  ✓ $tool_name installed successfully"
        else
            echo "  ✗ Failed to install $tool_name"
        fi
    else
        echo "  ✗ Go is not installed. Please install Go first."
        return 1
    fi
}

# Check if Go is installed
echo "[+] Checking Go installation..."
if command_exists go; then
    echo "  ✓ Go is installed: $(go version)"
    echo "  Go bin directory: $(go env GOPATH)/bin"
else
    echo "  ✗ Go is not installed"
    echo "  Please install Go from: https://golang.org/dl/"
    echo "  After installation, restart your terminal and run this script again."
    exit 1
fi

echo ""
echo "[+] Installing Go-based tools..."

# Install Go tools
install_go_tool "subfinder" "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
install_go_tool "httpx" "github.com/projectdiscovery/httpx/cmd/httpx@latest"
install_go_tool "katana" "github.com/projectdiscovery/katana/cmd/katana@latest"
install_go_tool "nuclei" "github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest"
install_go_tool "gau" "github.com/lc/gau/v2/cmd/gau@latest"

echo ""
echo "[+] Installing other tools..."

# Check for Python tools
echo "[+] Checking Python tools..."
if command_exists python3; then
    echo "  ✓ Python3 is available"
    
    # Install dirsearch if not available
    if ! command_exists dirsearch; then
        echo "  [+] Installing dirsearch..."
        pip3 install dirsearch
    else
        echo "  ✓ dirsearch is already installed"
    fi
else
    echo "  ✗ Python3 is not available"
fi

# Check for Node.js tools
echo "[+] Checking Node.js tools..."
if command_exists npm; then
    echo "  ✓ npm is available"
    
    # Install hakrawler if not available
    if ! command_exists hakrawler; then
        echo "  [+] Installing hakrawler..."
        npm install -g hakrawler
    else
        echo "  ✓ hakrawler is already installed"
    fi
else
    echo "  ✗ npm is not available"
fi

# Check for Perl tools
echo "[+] Checking Perl tools..."
if command_exists perl; then
    echo "  ✓ Perl is available"
    
    # Install nikto if not available
    if ! command_exists nikto; then
        echo "  [+] Installing nikto..."
        # Note: nikto installation might require additional steps
        echo "  Please install nikto manually or use package manager"
    else
        echo "  ✓ nikto is already installed"
    fi
else
    echo "  ✗ Perl is not available"
fi

# Check for jq
echo "[+] Checking jq..."
if ! command_exists jq; then
    echo "  [+] Installing jq..."
    # For Windows, you might need to download it manually
    echo "  Please download jq from: https://stedolan.github.io/jq/download/"
    echo "  Or install via chocolatey: choco install jq"
else
    echo "  ✓ jq is already installed"
fi

# Check for s3scanner
echo "[+] Checking s3scanner..."
if ! command_exists s3scanner; then
    echo "  [+] Installing s3scanner..."
    if command_exists go; then
        go install github.com/sa7mon/S3Scanner@latest
    else
        echo "  Please install s3scanner manually"
    fi
else
    echo "  ✓ s3scanner is already installed"
fi

# Check for assetfinder
echo "[+] Checking assetfinder..."
if ! command_exists assetfinder; then
    echo "  [+] Installing assetfinder..."
    if command_exists go; then
        go install github.com/tomnomnom/assetfinder@latest
    else
        echo "  Please install assetfinder manually"
    fi
else
    echo "  ✓ assetfinder is already installed"
fi

# Check for amass
echo "[+] Checking amass..."
if ! command_exists amass; then
    echo "  [+] Installing amass..."
    if command_exists go; then
        go install -v github.com/owasp-amass/amass/v4/...@master
    else
        echo "  Please install amass manually"
    fi
else
    echo "  ✓ amass is already installed"
fi

echo ""
echo "[+] Installation Summary:"
echo "========================="

# List all tools and their status
TOOLS=("subfinder" "amass" "assetfinder" "httpx" "katana" "hakrawler" "gau" "ffuf" "dirsearch" "nuclei" "nikto" "s3scanner" "jq")

for tool in "${TOOLS[@]}"; do
    if command_exists "$tool"; then
        echo "  ✓ $tool is available"
    else
        echo "  ✗ $tool is NOT available"
    fi
done

echo ""
echo "[+] Next Steps:"
echo "1. Add Go bin directory to your PATH if not already done:"
echo "   export PATH=\$PATH:\$(go env GOPATH)/bin"
echo ""
echo "2. Restart your terminal or run: source ~/.bashrc"
echo ""
echo "3. Run the diagnostic script again: ./debug_tools.sh"
echo ""
echo "[+] Installation script complete!" 