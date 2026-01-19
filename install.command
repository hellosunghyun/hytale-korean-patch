#!/bin/bash
# Hytale 한글 패치 통합 설치 스크립트 (고해상도 폰트 + 바이너리 패치)
set -e

# ==========================================
# 1. 환경 변수 설정
# ==========================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GAME_BASE="$HOME/Library/Application Support/Hytale/install/release/package/game/latest"
HYTALE_APP="$GAME_BASE/Client/Hytale.app"
GAME_DIR="$HYTALE_APP/Contents/Resources/Data/Shared"
GAME_EXE="$HYTALE_APP/Contents/MacOS/HytaleClient"
LANG_DIR="$GAME_DIR/Language/ko-KR"
FONTS_DIR="$GAME_DIR/Fonts"

VENV_DIR="$SCRIPT_DIR/.venv"
PYTHON_BIN="$VENV_DIR/bin/python3"
PIP_BIN="$VENV_DIR/bin/pip"

# 폰트 설정 (레포에 포함된 빌드 완료 폰트 사용)
FONT_NAME="WantedSans"
FONT_JSON="$SCRIPT_DIR/Fonts/${FONT_NAME}.json"
FONT_PNG="$SCRIPT_DIR/Fonts/${FONT_NAME}.png"

echo "=== Hytale 한글 패치 통합 설치 (고해상도 폰트) ==="
echo ""

# ==========================================
# 2. 필수 프로그램 확인
# ==========================================
echo "🛠️  필수 프로그램 확인 중..."

# Python 확인
if ! command -v python3 >/dev/null 2>&1; then
    echo "❌ Python3가 설치되어 있지 않습니다."
    echo "   macOS: brew install python3"
    exit 1
fi
echo "   ✓ Python3 확인됨"

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

if [ ! -d "$GAME_DIR" ]; then
    echo "❌ Hytale 게임 폴더를 찾을 수 없습니다."
    echo "   예상 경로: $GAME_DIR"
    echo ""
    echo "게임이 설치된 경로를 직접 입력해주세요 (Hytale.app 경로):"
    read -r CUSTOM_PATH
    if [ -d "$CUSTOM_PATH" ]; then
        HYTALE_APP="$CUSTOM_PATH"
        GAME_DIR="$HYTALE_APP/Contents/Resources/Data/Shared"
        GAME_EXE="$HYTALE_APP/Contents/MacOS/HytaleClient"
        LANG_DIR="$GAME_DIR/Language/ko-KR"
        FONTS_DIR="$GAME_DIR/Fonts"
        # Assets.zip 경로 재탐색
        CURRENT_PATH="$GAME_DIR"
        for i in {1..6}; do
            if [ -f "$CURRENT_PATH/Assets.zip" ]; then
                GAME_BASE="$CURRENT_PATH"
                break
            fi
            CURRENT_PATH="$(dirname "$CURRENT_PATH")"
        done
        echo "   ✓ 사용자 지정 경로 확인됨"
    else
        echo "❌ 유효하지 않은 경로입니다."
        exit 1
    fi
else
    echo "   ✓ 게임 폴더 확인됨"
fi

# ==========================================
# 6. 바이너리 패치 (텍스처 크기 512 -> 8192)
# ==========================================
echo ""
echo "🔧 바이너리 패치 중..."

# 바이너리 백업
BACKUP_EXE="${GAME_EXE}.backup_original"
if [ ! -f "$BACKUP_EXE" ]; then
    cp "$GAME_EXE" "$BACKUP_EXE"
    echo "   ✓ 원본 바이너리 백업됨"
fi

# Python으로 바이너리 직접 패치 (512 -> 8192)
GAME_EXE="$GAME_EXE" "$PYTHON_BIN" << 'PATCHPY'
import os

exe_path = os.environ.get('GAME_EXE')

with open(exe_path, 'rb') as f:
    data = bytearray(f.read())

# ARM64: movz w1, #0x200; movz w2, #0x200 -> movz w1, #0x2000; movz w2, #0x2000
# x86_64: mov edx, 0x200; mov r8d, 0x200 -> mov edx, 0x2000; mov r8d, 0x2000

count = 0
i = 0

# ARM64 패턴 (연속된 movz wX, #0x200 쌍)
while i < len(data) - 8:
    # movz wX, #0x200 = XX 40 80 52 (little-endian)
    if (data[i+1] == 0x40 and data[i+2] == 0x80 and data[i+3] == 0x52 and
        data[i+5] == 0x40 and data[i+6] == 0x80 and data[i+7] == 0x52):
        # 8192로 변경: XX 40 80 52 -> XX 00 84 52
        data[i+1] = 0x00
        data[i+2] = 0x84
        data[i+5] = 0x00
        data[i+6] = 0x84
        count += 1
        i += 8
    else:
        i += 4

# x86_64 패턴도 확인 (Universal binary인 경우)
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

# 바이너리 재서명 (ad-hoc)
echo "   바이너리 서명 중..."
codesign --force --sign - "$GAME_EXE" 2>/dev/null || true
echo "   ✓ 바이너리 패치 완료"

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

ASSETS_ZIP="$GAME_BASE/Assets.zip"
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
