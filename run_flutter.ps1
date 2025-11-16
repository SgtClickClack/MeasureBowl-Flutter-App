# Helper script to run Flutter commands from the root directory
# Usage: .\run_flutter.ps1 run --release --verbose -d RFCNC0MMD2R

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$FlutterArgs
)

$flutterAppDir = Join-Path $PSScriptRoot "flutter_app"

if (-not (Test-Path (Join-Path $flutterAppDir "pubspec.yaml"))) {
    Write-Error "Error: pubspec.yaml not found in $flutterAppDir"
    exit 1
}

Write-Host "Changing to Flutter app directory: $flutterAppDir" -ForegroundColor Cyan
Push-Location $flutterAppDir

try {
    Write-Host "Running: flutter $($FlutterArgs -join ' ')" -ForegroundColor Green
    flutter @FlutterArgs
} finally {
    Pop-Location
}

