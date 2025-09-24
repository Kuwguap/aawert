#!/bin/bash

# AI-Powered Analysis Script v2 - Gemini AI Integration
# Usage: ./ai_analysis_v2.sh <target_domain> <results_dir>
#        ./ai_analysis_v2.sh -d <target_domain> -r <results_dir>
#        ./ai_analysis_v2.sh -f <results_dir> -r <results_dir>

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# AI Configuration
AI_CONFIG_FILE="./ai_config.json"
GEMINI_API_KEY=""
AI_ENABLED=false
AI_MODEL="gemini-1.5-flash"
AI_TIMEOUT=300  # 5 minutes timeout for AI analysis

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
    echo "AI-Powered Analysis Script v2"
    echo "============================="
    echo ""
    echo "Usage:"
    echo "  $0 <target_domain> <results_dir>           # Single domain"
    echo "  $0 -d <target_domain> -r <results_dir>    # Single domain (explicit)"
    echo "  $0 -f <results_dir> -r <results_dir>      # Analyze existing results"
    echo ""
    echo "Options:"
    echo "  -d, --domain <domain>        Target domain"
    echo "  -f, --file <dir>             Results directory to analyze"
    echo "  -r, --results <dir>           Results directory"
    echo "  -k, --key <api_key>          Gemini API key"
    echo "  -v, --verbose                Verbose output"
    echo "  -h, --help                   Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 example.com ./results"
    echo "  $0 -f ./results/example.com_20241201_143022 -r ./results"
    echo "  $0 -k YOUR_GEMINI_API_KEY -r ./results"
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
                RESULTS_DIR="$2"
                shift 2
                ;;
            -r|--results)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -k|--key)
                GEMINI_API_KEY="$2"
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
                elif [[ -z "$OUTPUT_DIR" && ! "$1" =~ ^- ]]; then
                    OUTPUT_DIR="$1"
                fi
                shift
                ;;
        esac
    done
}

# Function to load AI configuration
load_ai_config() {
    if [[ -f "$AI_CONFIG_FILE" ]]; then
        print_status "$BLUE" "Loading AI configuration..."
        
        # Extract API key from config file
        if command_exists jq; then
            GEMINI_API_KEY=$(jq -r '.gemini_api_key' "$AI_CONFIG_FILE" 2>/dev/null)
            AI_MODEL=$(jq -r '.ai_model // "gemini-1.5-flash"' "$AI_CONFIG_FILE" 2>/dev/null)
            AI_TIMEOUT=$(jq -r '.ai_timeout // 300' "$AI_CONFIG_FILE" 2>/dev/null)
        else
            # Fallback: simple grep extraction
            GEMINI_API_KEY=$(grep -o '"gemini_api_key": *"[^"]*"' "$AI_CONFIG_FILE" | cut -d'"' -f4)
            AI_MODEL=$(grep -o '"ai_model": *"[^"]*"' "$AI_CONFIG_FILE" | cut -d'"' -f4 || echo "gemini-1.5-flash")
            AI_TIMEOUT=$(grep -o '"ai_timeout": *[0-9]*' "$AI_CONFIG_FILE" | cut -d':' -f2 | tr -d ' ' || echo "300")
        fi
        
        if [[ -n "$GEMINI_API_KEY" && "$GEMINI_API_KEY" != "null" ]]; then
            AI_ENABLED=true
            print_success "AI configuration loaded"
        else
            print_warning "No valid API key found in configuration"
        fi
    else
        print_warning "AI configuration file not found: $AI_CONFIG_FILE"
        print_warning "Create $AI_CONFIG_FILE with your Gemini API key"
    fi
}

# Function to validate AI prerequisites
validate_ai_prerequisites() {
    # Check if curl is available
    if ! command_exists curl; then
        print_error "curl is required for AI analysis but not available!"
        return 1
    fi
    
    # Check if API key is available
    if [[ -z "$GEMINI_API_KEY" ]]; then
        print_error "Gemini API key not found!"
        print_error "Please set GEMINI_API_KEY environment variable or create $AI_CONFIG_FILE"
        return 1
    fi
    
    print_success "AI prerequisites validated"
    return 0
}

# Function to create AI configuration file
create_ai_config() {
    if [[ ! -f "$AI_CONFIG_FILE" ]]; then
        print_status "$BLUE" "Creating AI configuration file..."
        cat > "$AI_CONFIG_FILE" << EOF
{
  "gemini_api_key": "YOUR_GEMINI_API_KEY_HERE",
  "ai_model": "gemini-1.5-flash",
  "ai_timeout": 300,
  "analysis_settings": {
    "max_tokens": 1000,
    "temperature": 0.7,
    "top_p": 0.9
  }
}
EOF
        print_success "AI configuration file created: $AI_CONFIG_FILE"
        print_warning "Please edit $AI_CONFIG_FILE and add your Gemini API key"
    fi
}

# Function to call Gemini AI API
call_gemini_api() {
    local prompt="$1"
    local output_file="$2"
    
    print_status "$BLUE" "Calling Gemini AI API..."
    
    # Create request payload
    local payload=$(cat << EOF
{
  "contents": [{
    "parts": [{
      "text": "$prompt"
    }]
  }],
  "generationConfig": {
    "temperature": 0.7,
    "topP": 0.9,
    "maxOutputTokens": 1000
  }
}
EOF
)
    
    # Call Gemini API with timeout
    timeout $AI_TIMEOUT curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "x-goog-api-key: $GEMINI_API_KEY" \
        -d "$payload" \
        "https://generativelanguage.googleapis.com/v1beta/models/$AI_MODEL:generateContent" \
        > "$output_file" 2>>"${output_file%.*}_error.log"
    
    if [[ $? -eq 0 ]]; then
        print_success "Gemini API call completed"
        return 0
    else
        print_warning "Gemini API call failed or timed out"
        return 1
    fi
}

# Function to extract AI response
extract_ai_response() {
    local input_file="$1"
    local output_file="$2"
    
    if command_exists jq; then
        jq -r '.candidates[0].content.parts[0].text' "$input_file" > "$output_file" 2>/dev/null
    else
        # Fallback: simple text extraction
        grep -o '"text":"[^"]*"' "$input_file" | sed 's/"text":"//g' | sed 's/"$//g' > "$output_file"
    fi
}

# Function to analyze subdomains with AI
analyze_subdomains() {
    local results_dir="$1"
    local target="$2"
    local output_file="$3"
    
    print_status "$BLUE" "Analyzing subdomains with AI..."
    
    # Read subdomain data
    local subdomains_file="$results_dir/all_subdomains.txt"
    local live_subdomains_file="$results_dir/live_subdomains_target.txt"
    
    if [[ ! -f "$subdomains_file" ]]; then
        print_warning "No subdomains file found"
        return 1
    fi
    
    # Prepare data for AI analysis
    local subdomain_count=$(wc -l < "$subdomains_file" 2>/dev/null || echo "0")
    local live_count=0
    if [[ -f "$live_subdomains_file" ]]; then
        live_count=$(wc -l < "$live_subdomains_file" 2>/dev/null || echo "0")
    fi
    
    # Create AI prompt
    local prompt="Analyze these subdomain enumeration results for $target:

Total subdomains found: $subdomain_count
Live subdomains: $live_count

Subdomains:
$(head -20 "$subdomains_file")

Please provide:
1. Risk assessment of discovered subdomains
2. Potential attack vectors
3. Recommended next steps for penetration testing
4. High-value targets to focus on
5. Security recommendations

Format your response as a structured security analysis report."

    # Call AI API
    local ai_response_file="$results_dir/ai_subdomain_analysis.json"
    call_gemini_api "$prompt" "$ai_response_file"
    
    if [[ $? -eq 0 ]]; then
        extract_ai_response "$ai_response_file" "$output_file"
        print_success "Subdomain analysis completed"
        return 0
    else
        print_warning "Subdomain analysis failed"
        return 1
    fi
}

# Function to analyze JavaScript files with AI
analyze_javascript() {
    local results_dir="$1"
    local target="$2"
    local output_file="$3"
    
    print_status "$BLUE" "Analyzing JavaScript files with AI..."
    
    # Read JavaScript data
    local js_files_file="$results_dir/js_files.txt"
    local secrets_file="$results_dir/secretfinder_results.txt"
    
    if [[ ! -f "$js_files_file" ]]; then
        print_warning "No JavaScript files found"
        return 1
    fi
    
    # Prepare data for AI analysis
    local js_count=$(wc -l < "$js_files_file" 2>/dev/null || echo "0")
    local secrets_count=0
    if [[ -f "$secrets_file" ]]; then
        secrets_count=$(wc -l < "$secrets_file" 2>/dev/null || echo "0")
    fi
    
    # Create AI prompt
    local prompt="Analyze these JavaScript files and secrets for $target:

JavaScript files found: $js_count
Secrets found: $secrets_count

JavaScript files:
$(head -10 "$js_files_file")

Secrets found:
$(head -10 "$secrets_file" 2>/dev/null || echo "No secrets found")

Please provide:
1. Analysis of JavaScript files for security vulnerabilities
2. Assessment of discovered secrets and their risk level
3. Recommendations for further investigation
4. Potential security issues in the code
5. Best practices for secure JavaScript development

Format your response as a structured security analysis report."

    # Call AI API
    local ai_response_file="$results_dir/ai_js_analysis.json"
    call_gemini_api "$prompt" "$ai_response_file"
    
    if [[ $? -eq 0 ]]; then
        extract_ai_response "$ai_response_file" "$output_file"
        print_success "JavaScript analysis completed"
        return 0
    else
        print_warning "JavaScript analysis failed"
        return 1
    fi
}

# Function to analyze vulnerabilities with AI
analyze_vulnerabilities() {
    local results_dir="$1"
    local target="$2"
    local output_file="$3"
    
    print_status "$BLUE" "Analyzing vulnerabilities with AI..."
    
    # Read vulnerability data
    local nuclei_files=$(find "$results_dir" -name "nuclei_*.txt" -type f)
    local nikto_files=$(find "$results_dir" -name "nikto_*.txt" -type f)
    
    if [[ -z "$nuclei_files" && -z "$nikto_files" ]]; then
        print_warning "No vulnerability scan results found"
        return 1
    fi
    
    # Create AI prompt
    local prompt="Analyze these vulnerability scan results for $target:

Nuclei scan results:
$(head -20 $nuclei_files 2>/dev/null || echo "No Nuclei results")

Nikto scan results:
$(head -20 $nikto_files 2>/dev/null || echo "No Nikto results")

Please provide:
1. Risk assessment of discovered vulnerabilities
2. Prioritization of vulnerabilities by severity
3. Exploitation recommendations
4. Remediation steps
5. Additional security testing recommendations

Format your response as a structured vulnerability assessment report."

    # Call AI API
    local ai_response_file="$results_dir/ai_vuln_analysis.json"
    call_gemini_api "$prompt" "$ai_response_file"
    
    if [[ $? -eq 0 ]]; then
        extract_ai_response "$ai_response_file" "$output_file"
        print_success "Vulnerability analysis completed"
        return 0
    else
        print_warning "Vulnerability analysis failed"
        return 1
    fi
}

# Function to generate comprehensive AI report
generate_ai_report() {
    local results_dir="$1"
    local target="$2"
    local output_file="$3"
    
    print_status "$BLUE" "Generating comprehensive AI report..."
    
    # Create comprehensive AI prompt
    local prompt="Generate a comprehensive security assessment report for $target based on the following reconnaissance data:

Target: $target
Assessment Date: $(date)

Available data:
- Subdomain enumeration results
- Live subdomain detection
- JavaScript file analysis
- Secret discovery
- Vulnerability scan results
- S3 bucket discovery
- Login endpoint discovery

Please provide:
1. Executive summary of security posture
2. Critical findings and high-risk issues
3. Attack surface analysis
4. Recommended security improvements
5. Next steps for penetration testing
6. Risk rating and overall assessment

Format your response as a professional security assessment report suitable for stakeholders."

    # Call AI API
    local ai_response_file="$results_dir/ai_comprehensive_analysis.json"
    call_gemini_api "$prompt" "$ai_response_file"
    
    if [[ $? -eq 0 ]]; then
        extract_ai_response "$ai_response_file" "$output_file"
        print_success "Comprehensive AI report generated"
        return 0
    else
        print_warning "Comprehensive AI report generation failed"
        return 1
    fi
}

# Function to generate statistics
generate_statistics() {
    local results_dir="$1"
    local target="$2"
    
    print_status "$CYAN" "AI Analysis Statistics:"
    
    # Count AI analysis files
    local analysis_count=0
    for file in "$results_dir"/ai_*.txt; do
        if [[ -f "$file" ]]; then
            analysis_count=$((analysis_count + 1))
        fi
    done
    
    echo "  - AI analysis files generated: $analysis_count"
    echo "  - Target analyzed: $target"
    echo "  - Analysis timestamp: $(date)"
}

# Main execution
main() {
    # Initialize variables
    TARGET=""
    RESULTS_DIR=""
    OUTPUT_DIR=""
    VERBOSE=false
    
    # Parse arguments
    parse_arguments "$@"
    
    # Check if no arguments provided
    if [[ -z "$TARGET" && -z "$RESULTS_DIR" ]]; then
        show_usage
        exit 1
    fi
    
    # Set default output directory if not provided
    if [[ -z "$OUTPUT_DIR" ]]; then
        OUTPUT_DIR="$RESULTS_DIR"
    fi
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    print_status "$GREEN" "Starting AI-Powered Analysis v2"
    echo "====================================="
    
    # Load AI configuration
    load_ai_config
    
    # Create AI config if it doesn't exist
    if [[ ! -f "$AI_CONFIG_FILE" ]]; then
        create_ai_config
        exit 1
    fi
    
    # Validate AI prerequisites
    if ! validate_ai_prerequisites; then
        exit 1
    fi
    
    # Determine results directory
    if [[ -z "$RESULTS_DIR" ]]; then
        RESULTS_DIR="$OUTPUT_DIR"
    fi
    
    # Check if results directory exists
    if [[ ! -d "$RESULTS_DIR" ]]; then
        print_error "Results directory not found: $RESULTS_DIR"
        exit 1
    fi
    
    print_status "$CYAN" "Analyzing results in: $RESULTS_DIR"
    
    # Run AI analysis
    local ai_output_dir="$OUTPUT_DIR/ai_analysis"
    mkdir -p "$ai_output_dir"
    
    # Analyze subdomains
    analyze_subdomains "$RESULTS_DIR" "$TARGET" "$ai_output_dir/subdomain_analysis.txt"
    
    # Analyze JavaScript files
    analyze_javascript "$RESULTS_DIR" "$TARGET" "$ai_output_dir/javascript_analysis.txt"
    
    # Analyze vulnerabilities
    analyze_vulnerabilities "$RESULTS_DIR" "$TARGET" "$ai_output_dir/vulnerability_analysis.txt"
    
    # Generate comprehensive report
    generate_ai_report "$RESULTS_DIR" "$TARGET" "$ai_output_dir/comprehensive_report.txt"
    
    # Generate statistics
    generate_statistics "$ai_output_dir" "$TARGET"
    
    print_success "AI analysis completed!"
    print_status "$CYAN" "AI analysis results saved to: $ai_output_dir/"
}

# Run main function
main "$@"