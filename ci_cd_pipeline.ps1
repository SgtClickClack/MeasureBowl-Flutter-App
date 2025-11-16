# CI/CD Pipeline Script for MeasureBowl Flutter App
# This script handles building, testing, and deploying the Flutter app

param(
    [string]$Action = "build",  # build, test, deploy, clean
    [string]$Platform = "android",  # android, ios, web
    [string]$BuildType = "release"  # debug, release
)

Write-Host "MeasureBowl CI/CD Pipeline" -ForegroundColor Green
Write-Host "Action: $Action, Platform: $Platform, Build Type: $BuildType" -ForegroundColor Blue

# Set error handling
$ErrorActionPreference = "Stop"

# Function to check if Flutter is installed
function Test-FlutterInstalled {
    try {
        $flutterVersion = & flutter --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Flutter is installed: $($flutterVersion[0])" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "Flutter is not installed or not in PATH" -ForegroundColor Red
        return $false
    }
    return $false
}

# Function to run Flutter doctor
function Invoke-FlutterDoctor {
    Write-Host "Running Flutter doctor..." -ForegroundColor Blue
    & flutter doctor -v
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter doctor failed"
    }
}

# Function to clean project
function Invoke-CleanProject {
    Write-Host "Cleaning Flutter project..." -ForegroundColor Blue
    & flutter clean
    & flutter pub get
}

# Function to run tests
function Invoke-RunTests {
    Write-Host "Running Flutter tests..." -ForegroundColor Blue
    & flutter test
    if ($LASTEXITCODE -ne 0) {
        throw "Tests failed"
    }
}

# Function to analyze code
function Invoke-AnalyzeCode {
    Write-Host "Analyzing Flutter code..." -ForegroundColor Blue
    & flutter analyze
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Code analysis found issues. Please fix them." -ForegroundColor Yellow
        # Don't throw here, just warn
    }
}

# Function to build Android
function Invoke-BuildAndroid {
    param([string]$BuildType)
    
    Write-Host "Building Android $BuildType..." -ForegroundColor Blue
    
    # Check if keystore exists for release builds
    if ($BuildType -eq "release") {
        $keystorePath = "android/app/upload-keystore.jks"
        if (!(Test-Path $keystorePath)) {
            Write-Host "Warning: Keystore file not found at $keystorePath" -ForegroundColor Yellow
            Write-Host "Release build may fail without proper signing configuration" -ForegroundColor Yellow
        }
    }
    
    if ($BuildType -eq "release") {
        & flutter build appbundle --release
    } else {
        & flutter build apk --debug
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Android build failed"
    }
    
    Write-Host "Android $BuildType build completed successfully" -ForegroundColor Green
}

# Function to build iOS
function Invoke-BuildIOS {
    param([string]$BuildType)
    
    Write-Host "Building iOS $BuildType..." -ForegroundColor Blue
    
    if ($BuildType -eq "release") {
        & flutter build ios --release --no-codesign
    } else {
        & flutter build ios --debug --no-codesign
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "iOS build failed"
    }
    
    Write-Host "iOS $BuildType build completed successfully" -ForegroundColor Green
}

# Function to build Web
function Invoke-BuildWeb {
    Write-Host "Building Web..." -ForegroundColor Blue
    & flutter build web
    if ($LASTEXITCODE -ne 0) {
        throw "Web build failed"
    }
    Write-Host "Web build completed successfully" -ForegroundColor Green
}

# Function to deploy using Fastlane
function Invoke-Deploy {
    param([string]$Platform)
    
    Write-Host "Deploying $Platform..." -ForegroundColor Blue
    
    if ($Platform -eq "android") {
        # Check if Fastlane is installed
        try {
            & bundle exec fastlane android internal
        } catch {
            Write-Host "Fastlane deployment failed. Make sure you have:" -ForegroundColor Red
            Write-Host "1. Ruby and Bundler installed" -ForegroundColor Red
            Write-Host "2. Run 'bundle install' in android/fastlane directory" -ForegroundColor Red
            Write-Host "3. Configured Google Play Console credentials" -ForegroundColor Red
            throw "Deployment failed"
        }
    } else {
        Write-Host "iOS deployment not implemented yet" -ForegroundColor Yellow
    }
}

# Main execution
try {
    # Check Flutter installation
    if (!(Test-FlutterInstalled)) {
        Write-Host "Please install Flutter first by running: .\setup_flutter.ps1" -ForegroundColor Red
        exit 1
    }
    
    # Change to Flutter app directory
    Set-Location "flutter_app"
    
    # Run Flutter doctor
    Invoke-FlutterDoctor
    
    # Execute based on action
    switch ($Action.ToLower()) {
        "clean" {
            Invoke-CleanProject
        }
        "test" {
            Invoke-RunTests
        }
        "analyze" {
            Invoke-AnalyzeCode
        }
        "build" {
            Invoke-AnalyzeCode
            Invoke-RunTests
            
            switch ($Platform.ToLower()) {
                "android" { Invoke-BuildAndroid -BuildType $BuildType }
                "ios" { Invoke-BuildIOS -BuildType $BuildType }
                "web" { Invoke-BuildWeb }
                default { 
                    Write-Host "Building all platforms..." -ForegroundColor Blue
                    Invoke-BuildAndroid -BuildType $BuildType
                    Invoke-BuildWeb
                }
            }
        }
        "deploy" {
            Invoke-Deploy -Platform $Platform
        }
        default {
            Write-Host "Unknown action: $Action" -ForegroundColor Red
            Write-Host "Available actions: clean, test, analyze, build, deploy" -ForegroundColor Yellow
            exit 1
        }
    }
    
    Write-Host "CI/CD pipeline completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "CI/CD pipeline failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    # Return to original directory
    Set-Location ".."
}






