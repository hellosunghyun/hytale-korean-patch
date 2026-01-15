@echo off
setlocal
cd /d "%~dp0"

echo === Hytale Korean Patch Installer (Windows) ===
echo.

:: 1. Python Check
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python not found.
    echo Please install Python from https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation.
    pause
    exit /b
)

:: 2. Node.js Check
call npx --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js (npx) not found.
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b
)

:: 3. Setup Virtual Environment
if not exist ".venv" (
    echo [INFO] Creating Python virtual environment...
    python -m venv .venv
)

:: 4. Install Dependencies
echo [INFO] Installing dependencies...
call .venv\Scripts\activate.bat
pip install --disable-pip-version-check pillow numpy requests >nul

:: 5. Run Installer Script
python scripts/install_windows.py

echo.
echo Press Enter to exit...
pause >nul
