# AAweRT PowerShell Wrapper
# This script allows you to run AAweRT from PowerShell

param(
    [Parameter(Position=0)]
    [string]$Target,
    
    [Parameter()]
    [string]$DomainList,
    
    [Parameter()]
    [string]$Wordlist
)

# Check if Git Bash is available
$bashPath = "C:\Program Files\Git\bin\bash.exe"
if (-not (Test-Path $bashPath)) {
    Write-Error "Git Bash not found at $bashPath. Please install Git for Windows."
    exit 1
}

# Check if aawert.sh exists in current directory
$scriptPath = Join-Path $PWD "aawert.sh"
if (-not (Test-Path $scriptPath)) {
    Write-Error "aawert.sh not found in current directory: $PWD"
    exit 1
}

# Build the command
$command = "./aawert.sh"

if ($DomainList) {
    $command += " -l `"$DomainList`""
} elseif ($Wordlist) {
    $command += " -w `"$Wordlist`""
} elseif ($Target) {
    $command += " `"$Target`""
} else {
    Write-Host "AAweRT - An Awesome Reconnaissance Tool" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\aawert.ps1 <target_domain>" -ForegroundColor White
    Write-Host "  .\aawert.ps1 -DomainList <domain_list_file>" -ForegroundColor White
    Write-Host "  .\aawert.ps1 -Wordlist <subdomain_wordlist_file>" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\aawert.ps1 example.com" -ForegroundColor White
    Write-Host "  .\aawert.ps1 -DomainList domains.txt" -ForegroundColor White
    Write-Host "  .\aawert.ps1 -Wordlist wordlist.txt" -ForegroundColor White
    exit 1
}

# Run the bash script
Write-Host "Running AAweRT with command: $command" -ForegroundColor Cyan
Write-Host "Current directory: $PWD" -ForegroundColor Gray
& $bashPath -c $command 