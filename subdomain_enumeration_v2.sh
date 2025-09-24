#!/bin/bash

# Subdomain Enumeration Script v2 - Standalone and Integrated
# Usage: ./subdomain_enumeration_v2.sh <target_domain> <results_dir>
#        ./subdomain_enumeration_v2.sh -d <target_domain> -r <results_dir>
#        ./subdomain_enumeration_v2.sh -l <domain_list_file> -r <results_dir>
#        ./subdomain_enumeration_v2.sh -w <wordlist_file> -r <results_dir>

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

# Function to show usage
show_usage() {
    echo "Subdomain Enumeration Script v2"
    echo "================================="
    echo ""
    echo "Usage:"
    echo "  $0 <target_domain> <results_dir>           # Single domain"
    echo "  $0 -d <target_domain> -r <results_dir>    # Single domain (explicit)"
    echo "  $0 -l <domain_list_file> -r <results_dir> # Multiple domains from file"
    echo "  $0 -w <wordlist_file> -r <results_dir>     # Custom subdomain wordlist"
    echo ""
    echo "Options:"
    echo "  -d, --domain <domain>        Target domain"
    echo "  -l, --list <file>            Domain list file"
    echo "  -w, --wordlist <file>        Subdomain wordlist file"
    echo "  -r, --results <dir>           Results directory"
    echo "  -v, --verbose                Verbose output"
    echo "  -h, --help                   Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 example.com ./results"
    echo "  $0 -l domains.txt -r ./results"
    echo "  $0 -w wordlist.txt -r ./results"
}

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--domain)
                TARGET="$2"
                shift 2
                ;;
            -l|--list)
                DOMAIN_LIST_FILE="$2"
                shift 2
                ;;
            -w|--wordlist)
                WORDLIST_FILE="$2"
                shift 2
                ;;
            -r|--results)
                RESULTS_DIR="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                if [[ -z "$TARGET" && ! "$1" =~ ^- ]]; then
                    TARGET="$1"
                elif [[ -z "$RESULTS_DIR" && ! "$1" =~ ^- ]]; then
                    RESULTS_DIR="$1"
                fi
                shift
                ;;
        esac
    done
}

# Function to load domains from file
load_domains_from_file() {
    local file="$1"
    local domains=()
    
    if [[ ! -f "$file" ]]; then
        print_error "Domain list file not found: $file"
        return 1
    fi
    
    while IFS= read -r domain; do
        # Skip empty lines and comments
        if [[ -n "$domain" && ! "$domain" =~ ^[[:space:]]*# ]]; then
            domains+=("$domain")
        fi
    done < "$file"
    
    echo "${domains[@]}"
}

# Function to run subfinder
run_subfinder() {
    local domain="$1"
    local output_file="$2"
    
    if command_exists subfinder; then
        print_status "$BLUE" "Running Subfinder on $domain..."
        subfinder -d "$domain" -o "$output_file" -v 2>>"${output_file%.*}_error.log"
        if [[ $? -eq 0 ]]; then
            print_success "Subfinder completed for $domain"
            return 0
        else
            print_warning "Subfinder encountered errors for $domain"
            return 1
        fi
    else
        print_warning "Subfinder not available"
        return 1
    fi
}

# Function to run amass
run_amass() {
    local domain="$1"
    local output_file="$2"
    
    if command_exists amass; then
        print_status "$BLUE" "Running Amass on $domain..."
        amass enum -d "$domain" -o "$output_file" 2>>"${output_file%.*}_error.log"
        
        if [[ $? -eq 0 ]]; then
            print_status "$BLUE" "Processing Amass output..."
            if [[ -f "$output_file" ]]; then
                cat "$output_file" |
                    ( iconv -f ISO-8859-1 -t utf-8 || iconv -f UTF-8 -t utf-8 ) |
                    grep "(FQDN)" | cut -d '(' -f 1 | tr -d ' ' | sort -u > "${output_file%.*}_processed.txt"
                print_success "Amass completed for $domain"
                return 0
            else
                print_warning "Amass output file not found for $domain"
                return 1
            fi
        else
            print_warning "Amass encountered errors for $domain"
            return 1
        fi
    else
        print_warning "Amass not available"
        return 1
    fi
}

# Function to run assetfinder
run_assetfinder() {
    local domain="$1"
    local output_file="$2"
    
    if command_exists assetfinder; then
        print_status "$BLUE" "Running Assetfinder on $domain..."
        assetfinder "$domain" > "$output_file" 2>>"${output_file%.*}_error.log"
        if [[ $? -eq 0 ]]; then
            print_success "Assetfinder completed for $domain"
            return 0
        else
            print_warning "Assetfinder encountered errors for $domain"
            return 1
        fi
    else
        print_warning "Assetfinder not available"
        return 1
    fi
}

# Function to run findomain
run_findomain() {
    local domain="$1"
    local output_file="$2"
    
    if command_exists findomain; then
        print_status "$BLUE" "Running Findomain on $domain..."
        findomain -t "$domain" -o "${output_file%.*}_findomain.txt" 2>>"${output_file%.*}_error.log"
        if [[ $? -eq 0 ]]; then
            print_success "Findomain completed for $domain"
            return 0
        else
            print_warning "Findomain encountered errors for $domain"
            return 1
        fi
    else
        print_warning "Findomain not available"
        return 1
    fi
}

# Function to combine and deduplicate results
combine_results() {
    local results_dir="$1"
    local output_file="$results_dir/all_subdomains.txt"
    
    print_status "$BLUE" "Combining and deduplicating subdomain results..."
    
    # Clear previous results
    rm -f "$output_file"
    
    # Combine all result files
    cat "$results_dir/"*_results.txt "$results_dir/"*_processed.txt 2>/dev/null | sort -u > "$output_file"
    
    # Count results
    local count=$(wc -l < "$output_file" 2>/dev/null || echo "0")
    
    if [[ $count -gt 0 ]]; then
        print_success "Found $count unique subdomains"
        return 0
    else
        print_warning "No subdomains found"
        return 1
    fi
}

# Function to validate prerequisites
validate_prerequisites() {
    local missing_tools=()
    
    # Check for at least one subdomain enumeration tool
    if ! command_exists subfinder && ! command_exists amass && ! command_exists assetfinder && ! command_exists findomain; then
        print_error "No subdomain enumeration tools available!"
        print_error "Please install at least one of: subfinder, amass, assetfinder, findomain"
        return 1
    fi
    
    # List available tools
    print_status "$CYAN" "Available tools:"
    for tool in subfinder amass assetfinder findomain; do
        if command_exists "$tool"; then
            print_success "$tool is available"
        else
            print_warning "$tool is not available"
        fi
    done
    
    return 0
}

# Main execution
main() {
    # Initialize variables
    TARGET=""
    DOMAIN_LIST_FILE=""
    WORDLIST_FILE=""
    RESULTS_DIR=""
    VERBOSE=false
    
    # Parse arguments
    parse_arguments "$@"
    
    # Check if no arguments provided
    if [[ -z "$TARGET" && -z "$DOMAIN_LIST_FILE" && -z "$WORDLIST_FILE" ]]; then
        show_usage
        exit 1
    fi
    
    # Set default results directory if not provided
    if [[ -z "$RESULTS_DIR" ]]; then
        RESULTS_DIR="./results"
    fi
    
    # Create results directory
    mkdir -p "$RESULTS_DIR"
    
    print_status "$GREEN" "Starting Subdomain Enumeration v2"
    echo "=========================================="
    
    # Validate prerequisites
    if ! validate_prerequisites; then
        exit 1
    fi
    
    # Determine domains to enumerate
    local domains_to_enumerate=()
    
    if [[ -n "$TARGET" ]]; then
        domains_to_enumerate+=("$TARGET")
        print_status "$CYAN" "Target: $TARGET"
    elif [[ -n "$DOMAIN_LIST_FILE" ]]; then
        domains_to_enumerate=($(load_domains_from_file "$DOMAIN_LIST_FILE"))
        if [[ ${#domains_to_enumerate[@]} -eq 0 ]]; then
            print_error "No valid domains found in $DOMAIN_LIST_FILE"
            exit 1
        fi
        print_status "$CYAN" "Domain list: $DOMAIN_LIST_FILE"
        print_status "$CYAN" "Domains: ${domains_to_enumerate[*]}"
    elif [[ -n "$WORDLIST_FILE" ]]; then
        print_status "$CYAN" "Wordlist: $WORDLIST_FILE"
        print_warning "Wordlist mode not yet implemented"
        exit 1
    fi
    
    if [[ ${#domains_to_enumerate[@]} -eq 0 ]]; then
        print_error "No valid domains to enumerate"
        exit 1
    fi
    
    # Clear previous results
    rm -f "$RESULTS_DIR/subfinder_results.txt"
    rm -f "$RESULTS_DIR/amass_raw_output.txt"
    rm -f "$RESULTS_DIR/amass_results.txt"
    rm -f "$RESULTS_DIR/assetfinder_results.txt"
    rm -f "$RESULTS_DIR/findomain_results.txt"
    rm -f "$RESULTS_DIR/all_subdomains.txt"
    
    # Run enumeration tools for each domain
    for domain in "${domains_to_enumerate[@]}"; do
        print_status "$PURPLE" "Enumerating subdomains for: $domain"
        
        # Run Subfinder
        run_subfinder "$domain" "$RESULTS_DIR/subfinder_results.txt"
        
        # Run Amass
        run_amass "$domain" "$RESULTS_DIR/amass_raw_output.txt"
        
        # Run Assetfinder
        run_assetfinder "$domain" "$RESULTS_DIR/assetfinder_results.txt"
        
        # Run Findomain
        run_findomain "$domain" "$RESULTS_DIR/findomain_results.txt"
    done
    
    # Combine and deduplicate results
    if combine_results "$RESULTS_DIR"; then
        print_success "Subdomain enumeration completed!"
        print_status "$CYAN" "Results saved to: $RESULTS_DIR/all_subdomains.txt"
        exit 0
    else
        print_error "Subdomain enumeration failed - no results found"
        exit 1
    fi
}

# Run main function
main "$@"