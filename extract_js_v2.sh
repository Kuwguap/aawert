#!/bin/bash

# JavaScript Extraction Script v2 - Standalone and Integrated
# Usage: ./extract_js_v2.sh <target_domain> <results_dir>
#        ./extract_js_v2.sh -d <target_domain> -r <results_dir>
#        ./extract_js_v2.sh -f <subdomain_file> -r <results_dir>

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
    echo "JavaScript Extraction Script v2"
    echo "==============================="
    echo ""
    echo "Usage:"
    echo "  $0 <target_domain> <results_dir>           # Single domain"
    echo "  $0 -d <target_domain> -r <results_dir>    # Single domain (explicit)"
    echo "  $0 -f <subdomain_file> -r <results_dir>  # Subdomain list file"
    echo ""
    echo "Options:"
    echo "  -d, --domain <domain>        Target domain"
    echo "  -f, --file <file>            Subdomain list file"
    echo "  -r, --results <dir>           Results directory"
    echo "  -v, --verbose                Verbose output"
    echo "  -h, --help                   Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 example.com ./results"
    echo "  $0 -f subdomains.txt -r ./results"
}

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--domain)
                TARGET="$2"
                shift 2
                ;;
            -f|--file)
                SUBDOMAIN_FILE="$2"
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

# Function to validate prerequisites
validate_prerequisites() {
    # Check if httpx is available
    if ! command_exists httpx; then
        print_error "httpx is required but not available!"
        print_error "Please install httpx: go install github.com/projectdiscovery/httpx/cmd/httpx@latest"
        return 1
    fi
    
    # Check if subdomain file exists
    if [[ -n "$SUBDOMAIN_FILE" && ! -f "$SUBDOMAIN_FILE" ]]; then
        print_error "Subdomain file not found: $SUBDOMAIN_FILE"
        return 1
    fi
    
    # Check if all_subdomains.txt exists (for integrated mode)
    if [[ -z "$SUBDOMAIN_FILE" && ! -f "$RESULTS_DIR/all_subdomains.txt" ]]; then
        print_error "No subdomain file found. Run subdomain enumeration first."
        return 1
    fi
    
    print_success "Prerequisites validated"
    return 0
}

# Function to get live subdomains
get_live_subdomains() {
    local input_file="$1"
    local output_file="$2"
    
    print_status "$BLUE" "Getting live subdomains (status 200) with httpx..."
    
    # Use httpx to get live subdomains with status 200
    cat "$input_file" | httpx -silent -status-code -mc 200 -o "$output_file" 2>>"${output_file%.*}_error.log"
    
    if [[ $? -eq 0 ]]; then
        print_success "Live subdomains identified"
        return 0
    else
        print_warning "httpx encountered errors"
        return 1
    fi
}

# Function to extract JavaScript URLs
extract_js_urls() {
    local input_file="$1"
    local output_file="$2"
    local target="$3"
    
    print_status "$BLUE" "Extracting JavaScript URLs..."
    
    # Clear output file
    rm -f "$output_file"
    
    # Extract JavaScript URLs from all input sources
    local temp_file="$RESULTS_DIR/js_files_temp.txt"
    rm -f "$temp_file"
    
    # Extract from live subdomains
    if [[ -f "$input_file" ]]; then
        grep -oE 'https?://[^"\'>]*\.js' "$input_file" >> "$temp_file" 2>/dev/null
    fi
    
    # Extract from parameters.txt if it exists
    if [[ -f "$RESULTS_DIR/parameters.txt" ]]; then
        print_status "$BLUE" "Adding parameters.txt to JavaScript extraction..."
        grep -oE 'https?://[^"\'>]*\.js' "$RESULTS_DIR/parameters.txt" >> "$temp_file" 2>/dev/null
    fi
    
    # Sort and deduplicate
    if [[ -f "$temp_file" ]]; then
        sort -u "$temp_file" > "$output_file"
        rm -f "$temp_file"
    else
        touch "$output_file"
    fi
}

# Function to filter JavaScript URLs by target domain
filter_js_urls() {
    local input_file="$1"
    local output_file="$2"
    local target="$3"
    
    print_status "$BLUE" "Filtering JavaScript URLs to only include $target..."
    
    # Clear output file
    rm -f "$output_file"
    
    # Filter URLs to only include those containing the target domain
    while IFS= read -r js_url; do
        if [[ "$js_url" =~ $target ]]; then
            echo "$js_url" >> "$output_file"
        fi
    done < "$input_file"
}

# Function to generate statistics
generate_statistics() {
    local results_dir="$1"
    local target="$2"
    
    print_status "$CYAN" "JavaScript Extraction Statistics:"
    
    # Count raw JavaScript URLs
    local raw_js_count=0
    if [[ -f "$results_dir/js_files_temp.txt" ]]; then
        raw_js_count=$(wc -l < "$results_dir/js_files_temp.txt" 2>/dev/null || echo "0")
    fi
    
    # Count filtered JavaScript URLs
    local filtered_js_count=0
    if [[ -f "$results_dir/js_files.txt" ]]; then
        filtered_js_count=$(wc -l < "$results_dir/js_files.txt" 2>/dev/null || echo "0")
    fi
    
    # Count live subdomains
    local live_count=0
    if [[ -f "$results_dir/alive_subdomains_for_js.txt" ]]; then
        live_count=$(wc -l < "$results_dir/alive_subdomains_for_js.txt" 2>/dev/null || echo "0")
    fi
    
    echo "  - Live subdomains: $live_count"
    echo "  - Raw JavaScript URLs: $raw_js_count"
    echo "  - Filtered JavaScript URLs: $filtered_js_count"
}

# Main execution
main() {
    # Initialize variables
    TARGET=""
    SUBDOMAIN_FILE=""
    RESULTS_DIR=""
    VERBOSE=false
    
    # Parse arguments
    parse_arguments "$@"
    
    # Check if no arguments provided
    if [[ -z "$TARGET" && -z "$SUBDOMAIN_FILE" ]]; then
        show_usage
        exit 1
    fi
    
    # Set default results directory if not provided
    if [[ -z "$RESULTS_DIR" ]]; then
        RESULTS_DIR="./results"
    fi
    
    # Create results directory
    mkdir -p "$RESULTS_DIR"
    
    print_status "$GREEN" "Starting JavaScript Extraction v2"
    echo "====================================="
    
    # Validate prerequisites
    if ! validate_prerequisites; then
        exit 1
    fi
    
    # Determine input file
    local input_file=""
    if [[ -n "$SUBDOMAIN_FILE" ]]; then
        input_file="$SUBDOMAIN_FILE"
        print_status "$CYAN" "Using subdomain file: $SUBDOMAIN_FILE"
    else
        input_file="$RESULTS_DIR/all_subdomains.txt"
        print_status "$CYAN" "Using subdomain file: $input_file"
    fi
    
    # Check if input file exists and has content
    if [[ ! -f "$input_file" ]]; then
        print_error "Input file not found: $input_file"
        exit 1
    fi
    
    if [[ ! -s "$input_file" ]]; then
        print_error "Input file is empty: $input_file"
        exit 1
    fi
    
    local subdomain_count=$(wc -l < "$input_file" 2>/dev/null || echo "0")
    print_status "$CYAN" "Found $subdomain_count subdomains for JavaScript extraction"
    
    # Get live subdomains
    local live_subdomains_file="$RESULTS_DIR/alive_subdomains_for_js.txt"
    get_live_subdomains "$input_file" "$live_subdomains_file"
    
    # Extract JavaScript URLs
    local js_urls_file="$RESULTS_DIR/js_files_raw.txt"
    extract_js_urls "$live_subdomains_file" "$js_urls_file" "$TARGET"
    
    # Filter JavaScript URLs by target domain
    local filtered_js_file="$RESULTS_DIR/js_files.txt"
    filter_js_urls "$js_urls_file" "$filtered_js_file" "$TARGET"
    
    # Generate statistics
    generate_statistics "$RESULTS_DIR" "$TARGET"
    
    # Check if we got any results
    if [[ -f "$filtered_js_file" && -s "$filtered_js_file" ]]; then
        local js_count=$(wc -l < "$filtered_js_file" 2>/dev/null || echo "0")
        print_success "JavaScript extraction completed!"
        print_status "$CYAN" "Found $js_count JavaScript files for $TARGET"
        print_status "$CYAN" "Results saved to: $filtered_js_file"
        exit 0
    else
        print_warning "No JavaScript files found for $TARGET"
        exit 1
    fi
}

# Run main function
main "$@"