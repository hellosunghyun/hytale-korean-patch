# Hytale 한글 패치

Hytale 게임을 한국어로 플레이할 수 있게 해주는 패치입니다.

## 포함 내용

- **한글 폰트**: 갈무리9 (Galmuri9) 픽셀 폰트
- **번역 파일**: UI, 서버 메시지, 아바타 커스터마이징 등

## 설치 방법

### macOS

1. 터미널을 열고 패치 폴더로 이동합니다.
2. 설치 스크립트를 실행합니다:
   > **참고**: 인터넷 연결이 필요합니다. (폰트 다운로드 및 빌드)

```bash
chmod +x install.sh
./install.sh
```

3. 게임을 실행하고 **설정 > 언어 > 한국어**를 선택합니다.

### 특징

- **자동 병합 (Merge)**: 기존 게임 파일(영어)을 베이스로, 번역된 부분만 안전하게 교체합니다. 게임이 업데이트되어도 깨지지 않습니다.
- **폰트 자동 빌드**: 최신 갈무리9 폰트를 다운로드하여 게임에 맞는 포맷으로 자동 변환합니다.
- **백업 및 복구**: 설치 전 자동으로 백업하며, 제거 시 완벽하게 복구됩니다.

### 수동 설치

1. `Fonts/` 폴더의 파일들을 아래 경로에 복사합니다:
   ```
   ~/Library/Application Support/Hytale/.../Shared/Fonts/
   ```
   - `Galmuri9-Final.json` → `NunitoSans-Medium.json` (이름 변경)
   - `Galmuri9-sharp.png` → `NunitoSans-Medium.png` (이름 변경)
   - 동일하게 `NunitoSans-ExtraBold`, `Lexend-Bold`, `NotoMono-Regular`도 교체

2. `Language/ko-KR/` 폴더를 아래 경로에 복사합니다:
   ```
   ~/Library/Application Support/Hytale/.../Shared/Language/
   ```

## 제거 방법

```bash
chmod +x uninstall.sh
./uninstall.sh
```

## 폰트 정보

- **폰트**: Galmuri9 (갈무리9)
- **사이즈**: 10px
- **글자 수**: 1960자
  - ASCII: 95자
  - 한글 자모: 51자 (ㄱ~ㅎ, ㅏ~ㅣ)
  - 한글 음절: ~1814자 (KSX1001 기반)
- **라이선스**: OFL (Open Font License)
- **다운로드**: https://galmuri.quiple.dev/

## 지원되지 않는 글자

512x512 텍스처 제한으로 일부 희귀 글자가 제외되었습니다:
- 겹받침: ㄳ ㄵ ㄶ ㄺ ㄻ ㄼ ㄽ ㄾ ㄿ ㅀ ㅄ
- 희귀 이중모음+받침 조합

## 파일 구조

```
hytale-korean-patch/
├── Fonts/
│   ├── Galmuri9-Final.json    # 폰트 메타데이터
│   └── Galmuri9-sharp.png     # 폰트 아틀라스
├── Language/ko-KR/
│   ├── client.lang            # UI 번역
│   ├── server.lang            # 서버 메시지 번역
│   ├── wordlists.lang         # 단어 목록
│   ├── meta.lang              # 언어 메타정보
│   └── avatarCustomization/   # 아바타 관련 번역
├── src/
│   └── charset/
│       └── charset_final.txt  # 글자셋 원본
├── scripts/
│   └── convert_font.py        # 폰트 변환 스크립트
├── install.sh                 # 설치 스크립트
├── uninstall.sh              # 제거 스크립트
└── README.md
```

## 문제 해결

### 폰트가 약간 뭉개져 보여요 (Anti-aliasing)
- Hytale은 **MSDF(Multi-channel Signed Distance Field)** 방식의 폰트 렌더링을 사용합니다.
- 이 기술은 벡터(곡선) 폰트에는 최적화되어 있지만, **비트맵(픽셀) 폰트와는 구조적으로 잘 맞지 않습니다.**
- 최대한 선명하게 보이도록 후처리(Sharpening)를 적용했으나, **시스템 한계상 픽셀이 칼같이 반듯하게 나오지 않고 약간 부드럽거나 뭉개져 보일 수 있습니다.**

### 글자가 깨져 보여요
- 게임을 완전히 종료 후 다시 실행해보세요.

### 일부 글자가 표시되지 않아요
- 희귀한 한글 조합은 제외되어 있습니다.
- 해당 글자가 자주 사용된다면 이슈로 알려주세요.

### 폰트가 너무 작아요 / 커요
- 현재 버전은 고정 크기입니다.
- 게임 내 UI 스케일 설정을 조정해보세요.

## 크레딧

- **폰트**: [Galmuri](https://galmuri.quiple.dev/) by Quiple
- **번역**: Gemini API 기반 자동 번역 + 수동 검수

## 라이선스

- 폰트: OFL (Open Font License)
- 패치 스크립트: MIT License
