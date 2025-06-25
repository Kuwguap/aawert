# AAweRT - An Awesome Reconnaissance Tool

AAweRT is a comprehensive reconnaissance framework that automates various phases of security reconnaissance and vulnerability assessment. Each run creates a separate session folder for better organization and to avoid conflicts between different reconnaissance sessions.

**Creator:** [github.com/kuwguap](https://github.com/kuwguap)  
**Created under:** [RAWPA](https://rawpa.vercel.com)

## Features

- **Session-Based Organization**: Each run creates a separate timestamped folder for the target
- **Phase 1**: Subdomain Enumeration (Subfinder, Amass, Assetfinder)
- **Phase 2**: Live Subdomain Detection (httpx)
- **Phase 3**: Subdomain Crawling (Katana, Hakrawler)
- **Phase 4**: Parameter Discovery (gau)
- **Phase 5**: Content Discovery (ffuf, dirsearch)
- **Phase 6**: JavaScript File Extraction
- **Phase 7**: Secret Finding in JavaScript (SecretFinder)
- **Phase 8**: Vulnerability Scanning (Nuclei, Nikto)
- **Phase 9**: S3 Bucket Discovery (s3scanner)
- **Phase 10**: Login Endpoint Discovery

## Session Management

AAweRT creates organized session folders for each reconnaissance run:

- **Single Domain**: `./results/example.com_20241201_143022/`
- **Domain List**: `./results/domains_20241201_143022/`
- **Wordlist**: `./results/wordlist_20241201_143022/`

Each session folder contains:
- All scan results and output files
- Session summary with metadata
- Timestamped organization for easy tracking

## Prerequisites

### Required Tools

Make sure you have the following tools installed and available in your PATH:

- **subfinder** - Subdomain enumeration
- **amass** - Network mapping and attack surface discovery
- **assetfinder** - Subdomain enumeration
- **httpx** - HTTP probe
- **katana** - Web crawling
- **hakrawler** - Web crawling
- **gau** - URL discovery
- **ffuf** - Web fuzzing
- **dirsearch** - Directory and file discovery
- **nuclei** - Vulnerability scanning
- **nikto** - Web server scanner
- **s3scanner** - S3 bucket discovery
- **jq** - JSON processor
- **python3** - Python interpreter

### Wordlists

Update the wordlist paths in the following scripts:
- `content_discovery.sh` - Line 4: Update the directory wordlist path
- `find_login_endpoints.sh` - Line 4: Update the login wordlist path

### SecretFinder

Update the SecretFinder path in `find_secrets.sh` - Line 4.

## Installation

1. Clone or download the repository
2. Make all scripts executable:
   ```bash
   chmod +x *.sh
   ```
3. The results directory will be created automatically on first run

## Usage

### Single Domain
```bash
./aawert.sh example.com
```
Creates: `./results/example.com_20241201_143022/`

### Multiple Domains from File
```bash
./aawert.sh -l domains.txt
```
Creates: `./results/domains_20241201_143022/`

### Using Custom Wordlist
```bash
./aawert.sh -w wordlist.txt
```
Creates: `./results/wordlist_20241201_143022/`

## Session Output Structure

Each session folder contains:

```
./results/example.com_20241201_143022/
├── session_summary.txt          # Session metadata and summary
├── all_subdomains.txt           # Combined subdomain enumeration results
├── live_subdomains_target.txt   # Live subdomains with HTTP responses
├── parameters.txt               # Discovered parameters
├── js_files.txt                 # Extracted JavaScript files
├── secretfinder_results.txt     # Secrets found in JavaScript files
├── ffuf_*.txt                   # Content discovery results
├── dirsearch_*.txt              # Directory enumeration results
├── nuclei_*.txt                 # Vulnerability scan results
├── nikto_*.txt                  # Web server scan results
├── s3_buckets_*.txt             # S3 bucket discovery results
└── *_error.log                  # Error logs from various tools
```

## Script Structure

- `aawert.sh` - Main orchestration script with session management
- `check_live_subdomains.sh` - Phase 2: Live subdomain detection
- `crawl_subdomains.sh` - Phase 3: Subdomain crawling
- `discover_parameters.sh` - Phase 4: Parameter discovery
- `content_discovery.sh` - Phase 5: Content discovery
- `extract_js.sh` - Phase 6: JavaScript extraction
- `find_secrets.sh` - Phase 7: Secret finding
- `vulnerability_scan.sh` - Phase 8: Vulnerability scanning
- `find_s3_buckets.sh` - Phase 9: S3 bucket discovery
- `find_login_endpoints.sh` - Phase 10: Login endpoint discovery

## Session Management Benefits

- **No Conflicts**: Each run is isolated in its own folder
- **Easy Tracking**: Timestamped folders for chronological organization
- **Clean Organization**: All related files for a target are grouped together
- **Multiple Targets**: Run reconnaissance on multiple targets simultaneously
- **Historical Data**: Keep previous scan results for comparison

## Error Handling

The framework includes comprehensive error handling:
- File existence checks before processing
- Empty file checks
- Tool availability verification
- Graceful failure handling
- Session directory creation validation

## Customization

You can customize the framework by:
- Modifying wordlist paths in individual scripts
- Adjusting tool parameters and options
- Adding new reconnaissance phases
- Modifying output formats
- Changing session naming conventions

## Security Notes

- Use this tool only on targets you have permission to test
- Respect rate limits and terms of service
- Be aware of legal implications in your jurisdiction
- Consider the impact on target systems
- Each session folder may contain sensitive information

## Troubleshooting

### Common Issues

1. **Tool not found**: Ensure all required tools are installed and in PATH
2. **Permission denied**: Make sure scripts are executable (`chmod +x *.sh`)
3. **Empty results**: Check if target domain is accessible and tools are working
4. **Wordlist not found**: Update wordlist paths in the scripts
5. **Session folder not created**: Check write permissions in the current directory

### Debug Mode

Add `set -x` at the beginning of any script to enable debug output.

### Session Cleanup

To clean up old sessions:
```bash
# Remove sessions older than 30 days
find ./results -type d -mtime +30 -exec rm -rf {} \;
```

## Contributing

Feel free to submit issues, feature requests, or pull requests to improve the framework.

## License

This tool is for educational and authorized security testing purposes only.
