Write-Host "==== Flutter Project Path Rename Helper ====" -ForegroundColor Cyan
Write-Host "This script helps you rename your project folder to eliminate spaces (the most reliable fix)" -ForegroundColor White

# Get the current directory
$currentPath = Get-Location
$currentDir = Split-Path -Path $currentPath -Leaf
$parentDir = Split-Path -Path $currentPath -Parent

# Check if the current folder has spaces
if ($currentDir -notmatch '\s') {
    Write-Host "`nYour project folder name ($currentDir) doesn't contain spaces." -ForegroundColor Green
    Write-Host "You should not be experiencing AAPT2 issues related to path spaces." -ForegroundColor Green
    Write-Host "Try running 'direct_build_fix.ps1' instead for a different approach." -ForegroundColor Yellow
    exit 0
}

# Suggest a new name
$suggestedName = $currentDir -replace '\s', ''
Write-Host "`nYour current project folder: $currentDir" -ForegroundColor White
Write-Host "Suggested new name (no spaces): $suggestedName" -ForegroundColor Green

# Confirm with the user
Write-Host "`nWARNING: This will rename your project folder! Make sure you:" -ForegroundColor Yellow
Write-Host "1. Close any IDEs or editors that might be accessing your project files" -ForegroundColor Yellow
Write-Host "2. Back up your project if you haven't already" -ForegroundColor Yellow

$confirmation = Read-Host "`nDo you want to proceed with renaming? (y/n)"
if ($confirmation.ToLower() -ne 'y') {
    Write-Host "`nOperation cancelled. No changes were made." -ForegroundColor Red
    exit 0
}

# Close any running Flutter or Gradle processes
Write-Host "`nStopping any Flutter or Gradle processes..." -ForegroundColor Cyan
Get-Process | Where-Object { $_.ProcessName -like "*flutter*" -or $_.ProcessName -like "*gradle*" -or $_.ProcessName -like "*java*" } | ForEach-Object {
    try {
        Write-Host "Stopping process: $($_.ProcessName) (ID: $($_.Id))" -ForegroundColor Yellow
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    } catch {
        # Ignore errors if process can't be stopped
    }
}

# Perform the rename
try {
    $newPath = Join-Path -Path $parentDir -ChildPath $suggestedName
    
    # Make sure the target path doesn't already exist
    if (Test-Path $newPath) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $suggestedName = $suggestedName + "_" + $timestamp
        $newPath = Join-Path -Path $parentDir -ChildPath $suggestedName
        Write-Host "`nTarget path already exists. Using: $suggestedName" -ForegroundColor Yellow
    }
    
    # Rename the directory
    Rename-Item -Path $currentPath -NewName $suggestedName -Force
    
    Write-Host "`nProject successfully renamed!" -ForegroundColor Green
    Write-Host "New location: $newPath" -ForegroundColor Green
    
    # Provide next steps
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Navigate to your renamed project: cd $newPath" -ForegroundColor White
    Write-Host "2. Run: flutter clean" -ForegroundColor White
    Write-Host "3. Run: flutter pub get" -ForegroundColor White
    Write-Host "4. Run: flutter build apk --debug" -ForegroundColor White
    
    Write-Host "`nNote: You may need to update any project references in your IDE." -ForegroundColor Yellow
} catch {
    Write-Host "`nError renaming project: $_" -ForegroundColor Red
    Write-Host "You may need to close any applications using the project files and try again." -ForegroundColor Yellow
    Write-Host "Alternatively, manually rename the folder to '$suggestedName'." -ForegroundColor Yellow
}

Write-Host "`n==== Script Completed ====" -ForegroundColor Cyan 