#!/bin/bash
# Hytale 한글 패치 설치 스크립트 (Linux)
set -e

# ==========================================
# 1. 환경 변수 설정
# ==========================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Linux Path Detection Logic
# Common paths:
# 1. ~/.local/share/Hytale/...
# 2. Custom?

POSSIBLE_PATHS=(
    "$HOME/.local/share/Hytale/install/release/package/game/latest/Client/Data/Shared"
    "$HOME/.local/share/Hytale/install/release/package/game/latest/Client/Shared"
)

GAME_DIR=""
for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -d "$path" ]; then
        GAME_DIR="$path"
        break
    fi
done

if [ -z "$GAME_DIR" ]; then
    echo "❌ Hytale 게임 폴더를 찾을 수 없습니다."
    echo "   예상 경로에 폴더가 없습니다:"
    for path in "${POSSIBLE_PATHS[@]}"; do
        echo "   - $path"
    done
    
    echo ""
    echo "게임이 설치된 경로를 직접 입력해주세요 (Client/Data/Shared 폴더 경로):"
    read -r CUSTOM_PATH
    if [ -d "$CUSTOM_PATH" ]; then
        GAME_DIR="$CUSTOM_PATH"
    else
        echo "❌ 유효하지 않은 경로입니다."
        exit 1
    fi
fi

# GAME_BASE calculation (Assuming standard structure: .../game/latest/Client/Data/Shared)
# We need to find Assets.zip which is usually in .../game/latest/Assets.zip
# From Shared (Client/Data/Shared), it is ../../../Assets.zip
# From Shared (Client/Shared), it is ../../Assets.zip

# Try to find Assets.zip
ASSETS_ZIP=""
CURRENT_PATH="$GAME_DIR"
for i in {1..6}; do
    if [ -f "$CURRENT_PATH/Assets.zip" ]; then
        ASSETS_ZIP="$CURRENT_PATH/Assets.zip"
        break
    fi
    CURRENT_PATH="$(dirname "$CURRENT_PATH")"
done

if [ -z "$ASSETS_ZIP" ]; then
    echo "⚠️ Assets.zip을 찾을 수 없습니다. (경고)"
fi

LANG_DIR="$GAME_DIR/Language/ko-KR"
FONTS_DIR="$GAME_DIR/Fonts"

VENV_DIR="$SCRIPT_DIR/.venv"
PYTHON_BIN="$VENV_DIR/bin/python3"
PIP_BIN="$VENV_DIR/bin/pip"
FONT_URL="https://quiple.dev/_astro/Galmuri9.ttf"
FONT_TTF="Galmuri9.ttf"

echo "=== Hytale 한글 패치 통합 설치 (Linux) ==="
echo "설치 경로: $GAME_DIR"
echo ""

# ==========================================
# 2. 필수 프로그램 확인 및 자동 설치
# ==========================================
echo "🛠️  필수 프로그램 확인 중..."

install_package() {
    PACKAGE=$1
    if command -v apt-get >/dev/null; then
        echo "   [Debian/Ubuntu] sudo apt-get install -y $PACKAGE"
        sudo apt-get update && sudo apt-get install -y $PACKAGE
    elif command -v dnf >/dev/null; then
        echo "   [Fedora/RHEL] sudo dnf install -y $PACKAGE"
        sudo dnf install -y $PACKAGE
    elif command -v pacman >/dev/null; then
        echo "   [Arch] sudo pacman -S --noconfirm $PACKAGE"
        sudo pacman -S --noconfirm $PACKAGE
    elif command -v zypper >/dev/null; then
        echo "   [OpenSUSE] sudo zypper install -y $PACKAGE"
        sudo zypper install -y $PACKAGE
    else
        echo "❌ 패키지 매니저를 찾을 수 없습니다. 수동으로 $PACKAGE 를 설치해주세요."
        exit 1
    fi
}

check_and_install() {
    CMD=$1
    PKG=$2
    if ! command -v $CMD >/dev/null 2>&1; then
        echo "⚠️  $CMD 가 설치되어 있지 않습니다."
        echo "   자동 설치를 시도합니다. (sudo 권한 필요)"
        install_package $PKG
        
        # 재확인
        if ! command -v $CMD >/dev/null 2>&1; then
            echo "❌ 설치 실패. 수동으로 $PKG 를 설치해주세요."
            exit 1
        fi
        echo "   ✓ $PKG 설치 완료"
    else
        echo "   ✓ $CMD 확인됨"
    fi
}

# Python 확인
check_and_install python3 python3

# npm / npx 확인
check_and_install npm npm

# unzip 확인
check_and_install unzip unzip

# ==========================================
# 3. Python 환경 설정 (.venv)
# ==========================================
echo ""
echo "🐍 Python 가상환경 설정 중..."

if [ ! -d "$VENV_DIR" ]; then
    echo "   가상환경 생성 중 (.venv)..."
    python3 -m venv "$VENV_DIR"
fi

# 필수 라이브러리 설치 (pillow, numpy)
echo "   필수 라이브러리 확인 및 설치..."
"$PIP_BIN" install --disable-pip-version-check pillow numpy >/dev/null
echo "   ✓ Python 라이브러리 준비 완료"

# ==========================================
# 4. 리소스 준비 (폰트 다운로드 & 글자셋)
# ==========================================
echo ""
echo "📥 리소스 준비 중..."

# 폰트 다운로드
if [ ! -f "$FONT_TTF" ]; then
    echo "   Galmuri9.ttf 다운로드 중..."
    curl -s -o "$FONT_TTF" "$FONT_URL"
    echo "   ✓ 폰트 다운로드 완료"
else
    echo "   ✓ 폰트 파일 확인됨 ($FONT_TTF)"
fi

# 글자셋 확인
CHARSET_FILE="$SCRIPT_DIR/src/charset/charset_final.txt"
if [ ! -f "$CHARSET_FILE" ]; then
    echo "   ⚠️ 글자셋 파일이 없어 재생성합니다."
    mkdir -p "$(dirname "$CHARSET_FILE")"
    echo " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_\`abcdefghijklmnopqrstuvwxyz{|}~가각간갇갈감갑갓갔강갖갗같갚갛개객갠갤갬갭갭갰갱" > "$CHARSET_FILE"
fi

# ==========================================
# 5. 폰트 빌드 (Generation)
# ==========================================
echo ""
echo "🏗️  폰트 빌드 시작..."

# 임시 파일 정리
rm -f Galmuri9.json Galmuri9-fixed.png Galmuri9-converted.json

# 5-1. MSDF 아틀라스 생성 (npx)
echo "   1) MSDF 아틀라스 생성 (시간이 걸릴 수 있습니다)..."
npx msdf-bmfont-xml -f json -m 512,512 -s 10 -r 2 -t msdf -p 0 --pot --square -i "$CHARSET_FILE" -o Galmuri9-fixed "$FONT_TTF" >/dev/null 2>&1
if [ ! -f "Galmuri9.json" ]; then
    echo "❌ 폰트 생성 실패. msdf-bmfont-xml 실행 중 오류 발생."
    exit 1
fi

# 5-2. 포맷 변환 (Hytale format)
echo "   2) Hytale 포맷으로 변환..."
"$PYTHON_BIN" "$SCRIPT_DIR/scripts/convert_font.py" Galmuri9.json Galmuri9-converted.json

# 5-3. 선명화 및 최종 저장
echo "   3) 폰트 선명화 및 최종 파일 생성..."
mkdir -p "$SCRIPT_DIR/Fonts"
"$PYTHON_BIN" "$SCRIPT_DIR/scripts/sharpen.py" Galmuri9-fixed.png Galmuri9-converted.json "$SCRIPT_DIR/Fonts/Galmuri9-Final.json" "$SCRIPT_DIR/Fonts/Galmuri9-sharp.png"

if [ -f "$SCRIPT_DIR/Fonts/Galmuri9-Final.json" ]; then
    echo "   ✓ 폰트 빌드 성공"
else
    echo "❌ 폰트 빌드 실패"
    exit 1
fi

# 임시 파일 정리
rm -f Galmuri9.json Galmuri9-fixed.png Galmuri9-converted.json

# ==========================================
# 6. 게임 패치 적용 (Installation)
# ==========================================
echo ""
echo "💾 게임 패치 적용 중..."

# 6-1. 폰트 설치
echo "   [폰트 설치]"
for font in NunitoSans-Medium NunitoSans-ExtraBold Lexend-Bold NotoMono-Regular; do
    if [ ! -f "$FONTS_DIR/${font}.json.backup" ]; then
        cp "$FONTS_DIR/${font}.json" "$FONTS_DIR/${font}.json.backup"
        cp "$FONTS_DIR/${font}.png" "$FONTS_DIR/${font}.png.backup"
    fi
    cp "$SCRIPT_DIR/Fonts/Galmuri9-Final.json" "$FONTS_DIR/${font}.json"
    cp "$SCRIPT_DIR/Fonts/Galmuri9-sharp.png" "$FONTS_DIR/${font}.png"
done
echo "   ✓ 폰트 파일 교체 완료"

# 6-2. 언어 파일 설치
echo "   [언어 파일 설치]"

if [ -d "$LANG_DIR" ]; then
    if [ ! -d "${LANG_DIR}_backup" ]; then
        cp -r "$LANG_DIR" "${LANG_DIR}_backup"
        echo "   ✓ 기존 언어 폴더 백업됨"
    fi
fi

# 임시 작업 공간
TEMP_WORK="$SCRIPT_DIR/temp_work"
rm -rf "$TEMP_WORK"
mkdir -p "$TEMP_WORK"

echo "   1) 원본(영어) 파일 추출 중..."

if [ -f "$ASSETS_ZIP" ]; then
    unzip -q "$ASSETS_ZIP" "Server/Languages/en-US/*" "Common/Languages/en-US/*" -d "$TEMP_WORK" 2>/dev/null || echo "      ⚠️ Assets.zip 추출 중 일부 경고 발생 (무시 가능)"
else
    echo "❌ Assets.zip을 찾을 수 없습니다. 게임이 설치되어 있나요?"
    echo "   경로: $GAME_DIR"
    exit 1
fi

# Find Client en-US (Smart Search)
CLIENT_EN_DIR=""
# 1. Try Sibling Language folder
if [ -d "$GAME_DIR/Language/en-US" ]; then
    CLIENT_EN_DIR="$GAME_DIR/Language/en-US"
elif [ -d "$(dirname "$GAME_DIR")/Language/en-US" ]; then # ../Language/en-US
    CLIENT_EN_DIR="$(dirname "$GAME_DIR")/Language/en-US"
fi

if [ -d "$CLIENT_EN_DIR" ]; then
    mkdir -p "$TEMP_WORK/Client"
    cp "$CLIENT_EN_DIR/"*.lang "$TEMP_WORK/Client/" 2>/dev/null || true
else
    echo "⚠️ 클라이언트 영어 폴더(en-US)를 찾을 수 없습니다. 패치 파일만 사용합니다."
fi

echo "   2) 한국어 번역 병합 (Merge) 중..."
mkdir -p "$LANG_DIR/avatarCustomization"

# A. Client
if [ ! -f "$TEMP_WORK/Client/client.lang" ]; then touch "$TEMP_WORK/Client/client.lang"; fi
"$PYTHON_BIN" "$SCRIPT_DIR/scripts/merge_lang.py" \
    "$TEMP_WORK/Client/client.lang" \
    "$SCRIPT_DIR/Language/ko-KR/client.lang" \
    "$LANG_DIR/client.lang"

cp "$SCRIPT_DIR/Language/ko-KR/meta.lang" "$LANG_DIR/"

# B. Server
SERVER_BASE="$TEMP_WORK/Server/Languages/en-US"
if [ ! -d "$SERVER_BASE" ]; then mkdir -p "$SERVER_BASE"; fi

for file in server.lang wordlists.lang; do
    if [ -f "$SERVER_BASE/$file" ]; then
        "$PYTHON_BIN" "$SCRIPT_DIR/scripts/merge_lang.py" \
            "$SERVER_BASE/$file" \
            "$SCRIPT_DIR/Assets/Server/Languages/ko-KR/$file" \
            "$LANG_DIR/$file"
    fi
done

# C. Avatar
AVATAR_BASE="$TEMP_WORK/Common/Languages/en-US/avatarCustomization"
AVATAR_PATCH="$SCRIPT_DIR/Assets/Common/Languages/ko-KR/avatarCustomization"

if [ -d "$AVATAR_BASE" ] && [ -d "$AVATAR_PATCH" ]; then
    for file in "$AVATAR_BASE"/*.lang; do
        filename=$(basename "$file")
        if [ -f "$AVATAR_PATCH/$filename" ]; then
            "$PYTHON_BIN" "$SCRIPT_DIR/scripts/merge_lang.py" \
                "$file" \
                "$AVATAR_PATCH/$filename" \
                "$LANG_DIR/avatarCustomization/$filename"
        fi
    done
fi

rm -rf "$TEMP_WORK"

echo "   ✓ 언어 파일 병합 및 설치 완료 (최신 버전 호환)"

echo ""
echo "✨ 모든 작업이 완료되었습니다!"
echo "이제 게임을 실행하고 설정 > 언어 > 한국어를 선택하세요."
echo ""
echo "엔터 키를 누르면 종료됩니다..."
read -r
