# Script to set up JDK 17 for Flutter Android development
Write-Host "Setting up JDK 17 for Flutter Android development" -ForegroundColor Green

# Check if user wants to install JDK 17 manually or with script
$choice = Read-Host "Do you want to install JDK 17? (y/n)"

if ($choice -eq "y") {
    Write-Host "Opening JDK 17 download page..."
    Start-Process "https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html"
    Write-Host "Please download and install JDK 17 from the Oracle website"
    Write-Host "After installation, press Enter to continue"
    Read-Host
} else {
    Write-Host "Skipping JDK 17 installation. Please ensure JDK 17 is installed on your system."
}

# Check current JAVA_HOME
$currentJavaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "User")
Write-Host "Current JAVA_HOME: $currentJavaHome"

# Ask user for JDK 17 path if not set
$jdk17Path = Read-Host "Enter the path to your JDK 17 installation (e.g., C:\Program Files\Java\jdk-17)"

# Validate the path
if (-not (Test-Path "$jdk17Path\bin\java.exe")) {
    Write-Host "Invalid JDK path. Could not find java.exe in $jdk17Path\bin" -ForegroundColor Red
    exit 1
}

# Backup existing JAVA_HOME
if ($currentJavaHome) {
    [Environment]::SetEnvironmentVariable("JAVA_HOME_BACKUP", $currentJavaHome, "User")
    Write-Host "Backed up current JAVA_HOME to JAVA_HOME_BACKUP" -ForegroundColor Yellow
}

# Set new JAVA_HOME
[Environment]::SetEnvironmentVariable("JAVA_HOME", $jdk17Path, "User")
Write-Host "Set JAVA_HOME to $jdk17Path" -ForegroundColor Green

# Create a local.properties file with JAVA_HOME
$localPropertiesPath = "android\local.properties"
$localPropertiesContent = Get-Content $localPropertiesPath
$newContent = @()

$javaHomeLine = "org.gradle.java.home=$($jdk17Path.Replace('\', '\\'))"
$javaHomeExists = $false

foreach ($line in $localPropertiesContent) {
    if ($line -match "^org\.gradle\.java\.home=") {
        $newContent += $javaHomeLine
        $javaHomeExists = $true
    } else {
        $newContent += $line
    }
}

if (-not $javaHomeExists) {
    $newContent += $javaHomeLine
}

$newContent | Set-Content $localPropertiesPath
Write-Host "Updated $localPropertiesPath with JDK 17 path" -ForegroundColor Green

# Instructions
Write-Host @"

======================================================
JDK 17 Setup Complete!
======================================================

The following changes have been made:
1. JAVA_HOME environment variable is now set to: $jdk17Path
2. Added JDK 17 path to local.properties file

You can now try building your Flutter Android app again using:
- flutter clean
- flutter pub get
- flutter build apk

If you need to restore your previous JAVA_HOME, run:
[Environment]::SetEnvironmentVariable("JAVA_HOME", [Environment]::GetEnvironmentVariable("JAVA_HOME_BACKUP", "User"), "User")

"@ -ForegroundColor Cyan 