#!/bin/bash
# Hytale 한글 패치 제거 스크립트 (Linux)

# Linux Path Detection Logic
POSSIBLE_PATHS=(
    "$HOME/.local/share/Hytale/install/release/package/game/latest/Client/Data/Shared"
    "$HOME/.local/share/Hytale/install/release/package/game/latest/Client/Shared"
    # Flatpak support
    "$HOME/.var/app/com.hypixel.HytaleLauncher/data/Hytale/install/release/package/game/latest/Client/Data/Shared"
    "$HOME/.var/app/com.hypixel.HytaleLauncher/data/Hytale/install/release/package/game/latest/Client/Shared"
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
    echo "   설치 시 사용했던 경로를 입력해주세요:"
    read -r CUSTOM_PATH
    if [ -d "$CUSTOM_PATH" ]; then
        GAME_DIR="$CUSTOM_PATH"
    else
        echo "❌ 유효하지 않은 경로입니다."
        exit 1
    fi
fi

LANG_DIR="$GAME_DIR/Language/ko-KR"
FONTS_DIR="$GAME_DIR/Fonts"

echo "=== Hytale 한글 패치 제거 (Linux) ==="
echo "제거 대상: $GAME_DIR"
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

if [ -d "$LANG_DIR" ]; then
    rm -rf "$LANG_DIR"
    echo "   ✓ 설치된 ko-KR 폴더 제거 완료"
else
    echo "   ⚠️ 설치된 ko-KR 폴더가 없습니다."
fi

# 기존 백업이 있다면 복원
if [ -d "${LANG_DIR}_backup" ]; then
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
