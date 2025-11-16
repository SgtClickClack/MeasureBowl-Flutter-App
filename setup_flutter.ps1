# Flutter Setup Script for Windows
# This script helps install Flutter SDK and configure the environment

Write-Host "Setting up Flutter SDK for MeasureBowl app..." -ForegroundColor Green

# Check if Flutter is already installed
$flutterPath = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterPath) {
    Write-Host "Flutter is already installed at: $($flutterPath.Source)" -ForegroundColor Yellow
    flutter doctor -v
    exit 0
}

# Create Flutter directory
$flutterDir = "C:\flutter"
if (!(Test-Path $flutterDir)) {
    Write-Host "Creating Flutter directory: $flutterDir" -ForegroundColor Blue
    New-Item -ItemType Directory -Path $flutterDir -Force
}

# Download Flutter SDK
Write-Host "Downloading Flutter SDK..." -ForegroundColor Blue
$flutterZip = "$env:TEMP\flutter_windows.zip"
$flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip"

try {
    Invoke-WebRequest -Uri $flutterUrl -OutFile $flutterZip -UseBasicParsing
    Write-Host "Flutter SDK downloaded successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to download Flutter SDK: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please download Flutter manually from: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
    exit 1
}

# Extract Flutter SDK
Write-Host "Extracting Flutter SDK..." -ForegroundColor Blue
try {
    Expand-Archive -Path $flutterZip -DestinationPath "C:\" -Force
    Remove-Item $flutterZip -Force
    Write-Host "Flutter SDK extracted successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to extract Flutter SDK: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Add Flutter to PATH
Write-Host "Adding Flutter to PATH..." -ForegroundColor Blue
$flutterBinPath = "C:\flutter\bin"
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$flutterBinPath*") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$flutterBinPath", "User")
    Write-Host "Flutter added to PATH. Please restart your terminal." -ForegroundColor Green
} else {
    Write-Host "Flutter is already in PATH" -ForegroundColor Yellow
}

# Run Flutter doctor
Write-Host "Running Flutter doctor..." -ForegroundColor Blue
& "$flutterBinPath\flutter.bat" doctor -v

Write-Host "Flutter setup completed!" -ForegroundColor Green
Write-Host "Please restart your terminal and run 'flutter doctor' to verify the installation." -ForegroundColor Yellow






