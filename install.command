#!/bin/bash
# Hytale 한글 패치 통합 설치 스크립트 (빌드 포함)
set -e

# ==========================================
# 1. 환경 변수 설정
# ==========================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GAME_BASE="$HOME/Library/Application Support/Hytale/install/release/package/game/latest"
GAME_DIR="$GAME_BASE/Client/Hytale.app/Contents/Resources/Data/Shared"
LANG_DIR="$GAME_DIR/Language/ko-KR"
FONTS_DIR="$GAME_DIR/Fonts"

VENV_DIR="$SCRIPT_DIR/.venv"
PYTHON_BIN="$VENV_DIR/bin/python3"
PIP_BIN="$VENV_DIR/bin/pip"
FONT_URL="https://quiple.dev/_astro/Galmuri9.ttf"
FONT_TTF="Galmuri9.ttf"

echo "=== Hytale 한글 패치 통합 설치 (All-in-One) ==="
echo "이 스크립트는 환경 설정, 폰트 빌드, 게임 패치를 모두 수행합니다."
echo ""

# ==========================================
# 2. 필수 프로그램 확인
# ==========================================
echo "🛠️  필수 프로그램 확인 중..."

# Python 확인
if ! command -v python3 >/dev/null 2>&1; then
    echo "❌ Python3가 설치되어 있지 않습니다."
    echo "   macOS: brew install python3 또는 공식 홈페이지에서 설치해주세요."
    exit 1
fi
echo "   ✓ Python3 확인됨"

# Node.js / npx 확인
if ! command -v npx >/dev/null 2>&1; then
    echo "❌ Node.js (npx)가 설치되어 있지 않습니다."
    echo "   macOS: brew install node 또는 공식 홈페이지에서 설치해주세요."
    exit 1
fi
echo "   ✓ Node.js (npx) 확인됨"

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

# 글자셋 확인 (없으면 기본 생성 - 안전장치)
CHARSET_FILE="$SCRIPT_DIR/src/charset/charset_final.txt"
if [ ! -f "$CHARSET_FILE" ]; then
    echo "   ⚠️ 글자셋 파일이 없어 재생성합니다."
    mkdir -p "$(dirname "$CHARSET_FILE")"
    # 간단한 기본 글자셋 생성 (실제로는 더 복잡하지만, 비상용)
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
# 공백 문자 경고는 무시해도 됨
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

# 빌드 결과물 확인
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

# 게임 폴더 확인
if [ ! -d "$GAME_DIR" ]; then
    echo "❌ Hytale 게임 폴더를 찾을 수 없습니다."
    echo "   예상 경로: $GAME_DIR"
    echo ""
    echo "게임이 설치된 경로를 직접 입력해주세요 (Client/.../Data/Shared 폴더 경로):"
    read -r CUSTOM_PATH
    if [ -d "$CUSTOM_PATH" ]; then
        GAME_DIR="$CUSTOM_PATH"
        LANG_DIR="$GAME_DIR/Language/ko-KR"
        FONTS_DIR="$GAME_DIR/Fonts"
        # Assets.zip 경로도 다시 탐색
        ASSETS_ZIP=""
        CURRENT_PATH="$GAME_DIR"
        for i in {1..6}; do
            if [ -f "$CURRENT_PATH/Assets.zip" ]; then
                ASSETS_ZIP="$CURRENT_PATH/Assets.zip"
                break
            fi
            CURRENT_PATH="$(dirname "$CURRENT_PATH")"
        done
        echo "   ✓ 사용자 지정 경로 확인됨: $GAME_DIR"
    else
        echo "❌ 유효하지 않은 경로입니다."
        exit 1
    fi
fi

# 6-1. 폰트 설치
echo "   [폰트 설치]"
for font in NunitoSans-Medium NunitoSans-ExtraBold Lexend-Bold NotoMono-Regular; do
    # 백업 (최초 1회만)
    if [ ! -f "$FONTS_DIR/${font}.json.backup" ]; then
        cp "$FONTS_DIR/${font}.json" "$FONTS_DIR/${font}.json.backup"
        cp "$FONTS_DIR/${font}.png" "$FONTS_DIR/${font}.png.backup"
    fi
    
    # 설치
    cp "$SCRIPT_DIR/Fonts/Galmuri9-Final.json" "$FONTS_DIR/${font}.json"
    cp "$SCRIPT_DIR/Fonts/Galmuri9-sharp.png" "$FONTS_DIR/${font}.png"
done
echo "   ✓ 폰트 파일 교체 완료"

# 6-2. 언어 파일 설치
echo "   [언어 파일 설치]"

# 기존 언어 폴더 백업
if [ -d "$LANG_DIR" ]; then
    if [ ! -d "${LANG_DIR}_backup" ]; then
        cp -r "$LANG_DIR" "${LANG_DIR}_backup"
        echo "   ✓ 기존 언어 폴더 백업됨"
    fi
fi

# 임시 작업 공간 생성
TEMP_WORK="$SCRIPT_DIR/temp_work"
rm -rf "$TEMP_WORK"
mkdir -p "$TEMP_WORK"

echo "   1) 원본(영어) 파일 추출 중..."

# 1. Assets.zip에서 서버/공용 언어 파일 추출 (Assets.zip은 수정하지 않음)
ASSETS_ZIP="$GAME_BASE/Assets.zip"
if [ -f "$ASSETS_ZIP" ]; then
    # unzip이 없으면 설치 확인 필요하지만, macOS는 기본 내장
    unzip -q "$ASSETS_ZIP" "Server/Languages/en-US/*" "Common/Languages/en-US/*" -d "$TEMP_WORK" 2>/dev/null || echo "      ⚠️ Assets.zip 추출 중 일부 경고 발생 (무시 가능)"
else
    echo "❌ Assets.zip을 찾을 수 없습니다. 게임이 설치되어 있나요?"
    exit 1
fi

# 2. 클라이언트 언어 파일 가져오기 (게임 폴더 내)
CLIENT_EN_DIR="$GAME_DIR/Language/en-US"
if [ -d "$CLIENT_EN_DIR" ]; then
    mkdir -p "$TEMP_WORK/Client"
    cp "$CLIENT_EN_DIR/"*.lang "$TEMP_WORK/Client/" 2>/dev/null || true
else
    echo "⚠️ 클라이언트 영어 폴더(en-US)를 찾을 수 없습니다. 패치 파일만 사용합니다."
fi

echo "   2) 한국어 번역 병합 (Merge) 중..."
mkdir -p "$LANG_DIR/avatarCustomization"

# A. Client 파일 병합 (client.lang)
# 베이스가 없으면 빈 파일 생성 (안전장치)
if [ ! -f "$TEMP_WORK/Client/client.lang" ]; then touch "$TEMP_WORK/Client/client.lang"; fi
"$PYTHON_BIN" "$SCRIPT_DIR/scripts/merge_lang.py" \
    "$TEMP_WORK/Client/client.lang" \
    "$SCRIPT_DIR/Language/ko-KR/client.lang" \
    "$LANG_DIR/client.lang"

# meta.lang은 병합이 아니라 그냥 복사 (한국어 설정 파일이므로)
cp "$SCRIPT_DIR/Language/ko-KR/meta.lang" "$LANG_DIR/"

# B. Server 파일 병합 (server.lang, wordlists.lang)
# 베이스 경로: temp_work/Server/Languages/en-US/
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

# C. Avatar 커스터마이징 파일 병합
# 베이스 경로: temp_work/Common/Languages/en-US/avatarCustomization/
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

# 임시 폴더 정리
rm -rf "$TEMP_WORK"

echo "   ✓ 언어 파일 병합 및 설치 완료 (최신 버전 호환)"

# ==========================================
# 7. 완료
# ==========================================
echo ""
echo "✨ 모든 작업이 완료되었습니다!"
echo "   1. Python 환경 설정 및 라이브러리 설치"
echo "   2. 최신 폰트 다운로드 및 빌드 (글자셋 적용)"
echo "   3. 게임 리소스(폰트, 언어) 패치"
echo ""
echo "이제 게임을 실행하고 설정 > 언어 > 한국어를 선택하세요."
echo ""
echo "엔터 키를 누르면 종료됩니다..."
read -r
