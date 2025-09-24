#!/bin/bash

# Secret Finding Script v2 - Standalone and Integrated
# Usage: ./find_secrets_v2.sh <target_domain> <results_dir>
#        ./find_secrets_v2.sh -d <target_domain> -r <results_dir>
#        ./find_secrets_v2.sh -f <js_files_file> -r <results_dir>

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default SecretFinder path (customize as needed)
DEFAULT_SECRETFINDER_PATH="/home/kali/Desktop/Tools/SecretFinder/SecretFinder.py"

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
    echo "Secret Finding Script v2"
    echo "========================="
    echo ""
    echo "Usage:"
    echo "  $0 <target_domain> <results_dir>           # Single domain"
    echo "  $0 -d <target_domain> -r <results_dir>    # Single domain (explicit)"
    echo "  $0 -f <js_files_file> -r <results_dir>     # JavaScript files file"
    echo ""
    echo "Options:"
    echo "  -d, --domain <domain>        Target domain"
    echo "  -f, --file <file>            JavaScript files file"
    echo "  -r, --results <dir>           Results directory"
    echo "  -s, --secretfinder <path>    SecretFinder.py path"
    echo "  -v, --verbose                Verbose output"
    echo "  -h, --help                   Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 example.com ./results"
    echo "  $0 -f js_files.txt -r ./results"
    echo "  $0 -s /path/to/SecretFinder.py -r ./results"
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
                JS_FILES_FILE="$2"
                shift 2
                ;;
            -r|--results)
                RESULTS_DIR="$2"
                shift 2
                ;;
            -s|--secretfinder)
                SECRETFINDER_PATH="$2"
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
    # Check if SecretFinder is available
    if [[ -z "$SECRETFINDER_PATH" ]]; then
        SECRETFINDER_PATH="$DEFAULT_SECRETFINDER_PATH"
    fi
    
    if [[ ! -f "$SECRETFINDER_PATH" ]]; then
        print_error "SecretFinder not found at: $SECRETFINDER_PATH"
        print_error "Please install SecretFinder or provide the correct path with -s option"
        return 1
    fi
    
    # Check if Python is available
    if ! command_exists python3; then
        print_error "Python3 is required but not available!"
        return 1
    fi
    
    # Check if JavaScript files file exists
    if [[ -n "$JS_FILES_FILE" && ! -f "$JS_FILES_FILE" ]]; then
        print_error "JavaScript files file not found: $JS_FILES_FILE"
        return 1
    fi
    
    # Check if js_files.txt exists (for integrated mode)
    if [[ -z "$JS_FILES_FILE" && ! -f "$RESULTS_DIR/js_files.txt" ]]; then
        print_error "No JavaScript files file found. Run JavaScript extraction first."
        return 1
    fi
    
    print_success "Prerequisites validated"
    return 0
}

# Function to run SecretFinder on JavaScript files
run_secretfinder() {
    local js_files_file="$1"
    local output_file="$2"
    local target="$3"
    
    print_status "$BLUE" "Running SecretFinder on JavaScript files..."
    
    # Clear output file
    rm -f "$output_file"
    
    # Run SecretFinder on each JavaScript file
    local processed_count=0
    local total_count=$(wc -l < "$js_files_file" 2>/dev/null || echo "0")
    
    while IFS= read -r js_file; do
        if [[ -n "$js_file" ]]; then
            processed_count=$((processed_count + 1))
            print_status "$BLUE" "Scanning JavaScript file $processed_count/$total_count: $js_file"
            
            # Run SecretFinder
            python3 "$SECRETFINDER_PATH" -i "$js_file" -o cli >> "$output_file" 2>>"${output_file%.*}_error.log"
        fi
    done < "$js_files_file"
    
    print_success "SecretFinder scan completed on $processed_count JavaScript files"
}

# Function to run custom sensitive data detection
run_custom_sensitive_detection() {
    local js_files_file="$1"
    local output_file="$2"
    local target="$3"
    
    print_status "$BLUE" "Running custom sensitive data detection..."
    
    # Clear output file
    rm -f "$output_file"
    
    # Run custom Python script if available
    if [[ -f "find_sensitive_data.py" ]]; then
        print_status "$BLUE" "Using custom sensitive data detection script..."
        cat "$js_files_file" | python3 find_sensitive_data.py >> "$output_file" 2>>"${output_file%.*}_error.log"
    else
        print_warning "Custom sensitive data detection script not found"
    fi
}

# Function to filter results by target domain
filter_results_by_target() {
    local input_file="$1"
    local output_file="$2"
    local target="$3"
    
    print_status "$BLUE" "Filtering results to only include $target related findings..."
    
    # Clear output file
    rm -f "$output_file"
    
    # Filter results to only include those related to the target domain
    while IFS= read -r line; do
        if [[ "$line" =~ $target ]]; then
            echo "$line" >> "$output_file"
        fi
    done < "$input_file"
}

# Function to generate statistics
generate_statistics() {
    local results_dir="$1"
    local target="$2"
    
    print_status "$CYAN" "Secret Finding Statistics:"
    
    # Count JavaScript files processed
    local js_count=0
    if [[ -f "$results_dir/js_files.txt" ]]; then
        js_count=$(wc -l < "$results_dir/js_files.txt" 2>/dev/null || echo "0")
    fi
    
    # Count SecretFinder results
    local secretfinder_count=0
    if [[ -f "$results_dir/secretfinder_results.txt" ]]; then
        secretfinder_count=$(wc -l < "$results_dir/secretfinder_results.txt" 2>/dev/null || echo "0")
    fi
    
    # Count custom detection results
    local custom_count=0
    if [[ -f "$results_dir/custom_sensitive_results.txt" ]]; then
        custom_count=$(wc -l < "$results_dir/custom_sensitive_results.txt" 2>/dev/null || echo "0")
    fi
    
    echo "  - JavaScript files processed: $js_count"
    echo "  - SecretFinder findings: $secretfinder_count"
    echo "  - Custom detection findings: $custom_count"
}

# Main execution
main() {
    # Initialize variables
    TARGET=""
    JS_FILES_FILE=""
    RESULTS_DIR=""
    SECRETFINDER_PATH=""
    VERBOSE=false
    
    # Parse arguments
    parse_arguments "$@"
    
    # Check if no arguments provided
    if [[ -z "$TARGET" && -z "$JS_FILES_FILE" ]]; then
        show_usage
        exit 1
    fi
    
    # Set default results directory if not provided
    if [[ -z "$RESULTS_DIR" ]]; then
        RESULTS_DIR="./results"
    fi
    
    # Create results directory
    mkdir -p "$RESULTS_DIR"
    
    print_status "$GREEN" "Starting Secret Finding v2"
    echo "============================="
    
    # Validate prerequisites
    if ! validate_prerequisites; then
        exit 1
    fi
    
    # Determine input file
    local input_file=""
    if [[ -n "$JS_FILES_FILE" ]]; then
        input_file="$JS_FILES_FILE"
        print_status "$CYAN" "Using JavaScript files file: $JS_FILES_FILE"
    else
        input_file="$RESULTS_DIR/js_files.txt"
        print_status "$CYAN" "Using JavaScript files file: $input_file"
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
    
    local js_count=$(wc -l < "$input_file" 2>/dev/null || echo "0")
    print_status "$CYAN" "Found $js_count JavaScript files for secret detection"
    
    # Run SecretFinder
    local secretfinder_output="$RESULTS_DIR/secretfinder_results.txt"
    run_secretfinder "$input_file" "$secretfinder_output" "$TARGET"
    
    # Run custom sensitive data detection
    local custom_output="$RESULTS_DIR/custom_sensitive_results.txt"
    run_custom_sensitive_detection "$input_file" "$custom_output" "$TARGET"
    
    # Filter results by target domain
    local filtered_output="$RESULTS_DIR/secretfinder_filtered.txt"
    filter_results_by_target "$secretfinder_output" "$filtered_output" "$TARGET"
    
    # Generate statistics
    generate_statistics "$RESULTS_DIR" "$TARGET"
    
    # Check if we got any results
    if [[ -f "$secretfinder_output" && -s "$secretfinder_output" ]]; then
        local findings_count=$(wc -l < "$secretfinder_output" 2>/dev/null || echo "0")
        print_success "Secret finding completed!"
        print_status "$CYAN" "Found $findings_count potential secrets"
        print_status "$CYAN" "Results saved to: $secretfinder_output"
        exit 0
    else
        print_warning "No secrets found in JavaScript files"
        exit 1
    fi
}

# Run main function
main "$@"