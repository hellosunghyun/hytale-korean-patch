@echo off
setlocal
cd /d "%~dp0"

echo === Hytale Korean Patch Uninstaller (Windows) ===
echo.

:: Path Logic (Same as installer)
set "LOCAL_APPDATA=%LOCALAPPDATA%"
set "APPDATA=%APPDATA%"

:: Possible Paths
set "GAME_DIR="
if exist "%LOCAL_APPDATA%\Hytale\install\release\package\game\latest\Client\Data\Shared" (
    set "GAME_DIR=%LOCAL_APPDATA%\Hytale\install\release\package\game\latest\Client\Data\Shared"
) else if exist "%LOCAL_APPDATA%\Hytale\install\release\package\game\latest\Client\Shared" (
    set "GAME_DIR=%LOCAL_APPDATA%\Hytale\install\release\package\game\latest\Client\Shared"
) else if exist "%APPDATA%\Hytale\install\release\package\game\latest\Client\Data\Shared" (
    set "GAME_DIR=%APPDATA%\Hytale\install\release\package\game\latest\Client\Data\Shared"
)

if "%GAME_DIR%"=="" (
    echo [ERROR] Hytale game folder not found.
    pause
    exit /b
)

echo Found Game Dir: %GAME_DIR%
echo.

:: 1. Restore Fonts
echo [Restoring Fonts...]
set "FONTS_DIR=%GAME_DIR%\Fonts"
for %%f in (NunitoSans-Medium NunitoSans-ExtraBold Lexend-Bold NotoMono-Regular) do (
    if exist "%FONTS_DIR%\%%f.json.backup" (
        move /y "%FONTS_DIR%\%%f.json.backup" "%FONTS_DIR%\%%f.json" >nul
        move /y "%FONTS_DIR%\%%f.png.backup" "%FONTS_DIR%\%%f.png" >nul
        echo    - %%f Restored
    )
)

:: 2. Restore Language Files
echo.
echo [Restoring Language Files...]
set "LANG_DIR=%GAME_DIR%\Language\ko-KR"
set "LANG_BACKUP=%GAME_DIR%\Language\ko-KR_backup"

if exist "%LANG_DIR%" (
    rmdir /s /q "%LANG_DIR%"
    echo    - Removed installed ko-KR folder
)

if exist "%LANG_BACKUP%" (
    move "%LANG_BACKUP%" "%LANG_DIR%" >nul
    echo    - Restored backup ko-KR folder
) else (
    echo    - No backup found (clean uninstall)
)

echo.
echo === Uninstallation Complete! ===
echo Press Enter to exit...
pause >nul
