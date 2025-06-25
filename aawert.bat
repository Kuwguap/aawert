@echo off
REM AAweRT Batch Wrapper
REM This script allows you to run AAweRT from Windows Command Prompt or PowerShell

set BASH_PATH="C:\Program Files\Git\bin\bash.exe"

REM Check if Git Bash is available
if not exist %BASH_PATH% (
    echo Error: Git Bash not found at %BASH_PATH%
    echo Please install Git for Windows.
    pause
    exit /b 1
)

REM Check if no arguments provided
if "%~1"=="" (
    echo AAweRT - An Awesome Reconnaissance Tool
    echo ========================================
    echo.
    echo Usage:
    echo   aawert.bat ^<target_domain^>
    echo   aawert.bat -l ^<domain_list_file^>
    echo   aawert.bat -w ^<subdomain_wordlist_file^>
    echo.
    echo Examples:
    echo   aawert.bat example.com
    echo   aawert.bat -l domains.txt
    echo   aawert.bat -w wordlist.txt
    pause
    exit /b 1
)

REM Run the bash script with all arguments
%BASH_PATH% aawert.sh %* 