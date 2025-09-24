#!/bin/bash

# EyeWitness Screenshot Script v2 - Standalone and Integrated
# Usage: ./take_screenshots_v2.sh <target_domain> <results_dir>
#        ./take_screenshots_v2.sh -d <target_domain> -r <results_dir>
#        ./take_screenshots_v2.sh -f <live_subdomains_file> -r <results_dir>

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
    echo "EyeWitness Screenshot Script v2"
    echo "==============================="
    echo ""
    echo "Usage:"
    echo "  $0 <target_domain> <results_dir>           # Single domain"
    echo "  $0 -d <target_domain> -r <results_dir>    # Single domain (explicit)"
    echo "  $0 -f <live_subdomains_file> -r <results_dir> # Live subdomains file"
    echo ""
    echo "Options:"
    echo "  -d, --domain <domain>        Target domain"
    echo "  -f, --file <file>            Live subdomains file"
    echo "  -r, --results <dir>           Results directory"
    echo "  -t, --timeout <seconds>      Screenshot timeout (default: 30)"
    echo "  -v, --verbose                Verbose output"
    echo "  -h, --help                   Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 example.com ./results"
    echo "  $0 -f live_subdomains.txt -r ./results"
    echo "  $0 -t 60 -r ./results"
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
                LIVE_SUBDOMAINS_FILE="$2"
                shift 2
                ;;
            -r|--results)
                RESULTS_DIR="$2"
                shift 2
                ;;
            -t|--timeout)
                TIMEOUT="$2"
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
    # Check if EyeWitness is available
    if ! command_exists eyewitness; then
        print_error "EyeWitness is required but not available!"
        print_error "Please install EyeWitness: https://github.com/FortyNorthSecurity/EyeWitness"
        return 1
    fi
    
    # Check if live subdomains file exists
    if [[ -n "$LIVE_SUBDOMAINS_FILE" && ! -f "$LIVE_SUBDOMAINS_FILE" ]]; then
        print_error "Live subdomains file not found: $LIVE_SUBDOMAINS_FILE"
        return 1
    fi
    
    # Check if live_subdomains_target.txt exists (for integrated mode)
    if [[ -z "$LIVE_SUBDOMAINS_FILE" && ! -f "$RESULTS_DIR/live_subdomains_target.txt" ]]; then
        print_error "No live subdomains file found. Run live subdomain detection first."
        return 1
    fi
    
    print_success "Prerequisites validated"
    return 0
}

# Function to prepare URLs for EyeWitness
prepare_urls_for_eyewitness() {
    local input_file="$1"
    local output_file="$2"
    local target="$3"
    
    print_status "$BLUE" "Preparing URLs for EyeWitness..."
    
    # Clear output file
    rm -f "$output_file"
    
    # Add main domain if provided
    if [[ -n "$TARGET" ]]; then
        echo "https://$TARGET" >> "$output_file"
        echo "http://$TARGET" >> "$output_file"
    fi
    
    # Add live subdomains
    while IFS= read -r subdomain; do
        if [[ -n "$subdomain" ]]; then
            # Add both HTTP and HTTPS versions
            echo "https://$subdomain" >> "$output_file"
            echo "http://$subdomain" >> "$output_file"
        fi
    done < "$input_file"
    
    # Remove duplicates
    sort -u -o "$output_file" "$output_file"
    
    local url_count=$(wc -l < "$output_file" 2>/dev/null || echo "0")
    print_success "Prepared $url_count URLs for EyeWitness"
}

# Function to run EyeWitness
run_eyewitness() {
    local urls_file="$1"
    local output_dir="$2"
    local timeout="$3"
    
    print_status "$BLUE" "Running EyeWitness screenshot capture..."
    
    # Create EyeWitness output directory
    local eyewitness_dir="$output_dir/eyewitness_screenshots"
    mkdir -p "$eyewitness_dir"
    
    # Run EyeWitness
    eyewitness -f "$urls_file" -d "$eyewitness_dir" --timeout "$timeout" --no-prompt 2>>"$output_dir/eyewitness_error.log"
    
    if [[ $? -eq 0 ]]; then
        print_success "EyeWitness screenshot capture completed"
        return 0
    else
        print_warning "EyeWitness encountered errors"
        return 1
    fi
}

# Function to generate statistics
generate_statistics() {
    local results_dir="$1"
    local target="$2"
    
    print_status "$CYAN" "Screenshot Statistics:"
    
    # Count URLs processed
    local url_count=0
    if [[ -f "$results_dir/eyewitness_urls.txt" ]]; then
        url_count=$(wc -l < "$results_dir/eyewitness_urls.txt" 2>/dev/null || echo "0")
    fi
    
    # Count screenshots taken
    local screenshot_count=0
    if [[ -d "$results_dir/eyewitness_screenshots" ]]; then
        screenshot_count=$(find "$results_dir/eyewitness_screenshots" -name "*.png" | wc -l 2>/dev/null || echo "0")
    fi
    
    echo "  - URLs processed: $url_count"
    echo "  - Screenshots taken: $screenshot_count"
}

# Main execution
main() {
    # Initialize variables
    TARGET=""
    LIVE_SUBDOMAINS_FILE=""
    RESULTS_DIR=""
    TIMEOUT="30"
    VERBOSE=false
    
    # Parse arguments
    parse_arguments "$@"
    
    # Check if no arguments provided
    if [[ -z "$TARGET" && -z "$LIVE_SUBDOMAINS_FILE" ]]; then
        show_usage
        exit 1
    fi
    
    # Set default results directory if not provided
    if [[ -z "$RESULTS_DIR" ]]; then
        RESULTS_DIR="./results"
    fi
    
    # Create results directory
    mkdir -p "$RESULTS_DIR"
    
    print_status "$GREEN" "Starting EyeWitness Screenshot Capture v2"
    echo "============================================="
    
    # Validate prerequisites
    if ! validate_prerequisites; then
        exit 1
    fi
    
    # Determine input file
    local input_file=""
    if [[ -n "$LIVE_SUBDOMAINS_FILE" ]]; then
        input_file="$LIVE_SUBDOMAINS_FILE"
        print_status "$CYAN" "Using live subdomains file: $LIVE_SUBDOMAINS_FILE"
    else
        input_file="$RESULTS_DIR/live_subdomains_target.txt"
        print_status "$CYAN" "Using live subdomains file: $input_file"
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
    print_status "$CYAN" "Found $subdomain_count live subdomains for screenshot capture"
    print_status "$CYAN" "Screenshot timeout: ${TIMEOUT}s"
    
    # Prepare URLs for EyeWitness
    local urls_file="$RESULTS_DIR/eyewitness_urls.txt"
    prepare_urls_for_eyewitness "$input_file" "$urls_file" "$TARGET"
    
    # Run EyeWitness
    if run_eyewitness "$urls_file" "$RESULTS_DIR" "$TIMEOUT"; then
        # Generate statistics
        generate_statistics "$RESULTS_DIR" "$TARGET"
        
        print_success "Screenshot capture completed!"
        print_status "$CYAN" "Screenshots saved to: $RESULTS_DIR/eyewitness_screenshots/"
        exit 0
    else
        print_error "Screenshot capture failed"
        exit 1
    fi
}

# Run main function
main "$@"