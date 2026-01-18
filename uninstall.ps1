# Hytale Korean Patch Uninstaller (Windows PowerShell)
# 고해상도 폰트 + 메모리 패처 제거

Write-Host "=== Hytale 한글 패치 제거 (Windows) ===" -ForegroundColor Cyan
Write-Host ""

# Path Logic
$localAppData = $env:LOCALAPPDATA
$appData = $env:APPDATA

$gameDir = $null
$possiblePaths = @(
    "$appData\Hytale\install\release\package\game\latest\Client\Data\Shared",
    "$appData\Hytale\install\release\package\game\latest\Client\Shared",
    "$localAppData\Hytale\install\release\package\game\latest\Client\Data\Shared",
    "$localAppData\Hytale\install\release\package\game\latest\Client\Shared"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $gameDir = $path
        break
    }
}

if ($null -eq $gameDir) {
    Write-Host "[ERROR] Hytale 게임 폴더를 찾을 수 없습니다." -ForegroundColor Red
    Write-Host "예상 경로:" -ForegroundColor Yellow
    foreach ($p in $possiblePaths) {
        Write-Host "   - $p"
    }
    Write-Host ""
    $customPath = Read-Host "게임 경로를 직접 입력해주세요 (Client/Data/Shared 폴더)"
    if ($customPath -and (Test-Path $customPath)) {
        $gameDir = $customPath
        Write-Host "   [OK] 사용자 지정 경로 확인됨" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] 유효하지 않은 경로입니다." -ForegroundColor Red
        Read-Host "엔터를 누르면 종료합니다"
        exit 1
    }
}

Write-Host "게임 폴더: $gameDir"
Write-Host ""

# 1. 바이너리 복원
Write-Host "[바이너리 복원 중...]" -ForegroundColor Yellow

# HytaleClient.exe 찾기 (상위로 탐색)
$exePath = $null
$currentPath = $gameDir
for ($i = 0; $i -lt 5; $i++) {
    $checkExe = Join-Path $currentPath "HytaleClient.exe"
    if (Test-Path $checkExe) {
        $exePath = $checkExe
        break
    }
    $currentPath = Split-Path $currentPath -Parent
}

if ($exePath -and (Test-Path $exePath)) {
    $backupExe = $exePath -replace "\.exe$", ".exe.backup_original"
    if (Test-Path $backupExe) {
        Copy-Item -Path $backupExe -Destination $exePath -Force
        Write-Host "   - 원본 바이너리 복원됨" -ForegroundColor Green
    } else {
        Write-Host "   - 원본 바이너리 백업 파일이 없습니다"
        Write-Host "   - 게임 업데이트를 통해 원본으로 복원할 수 있습니다" -ForegroundColor Yellow
    }

    # 이전 버전 DLL 제거 (호환성)
    $clientDir = Split-Path $exePath -Parent
    $versionDll = Join-Path $clientDir "version.dll"
    if (Test-Path $versionDll) {
        Remove-Item -Path $versionDll -Force
        Write-Host "   - version.dll 제거됨 (이전 버전 호환)" -ForegroundColor Green
    }
} else {
    Write-Host "   - HytaleClient.exe를 찾을 수 없습니다"
}

# 2. 폰트 복원
Write-Host ""
Write-Host "[폰트 복원 중...]" -ForegroundColor Yellow
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
        Write-Host "   - $font 복원됨" -ForegroundColor Green
    } else {
        Write-Host "   - $font 백업 없음"
    }
}

# 3. 언어 파일 복원
Write-Host ""
Write-Host "[언어 파일 복원 중...]" -ForegroundColor Yellow
$langDir = Join-Path $gameDir "Language\ko-KR"
$langBackup = Join-Path $gameDir "Language\ko-KR_backup"

if (Test-Path $langDir) {
    Remove-Item -Path $langDir -Recurse -Force
    Write-Host "   - 설치된 ko-KR 폴더 제거됨" -ForegroundColor Green
}

if (Test-Path $langBackup) {
    Move-Item -Path $langBackup -Destination $langDir -Force
    Write-Host "   - 기존 ko-KR 폴더 복원됨" -ForegroundColor Green
} else {
    Write-Host "   - 복원할 백업 없음 (클린 제거)"
}

Write-Host ""
Write-Host "=== 제거 완료! ===" -ForegroundColor Green
Write-Host "Hytale이 초기 상태로 복구되었습니다."
Read-Host "엔터를 누르면 종료합니다"
