# Hytale Korean Patch Uninstaller (Windows PowerShell)
Write-Host "=== Hytale Korean Patch Uninstaller (Windows) ===" -ForegroundColor Cyan
Write-Host ""

# Path Logic (Same as installer)
$localAppData = $env:LOCALAPPDATA
$appData = $env:APPDATA

# Possible Paths
$gameDir = $null
$possiblePaths = @(
    "$localAppData\Hytale\install\release\package\game\latest\Client\Data\Shared",
    "$localAppData\Hytale\install\release\package\game\latest\Client\Shared",
    "$appData\Hytale\install\release\package\game\latest\Client\Data\Shared"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $gameDir = $path
        break
    }
}

if ($null -eq $gameDir) {
    Write-Host "[ERROR] Hytale game folder not found." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Found Game Dir: $gameDir"
Write-Host ""

# 1. Restore Fonts
Write-Host "[Restoring Fonts...]"
$fontsDir = Join-Path $gameDir "Fonts"
$fonts = @("NunitoSans-Medium", "NunitoSans-ExtraBold", "Lexend-Bold", "NotoMono-Regular")

foreach ($font in $fonts) {
    $backupJson = Join-Path $fontsDir "$font.json.backup"
    $backupPng = Join-Path $fontsDir "$font.png.backup"
    $targetJson = Join-Path $fontsDir "$font.json"
    $targetPng = Join-Path $fontsDir "$font.png"

    if (Test-Path $backupJson) {
        Move-Item -Path $backupJson -Destination $targetJson -Force
        Move-Item -Path $backupPng -Destination $targetPng -Force
        Write-Host "   - $font Restored"
    }
}

# 2. Restore Language Files
Write-Host ""
Write-Host "[Restoring Language Files...]"
$langDir = Join-Path $gameDir "Language\ko-KR"
$langBackup = Join-Path $gameDir "Language\ko-KR_backup"

if (Test-Path $langDir) {
    Remove-Item -Path $langDir -Recurse -Force
    Write-Host "   - Removed installed ko-KR folder"
}

if (Test-Path $langBackup) {
    Move-Item -Path $langBackup -Destination $langDir -Force
    Write-Host "   - Restored backup ko-KR folder"
} else {
    Write-Host "   - No backup found (clean uninstall)"
}

Write-Host ""
Write-Host "=== Uninstallation Complete! ===" -ForegroundColor Green
Read-Host "Press Enter to exit"
