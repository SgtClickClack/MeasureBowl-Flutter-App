# Alternative Flutter Setup Script for Windows
# This script provides multiple methods to install Flutter SDK

Write-Host "Alternative Flutter Setup for MeasureBowl app..." -ForegroundColor Green

# Method 1: Check if Flutter is already installed via other means
Write-Host "`nMethod 1: Checking existing Flutter installations..." -ForegroundColor Blue

# Check common Flutter installation paths
$flutterPaths = @(
    "C:\flutter\bin\flutter.bat",
    "C:\src\flutter\bin\flutter.bat",
    "$env:USERPROFILE\flutter\bin\flutter.bat",
    "$env:LOCALAPPDATA\flutter\bin\flutter.bat"
)

$flutterFound = $false
foreach ($path in $flutterPaths) {
    if (Test-Path $path) {
        Write-Host "Found Flutter at: $path" -ForegroundColor Green
        $flutterFound = $true
        
        # Add to PATH if not already there
        $flutterBinPath = Split-Path $path -Parent
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        if ($currentPath -notlike "*$flutterBinPath*") {
            [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$flutterBinPath", "User")
            Write-Host "Added Flutter to PATH. Please restart your terminal." -ForegroundColor Yellow
        }
        break
    }
}

if ($flutterFound) {
    Write-Host "Flutter installation found! Testing..." -ForegroundColor Green
    try {
        & flutter --version
        Write-Host "Flutter is working correctly!" -ForegroundColor Green
        exit 0
    } catch {
        Write-Host "Flutter found but not working properly." -ForegroundColor Red
    }
}

# Method 2: Manual download instructions
Write-Host "`nMethod 2: Manual Installation Instructions" -ForegroundColor Blue
Write-Host "Since automatic download failed, please follow these steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Download Flutter SDK manually:" -ForegroundColor Cyan
Write-Host "   https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Extract to C:\flutter" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Add C:\flutter\bin to your PATH:" -ForegroundColor Cyan
Write-Host "   - Open System Properties > Environment Variables" -ForegroundColor Cyan
Write-Host "   - Add C:\flutter\bin to User PATH" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Restart your terminal and run: flutter doctor" -ForegroundColor Cyan

# Method 3: Using Git to clone Flutter
Write-Host "`nMethod 3: Git Clone Method" -ForegroundColor Blue
Write-Host "If you have Git installed, you can clone Flutter:" -ForegroundColor Yellow
Write-Host ""
Write-Host "git clone https://github.com/flutter/flutter.git -b stable C:\flutter" -ForegroundColor Cyan
Write-Host ""

# Method 4: Using Chocolatey (if available)
Write-Host "`nMethod 4: Chocolatey Package Manager" -ForegroundColor Blue
try {
    $choco = Get-Command choco -ErrorAction SilentlyContinue
    if ($choco) {
        Write-Host "Chocolatey detected! You can install Flutter with:" -ForegroundColor Green
        Write-Host "choco install flutter" -ForegroundColor Cyan
        Write-Host ""
        $useChoco = Read-Host "Would you like to install Flutter using Chocolatey? (y/n)"
        if ($useChoco -eq "y" -or $useChoco -eq "Y") {
            Write-Host "Installing Flutter via Chocolatey..." -ForegroundColor Blue
            & choco install flutter -y
            Write-Host "Flutter installation completed!" -ForegroundColor Green
            exit 0
        }
    }
} catch {
    Write-Host "Chocolatey not available." -ForegroundColor Yellow
}

# Method 5: Using Scoop (if available)
Write-Host "`nMethod 5: Scoop Package Manager" -ForegroundColor Blue
try {
    $scoop = Get-Command scoop -ErrorAction SilentlyContinue
    if ($scoop) {
        Write-Host "Scoop detected! You can install Flutter with:" -ForegroundColor Green
        Write-Host "scoop install flutter" -ForegroundColor Cyan
        Write-Host ""
        $useScoop = Read-Host "Would you like to install Flutter using Scoop? (y/n)"
        if ($useScoop -eq "y" -or $useScoop -eq "Y") {
            Write-Host "Installing Flutter via Scoop..." -ForegroundColor Blue
            & scoop install flutter
            Write-Host "Flutter installation completed!" -ForegroundColor Green
            exit 0
        }
    }
} catch {
    Write-Host "Scoop not available." -ForegroundColor Yellow
}

Write-Host "`nPlease choose one of the methods above to install Flutter." -ForegroundColor Yellow
Write-Host "After installation, run 'flutter doctor' to verify the setup." -ForegroundColor Yellow





