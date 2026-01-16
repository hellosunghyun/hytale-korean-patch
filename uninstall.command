#!/bin/bash
# Hytale 한글 패치 제거 스크립트

GAME_BASE="$HOME/Library/Application Support/Hytale/install/release/package/game/latest"
GAME_DIR="$GAME_BASE/Client/Hytale.app/Contents/Resources/Data/Shared"

# 게임 폴더 확인
if [ ! -d "$GAME_DIR" ]; then
    echo "❌ Hytale 게임 폴더를 찾을 수 없습니다."
    echo "   예상 경로: $GAME_DIR"
    echo ""
    echo "설치 시 사용했던 경로를 입력해주세요 (Client/.../Data/Shared 폴더 경로):"
    read -r CUSTOM_PATH
    if [ -d "$CUSTOM_PATH" ]; then
        GAME_DIR="$CUSTOM_PATH"
        echo "   ✓ 사용자 지정 경로 확인됨: $GAME_DIR"
    else
        echo "❌ 유효하지 않은 경로입니다."
        exit 1
    fi
fi

LANG_DIR="$GAME_DIR/Language/ko-KR"
FONTS_DIR="$GAME_DIR/Fonts"

# Assets.zip 경로 탐색
ASSETS_ZIP=""
CURRENT_PATH="$GAME_DIR"
for i in {1..6}; do
    if [ -f "$CURRENT_PATH/Assets.zip" ]; then
        ASSETS_ZIP="$CURRENT_PATH/Assets.zip"
        break
    fi
    CURRENT_PATH="$(dirname "$CURRENT_PATH")"
done

echo "=== Hytale 한글 패치 제거 ==="
echo ""

# 1. 폰트 복원
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

# 2. 언어 파일 제거 및 복원
echo ""
echo "📁 언어 파일 제거 중..."

# 설치된 ko-KR 폴더 제거
if [ -d "$LANG_DIR" ]; then
    rm -rf "$LANG_DIR"
    echo "   ✓ 설치된 ko-KR 폴더 제거 완료"
else
    echo "   ⚠️ 설치된 ko-KR 폴더가 없습니다."
fi

# 기존 백업이 있다면 복원 (Language 폴더 덮어쓰기 복구)
if [ -d "${LANG_DIR}_backup" ]; then
    # 혹시 ko-KR 폴더가 남아있을 경우(위의 제거 실패 등)를 대비해 안전하게 처리
    if [ -d "$LANG_DIR" ]; then
        rm -rf "$LANG_DIR"
    fi
    mv "${LANG_DIR}_backup" "$LANG_DIR"
    echo "   ✓ 기존 ko-KR 폴더 복원 완료"
else
    echo "   ⚠️ 복원할 기존 언어 폴더 백업(${LANG_DIR}_backup)이 없습니다."
fi

echo ""
echo "=== 제거 완료! ==="
echo "Hytale이 초기 상태로 복구되었습니다."
echo ""
echo "엔터 키를 누르면 종료됩니다..."
read -r
