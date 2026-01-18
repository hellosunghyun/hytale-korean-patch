# macOS Font Patcher (libfontpatch.dylib)

Hytale 게임의 텍스처 크기 제한(512x512)을 4096x4096으로 확장하는 dylib입니다.

## 빌드 방법

```bash
cd patcher/macos
make
```

Universal binary (x86_64 + arm64)로 빌드됩니다.

## 설치 방법

### 1. 코드 서명 제거 (필수)

macOS의 Hardened Runtime으로 인해 dylib 주입이 차단됩니다.
게임 실행 파일의 코드 서명을 제거해야 합니다.

```bash
HYTALE_APP="$HOME/Library/Application Support/Hytale/install/release/package/game/latest/Client/Hytale.app"
codesign --remove-signature "$HYTALE_APP/Contents/MacOS/HytaleClient"
```

### 2. dylib 설치

```bash
cp libfontpatch.dylib "$HYTALE_APP/Contents/MacOS/"
```

### 3. 환경변수 설정하여 실행

```bash
DYLD_INSERT_LIBRARIES="$HYTALE_APP/Contents/MacOS/libfontpatch.dylib" \
    "$HYTALE_APP/Contents/MacOS/HytaleClient"
```

또는 런처 스크립트를 생성하여 사용합니다. (install.command에서 자동 생성)

## 주의사항

- 게임 업데이트 시 코드 서명이 복원되므로 다시 제거해야 합니다.
- 코드 서명 제거 후에도 게임 자체는 정상 작동합니다.
- Gatekeeper 경고가 표시될 수 있습니다.

## 동작 원리

dylib가 로드될 때 `__attribute__((constructor))`로 지정된 함수가 자동 실행됩니다.
게임 메모리에서 텍스처 크기 패턴을 찾아 수정합니다.
