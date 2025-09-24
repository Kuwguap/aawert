#!/bin/bash

# AAweRT v2 Installation Script
# This script installs all required tools and dependencies

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[+] ${message}${NC}"
}

print_error() {
    echo -e "${RED}[!] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Go tools
install_go_tool() {
    local tool_name="$1"
    local install_name="$2"
    
    if command_exists "$tool_name"; then
        print_success "$tool_name is already installed"
        return 0
    fi
    
    print_status "$BLUE" "Installing $tool_name..."
    if command_exists go; then
        go install -v "$install_name@latest"
        if [ $? -eq 0 ]; then
            print_success "$tool_name installed successfully"
        else
            print_error "Failed to install $tool_name"
        fi
    else
        print_error "Go is not installed. Please install Go first."
        return 1
    fi
}

# Function to install Python tools
install_python_tool() {
    local tool_name="$1"
    local install_command="$2"
    
    if command_exists "$tool_name"; then
        print_success "$tool_name is already installed"
        return 0
    fi
    
    print_status "$BLUE" "Installing $tool_name..."
    if command_exists python3; then
        eval "$install_command"
        if [ $? -eq 0 ]; then
            print_success "$tool_name installed successfully"
        else
            print_error "Failed to install $tool_name"
        fi
    else
        print_error "Python3 is not installed. Please install Python3 first."
        return 1
    fi
}

# Function to install Node.js tools
install_nodejs_tool() {
    local tool_name="$1"
    local install_command="$2"
    
    if command_exists "$tool_name"; then
        print_success "$tool_name is already installed"
        return 0
    fi
    
    print_status "$BLUE" "Installing $tool_name..."
    if command_exists npm; then
        eval "$install_command"
        if [ $? -eq 0 ]; then
            print_success "$tool_name installed successfully"
        else
            print_error "Failed to install $tool_name"
        fi
    else
        print_error "npm is not installed. Please install Node.js first."
        return 1
    fi
}

# Function to install EyeWitness
install_eyewitness() {
    if command_exists eyewitness; then
        print_success "EyeWitness is already installed"
        return 0
    fi
    
    print_status "$BLUE" "Installing EyeWitness..."
    
    # Clone EyeWitness repository
    if [[ ! -d "EyeWitness" ]]; then
        git clone https://github.com/FortyNorthSecurity/EyeWitness.git
    fi
    
    cd EyeWitness/Python
    pip3 install -r requirements.txt
    chmod +x setup/setup.sh
    ./setup/setup.sh
    
    if [ $? -eq 0 ]; then
        print_success "EyeWitness installed successfully"
    else
        print_error "Failed to install EyeWitness"
        return 1
    fi
}

# Main installation function
main() {
    print_status "$GREEN" "Starting AAweRT v2 Installation"
    echo "====================================="
    
    # Check if Go is installed
    print_status "$CYAN" "Checking Go installation..."
    if command_exists go; then
        print_success "Go is installed: $(go version)"
        echo "  Go bin directory: $(go env GOPATH)/bin"
    else
        print_error "Go is not installed"
        print_error "Please install Go from: https://golang.org/dl/"
        print_error "After installation, restart your terminal and run this script again."
        exit 1
    fi
    
    # Install Go tools
    print_status "$CYAN" "Installing Go-based tools..."
    install_go_tool "subfinder" "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    install_go_tool "httpx" "github.com/projectdiscovery/httpx/cmd/httpx@latest"
    install_go_tool "katana" "github.com/projectdiscovery/katana/cmd/katana@latest"
    install_go_tool "nuclei" "github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest"
    install_go_tool "gau" "github.com/lc/gau/v2/cmd/gau@latest"
    install_go_tool "assetfinder" "github.com/tomnomnom/assetfinder@latest"
    install_go_tool "s3scanner" "github.com/sa7mon/S3Scanner@latest"
    
    # Install Amass
    print_status "$CYAN" "Installing Amass..."
    if command_exists amass; then
        print_success "Amass is already installed"
    else
        go install -v github.com/owasp-amass/amass/v4/...@master
        if [ $? -eq 0 ]; then
            print_success "Amass installed successfully"
        else
            print_error "Failed to install Amass"
        fi
    fi
    
    # Install Python tools
    print_status "$CYAN" "Installing Python-based tools..."
    install_python_tool "dirsearch" "pip3 install dirsearch"
    install_python_tool "nikto" "pip3 install nikto"
    
    # Install Node.js tools
    print_status "$CYAN" "Installing Node.js-based tools..."
    install_nodejs_tool "hakrawler" "npm install -g hakrawler"
    
    # Install jq
    print_status "$CYAN" "Installing jq..."
    if command_exists jq; then
        print_success "jq is already installed"
    else
        print_warning "jq installation depends on your system package manager"
        print_warning "Please install jq manually:"
        print_warning "  Ubuntu/Debian: sudo apt install jq"
        print_warning "  CentOS/RHEL: sudo yum install jq"
        print_warning "  macOS: brew install jq"
        print_warning "  Windows: choco install jq"
    fi
    
    # Install EyeWitness
    print_status "$CYAN" "Installing EyeWitness..."
    install_eyewitness
    
    # Add Go bin to PATH if not already there
    print_status "$CYAN" "Setting up PATH..."
    local go_bin_path="$(go env GOPATH)/bin"
    if [[ ":$PATH:" != *":$go_bin_path:"* ]]; then
        echo "export PATH=\$PATH:$go_bin_path" >> ~/.bashrc
        print_success "Added Go bin directory to PATH"
        print_warning "Please run: source ~/.bashrc"
    else
        print_success "Go bin directory already in PATH"
    fi
    
    # Installation summary
    print_status "$CYAN" "Installation Summary:"
    echo "==================="
    
    # List all tools and their status
    TOOLS=("subfinder" "amass" "assetfinder" "httpx" "katana" "hakrawler" "gau" "ffuf" "dirsearch" "nuclei" "nikto" "s3scanner" "jq" "eyewitness")
    
    for tool in "${TOOLS[@]}"; do
        if command_exists "$tool"; then
            print_success "$tool is available"
        else
            print_error "$tool is NOT available"
        fi
    done
    
    print_success "AAweRT v2 installation completed!"
    print_status "$CYAN" "Next steps:"
    echo "1. Restart your terminal or run: source ~/.bashrc"
    echo "2. Run: ./aawert_v2.sh --help"
    echo "3. Start reconnaissance: ./aawert_v2.sh example.com"
}

# Run main function
main "$@"