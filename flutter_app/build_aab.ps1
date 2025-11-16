# Build Android App Bundle (AAB) Script
# Usage: .\build_aab.ps1

param(
    [switch]$Clean,
    [switch]$Help
)

if ($Help) {
    Write-Host "Build Android App Bundle (AAB) for MeasureBowl" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\build_aab.ps1              # Build AAB file"
    Write-Host "  .\build_aab.ps1 -Clean       # Clean before building"
    Write-Host "  .\build_aab.ps1 -Help         # Show this help"
    Write-Host ""
    Write-Host "Output:" -ForegroundColor Yellow
    Write-Host "  flutter_app\build\app\outputs\bundle\release\app-release.aab"
    exit 0
}

# Ensure we're in the Flutter app directory
# If we're in the project root, navigate to flutter_app
# If we're already in flutter_app, stay here
if (Test-Path "pubspec.yaml") {
    # Already in flutter_app directory
    Write-Host "Working in Flutter app directory: $(Get-Location)" -ForegroundColor Green
} elseif (Test-Path "flutter_app\pubspec.yaml") {
    # In project root, need to navigate
    Set-Location "flutter_app"
    Write-Host "Navigated to Flutter app directory: $(Get-Location)" -ForegroundColor Green
} else {
    Write-Host "Error: Cannot find Flutter app directory. Please run from project root or flutter_app directory." -ForegroundColor Red
    exit 1
}

# Check if Flutter is installed
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-Host "Using: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "Error: Flutter not found. Please install Flutter SDK." -ForegroundColor Red
    exit 1
}

# Clean if requested
if ($Clean) {
    Write-Host "Cleaning build files..." -ForegroundColor Yellow
    flutter clean
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Warning: Clean failed, continuing anyway..." -ForegroundColor Yellow
    }
}

# Get dependencies
Write-Host "Getting Flutter dependencies..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to get dependencies" -ForegroundColor Red
    exit 1
}

# Check keystore configuration
$keyPropertiesPath = "android\key.properties"
$keystorePath = "android\app\upload-keystore.jks"

if (-not (Test-Path $keyPropertiesPath)) {
    Write-Host "Warning: key.properties not found at $keyPropertiesPath" -ForegroundColor Yellow
    Write-Host "Release build may fail without proper signing configuration" -ForegroundColor Yellow
} else {
    Write-Host "Keystore configuration found" -ForegroundColor Green
}

if (-not (Test-Path $keystorePath)) {
    Write-Host "Warning: Keystore file not found at $keystorePath" -ForegroundColor Yellow
    Write-Host "Release build may fail without proper signing configuration" -ForegroundColor Yellow
} else {
    Write-Host "Keystore file found" -ForegroundColor Green
}

# Build AAB
Write-Host ""
Write-Host "Building Android App Bundle (AAB)..." -ForegroundColor Cyan
Write-Host "This may take several minutes..." -ForegroundColor Yellow
Write-Host ""

flutter build appbundle --release

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Error: Build failed!" -ForegroundColor Red
    Write-Host "Check the error messages above for details." -ForegroundColor Yellow
    exit 1
}

# Locate output file
$outputPath = "build\app\outputs\bundle\release\app-release.aab"

if (Test-Path $outputPath) {
    $fileInfo = Get-Item $outputPath
    $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
    
    Write-Host ""
    Write-Host "Build completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "AAB File Location:" -ForegroundColor Cyan
    Write-Host "  $((Get-Location).Path)\$outputPath" -ForegroundColor White
    Write-Host ""
    Write-Host "File Size: $fileSizeMB MB" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Upload this file to Google Play Console" -ForegroundColor White
    Write-Host "  2. Go to: https://play.google.com/console" -ForegroundColor White
    Write-Host "  3. Select your app -> Production -> Create new release" -ForegroundColor White
    Write-Host "  4. Upload: $outputPath" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "Warning: Build completed but AAB file not found at expected location" -ForegroundColor Yellow
    Write-Host "Expected: $outputPath" -ForegroundColor White
    Write-Host ""
    Write-Host "Try running:" -ForegroundColor Yellow
    Write-Host '  flutter build appbundle --release --verbose' -ForegroundColor White
    exit 1
}

