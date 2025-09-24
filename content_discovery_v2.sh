#!/bin/bash

# Content Discovery Script v2 - Standalone and Integrated
# Usage: ./content_discovery_v2.sh <target_domain> <results_dir>
#        ./content_discovery_v2.sh -d <target_domain> -r <results_dir>
#        ./content_discovery_v2.sh -f <live_subdomains_file> -r <results_dir>

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default wordlist path (customize as needed)
DEFAULT_WORDLIST="/home/kali/Desktop/Tools/SecLists-master/Discovery/Web-Content/directory-list-2.3-medium.txt"

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
    echo "Content Discovery Script v2"
    echo "==========================="
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
    echo "  -w, --wordlist <file>        Custom wordlist file"
    echo "  -v, --verbose                Verbose output"
    echo "  -h, --help                   Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 example.com ./results"
    echo "  $0 -f live_subdomains.txt -r ./results"
    echo "  $0 -w custom_wordlist.txt -r ./results"
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
            -w|--wordlist)
                WORDLIST_FILE="$2"
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
    # Check if at least one content discovery tool is available
    if ! command_exists ffuf && ! command_exists dirsearch; then
        print_error "No content discovery tools available!"
        print_error "Please install at least one of: ffuf, dirsearch"
        return 1
    fi
    
    # Check if wordlist exists
    if [[ -n "$WORDLIST_FILE" && ! -f "$WORDLIST_FILE" ]]; then
        print_error "Wordlist file not found: $WORDLIST_FILE"
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

# Function to process ffuf output and filter for target domain
process_ffuf_output() {
    local input_file="$1"
    local output_file="$2"
    local target_domain="$3"
    
    print_status "$BLUE" "Processing ffuf results and filtering for $target_domain..."
    
    # Clear output file
    rm -f "$output_file"
    
    # Process JSON output and filter for target domain
    if command_exists jq; then
        cat "$input_file" | jq -r '.results[] | select(.status == 200) | .url' | while IFS= read -r url; do
            if [[ "$url" =~ $target_domain ]]; then
                echo "$url" >> "$output_file"
            fi
        done
    else
        # Fallback: simple text processing
        cat "$input_file" | grep -E '\[200\]' | grep "$target_domain" | awk '{print $1}' >> "$output_file"
    fi
}

# Function to filter dirsearch results for target domain
filter_dirsearch_results() {
    local input_file="$1"
    local output_file="$2"
    local target_domain="$3"
    
    print_status "$BLUE" "Filtering dirsearch results for $target_domain..."
    
    # Clear output file
    rm -f "$output_file"
    
    # Filter dirsearch results
    while IFS= read -r line; do
        if [[ "$line" == *"$target_domain"* ]]; then
            if [[ "$line" == *"[200]"* ]]; then
                url=$(echo "$line" | awk '{print $3}')
                if [[ "$url" =~ $target_domain ]]; then
                    echo "$url" >> "$output_file"
                fi
            elif [[ "$line" == *"REDIRECTS TO:"* ]]; then
                redirect_url=$(echo "$line" | awk '{print $NF}')
                if [[ "$redirect_url" == *"$target_domain"* ]]; then
                    url=$(echo "$line" | awk '{print $3}')
                    if [[ "$url" =~ $target_domain ]]; then
                        echo "$url" >> "$output_file"
                    fi
                fi
            fi
        fi
    done < "$input_file"
}

# Function to run ffuf on a single target
run_ffuf_on_target() {
    local target="$1"
    local wordlist="$2"
    local results_dir="$3"
    local target_domain="$4"
    
    if command_exists ffuf; then
        print_status "$BLUE" "Running ffuf on $target..."
        
        local output_file="$results_dir/ffuf_${target//./_}_raw.json"
        local filtered_file="$results_dir/ffuf_${target//./_}.txt"
        
        # Run ffuf
        ffuf -w "$wordlist" -u "https://$target/FUZZ" -recursion -o "$output_file" 2>>"${output_file%.*}_error.log"
        
        if [[ $? -eq 0 ]]; then
            # Process and filter results
            process_ffuf_output "$output_file" "$filtered_file" "$target_domain"
            print_success "ffuf completed for $target"
            return 0
        else
            print_warning "ffuf encountered errors for $target"
            return 1
        fi
    else
        print_warning "ffuf not available"
        return 1
    fi
}

# Function to run dirsearch on a single target
run_dirsearch_on_target() {
    local target="$1"
    local wordlist="$2"
    local results_dir="$3"
    local target_domain="$4"
    
    if command_exists dirsearch; then
        print_status "$BLUE" "Running dirsearch on $target..."
        
        local output_file="$results_dir/dirsearch_${target//./_}_raw.txt"
        local filtered_file="$results_dir/dirsearch_${target//./_}.txt"
        
        # Run dirsearch on both HTTP and HTTPS
        dirsearch -u "https://$target" -w "$wordlist" -r -o "$output_file" 2>>"${output_file%.*}_error.log"
        dirsearch -u "http://$target" -w "$wordlist" -r -o "$output_file" 2>>"${output_file%.*}_error.log"
        
        if [[ $? -eq 0 ]]; then
            # Process and filter results
            filter_dirsearch_results "$output_file" "$filtered_file" "$target_domain"
            print_success "dirsearch completed for $target"
            return 0
        else
            print_warning "dirsearch encountered errors for $target"
            return 1
        fi
    else
        print_warning "dirsearch not available"
        return 1
    fi
}

# Function to generate statistics
generate_statistics() {
    local results_dir="$1"
    local target="$2"
    
    print_status "$CYAN" "Content Discovery Statistics:"
    
    # Count ffuf results
    local ffuf_count=0
    for file in "$results_dir"/ffuf_*.txt; do
        if [[ -f "$file" ]]; then
            count=$(wc -l < "$file" 2>/dev/null || echo "0")
            ffuf_count=$((ffuf_count + count))
        fi
    done
    
    # Count dirsearch results
    local dirsearch_count=0
    for file in "$results_dir"/dirsearch_*.txt; do
        if [[ -f "$file" ]]; then
            count=$(wc -l < "$file" 2>/dev/null || echo "0")
            dirsearch_count=$((dirsearch_count + count))
        fi
    done
    
    echo "  - ffuf results: $ffuf_count"
    echo "  - dirsearch results: $dirsearch_count"
    echo "  - Total results: $((ffuf_count + dirsearch_count))"
}

# Main execution
main() {
    # Initialize variables
    TARGET=""
    LIVE_SUBDOMAINS_FILE=""
    RESULTS_DIR=""
    WORDLIST_FILE=""
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
    
    # Set default wordlist if not provided
    if [[ -z "$WORDLIST_FILE" ]]; then
        WORDLIST_FILE="$DEFAULT_WORDLIST"
    fi
    
    # Create results directory
    mkdir -p "$RESULTS_DIR"
    
    print_status "$GREEN" "Starting Content Discovery v2"
    echo "=================================="
    
    # Validate prerequisites
    if ! validate_prerequisites; then
        exit 1
    fi
    
    # Check if wordlist exists
    if [[ ! -f "$WORDLIST_FILE" ]]; then
        print_error "Wordlist file not found: $WORDLIST_FILE"
        print_error "Please provide a valid wordlist file with -w option"
        exit 1
    fi
    
    print_status "$CYAN" "Using wordlist: $WORDLIST_FILE"
    
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
    print_status "$CYAN" "Found $subdomain_count live subdomains for content discovery"
    
    # Run content discovery on main domain if provided
    if [[ -n "$TARGET" ]]; then
        print_status "$PURPLE" "Running content discovery on main domain: $TARGET"
        run_ffuf_on_target "$TARGET" "$WORDLIST_FILE" "$RESULTS_DIR" "$TARGET"
        run_dirsearch_on_target "$TARGET" "$WORDLIST_FILE" "$RESULTS_DIR" "$TARGET"
    fi
    
    # Run content discovery on live subdomains
    print_status "$PURPLE" "Running content discovery on live subdomains..."
    while IFS= read -r subdomain; do
        if [[ -n "$subdomain" ]]; then
            run_ffuf_on_target "$subdomain" "$WORDLIST_FILE" "$RESULTS_DIR" "$TARGET"
            run_dirsearch_on_target "$subdomain" "$WORDLIST_FILE" "$RESULTS_DIR" "$TARGET"
        fi
    done < "$input_file"
    
    # Generate statistics
    generate_statistics "$RESULTS_DIR" "$TARGET"
    
    print_success "Content discovery completed!"
    print_status "$CYAN" "Results saved in: $RESULTS_DIR/"
}

# Run main function
main "$@"