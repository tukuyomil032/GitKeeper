# gitkeeper PowerShell wrapper
# Allows easier execution of gitkeeper on Windows

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

# Get the directory where this script is located
$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir = if ($ScriptPath) {
    Split-Path -Parent $ScriptPath
} else {
    Get-Location
}

# Try to find gitkeeper in common locations
$gitKeeperPaths = @(
    "$ScriptDir\bin\gitkeeper",
    "$ScriptDir\..\bin\gitkeeper",
    "$(Get-Command git | % { Split-Path -Parent (Split-Path -Parent $_.Source) })\bin\gitkeeper",
    "$(Get-Command bash | % { Split-Path -Parent $_.Source })\..\bin\gitkeeper"
)

$gitKeeperPath = $null
foreach ($path in $gitKeeperPaths) {
    if (Test-Path $path) {
        $gitKeeperPath = $path
        break
    }
}

if (-not $gitKeeperPath) {
    Write-Host "Error: gitkeeper not found in expected locations" -ForegroundColor Red
    Write-Host "Please ensure gitkeeper is installed properly" -ForegroundColor Red
    exit 1
}

# Check if bash is available (Git Bash or WSL)
if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Git Bash or WSL not found. Please install Git for Windows." -ForegroundColor Red
    Write-Host "Download from: https://git-scm.com/download/win" -ForegroundColor Yellow
    exit 1
}

# Run gitkeeper via bash
Write-Verbose "Running: bash '$gitKeeperPath' $Arguments"
bash $gitKeeperPath @Arguments
exit $LASTEXITCODE
