#!/bin/bash

# S3 Bucket Discovery Script v2 - Standalone and Integrated
# Usage: ./find_s3_buckets_v2.sh <target_domain> <results_dir>
#        ./find_s3_buckets_v2.sh -d <target_domain> -r <results_dir>
#        ./find_s3_buckets_v2.sh -f <subdomain_file> -r <results_dir>

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
    echo "S3 Bucket Discovery Script v2"
    echo "============================="
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
    # Check if s3scanner is available
    if ! command_exists s3scanner; then
        print_error "s3scanner is required but not available!"
        print_error "Please install s3scanner: go install github.com/sa7mon/S3Scanner@latest"
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

# Function to run s3scanner on main domain
run_s3scanner_main_domain() {
    local target="$1"
    local output_file="$2"
    
    print_status "$BLUE" "Running s3scanner on main domain: $target"
    
    # Run s3scanner on main domain
    s3scanner --domain "$target" --output "$output_file" 2>>"${output_file%.*}_error.log"
    
    if [[ $? -eq 0 ]]; then
        print_success "s3scanner completed for main domain: $target"
        return 0
    else
        print_warning "s3scanner encountered errors for main domain: $target"
        return 1
    fi
}

# Function to run s3scanner on subdomains
run_s3scanner_subdomains() {
    local input_file="$1"
    local output_file="$2"
    local target="$3"
    
    print_status "$BLUE" "Running s3scanner on subdomains..."
    
    # Run s3scanner on all subdomains
    cat "$input_file" | s3scanner --output "$output_file" 2>>"${output_file%.*}_error.log"
    
    if [[ $? -eq 0 ]]; then
        print_success "s3scanner completed for subdomains"
        return 0
    else
        print_warning "s3scanner encountered errors for subdomains"
        return 1
    fi
}

# Function to combine and deduplicate S3 results
combine_s3_results() {
    local results_dir="$1"
    local target="$2"
    
    print_status "$BLUE" "Combining and deduplicating S3 bucket results..."
    
    # Combine all S3 results
    local combined_file="$results_dir/s3_buckets_combined.txt"
    rm -f "$combined_file"
    
    # Combine main domain and subdomain results
    cat "$results_dir/s3_buckets_domain.txt" "$results_dir/s3_buckets_subdomains.txt" 2>/dev/null | sort -u > "$combined_file"
    
    # Filter results to only include target domain related buckets
    local filtered_file="$results_dir/s3_buckets_filtered.txt"
    rm -f "$filtered_file"
    
    while IFS= read -r bucket; do
        if [[ "$bucket" =~ $target ]]; then
            echo "$bucket" >> "$filtered_file"
        fi
    done < "$combined_file"
    
    # Count results
    local total_buckets=$(wc -l < "$combined_file" 2>/dev/null || echo "0")
    local filtered_buckets=$(wc -l < "$filtered_file" 2>/dev/null || echo "0")
    
    print_success "Found $total_buckets total S3 buckets, $filtered_buckets filtered for target domain"
}

# Function to generate statistics
generate_statistics() {
    local results_dir="$1"
    local target="$2"
    
    print_status "$CYAN" "S3 Bucket Discovery Statistics:"
    
    # Count main domain results
    local domain_count=0
    if [[ -f "$results_dir/s3_buckets_domain.txt" ]]; then
        domain_count=$(wc -l < "$results_dir/s3_buckets_domain.txt" 2>/dev/null || echo "0")
    fi
    
    # Count subdomain results
    local subdomain_count=0
    if [[ -f "$results_dir/s3_buckets_subdomains.txt" ]]; then
        subdomain_count=$(wc -l < "$results_dir/s3_buckets_subdomains.txt" 2>/dev/null || echo "0")
    fi
    
    # Count filtered results
    local filtered_count=0
    if [[ -f "$results_dir/s3_buckets_filtered.txt" ]]; then
        filtered_count=$(wc -l < "$results_dir/s3_buckets_filtered.txt" 2>/dev/null || echo "0")
    fi
    
    echo "  - Main domain S3 buckets: $domain_count"
    echo "  - Subdomain S3 buckets: $subdomain_count"
    echo "  - Filtered S3 buckets: $filtered_count"
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
    
    print_status "$GREEN" "Starting S3 Bucket Discovery v2"
    echo "===================================="
    
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
    print_status "$CYAN" "Found $subdomain_count subdomains for S3 bucket discovery"
    
    # Run s3scanner on main domain
    local domain_output="$RESULTS_DIR/s3_buckets_domain.txt"
    run_s3scanner_main_domain "$TARGET" "$domain_output"
    
    # Run s3scanner on subdomains
    local subdomain_output="$RESULTS_DIR/s3_buckets_subdomains.txt"
    run_s3scanner_subdomains "$input_file" "$subdomain_output" "$TARGET"
    
    # Combine and deduplicate results
    combine_s3_results "$RESULTS_DIR" "$TARGET"
    
    # Generate statistics
    generate_statistics "$RESULTS_DIR" "$TARGET"
    
    # Check if we got any results
    if [[ -f "$RESULTS_DIR/s3_buckets_filtered.txt" && -s "$RESULTS_DIR/s3_buckets_filtered.txt" ]]; then
        local bucket_count=$(wc -l < "$RESULTS_DIR/s3_buckets_filtered.txt" 2>/dev/null || echo "0")
        print_success "S3 bucket discovery completed!"
        print_status "$CYAN" "Found $bucket_count S3 buckets for $TARGET"
        print_status "$CYAN" "Results saved to: $RESULTS_DIR/s3_buckets_filtered.txt"
        exit 0
    else
        print_warning "No S3 buckets found for $TARGET"
        exit 1
    fi
}

# Run main function
main "$@"