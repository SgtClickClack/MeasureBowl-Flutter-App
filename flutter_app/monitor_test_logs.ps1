# Test Log Monitor Script
# Monitors field_test_log.txt for errors and critical issues during testing

param(
    [string]$LogFile = "field_test_log.txt",
    [int]$RefreshInterval = 2
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Field Test Log Monitor" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Monitoring: $LogFile" -ForegroundColor Yellow
Write-Host "Refresh interval: $RefreshInterval seconds" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
Write-Host ""

$lastSize = 0
$errorCount = 0
$exceptionCount = 0
$fatalCount = 0

while ($true) {
    if (Test-Path $LogFile) {
        $currentSize = (Get-Item $LogFile).Length
        
        if ($currentSize -gt $lastSize) {
            # New content added, check for issues
            $content = Get-Content $LogFile -Tail 50 -ErrorAction SilentlyContinue
            
            # Check for errors
            $errors = $content | Select-String -Pattern "ERROR|FATAL" -CaseSensitive
            $exceptions = $content | Select-String -Pattern "Exception|Throwable" -CaseSensitive
            $typeCastIssues = $content | Select-String -Pattern "int.*double|double.*int|type.*cast" -CaseSensitive
            
            if ($errors) {
                $newErrors = $errors | Where-Object { $_.LineNumber -gt ($lastSize / 100) }
                if ($newErrors) {
                    $errorCount += $newErrors.Count
                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] ⚠️  ERRORS DETECTED:" -ForegroundColor Red
                    $newErrors | ForEach-Object {
                        Write-Host "  $($_.Line)" -ForegroundColor Red
                    }
                    Write-Host ""
                }
            }
            
            if ($exceptions) {
                $newExceptions = $exceptions | Where-Object { $_.LineNumber -gt ($lastSize / 100) }
                if ($newExceptions) {
                    $exceptionCount += $newExceptions.Count
                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] ⚠️  EXCEPTIONS DETECTED:" -ForegroundColor Yellow
                    $newExceptions | ForEach-Object {
                        Write-Host "  $($_.Line)" -ForegroundColor Yellow
                    }
                    Write-Host ""
                }
            }
            
            if ($typeCastIssues) {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] ⚠️  TYPE CAST ISSUES DETECTED:" -ForegroundColor Magenta
                $typeCastIssues | ForEach-Object {
                    Write-Host "  $($_.Line)" -ForegroundColor Magenta
                }
                Write-Host ""
            }
            
            $lastSize = $currentSize
        }
        
        # Display summary every 10 seconds
        if ((Get-Date).Second % 10 -eq 0) {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Monitoring... (Errors: $errorCount, Exceptions: $exceptionCount, Fatal: $fatalCount)" -ForegroundColor Gray
        }
    } else {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Waiting for log file to be created..." -ForegroundColor Gray
    }
    
    Start-Sleep -Seconds $RefreshInterval
}

