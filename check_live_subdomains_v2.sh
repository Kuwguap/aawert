#!/bin/bash

# Live Subdomain Detection Script v2 - Standalone and Integrated
# Usage: ./check_live_subdomains_v2.sh <target_domain> <results_dir>
#        ./check_live_subdomains_v2.sh -d <target_domain> -r <results_dir>
#        ./check_live_subdomains_v2.sh -f <subdomain_file> -r <results_dir>

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
    echo "Live Subdomain Detection Script v2"
    echo "===================================="
    echo ""
    echo "Usage:"
    echo "  $0 <target_domain> <results_dir>           # Single domain"
    echo "  $0 -d <target_domain> -r <results_dir>    # Single domain (explicit)"
    echo "  $0 -f <subdomain_file> -r <results_dir>   # Subdomain list file"
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

# Function to run httpx probe
run_httpx_probe() {
    local input_file="$1"
    local output_file="$2"
    local target="$3"
    
    print_status "$BLUE" "Probing subdomains with httpx..."
    
    # Run httpx with status code, server info, and output to file
    cat "$input_file" | httpx -status-code -server -title -tech-detect -o "$output_file" 2>>"${output_file%.*}_error.log"
    
    if [[ $? -eq 0 ]]; then
        print_success "httpx probe completed"
        return 0
    else
        print_warning "httpx encountered errors"
        return 1
    fi
}

# Function to process httpx results
process_httpx_results() {
    local input_file="$1"
    local output_file="$2"
    local target="$3"
    
    print_status "$BLUE" "Processing httpx results..."
    
    # Convert to UTF-8 if needed
    ( iconv -f ISO-8859-1 -t utf-8 "$input_file" -o "${input_file}.utf8" || iconv -f UTF-8 -t utf-8 "$input_file" -o "${input_file}.utf8" )
    
    local processed_file="${input_file}.utf8"
    if [[ ! -f "$processed_file" ]]; then
        processed_file="$input_file"
    fi
    
    # Extract live subdomains (status 200 and 3xx)
    print_status "$BLUE" "Filtering live subdomains (status 200 and 3xx)..."
    
    while IFS= read -r line; do
        # Remove ANSI escape codes
        cleaned_line=$(echo "$line" | sed -e 's/\x1B\[[0-9;]*[a-zA-Z]//g' -e 's/\x1B\][0-9;]*[a-zA-Z]//g')
        
        # Extract URL ending just before [200] or [3xx]
        url=$(echo "$cleaned_line" | grep -oP 'h[^ ]+(?= \[200\]| \[3\d{2}\])')
        status=$(echo "$cleaned_line" | grep -oP '\[(200|3\d{2})\]')
        
        if [[ -n "$url" ]]; then
            echo "$url" >> "$output_file"
        fi
    done < "$processed_file"
    
    # Clean up temporary file
    if [[ -f "${input_file}.utf8" ]]; then
        rm -f "${input_file}.utf8"
    fi
}

# Function to filter results by target domain
filter_by_target() {
    local input_file="$1"
    local output_file="$2"
    local target="$3"
    
    print_status "$BLUE" "Filtering results to only include $target URLs..."
    
    # Clear output file
    rm -f "$output_file"
    
    # Filter URLs to only include those containing the target domain
    while IFS= read -r url; do
        if [[ "$url" =~ $target ]]; then
            echo "$url" >> "$output_file"
        fi
    done < "$input_file"
}

# Function to generate statistics
generate_statistics() {
    local results_dir="$1"
    local target="$2"
    
    print_status "$CYAN" "Live Subdomain Detection Statistics:"
    
    # Count total subdomains
    local total_subdomains=0
    if [[ -f "$results_dir/all_subdomains.txt" ]]; then
        total_subdomains=$(wc -l < "$results_dir/all_subdomains.txt" 2>/dev/null || echo "0")
    fi
    
    # Count live subdomains
    local live_subdomains=0
    if [[ -f "$results_dir/live_subdomains_target.txt" ]]; then
        live_subdomains=$(wc -l < "$results_dir/live_subdomains_target.txt" 2>/dev/null || echo "0")
    fi
    
    # Count HTTP probe results
    local probe_results=0
    if [[ -f "$results_dir/http_probe_results.txt" ]]; then
        probe_results=$(wc -l < "$results_dir/http_probe_results.txt" 2>/dev/null || echo "0")
    fi
    
    echo "  - Total subdomains: $total_subdomains"
    echo "  - Live subdomains: $live_subdomains"
    echo "  - HTTP probe results: $probe_results"
    
    if [[ $total_subdomains -gt 0 ]]; then
        local percentage=$((live_subdomains * 100 / total_subdomains))
        echo "  - Live percentage: $percentage%"
    fi
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
    
    print_status "$GREEN" "Starting Live Subdomain Detection v2"
    echo "============================================="
    
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
    print_status "$CYAN" "Found $subdomain_count subdomains to probe"
    
    # Run httpx probe
    local probe_output="$RESULTS_DIR/http_probe_results_raw.txt"
    if ! run_httpx_probe "$input_file" "$probe_output" "$TARGET"; then
        print_error "httpx probe failed"
        exit 1
    fi
    
    # Process httpx results
    local processed_output="$RESULTS_DIR/http_probe_results.txt"
    process_httpx_results "$probe_output" "$processed_output" "$TARGET"
    
    # Filter results by target domain
    local filtered_output="$RESULTS_DIR/live_subdomains_target.txt"
    filter_by_target "$processed_output" "$filtered_output" "$TARGET"
    
    # Generate statistics
    generate_statistics "$RESULTS_DIR" "$TARGET"
    
    # Check if we got any results
    if [[ -f "$filtered_output" && -s "$filtered_output" ]]; then
        local live_count=$(wc -l < "$filtered_output" 2>/dev/null || echo "0")
        print_success "Live subdomain detection completed!"
        print_status "$CYAN" "Found $live_count live subdomains"
        print_status "$CYAN" "Results saved to: $filtered_output"
        exit 0
    else
        print_warning "No live subdomains found"
        exit 1
    fi
}

# Run main function
main "$@"