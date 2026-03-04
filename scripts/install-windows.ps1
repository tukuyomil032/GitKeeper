# gitkeeper installer for Windows (PowerShell 5.0+)

param(
    [string]$InstallDir = $env:ProgramFiles + "\gitkeeper",
    [string]$UserInstall = $false
)

# Color output helper
function Write-ColorOutput {
    param(
        [Parameter(ValueFromPipeline=$true)]
        [ValidateSet('Green', 'Red', 'Yellow', 'Cyan', 'Magenta')]
        [string]$Color,
        [string]$Message
    )
    
    $ColorMap = @{
        'Green'   = 10
        'Red'     = 12
        'Yellow'  = 14
        'Cyan'    = 11
        'Magenta' = 13
    }
    
    $code = $ColorMap[$Color]
    Write-Host $Message -ForegroundColor $Color
}

$ScriptDir = Split-Path -Absolute $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ConfigSource = "$ProjectRoot\templates\config.json"
$ConfigDest = "$env:USERPROFILE\.config\gitkeeper\config.json"

Write-Host ""
Write-Host "📦 gitkeeper Installer (Windows)" -ForegroundColor Cyan -BackgroundColor Black
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host ""

# Check for required tools
Write-Host "✓ Checking dependencies..." -ForegroundColor Cyan

# Check for Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Git is required but not installed" -ForegroundColor Red
    Write-Host "   Download from: https://git-scm.com/download/win"
    exit 1
}

# Check for jq (try both system and in Git's bin)
$jqFound = $false
if (Get-Command jq -ErrorAction SilentlyContinue) {
    $jqFound = $true
} else {
    $gitBash = Get-Command git | % { Split-Path -Parent $_.Source }
    if (Test-Path "$gitBash\jq.exe") {
        Write-Host "   Note: jq found in Git Bash, using that"
        $jqFound = $true
    }
}

if (-not $jqFound) {
    Write-Host "❌ jq is required but not installed" -ForegroundColor Red
    Write-Host "   Download from: https://stedolan.github.io/jq/download/"
    Write-Host "   Or install via: choco install jq"
    exit 1
}

Write-Host "✓ Dependencies OK" -ForegroundColor Green
Write-Host ""

# Determine installation directory
if ($UserInstall -eq $true) {
    $InstallDir = "$env:USERPROFILE\AppData\Local\gitkeeper"
}

Write-Host "📝 Installation directory: $InstallDir" -ForegroundColor Cyan
Write-Host ""

# Create installation directory if needed
if (-not (Test-Path $InstallDir)) {
    Write-Host "Creating installation directory..."
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# Copy main binary and libraries
Write-Host "📦 Copying files..."
Copy-Item -Path "$ProjectRoot\bin" -Destination "$InstallDir\bin" -Recurse -Force
Copy-Item -Path "$ProjectRoot\lib" -Destination "$InstallDir\lib" -Recurse -Force
Copy-Item -Path "$ProjectRoot\templates" -Destination "$InstallDir\templates" -Recurse -Force

# Create PowerShell wrapper script
$WrapperScript = @"
#!/bin/bash
# gitkeeper wrapper for Windows PowerShell

# Get the installation directory
INSTALL_DIR=`$1
shift

# Source the main gitkeeper script via bash
bash "`$INSTALL_DIR/bin/gitkeeper" `$@
"@

# Create CMD batch wrapper
$BatchWrapper = @"
@echo off
REM gitkeeper launcher for CMD

bash "%~dp0gitkeeper.sh" %*
"@

# Save wrappers
$WrapperScript | Out-File -FilePath "$InstallDir\gitkeeper.sh" -Encoding UTF8
$BatchWrapper | Out-File -FilePath "$InstallDir\gitkeeper.cmd" -Encoding UTF8 -NoNewline

Write-Host "✓ Files copied to $InstallDir" -ForegroundColor Green
Write-Host ""

# Add to PATH
Write-Host "🔗 Updating PATH..."
$UserPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
$PathExists = $UserPath -split ';' | Where-Object { $_ -eq $InstallDir }

if (-not $PathExists) {
    $NewPath = "$InstallDir;$UserPath"
    [Environment]::SetEnvironmentVariable('PATH', $NewPath, 'User')
    Write-Host "✓ $InstallDir added to PATH" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️  Please restart PowerShell for PATH changes to take effect" -ForegroundColor Yellow
    Write-Host ""
}

# Setup configuration
Write-Host "⚙️  Setting up configuration..." -ForegroundColor Cyan
$ConfigDir = Split-Path -Parent $ConfigDest
if (-not (Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
}

if (Test-Path $ConfigDest) {
    Write-Host "⚠️  Config already exists at $ConfigDest" -ForegroundColor Yellow
    $overwrite = Read-Host "   Overwrite? (y/N)"
    if ($overwrite -eq 'y' -or $overwrite -eq 'Y') {
        Copy-Item -Path $ConfigSource -Destination $ConfigDest -Force
        Write-Host "✓ Config updated" -ForegroundColor Green
    }
} else {
    Copy-Item -Path $ConfigSource -Destination $ConfigDest -Force
    Write-Host "✓ Config installed to $ConfigDest" -ForegroundColor Green
}
Write-Host ""

# Verify installation
Write-Host "✅ Verifying installation..." -ForegroundColor Green
if (Get-Command gitkeeper.cmd -ErrorAction SilentlyContinue) {
    Write-Host "✓ gitkeeper is available" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "⚠️  gitkeeper command not yet available in this shell" -ForegroundColor Yellow
    Write-Host "   Restart PowerShell for changes to take effect" -ForegroundColor Yellow
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "✨ gitkeeper installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Getting started:" -BackgroundColor Black
Write-Host "   gitkeeper.cmd          # Run interactive cleanup"
Write-Host "   gitkeeper.cmd --help   # Show help"
Write-Host "   gitkeeper.cmd --dry-run # Preview changes"
Write-Host ""
Write-Host "⚙️  Configuration:" -BackgroundColor Black
Write-Host "   Edit: $ConfigDest"
Write-Host ""
Write-Host "📊  Documentation:" -BackgroundColor Black
Write-Host "   README:   https://github.com/hosiyomi322/gitkeeper#readme"
Write-Host ""
