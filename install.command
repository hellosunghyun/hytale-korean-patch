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

# 고해상도 폰트 설정
FONT_NAME="WantedSans"
FONT_URL="https://github.com/wanteddev/wanted-sans/releases/download/v1.0.3/WantedSans-1.0.3.zip"
FONT_DIR="$SCRIPT_DIR/reference/WantedSans-1.0.3"
FONT_TTF="$FONT_DIR/ttf/WantedSans-Medium.ttf"
CHARSET_FILE="$SCRIPT_DIR/src/charset/charset_full.txt"

echo "=== Hytale 한글 패치 통합 설치 (고해상도 폰트) ==="
echo "이 스크립트는 환경 설정, 폰트 빌드, 바이너리 패치를 수행합니다."
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

# Node.js / npx 확인
if ! command -v npx >/dev/null 2>&1; then
    echo "❌ Node.js (npx)가 설치되어 있지 않습니다."
    echo "   macOS: brew install node"
    exit 1
fi
echo "   ✓ Node.js (npx) 확인됨"

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
# 4. 폰트 다운로드
# ==========================================
echo ""
echo "📥 폰트 다운로드 중..."

if [ ! -f "$FONT_TTF" ]; then
    mkdir -p "$SCRIPT_DIR/reference"
    FONT_ZIP="$SCRIPT_DIR/reference/WantedSans.zip"

    # curl 또는 wget으로 다운로드
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$FONT_ZIP" "$FONT_URL" 2>/dev/null
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$FONT_ZIP" "$FONT_URL"
    else
        echo "❌ curl 또는 wget이 필요합니다."
        exit 1
    fi

    # 압축 해제
    unzip -q -o "$FONT_ZIP" -d "$SCRIPT_DIR/reference/"
    rm -f "$FONT_ZIP"

    if [ -f "$FONT_TTF" ]; then
        echo "   ✓ 폰트 다운로드 완료"
    else
        echo "❌ 폰트 다운로드 실패"
        exit 1
    fi
else
    echo "   ✓ 폰트 이미 존재함"
fi

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
# 6. 고해상도 폰트 빌드
# ==========================================
echo ""
echo "🏗️  고해상도 폰트 빌드 시작..."

# 글자셋 확인/생성 (msdf-bmfont-xml용: 문자 그대로 저장)
if [ ! -f "$CHARSET_FILE" ]; then
    echo "   글자셋 생성 중..."
    mkdir -p "$(dirname "$CHARSET_FILE")"
    "$PYTHON_BIN" -c "
chars = []
# ASCII
for i in range(0x20, 0x7F): chars.append(chr(i))
# Extended symbols
for c in '°–—''\"\"•…': chars.append(c)
# Korean Jamo
for i in range(0x3131, 0x3164): chars.append(chr(i))
# Korean Syllables (11,172)
for i in range(0xAC00, 0xD7A4): chars.append(chr(i))
with open('$CHARSET_FILE', 'w', encoding='utf-8') as f:
    f.write(''.join(chars))
print(f'   ✓ 글자셋 생성 완료: {len(chars)}자')
"
else
    # charset_full.txt가 hex 형식이면 문자 형식으로 변환
    if head -c 4 "$CHARSET_FILE" | grep -q "0x"; then
        echo "   글자셋 형식 변환 중..."
        "$PYTHON_BIN" -c "
chars = []
for i in range(0x20, 0x7F): chars.append(chr(i))
for c in '°–—''\"\"•…': chars.append(c)
for i in range(0x3131, 0x3164): chars.append(chr(i))
for i in range(0xAC00, 0xD7A4): chars.append(chr(i))
with open('$CHARSET_FILE', 'w', encoding='utf-8') as f:
    f.write(''.join(chars))
print(f'   ✓ 글자셋 변환 완료: {len(chars)}자')
"
    fi
fi

# MSDF 아틀라스 생성 (npx msdf-bmfont-xml 사용)
echo "   MSDF 아틀라스 생성 중 (8192x8192, 시간이 걸릴 수 있습니다)..."
mkdir -p "$SCRIPT_DIR/Fonts"

cd "$SCRIPT_DIR"
npx msdf-bmfont-xml \
    -f json \
    -m 8192,8192 \
    -s 48 \
    -r 8 \
    -t msdf \
    -p 2 \
    --pot --square \
    -i "$CHARSET_FILE" \
    -o "${FONT_NAME}" \
    "$FONT_TTF" 2>/dev/null || {
    echo "❌ 폰트 생성 실패"
    exit 1
}

# msdf-bmfont-xml은 폰트 이름에 따라 다른 파일명 생성
TEMP_PNG=""
TEMP_JSON=""

# PNG 찾기
if [ -f "$SCRIPT_DIR/${FONT_NAME}.png" ]; then
    TEMP_PNG="$SCRIPT_DIR/${FONT_NAME}.png"
elif [ -f "$SCRIPT_DIR/${FONT_NAME}.0.png" ]; then
    TEMP_PNG="$SCRIPT_DIR/${FONT_NAME}.0.png"
fi

# JSON 찾기 (여러 가능한 이름 확인)
for json_name in "${FONT_NAME}.json" "${FONT_NAME}-Medium.json" "WantedSans-Medium.json"; do
    if [ -f "$SCRIPT_DIR/$json_name" ]; then
        TEMP_JSON="$SCRIPT_DIR/$json_name"
        break
    fi
done

if [ -z "$TEMP_PNG" ] || [ ! -f "$TEMP_PNG" ]; then
    echo "❌ 폰트 생성 실패 - PNG 파일 없음"
    ls -la "$SCRIPT_DIR"/*.png 2>/dev/null || true
    exit 1
fi

if [ -z "$TEMP_JSON" ] || [ ! -f "$TEMP_JSON" ]; then
    echo "❌ 폰트 생성 실패 - JSON 파일 없음"
    ls -la "$SCRIPT_DIR"/*.json 2>/dev/null || true
    exit 1
fi

# Hytale 포맷으로 변환
echo "   Hytale 포맷으로 변환 중..."
"$PYTHON_BIN" - "$TEMP_JSON" "$SCRIPT_DIR/Fonts/${FONT_NAME}.json" << 'PYEOF'
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    bmfont = json.load(f)

info = bmfont.get('info', {})
common = bmfont.get('common', {})
df = bmfont.get('distanceField', {})
chars = bmfont.get('chars', [])

size = info.get('size', 48)
tex_w = common.get('scaleW', 4096)
tex_h = common.get('scaleH', 4096)
base = common.get('base', size)

hytale = {
    "atlas": {
        "type": df.get('fieldType', 'msdf'),
        "distanceRange": df.get('distanceRange', 8),
        "distanceRangeMiddle": 0,
        "size": size,
        "width": tex_w,
        "height": tex_h,
        "yOrigin": "top"
    },
    "metrics": {
        "emSize": 1,
        "lineHeight": 1.364,
        "ascender": -1.011,
        "descender": 0.353,
        "underlineY": 0.101,
        "underlineThickness": 0.037
    },
    "glyphs": [],
    "kerning": []
}

for ch in chars:
    char_id = ch['id']
    w = ch['width']
    h = ch['height']
    x = ch['x']
    y = ch['y']
    xoff = ch['xoffset']
    yoff = ch['yoffset']
    xadv = ch['xadvance']

    advance = xadv / size
    left = xoff / size
    top = -(base - yoff) / size
    right = (xoff + w) / size
    bottom = -(base - yoff - h) / size

    glyph = {
        "unicode": char_id,
        "advance": advance,
        "planeBounds": {"left": left, "top": top, "right": right, "bottom": bottom},
        "atlasBounds": {"left": x + 0.5, "top": y + 0.5, "right": x + w - 0.5, "bottom": y + h - 0.5}
    }
    hytale["glyphs"].append(glyph)

for kern in bmfont.get('kernings', []):
    hytale["kerning"].append({
        "unicode1": kern['first'],
        "unicode2": kern['second'],
        "advance": kern['amount'] / size
    })

with open(sys.argv[2], 'w', encoding='utf-8') as f:
    json.dump(hytale, f, separators=(',', ': '))

print(f"   ✓ 변환 완료: {len(hytale['glyphs'])}자")
PYEOF

# 파일 이동 및 정리
mv "$TEMP_PNG" "$SCRIPT_DIR/Fonts/${FONT_NAME}.png"
rm -f "$SCRIPT_DIR/${FONT_NAME}"*.json "$SCRIPT_DIR/${FONT_NAME}"*.png 2>/dev/null || true
echo "   ✓ 폰트 빌드 완료"

# ==========================================
# 7. 바이너리 패치 (텍스처 크기 512 -> 8192)
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
# 8. 게임 패치 적용 (폰트 + 언어)
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
    cp "$SCRIPT_DIR/Fonts/${FONT_NAME}.json" "$FONTS_DIR/${font}.json"
    cp "$SCRIPT_DIR/Fonts/${FONT_NAME}.png" "$FONTS_DIR/${font}.png"
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
# 9. 완료
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
