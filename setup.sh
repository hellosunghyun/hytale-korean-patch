#!/bin/bash
# Hytale 한글 패치 원클릭 부트스트랩 (macOS/Linux)

REPO_URL="https://github.com/hellosunghyun/hytale-korean-patch"
ZIP_URL="https://github.com/hellosunghyun/hytale-korean-patch/archive/refs/heads/master.zip"
INSTALL_DIR="$HOME/hytale-korean-patch"

echo "=== Hytale 한글 패치 다운로더 ==="
echo ""

# 1. 기존 폴더 정리
if [ -d "$INSTALL_DIR" ]; then
    echo "♻️  기존 설치 폴더를 정리합니다..."
    rm -rf "$INSTALL_DIR"
fi

# 2. 다운로드 (Git 또는 ZIP)
if command -v git >/dev/null 2>&1; then
    echo "⬇️  Git을 사용하여 다운로드 중..."
    git clone "$REPO_URL" "$INSTALL_DIR"
else
    echo "⚠️  Git이 설치되어 있지 않습니다."
    echo "⬇️  ZIP 파일로 다운로드 중..."
    
    # curl 또는 wget 확인
    if command -v curl >/dev/null 2>&1; then
        curl -L -o hytale-patch.zip "$ZIP_URL"
    elif command -v wget >/dev/null 2>&1; then
        wget -O hytale-patch.zip "$ZIP_URL"
    else
        echo "❌ curl 또는 wget이 필요합니다."
        exit 1
    fi
    
    # unzip 확인
    if ! command -v unzip >/dev/null 2>&1; then
        echo "❌ unzip 명령어가 필요합니다."
        exit 1
    fi
    
    unzip -q hytale-patch.zip
    mv hytale-korean-patch-master "$INSTALL_DIR"
    rm hytale-patch.zip
fi

# 3. 설치 스크립트 실행
echo ""
echo "🚀 설치 스크립트를 실행합니다..."
cd "$INSTALL_DIR"

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    chmod +x install.command
    ./install.command
else
    # Linux
    chmod +x install_linux.sh
    ./install_linux.sh
fi
