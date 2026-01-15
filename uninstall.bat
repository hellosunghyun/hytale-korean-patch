@echo off
setlocal
cd /d "%~dp0"

echo === Hytale Korean Patch Uninstaller Wrapper ===
echo.
echo Running uninstall.ps1 with Bypass policy...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "uninstall.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] PowerShell script execution failed.
    echo Please try running uninstall.ps1 manually (Right-click > Run with PowerShell).
    pause
)
