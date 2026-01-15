@echo off
setlocal
cd /d "%~dp0"

echo === Hytale Korean Patch Installer Wrapper ===
echo.
echo Running install.ps1 with Bypass policy...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "install.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] PowerShell script execution failed.
    echo Please try running install.ps1 manually (Right-click > Run with PowerShell).
    pause
)
