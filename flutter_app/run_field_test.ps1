# Field Test Helper Script
# This script helps automate the setup phase of the E2E field test

param(
    [string]$PackageName = "com.standnmeasure.app",
    [string]$LogFile = "field_test_log.txt",
    [switch]$ClearData,
    [switch]$StartLogging,
    [switch]$CheckDevice
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Field Test Helper Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if adb is available
function Test-ADB {
    try {
        $null = adb version 2>&1
        return $true
    } catch {
        return $false
    }
}

# Function to check if device is connected
function Test-DeviceConnected {
    $devices = adb devices 2>&1 | Select-String -Pattern "device$"
    return $devices.Count -gt 0
}

# Function to get connected devices
function Get-ConnectedDevices {
    $output = adb devices 2>&1
    $devices = $output | Select-String -Pattern "device$" | ForEach-Object {
        ($_ -split "\s+")[0]
    }
    return $devices
}

# Check if ADB is available
if (-not (Test-ADB)) {
    Write-Host "ERROR: ADB (Android Debug Bridge) is not found in PATH." -ForegroundColor Red
    Write-Host "Please install Android SDK Platform Tools and add it to your PATH." -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ ADB is available" -ForegroundColor Green
Write-Host ""

# Check device connection
if ($CheckDevice) {
    Write-Host "Checking device connection..." -ForegroundColor Yellow
    if (-not (Test-DeviceConnected)) {
        Write-Host "ERROR: No Android device or emulator is connected." -ForegroundColor Red
        Write-Host "Please connect a device via USB (with USB debugging enabled) or start an emulator." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Attempting to list devices:" -ForegroundColor Yellow
        adb devices
        exit 1
    }
    
    $devices = Get-ConnectedDevices
    Write-Host "✓ Device(s) connected:" -ForegroundColor Green
    foreach ($device in $devices) {
        Write-Host "  - $device" -ForegroundColor Cyan
    }
    Write-Host ""
}

# Clear app data if requested
if ($ClearData) {
    Write-Host "Clearing app data for package: $PackageName" -ForegroundColor Yellow
    try {
        adb shell pm clear $PackageName 2>&1 | Out-Null
        Write-Host "✓ App data cleared successfully" -ForegroundColor Green
    } catch {
        Write-Host "WARNING: Failed to clear app data. Error: $_" -ForegroundColor Yellow
        Write-Host "You may need to clear it manually from device settings." -ForegroundColor Yellow
    }
    Write-Host ""
}

# Start logging if requested
if ($StartLogging) {
    Write-Host "Starting logcat logging to: $LogFile" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop logging when test is complete." -ForegroundColor Yellow
    Write-Host ""
    
    # Clear any existing log file
    if (Test-Path $LogFile) {
        Remove-Item $LogFile -Force
        Write-Host "Cleared existing log file." -ForegroundColor Yellow
    }
    
    Write-Host "Logging started. Logs will be saved to: $LogFile" -ForegroundColor Green
    Write-Host "Keep this window open during testing." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Start logcat and redirect to file
    adb logcat > $LogFile
} else {
    # If no specific action requested, show usage
    if (-not $ClearData -and -not $StartLogging -and -not $CheckDevice) {
        Write-Host "Usage Examples:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1. Check device connection:" -ForegroundColor Yellow
        Write-Host "   .\run_field_test.ps1 -CheckDevice" -ForegroundColor White
        Write-Host ""
        Write-Host "2. Clear app data:" -ForegroundColor Yellow
        Write-Host "   .\run_field_test.ps1 -ClearData" -ForegroundColor White
        Write-Host ""
        Write-Host "3. Start logging:" -ForegroundColor Yellow
        Write-Host "   .\run_field_test.ps1 -StartLogging" -ForegroundColor White
        Write-Host ""
        Write-Host "4. Full setup (clear data + start logging):" -ForegroundColor Yellow
        Write-Host "   .\run_field_test.ps1 -ClearData -StartLogging" -ForegroundColor White
        Write-Host ""
        Write-Host "5. Custom package name:" -ForegroundColor Yellow
        Write-Host "   .\run_field_test.ps1 -PackageName 'com.your.package' -ClearData" -ForegroundColor White
        Write-Host ""
        Write-Host "Parameters:" -ForegroundColor Cyan
        Write-Host "  -PackageName    App package name (default: com.standnmeasure.app)" -ForegroundColor White
        Write-Host "  -LogFile        Log file name (default: field_test_log.txt)" -ForegroundColor White
        Write-Host "  -ClearData      Clear app data before testing" -ForegroundColor White
        Write-Host "  -StartLogging   Start adb logcat and save to file" -ForegroundColor White
        Write-Host "  -CheckDevice    Check if device is connected" -ForegroundColor White
        Write-Host ""
    }
}

