@echo off
setlocal
cd /d "%~dp0"

echo === Hytale Korean Patch Installer Wrapper ===
echo.
echo Running install.ps1 with Bypass policy...
echo.

:: 2. Node.js Check
call npx --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js (npx) not found.
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
