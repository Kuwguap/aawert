# AAweRT - An Awesome Reconnaissance Tool

A comprehensive reconnaissance framework that automates various phases of security reconnaissance and vulnerability assessment. Each run creates a separate session folder for better organization.

**Creator:** [github.com/kuwguap](https://github.com/kuwguap)  
**Created under:** [RAWPA](https://rawpa.vercel.com)

## Features

- **Session-Based Organization**: Each run creates a separate timestamped folder
- **10-Phase Reconnaissance**: Complete workflow from subdomain enumeration to vulnerability scanning
- **URL Filtering**: Automatic filtering to prevent noise from external links
- **Sequential Execution**: Proper dependency handling between phases

## Quick Start

### Windows (PowerShell)
```powershell
# Using PowerShell wrapper
.\aawert.ps1 example.com

# Using Git Bash directly
& "C:\Program Files\Git\bin\bash.exe" aawert.sh example.com
```

### Linux/macOS
```bash
chmod +x *.sh
./aawert.sh example.com
```

## Usage Examples

```bash
# Single domain
./aawert.sh example.com

# Multiple domains from file
./aawert.sh -l domains.txt

# Using custom wordlist
./aawert.sh -w wordlist.txt
```

## Required Tools

### Core Tools (Required)
- **subfinder** - Subdomain enumeration
- **amass** - Network mapping and attack surface discovery
- **assetfinder** - Subdomain enumeration
- **httpx** - HTTP probe
- **gau** - URL discovery

### Additional Tools (Optional)
- **katana** - Web crawling
- **hakrawler** - Web crawling
- **ffuf** - Web fuzzing
- **dirsearch** - Directory and file discovery
- **nuclei** - Vulnerability scanning
- **nikto** - Web server scanner
- **s3scanner** - S3 bucket discovery
- **jq** - JSON processor

## Installation

### 1. Install Go (Required)
```bash
# Download from: https://golang.org/dl/
# Or use package manager
```

### 2. Install Tools
```bash
# Run the installation script
./install_tools.sh

# Or install manually
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/owasp-amass/amass/v4/...@master
go install github.com/tomnomnom/assetfinder@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/lc/gau/v2/cmd/gau@latest
```

### 3. Add to PATH
```bash
export PATH=$PATH:$(go env GOPATH)/bin
```

### 4. Install Python Tools
```bash
pip3 install dirsearch
```

## Session Output

Each run creates a timestamped session folder:
```
./results/example.com_20241201_143022/
├── session_summary.txt          # Session metadata
├── all_subdomains.txt           # Combined subdomain results
├── live_subdomains_target.txt   # Live subdomains
├── parameters.txt               # Discovered parameters
├── js_files.txt                 # JavaScript files
└── Various scan results...
```

## Phases

1. **Subdomain Enumeration** (subfinder, amass, assetfinder)
2. **Live Subdomain Detection** (httpx)
3. **Subdomain Crawling** (katana, hakrawler)
4. **Parameter Discovery** (gau)
5. **Content Discovery** (ffuf, dirsearch)
6. **JavaScript Extraction**
7. **Secret Finding** (SecretFinder)
8. **Vulnerability Scanning** (nuclei, nikto)
9. **S3 Bucket Discovery** (s3scanner)
10. **Login Endpoint Discovery**

## Troubleshooting

### Missing Tools
```bash
# Check tool availability
./debug_tools.sh

# Install missing tools
./install_tools.sh
```

### Windows Issues
- Ensure Git Bash is installed
- Use PowerShell wrapper: `.\aawert.ps1 example.com`
- Or use batch file: `aawert.bat example.com`

## Security Notice

Use this tool only on targets you have permission to test. Respect rate limits and terms of service.

## License

This tool is for educational and authorized security testing purposes only.