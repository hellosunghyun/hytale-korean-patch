#!/bin/bash
# Hytale 한글 패치 제거 스크립트 (고해상도 폰트 + 바이너리 패치)

GAME_BASE="$HOME/Library/Application Support/Hytale/install/release/package/game/latest"
HYTALE_APP="$GAME_BASE/Client/Hytale.app"
GAME_DIR="$HYTALE_APP/Contents/Resources/Data/Shared"
GAME_EXE="$HYTALE_APP/Contents/MacOS/HytaleClient"

# 게임 폴더 확인
if [ ! -d "$GAME_DIR" ]; then
    echo "❌ Hytale 게임 폴더를 찾을 수 없습니다."
    echo "   예상 경로: $GAME_DIR"
    echo ""
    echo "설치 시 사용했던 경로를 입력해주세요 (Hytale.app 경로):"
    read -r CUSTOM_PATH
    if [ -d "$CUSTOM_PATH" ]; then
        HYTALE_APP="$CUSTOM_PATH"
        GAME_DIR="$HYTALE_APP/Contents/Resources/Data/Shared"
        GAME_EXE="$HYTALE_APP/Contents/MacOS/HytaleClient"
        echo "   ✓ 사용자 지정 경로 확인됨"
    else
        echo "❌ 유효하지 않은 경로입니다."
        exit 1
    fi
fi

LANG_DIR="$GAME_DIR/Language/ko-KR"
FONTS_DIR="$GAME_DIR/Fonts"

echo "=== Hytale 한글 패치 제거 ==="
echo ""

# 1. 바이너리 복원
echo "🔧 바이너리 복원 중..."

BACKUP_EXE="${GAME_EXE}.backup_original"
if [ -f "$BACKUP_EXE" ]; then
    cp "$BACKUP_EXE" "$GAME_EXE"
    codesign --force --sign - "$GAME_EXE" 2>/dev/null || true
    echo "   ✓ 원본 바이너리 복원 완료"
else
    echo "   ⚠️ 원본 바이너리 백업 파일이 없습니다."
    echo "   → 게임 업데이트를 통해 원본으로 복원할 수 있습니다."
fi

# 오래된 백업 파일들 정리
rm -f "${GAME_EXE}.backup" 2>/dev/null
rm -f "${GAME_EXE}.backup_512" 2>/dev/null
rm -f "${GAME_EXE}.original" 2>/dev/null

# dylib 제거 (이전 버전 호환)
GAME_EXE_DIR="$HYTALE_APP/Contents/MacOS"
if [ -f "$GAME_EXE_DIR/libfontpatch.dylib" ]; then
    rm -f "$GAME_EXE_DIR/libfontpatch.dylib"
    echo "   ✓ libfontpatch.dylib 제거됨"
fi

# 런처 스크립트 제거 (이전 버전 호환)
if [ -f "$GAME_EXE_DIR/HytaleKorean.command" ]; then
    rm -f "$GAME_EXE_DIR/HytaleKorean.command"
    echo "   ✓ 런처 스크립트 제거됨"
fi

# 2. 폰트 복원
echo ""
echo "📁 폰트 복원 중..."
for font in NunitoSans-Medium NunitoSans-ExtraBold Lexend-Bold NotoMono-Regular; do
    if [ -f "$FONTS_DIR/${font}.json.backup" ]; then
        mv "$FONTS_DIR/${font}.json.backup" "$FONTS_DIR/${font}.json"
        mv "$FONTS_DIR/${font}.png.backup" "$FONTS_DIR/${font}.png"
        echo "   ✓ ${font} 복원 완료"
    else
        echo "   ⚠️ ${font} 백업 파일이 없습니다."
    fi
done

# 3. 언어 파일 제거 및 복원
echo ""
echo "📁 언어 파일 제거 중..."

if [ -d "$LANG_DIR" ]; then
    rm -rf "$LANG_DIR"
    echo "   ✓ 설치된 ko-KR 폴더 제거 완료"
fi

if [ -d "${LANG_DIR}_backup" ]; then
    mv "${LANG_DIR}_backup" "$LANG_DIR"
    echo "   ✓ 기존 ko-KR 폴더 복원 완료"
fi

# Assets 심볼릭 링크 제거 (이전 버전 호환)
ASSETS_LINK="$HYTALE_APP/Contents/Assets"
if [ -L "$ASSETS_LINK" ]; then
    rm -f "$ASSETS_LINK"
    echo "   ✓ Assets 심볼릭 링크 제거됨"
fi

echo ""
echo "=== 제거 완료! ==="
echo "Hytale이 초기 상태로 복구되었습니다."
echo ""
echo "엔터 키를 누르면 종료됩니다..."
read -r
