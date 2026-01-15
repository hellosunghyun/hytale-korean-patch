# Hytale Korean Patch Installer (Windows PowerShell)
Write-Host "=== Hytale Korean Patch Installer (Windows) ===" -ForegroundColor Cyan
Write-Host ""

# 1. Python Check
try {
    $null = python --version 2>&1
} catch {
    Write-Host "[ERROR] Python not found." -ForegroundColor Red
    
    # Try Winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "[INFO] Attempting to install Python via Winget..." -ForegroundColor Yellow
        winget install -e --id Python.Python.3.12
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n[SUCCESS] Python installed." -ForegroundColor Green
            Write-Host "[IMPORTANT] Please RESTART this script to apply changes." -ForegroundColor Cyan
            Read-Host "Press Enter to exit"
            exit 0
        }
    }

    Write-Host "Please install Python from https://www.python.org/downloads/"
    Write-Host "Make sure to check 'Add Python to PATH' during installation."
    Read-Host "Press Enter to exit"
    exit 1
}

# 2. Node.js Check
try {
    $null = npx --version 2>&1
} catch {
    Write-Host "[ERROR] Node.js (npx) not found." -ForegroundColor Red
    
    # Try Winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "[INFO] Attempting to install Node.js via Winget..." -ForegroundColor Yellow
        winget install -e --id OpenJS.NodeJS.LTS
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n[SUCCESS] Node.js installed." -ForegroundColor Green
            Write-Host "[IMPORTANT] Please RESTART this script to apply changes." -ForegroundColor Cyan
            Read-Host "Press Enter to exit"
            exit 0
        }
    }

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "[REQUIRED] Node.js is required to build the font." -ForegroundColor Yellow
    Write-Host "Opening download page... (https://nodejs.org/)"
    Write-Host "Please install the 'LTS' version and try again."
    Write-Host "============================================================" -ForegroundColor Yellow
    
    Start-Sleep -Seconds 3
    Start-Process "https://nodejs.org/"
    
    Read-Host "Press Enter to exit"
    exit 1
}

# 3. Setup Virtual Environment
if (-not (Test-Path ".venv")) {
    Write-Host "[INFO] Creating Python virtual environment..."
    python -m venv .venv
}

# 4. Install Dependencies
Write-Host "[INFO] Installing dependencies..."
& .\.venv\Scripts\Activate.ps1
pip install --disable-pip-version-check pillow numpy requests 2>&1 | Out-Null

# 5. Run Installer Script
python scripts/install_windows.py

Write-Host ""
Read-Host "Press Enter to exit"
