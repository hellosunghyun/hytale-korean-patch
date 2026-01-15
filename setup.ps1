# Hytale Korean Patch One-Click Bootstrap (Windows)
$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/hellosunghyun/hytale-korean-patch.git"
$ZipUrl = "https://github.com/hellosunghyun/hytale-korean-patch/archive/refs/heads/master.zip"
$InstallDir = "$HOME\hytale-korean-patch"
$ZipFile = "$HOME\hytale-patch.zip"

Write-Host "=== Hytale Korean Patch Downloader ===" -ForegroundColor Cyan
Write-Host ""

# 1. Cleanup
if (Test-Path $InstallDir) {
    Write-Host "♻️  Cleaning up existing folder..."
    Remove-Item -Path $InstallDir -Recurse -Force
}

# 2. Download (Git or ZIP)
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "⬇️  Downloading via Git..."
    git clone $RepoUrl $InstallDir
} else {
    Write-Host "⚠️  Git not found."
    Write-Host "⬇️  Downloading via ZIP..."
    
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipFile
    Expand-Archive -Path $ZipFile -DestinationPath "$HOME" -Force
    
    # Rename folder (zip contains hytale-korean-patch-master)
    Move-Item -Path "$HOME\hytale-korean-patch-master" -Destination $InstallDir
    Remove-Item -Path $ZipFile -Force
}

# 3. Run Installer
Write-Host ""
Write-Host "🚀 Running installer..."
Set-Location $InstallDir

# Run install.ps1 via wrapper or directly
if (Test-Path "install.ps1") {
    powershell -NoProfile -ExecutionPolicy Bypass -File "install.ps1"
} else {
    Write-Host "❌ install.ps1 not found!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
}
