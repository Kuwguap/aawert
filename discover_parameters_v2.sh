#!/bin/bash

# Parameter Discovery Script v2 - Standalone and Integrated
# Usage: ./discover_parameters_v2.sh <target_domain> <results_dir>
#        ./discover_parameters_v2.sh -d <target_domain> -r <results_dir>
#        ./discover_parameters_v2.sh -f <subdomain_file> -r <results_dir>

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
    echo "Parameter Discovery Script v2"
    echo "============================"
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
    # Check if gau is available
    if ! command_exists gau; then
        print_error "gau is required but not available!"
        print_error "Please install gau: go install github.com/lc/gau/v2/cmd/gau@latest"
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

# Function to run gau parameter discovery
run_gau_discovery() {
    local input_file="$1"
    local output_file="$2"
    local target="$3"
    
    print_status "$BLUE" "Running gau parameter discovery..."
    
    # Run gau on all subdomains
    cat "$input_file" | gau > "$output_file" 2>>"${output_file%.*}_error.log"
    
    if [[ $? -eq 0 ]]; then
        print_success "gau parameter discovery completed"
        return 0
    else
        print_warning "gau encountered errors"
        return 1
    fi
}

# Function to filter parameters by target domain
filter_parameters_by_target() {
    local input_file="$1"
    local output_file="$2"
    local target="$3"
    
    print_status "$BLUE" "Filtering parameters to only include $target URLs..."
    
    # Clear output file
    rm -f "$output_file"
    
    # Filter URLs to only include those containing the target domain
    while IFS= read -r url; do
        if [[ "$url" =~ $target ]]; then
            echo "$url" >> "$output_file"
        fi
    done < "$input_file"
}

# Function to extract unique parameters
extract_unique_parameters() {
    local input_file="$1"
    local output_file="$2"
    
    print_status "$BLUE" "Extracting unique parameters..."
    
    # Extract unique parameters from URLs
    cat "$input_file" | grep -oP '(?<=\?)[^&]+' | sort -u > "$output_file"
    
    # Also extract parameters from fragment identifiers
    cat "$input_file" | grep -oP '(?<=#)[^&]+' | sort -u >> "$output_file"
    
    # Remove duplicates
    sort -u -o "$output_file" "$output_file"
}

# Function to generate statistics
generate_statistics() {
    local results_dir="$1"
    local target="$2"
    
    print_status "$CYAN" "Parameter Discovery Statistics:"
    
    # Count raw URLs
    local raw_count=0
    if [[ -f "$results_dir/parameters_raw.txt" ]]; then
        raw_count=$(wc -l < "$results_dir/parameters_raw.txt" 2>/dev/null || echo "0")
    fi
    
    # Count filtered URLs
    local filtered_count=0
    if [[ -f "$results_dir/parameters.txt" ]]; then
        filtered_count=$(wc -l < "$results_dir/parameters.txt" 2>/dev/null || echo "0")
    fi
    
    # Count unique parameters
    local unique_params=0
    if [[ -f "$results_dir/unique_parameters.txt" ]]; then
        unique_params=$(wc -l < "$results_dir/unique_parameters.txt" 2>/dev/null || echo "0")
    fi
    
    echo "  - Raw URLs found: $raw_count"
    echo "  - Filtered URLs: $filtered_count"
    echo "  - Unique parameters: $unique_params"
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
    
    print_status "$GREEN" "Starting Parameter Discovery v2"
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
    print_status "$CYAN" "Found $subdomain_count subdomains for parameter discovery"
    
    # Run gau parameter discovery
    local raw_output="$RESULTS_DIR/parameters_raw.txt"
    if ! run_gau_discovery "$input_file" "$raw_output" "$TARGET"; then
        print_error "Parameter discovery failed"
        exit 1
    fi
    
    # Filter parameters by target domain
    local filtered_output="$RESULTS_DIR/parameters.txt"
    filter_parameters_by_target "$raw_output" "$filtered_output" "$TARGET"
    
    # Extract unique parameters
    local unique_params_output="$RESULTS_DIR/unique_parameters.txt"
    extract_unique_parameters "$filtered_output" "$unique_params_output"
    
    # Generate statistics
    generate_statistics "$RESULTS_DIR" "$TARGET"
    
    # Check if we got any results
    if [[ -f "$filtered_output" && -s "$filtered_output" ]]; then
        local param_count=$(wc -l < "$filtered_output" 2>/dev/null || echo "0")
        print_success "Parameter discovery completed!"
        print_status "$CYAN" "Found $param_count parameters for $TARGET"
        print_status "$CYAN" "Results saved to: $filtered_output"
        exit 0
    else
        print_warning "No parameters found for $TARGET"
        exit 1
    fi
}

# Run main function
main "$@"