#!/bin/bash

: <<'AAWERT_BANNER'
   ▄████████    ▄████████  ▄█     █▄     ▄████████    ▄████████     ███     
  ███    ███   ███    ███ ███     ███   ███    ███   ███    ███ ▀█████████▄ 
  ███    ███   ███    ███ ███     ███   ███    █▀    ███    ███    ▀███▀▀██ 
  ███    ███   ███    ███ ███     ███  ▄███▄▄▄      ▄███▄▄▄▄██▀     ███   ▀ 
▀███████████ ▀███████████ ███     ███ ▀▀███▀▀▀     ▀▀███▀▀▀▀▀       ███     
  ███    ███   ███    ███ ███     ███   ███    █▄  ▀███████████     ███     
  ███    ███   ███    ███ ███ ▄█▄ ███   ███    ███   ███    ███     ███     
  ███    █▀    ███    █▀   ▀███▀███▀    ██████████   ███    ███    ▄████▀   
                                                     ███    ███             
AAWERT_BANNER

# AAweRT v2 - An Awesome Reconnaissance Tool (AI-Enhanced with Timeouts)
# Features: AI analysis, 5-minute timeouts, better dependency management

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_RESULTS_DIR="./results"
SESSION_DIR=""
RESULTS_DIR=""
TARGET=""
DOMAIN_LIST_FILE=""
SUBDOMAIN_WORDLIST_FILE=""
SESSION_NAME=""
VERBOSE=false
SKIP_VALIDATION=false
AI_ANALYSIS=false
SCAN_TIMEOUT=300  # 5 minutes timeout for all scans

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

# Function to run command with timeout
run_with_timeout() {
    local timeout_seconds="$1"
    local command="$2"
    local output_file="$3"
    local error_file="$4"
    
    print_status "$BLUE" "Running with ${timeout_seconds}s timeout: $command"
    
    # Run command with timeout
    timeout "$timeout_seconds" bash -c "$command" > "$output_file" 2>>"$error_file"
    local exit_code=$?
    
    if [[ $exit_code -eq 124 ]]; then
        print_warning "Command timed out after ${timeout_seconds}s"
        return 1
    elif [[ $exit_code -eq 0 ]]; then
        print_success "Command completed successfully"
        return 0
    else
        print_warning "Command failed with exit code $exit_code"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "AAweRT v2 - An Awesome Reconnaissance Tool (AI-Enhanced)"
    echo "======================================================"
    echo ""
    echo "Usage:"
    echo "  $0 <target_domain>                    # Single domain"
    echo "  $0 -d <target_domain>                  # Single domain (explicit)"
    echo "  $0 -l <domain_list_file>              # Multiple domains from file"
    echo "  $0 -w <subdomain_wordlist_file>       # Custom subdomain wordlist"
    echo "  $0 --standalone <phase> <target>      # Run specific phase standalone"
    echo "  $0 --ai <target>                      # Run with AI analysis"
    echo ""
    echo "Options:"
    echo "  -v, --verbose                         # Verbose output"
    echo "  --skip-validation                # Skip prerequisite validation"
    echo "  --ai                               # Enable AI analysis"
    echo "  -t, --timeout <seconds>            # Scan timeout (default: 300s)"
    echo "  -h, --help                           # Show this help"
    echo ""
    echo "Standalone Phase Options:"
    echo "  --standalone subdomain <target>       # Subdomain enumeration only"
    echo "  --standalone live <target>           # Live subdomain detection only"
    echo "  --standalone crawl <target>          # Subdomain crawling only"
    echo "  --standalone parameters <target>     # Parameter discovery only"
    echo "  --standalone content <target>        # Content discovery only"
    echo "  --standalone js <target>              # JavaScript extraction only"
    echo "  --standalone secrets <target>         # Secret finding only"
    echo "  --standalone vuln <target>           # Vulnerability scanning only"
    echo "  --standalone s3 <target>             # S3 bucket discovery only"
    echo "  --standalone login <target>          # Login endpoint discovery only"
    echo "  --standalone screenshots <target>    # Screenshot capture only"
    echo "  --standalone ai <target>             # AI analysis only"
    echo ""
    echo "Examples:"
    echo "  $0 example.com"
    echo "  $0 -l domains.txt"
    echo "  $0 --ai example.com"
    echo "  $0 --standalone subdomain example.com"
    echo "  $0 -t 600 example.com  # 10 minute timeout"
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
                SUBDOMAIN_WORDLIST_FILE="$2"
                shift 2
                ;;
            --standalone)
                STANDALONE_PHASE="$2"
                TARGET="$3"
                shift 3
                ;;
            --ai)
                AI_ANALYSIS=true
                shift
                ;;
            -t|--timeout)
                SCAN_TIMEOUT="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --skip-validation)
                SKIP_VALIDATION=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                if [[ -z "$TARGET" && ! "$1" =~ ^- ]]; then
                    TARGET="$1"
                fi
                shift
                ;;
        esac
    done
}

# Function to run full reconnaissance with timeouts
run_full_reconnaissance() {
    print_status "$GREEN" "Starting Full AAweRT Reconnaissance v2 (with ${SCAN_TIMEOUT}s timeouts)"
    echo "================================================================"
    
    # Phase 1: Subdomain Enumeration
    print_status "$CYAN" "Phase 1: Subdomain Enumeration (${SCAN_TIMEOUT}s timeout)"
    if [[ "$SKIP_VALIDATION" == false ]]; then
        validate_prerequisites "1" "" "subfinder amass assetfinder" || {
            print_warning "Some tools missing, continuing with available tools"
        }
    fi
    
    # Run subdomain enumeration with timeout
    run_with_timeout "$SCAN_TIMEOUT" "./subdomain_enumeration_v2.sh \"$TARGET\" \"$RESULTS_DIR\"" \
        "$RESULTS_DIR/subdomain_enumeration.log" "$RESULTS_DIR/subdomain_enumeration_error.log"
    
    # Validate Phase 1 results
    if [[ ! -f "$RESULTS_DIR/all_subdomains.txt" || ! -s "$RESULTS_DIR/all_subdomains.txt" ]]; then
        print_error "Phase 1 failed: No subdomains found"
        exit 1
    fi
    print_success "Phase 1 completed: $(wc -l < "$RESULTS_DIR/all_subdomains.txt") subdomains found"
    
    # Phase 2: Live Subdomain Detection
    print_status "$CYAN" "Phase 2: Live Subdomain Detection (${SCAN_TIMEOUT}s timeout)"
    if [[ "$SKIP_VALIDATION" == false ]]; then
        validate_prerequisites "2" "$RESULTS_DIR/all_subdomains.txt" "httpx" || {
            print_warning "httpx not available, skipping live detection"
        }
    fi
    
    run_with_timeout "$SCAN_TIMEOUT" "./check_live_subdomains_v2.sh \"$TARGET\" \"$RESULTS_DIR\"" \
        "$RESULTS_DIR/live_detection.log" "$RESULTS_DIR/live_detection_error.log"
    
    # Validate Phase 2 results
    if [[ -f "$RESULTS_DIR/live_subdomains_target.txt" && -s "$RESULTS_DIR/live_subdomains_target.txt" ]]; then
        print_success "Phase 2 completed: $(wc -l < "$RESULTS_DIR/live_subdomains_target.txt") live subdomains found"
    else
        print_warning "Phase 2: No live subdomains found"
    fi
    
    # Phase 3: Subdomain Crawling
    if [[ -f "$RESULTS_DIR/live_subdomains_target.txt" && -s "$RESULTS_DIR/live_subdomains_target.txt" ]]; then
        print_status "$CYAN" "Phase 3: Subdomain Crawling (${SCAN_TIMEOUT}s timeout)"
        if [[ "$SKIP_VALIDATION" == false ]]; then
            validate_prerequisites "3" "$RESULTS_DIR/live_subdomains_target.txt" "katana hakrawler" || {
                print_warning "Crawling tools not available, skipping"
            }
        fi
        
        run_with_timeout "$SCAN_TIMEOUT" "./crawl_subdomains_v2.sh \"$TARGET\" \"$RESULTS_DIR\"" \
            "$RESULTS_DIR/crawling.log" "$RESULTS_DIR/crawling_error.log"
        print_success "Phase 3 completed"
    else
        print_warning "Skipping Phase 3: No live subdomains available"
    fi
    
    # Phase 4: Parameter Discovery
    if [[ -f "$RESULTS_DIR/all_subdomains.txt" && -s "$RESULTS_DIR/all_subdomains.txt" ]]; then
        print_status "$CYAN" "Phase 4: Parameter Discovery (${SCAN_TIMEOUT}s timeout)"
        if [[ "$SKIP_VALIDATION" == false ]]; then
            validate_prerequisites "4" "$RESULTS_DIR/all_subdomains.txt" "gau" || {
                print_warning "gau not available, skipping parameter discovery"
            }
        fi
        
        run_with_timeout "$SCAN_TIMEOUT" "./discover_parameters_v2.sh \"$TARGET\" \"$RESULTS_DIR\"" \
            "$RESULTS_DIR/parameter_discovery.log" "$RESULTS_DIR/parameter_discovery_error.log"
        print_success "Phase 4 completed"
    else
        print_warning "Skipping Phase 4: No subdomains available"
    fi
    
    # Phase 5: Content Discovery
    if [[ -f "$RESULTS_DIR/live_subdomains_target.txt" && -s "$RESULTS_DIR/live_subdomains_target.txt" ]]; then
        print_status "$CYAN" "Phase 5: Content Discovery (${SCAN_TIMEOUT}s timeout)"
        if [[ "$SKIP_VALIDATION" == false ]]; then
            validate_prerequisites "5" "$RESULTS_DIR/live_subdomains_target.txt" "ffuf dirsearch" || {
                print_warning "Content discovery tools not available, skipping"
            }
        fi
        
        run_with_timeout "$SCAN_TIMEOUT" "./content_discovery_v2.sh \"$TARGET\" \"$RESULTS_DIR\"" \
            "$RESULTS_DIR/content_discovery.log" "$RESULTS_DIR/content_discovery_error.log"
        print_success "Phase 5 completed"
    else
        print_warning "Skipping Phase 5: No live subdomains available"
    fi
    
    # Phase 6: JavaScript Extraction
    if [[ -f "$RESULTS_DIR/all_subdomains.txt" && -s "$RESULTS_DIR/all_subdomains.txt" ]]; then
        print_status "$CYAN" "Phase 6: JavaScript Extraction (${SCAN_TIMEOUT}s timeout)"
        if [[ "$SKIP_VALIDATION" == false ]]; then
            validate_prerequisites "6" "$RESULTS_DIR/all_subdomains.txt" "httpx" || {
                print_warning "httpx not available, skipping JavaScript extraction"
            }
        fi
        
        run_with_timeout "$SCAN_TIMEOUT" "./extract_js_v2.sh \"$TARGET\" \"$RESULTS_DIR\"" \
            "$RESULTS_DIR/js_extraction.log" "$RESULTS_DIR/js_extraction_error.log"
        print_success "Phase 6 completed"
    else
        print_warning "Skipping Phase 6: No subdomains available"
    fi
    
    # Phase 7: Secret Finding
    if [[ -f "$RESULTS_DIR/js_files.txt" && -s "$RESULTS_DIR/js_files.txt" ]]; then
        print_status "$CYAN" "Phase 7: Secret Finding (${SCAN_TIMEOUT}s timeout)"
        
        run_with_timeout "$SCAN_TIMEOUT" "./find_secrets_v2.sh \"$TARGET\" \"$RESULTS_DIR\"" \
            "$RESULTS_DIR/secret_finding.log" "$RESULTS_DIR/secret_finding_error.log"
        print_success "Phase 7 completed"
    else
        print_warning "Skipping Phase 7: No JavaScript files available"
    fi
    
    # Phase 8: Vulnerability Scanning
    if [[ -f "$RESULTS_DIR/live_subdomains_target.txt" && -s "$RESULTS_DIR/live_subdomains_target.txt" ]]; then
        print_status "$CYAN" "Phase 8: Vulnerability Scanning (${SCAN_TIMEOUT}s timeout)"
        if [[ "$SKIP_VALIDATION" == false ]]; then
            validate_prerequisites "8" "$RESULTS_DIR/live_subdomains_target.txt" "nuclei nikto" || {
                print_warning "Vulnerability scanning tools not available, skipping"
            }
        fi
        
        run_with_timeout "$SCAN_TIMEOUT" "./vulnerability_scan.sh \"$TARGET\" \"$RESULTS_DIR\"" \
            "$RESULTS_DIR/vulnerability_scanning.log" "$RESULTS_DIR/vulnerability_scanning_error.log"
        print_success "Phase 8 completed"
    else
        print_warning "Skipping Phase 8: No live subdomains available"
    fi
    
    # Phase 9: S3 Bucket Discovery
    if [[ -f "$RESULTS_DIR/all_subdomains.txt" && -s "$RESULTS_DIR/all_subdomains.txt" ]]; then
        print_status "$CYAN" "Phase 9: S3 Bucket Discovery (${SCAN_TIMEOUT}s timeout)"
        if [[ "$SKIP_VALIDATION" == false ]]; then
            validate_prerequisites "9" "$RESULTS_DIR/all_subdomains.txt" "s3scanner" || {
                print_warning "s3scanner not available, skipping S3 discovery"
            }
        fi
        
        run_with_timeout "$SCAN_TIMEOUT" "./find_s3_buckets_v2.sh \"$TARGET\" \"$RESULTS_DIR\"" \
            "$RESULTS_DIR/s3_discovery.log" "$RESULTS_DIR/s3_discovery_error.log"
        print_success "Phase 9 completed"
    else
        print_warning "Skipping Phase 9: No subdomains available"
    fi
    
    # Phase 10: Login Endpoint Discovery
    if [[ -f "$RESULTS_DIR/live_subdomains_target.txt" && -s "$RESULTS_DIR/live_subdomains_target.txt" ]]; then
        print_status "$CYAN" "Phase 10: Login Endpoint Discovery (${SCAN_TIMEOUT}s timeout)"
        if [[ "$SKIP_VALIDATION" == false ]]; then
            validate_prerequisites "10" "$RESULTS_DIR/live_subdomains_target.txt" "ffuf dirsearch" || {
                print_warning "Login discovery tools not available, skipping"
            }
        fi
        
        run_with_timeout "$SCAN_TIMEOUT" "./find_login_endpoints_v2.sh \"$TARGET\" \"$RESULTS_DIR\"" \
            "$RESULTS_DIR/login_discovery.log" "$RESULTS_DIR/login_discovery_error.log"
        print_success "Phase 10 completed"
    else
        print_warning "Skipping Phase 10: No live subdomains available"
    fi
    
    # Phase 11: Screenshot Capture
    if [[ -f "$RESULTS_DIR/live_subdomains_target.txt" && -s "$RESULTS_DIR/live_subdomains_target.txt" ]]; then
        print_status "$CYAN" "Phase 11: Screenshot Capture (${SCAN_TIMEOUT}s timeout)"
        if [[ "$SKIP_VALIDATION" == false ]]; then
            validate_prerequisites "11" "$RESULTS_DIR/live_subdomains_target.txt" "eyewitness" || {
                print_warning "EyeWitness not available, skipping screenshot capture"
            }
        fi
        
        run_with_timeout "$SCAN_TIMEOUT" "./take_screenshots_v2.sh \"$TARGET\" \"$RESULTS_DIR\"" \
            "$RESULTS_DIR/screenshot_capture.log" "$RESULTS_DIR/screenshot_capture_error.log"
        print_success "Phase 11 completed"
    else
        print_warning "Skipping Phase 11: No live subdomains available"
    fi
    
    # Phase 12: AI Analysis (if enabled)
    if [[ "$AI_ANALYSIS" == true ]]; then
        print_status "$CYAN" "Phase 12: AI Analysis (${SCAN_TIMEOUT}s timeout)"
        
        run_with_timeout "$SCAN_TIMEOUT" "./ai_analysis_v2.sh \"$TARGET\" \"$RESULTS_DIR\"" \
            "$RESULTS_DIR/ai_analysis.log" "$RESULTS_DIR/ai_analysis_error.log"
        print_success "Phase 12 completed"
    fi
    
    # Create session summary
    create_session_summary
    print_success "Full reconnaissance completed! Results in: $SESSION_DIR"
}

# Function to create session summary
create_session_summary() {
    cat > "$SESSION_DIR/session_summary.txt" << EOF
AAweRT v2 Session Summary (AI-Enhanced)
======================================
Session Name: $SESSION_NAME
Session Directory: $SESSION_DIR
Timestamp: $(date)
Target: $TARGET
Domain List File: $DOMAIN_LIST_FILE
Subdomain Wordlist: $SUBDOMAIN_WORDLIST_FILE
Scan Timeout: ${SCAN_TIMEOUT}s
AI Analysis: $AI_ANALYSIS

Tool Availability:
$(for tool in subfinder amass assetfinder httpx katana hakrawler gau ffuf dirsearch nuclei nikto s3scanner jq eyewitness; do
    if command_exists "$tool"; then
        echo "- $tool: Available"
    else
        echo "- $tool: NOT AVAILABLE"
    fi
done)

Files Generated:
- all_subdomains.txt: Combined subdomain enumeration results
- live_subdomains_target.txt: Live subdomains with HTTP responses
- parameters.txt: Discovered parameters
- js_files.txt: Extracted JavaScript files
- secretfinder_results.txt: Secrets found in JavaScript files
- s3_buckets_filtered.txt: S3 buckets discovered
- login_endpoints_from_js.txt: Login endpoints found
- eyewitness_screenshots/: Screenshots of live subdomains
- ai_analysis/: AI-powered analysis results
- Various scan results from ffuf, dirsearch, nuclei, nikto, etc.

Session completed at: $(date)
EOF
}

# Main execution
main() {
    # Parse arguments
    parse_arguments "$@"
    
    # Check if no arguments provided
    if [[ -z "$TARGET" && -z "$DOMAIN_LIST_FILE" && -z "$SUBDOMAIN_WORDLIST_FILE" && -z "$STANDALONE_PHASE" ]]; then
        show_usage
        exit 1
    fi
    
    # Create base results directory
    mkdir -p "$BASE_RESULTS_DIR"
    
    # Handle standalone mode
    if [[ -n "$STANDALONE_PHASE" ]]; then
        if [[ -z "$TARGET" ]]; then
            print_error "Target required for standalone mode"
            exit 1
        fi
        run_standalone_phase "$STANDALONE_PHASE" "$TARGET"
        exit 0
    fi
    
    # Determine session name and create session
    if [[ -n "$TARGET" ]]; then
        SESSION_NAME="$TARGET"
    elif [[ -n "$DOMAIN_LIST_FILE" ]]; then
        SESSION_NAME=$(basename "$DOMAIN_LIST_FILE" | sed 's/\.[^.]*$//')
    elif [[ -n "$SUBDOMAIN_WORDLIST_FILE" ]]; then
        SESSION_NAME=$(basename "$SUBDOMAIN_WORDLIST_FILE" | sed 's/\.[^.]*$//')
    fi
    
    create_session
    
    # Run full reconnaissance
    run_full_reconnaissance
}

# Run main function
main "$@"