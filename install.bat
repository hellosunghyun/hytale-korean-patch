@echo off
setlocal
cd /d "%~dp0"

echo === Hytale Korean Patch Installer Wrapper ===
echo.
echo Running install.ps1 with Bypass policy...
echo.

:: 1. Python Check
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python not found.
    
    :: Try Winget Auto-install
    winget --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo [INFO] Attempting to install Python via Winget...
        winget install -e --id Python.Python.3.12
        if %errorlevel% equ 0 (
            echo.
            echo [SUCCESS] Python installed.
            echo [IMPORTANT] Please RESTART this script to apply changes.
            pause
            exit /b
        )
    )

    echo.
    echo Please install Python from https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation.
    pause
    exit /b
)

:: 2. Node.js Check
call npx --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js (npx) not found.
    
    :: Try Winget Auto-install
    winget --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo [INFO] Attempting to install Node.js via Winget...
        winget install -e --id OpenJS.NodeJS.LTS
        if %errorlevel% equ 0 (
            echo.
            echo [SUCCESS] Node.js installed.
            echo [IMPORTANT] Please RESTART this script to apply changes.
            pause
            exit /b
        )
    )

    echo.
    echo ============================================================
    echo [REQUIRED] Node.js is required to build the font.
    echo Opening download page... (https://nodejs.org/)
    echo Please install the "LTS" version and try again.
    echo ============================================================
    timeout /t 3 >nul
    start https://nodejs.org/
    pause
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "install.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] PowerShell script execution failed.
    echo Please try running install.ps1 manually (Right-click > Run with PowerShell).
    pause
)
