#!/bin/bash
# Hytale 한글 패치 통합 설치 스크립트 (Linux - 고해상도 폰트 + 바이너리 패치)
set -e

# ==========================================
# 1. 환경 변수 설정
# ==========================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Linux Path Detection
POSSIBLE_PATHS=(
    "$HOME/.local/share/Hytale/install/release/package/game/latest/Client/Data/Shared"
    "$HOME/.local/share/Hytale/install/release/package/game/latest/Client/Shared"
    "$HOME/.var/app/com.hypixel.HytaleLauncher/data/Hytale/install/release/package/game/latest/Client/Data/Shared"
    "$HOME/.var/app/com.hypixel.HytaleLauncher/data/Hytale/install/release/package/game/latest/Client/Shared"
)

VENV_DIR="$SCRIPT_DIR/.venv"
PYTHON_BIN="$VENV_DIR/bin/python3"
PIP_BIN="$VENV_DIR/bin/pip"

# 폰트 설정 (레포에 포함된 빌드 완료 폰트 사용)
FONT_NAME="WantedSans"
FONT_JSON="$SCRIPT_DIR/Fonts/${FONT_NAME}.json"
FONT_PNG="$SCRIPT_DIR/Fonts/${FONT_NAME}.png"

echo "=== Hytale 한글 패치 통합 설치 (Linux - 고해상도 폰트) ==="
echo ""

# ==========================================
# 2. 필수 프로그램 확인
# ==========================================
echo "🛠️  필수 프로그램 확인 중..."

install_package() {
    PACKAGE=$1
    if command -v apt-get >/dev/null; then
        sudo apt-get update && sudo apt-get install -y $PACKAGE
    elif command -v dnf >/dev/null; then
        sudo dnf install -y $PACKAGE
    elif command -v pacman >/dev/null; then
        sudo pacman -S --noconfirm $PACKAGE
    elif command -v zypper >/dev/null; then
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
        echo "⚠️  $CMD 가 설치되어 있지 않습니다. 자동 설치 시도..."
        install_package $PKG
        if ! command -v $CMD >/dev/null 2>&1; then
            echo "❌ 설치 실패. 수동으로 $PKG 를 설치해주세요."
            exit 1
        fi
    fi
    echo "   ✓ $CMD 확인됨"
}

check_and_install python3 python3
check_and_install unzip unzip

# ==========================================
# 3. Python 환경 설정
# ==========================================
echo ""
echo "🐍 Python 가상환경 설정 중..."

if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi

"$PIP_BIN" install --disable-pip-version-check -q pillow >/dev/null 2>&1
echo "   ✓ Python 환경 준비 완료"

# ==========================================
# 4. 폰트 파일 확인
# ==========================================
echo ""
echo "📦 폰트 파일 확인 중..."

if [ ! -f "$FONT_JSON" ] || [ ! -f "$FONT_PNG" ]; then
    echo "❌ 폰트 파일이 없습니다."
    echo "   필요한 파일:"
    echo "   - $FONT_JSON"
    echo "   - $FONT_PNG"
    echo ""
    echo "   git pull로 최신 버전을 받아주세요."
    exit 1
fi
echo "   ✓ 폰트 파일 확인됨"

# ==========================================
# 5. 게임 폴더 확인
# ==========================================
echo ""
echo "🔍 게임 폴더 확인 중..."

GAME_DIR=""
for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -d "$path" ]; then
        GAME_DIR="$path"
        break
    fi
done

if [ -z "$GAME_DIR" ]; then
    echo "❌ Hytale 게임 폴더를 찾을 수 없습니다."
    echo "   예상 경로:"
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

echo "   ✓ 게임 폴더 확인됨: $GAME_DIR"

# Game exe 찾기 (Linux는 HytaleClient 실행 파일)
GAME_EXE=""
CURRENT_PATH="$GAME_DIR"
for i in {1..5}; do
    if [ -f "$CURRENT_PATH/HytaleClient" ]; then
        GAME_EXE="$CURRENT_PATH/HytaleClient"
        break
    fi
    CURRENT_PATH="$(dirname "$CURRENT_PATH")"
done

# Assets.zip 찾기
ASSETS_ZIP=""
CURRENT_PATH="$GAME_DIR"
for i in {1..6}; do
    if [ -f "$CURRENT_PATH/Assets.zip" ]; then
        ASSETS_ZIP="$CURRENT_PATH/Assets.zip"
        GAME_BASE="$CURRENT_PATH"
        break
    fi
    CURRENT_PATH="$(dirname "$CURRENT_PATH")"
done

LANG_DIR="$GAME_DIR/Language/ko-KR"
FONTS_DIR="$GAME_DIR/Fonts"

# ==========================================
# 6. 바이너리 패치 (텍스처 크기 512 -> 8192)
# ==========================================
echo ""
echo "🔧 바이너리 패치 중..."

if [ -n "$GAME_EXE" ] && [ -f "$GAME_EXE" ]; then
    BACKUP_EXE="${GAME_EXE}.backup_original"
    if [ ! -f "$BACKUP_EXE" ]; then
        cp "$GAME_EXE" "$BACKUP_EXE"
        echo "   ✓ 원본 바이너리 백업됨"
    fi

    GAME_EXE="$GAME_EXE" "$PYTHON_BIN" << 'PATCHPY'
import os

exe_path = os.environ.get('GAME_EXE')

with open(exe_path, 'rb') as f:
    data = bytearray(f.read())

count = 0

# x86_64 패턴: BA 00 02 00 00 41 B8 00 02 00 00 (mov edx, 0x200; mov r8d, 0x200)
pattern_x86 = bytes([0xBA, 0x00, 0x02, 0x00, 0x00, 0x41, 0xB8, 0x00, 0x02, 0x00, 0x00])
replacement_x86 = bytes([0xBA, 0x00, 0x20, 0x00, 0x00, 0x41, 0xB8, 0x00, 0x20, 0x00, 0x00])
pos = 0
while True:
    pos = data.find(pattern_x86, pos)
    if pos == -1:
        break
    data[pos:pos+11] = replacement_x86
    count += 1
    pos += 11

with open(exe_path, 'wb') as f:
    f.write(data)

if count > 0:
    print(f"   ✓ {count}개 패턴 패치 완료 (512 -> 8192)")
else:
    print("   ⚠️ 패치할 패턴을 찾지 못했습니다")
PATCHPY
    echo "   ✓ 바이너리 패치 완료"
else
    echo "   ⚠️ HytaleClient 실행 파일을 찾을 수 없어 바이너리 패치를 건너뜁니다."
fi

# ==========================================
# 7. 게임 패치 적용 (폰트 + 언어)
# ==========================================
echo ""
echo "💾 게임 패치 적용 중..."

# 폰트 설치
echo "   [폰트 설치]"
for font in NunitoSans-Medium NunitoSans-ExtraBold Lexend-Bold NotoMono-Regular; do
    if [ ! -f "$FONTS_DIR/${font}.json.backup" ]; then
        cp "$FONTS_DIR/${font}.json" "$FONTS_DIR/${font}.json.backup" 2>/dev/null || true
        cp "$FONTS_DIR/${font}.png" "$FONTS_DIR/${font}.png.backup" 2>/dev/null || true
    fi
    cp "$FONT_JSON" "$FONTS_DIR/${font}.json"
    cp "$FONT_PNG" "$FONTS_DIR/${font}.png"
done
echo "   ✓ 폰트 파일 교체 완료"

# 언어 파일 설치
echo "   [언어 파일 설치]"

if [ -d "$LANG_DIR" ] && [ ! -d "${LANG_DIR}_backup" ]; then
    cp -r "$LANG_DIR" "${LANG_DIR}_backup"
fi

TEMP_WORK="$SCRIPT_DIR/temp_work"
rm -rf "$TEMP_WORK"
mkdir -p "$TEMP_WORK"

if [ -f "$ASSETS_ZIP" ]; then
    unzip -q "$ASSETS_ZIP" "Server/Languages/en-US/*" "Common/Languages/en-US/*" -d "$TEMP_WORK" 2>/dev/null || true
fi

CLIENT_EN_DIR="$GAME_DIR/Language/en-US"
if [ -d "$CLIENT_EN_DIR" ]; then
    mkdir -p "$TEMP_WORK/Client"
    cp "$CLIENT_EN_DIR/"*.lang "$TEMP_WORK/Client/" 2>/dev/null || true
fi

mkdir -p "$LANG_DIR/avatarCustomization"

# Client 병합
mkdir -p "$TEMP_WORK/Client"
if [ ! -f "$TEMP_WORK/Client/client.lang" ]; then touch "$TEMP_WORK/Client/client.lang"; fi
"$PYTHON_BIN" "$SCRIPT_DIR/scripts/merge_lang.py" \
    "$TEMP_WORK/Client/client.lang" \
    "$SCRIPT_DIR/Language/ko-KR/client.lang" \
    "$LANG_DIR/client.lang"

cp "$SCRIPT_DIR/Language/ko-KR/meta.lang" "$LANG_DIR/"

# Server 병합
SERVER_BASE="$TEMP_WORK/Server/Languages/en-US"
[ ! -d "$SERVER_BASE" ] && mkdir -p "$SERVER_BASE"
for file in server.lang wordlists.lang; do
    if [ -f "$SERVER_BASE/$file" ]; then
        "$PYTHON_BIN" "$SCRIPT_DIR/scripts/merge_lang.py" \
            "$SERVER_BASE/$file" \
            "$SCRIPT_DIR/Assets/Server/Languages/ko-KR/$file" \
            "$LANG_DIR/$file"
    fi
done

# Avatar 병합
AVATAR_BASE="$TEMP_WORK/Common/Languages/en-US/avatarCustomization"
AVATAR_PATCH="$SCRIPT_DIR/Assets/Common/Languages/ko-KR/avatarCustomization"
if [ -d "$AVATAR_BASE" ] && [ -d "$AVATAR_PATCH" ]; then
    for file in "$AVATAR_BASE"/*.lang; do
        filename=$(basename "$file")
        if [ -f "$AVATAR_PATCH/$filename" ]; then
            "$PYTHON_BIN" "$SCRIPT_DIR/scripts/merge_lang.py" \
                "$file" "$AVATAR_PATCH/$filename" "$LANG_DIR/avatarCustomization/$filename"
        fi
    done
fi

rm -rf "$TEMP_WORK"
echo "   ✓ 언어 파일 설치 완료"

# ==========================================
# 8. 완료
# ==========================================
echo ""
echo "✨ 설치 완료!"
echo ""
echo "📌 중요 안내:"
echo "   1. 기본 런처로 게임을 실행하세요."
echo ""
echo "   2. 게임 업데이트 후에는 이 스크립트를 다시 실행하세요."
echo "      (바이너리가 원본으로 복원되기 때문)"
echo ""
echo "   3. 게임 설정에서 언어 > 한국어를 선택하세요."
echo ""
echo "엔터 키를 누르면 종료됩니다..."
read -r
