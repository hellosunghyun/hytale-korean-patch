# Hytale 한글 패치

[![GitHub stars](https://img.shields.io/github/stars/hellosunghyun/hytale-korean-patch?style=social)](https://github.com/hellosunghyun/hytale-korean-patch/stargazers)
> **도움이 되셨다면 우측 상단의 Star 버튼을 눌러주세요!**
> 개발자에게 큰 힘이 됩니다.

Hytale 게임을 한국어로 플레이할 수 있게 해주는 패치입니다.

> **참고**: 이 브랜치(dev)는 고해상도 폰트 버전입니다.

## 포함 내용

- **한글 폰트**: WantedSans (고해상도 벡터 폰트, 8192x8192)
- **번역 파일**: UI, 서버 메시지, 아바타 커스터마이징 등
- **바이너리 패치**: 텍스처 크기 제한 해제 (512 → 8192)

## 필수 프로그램

설치 스크립트 실행 전 미리 설치해주세요.

- **[Node.js](https://nodejs.org/)** (LTS 버전 권장)
- **[Python](https://www.python.org/downloads/)** (3.8 이상)
  - Windows 설치 시 **"Add Python to PATH"** 체크 필수!

## 설치 방법

### macOS

1. `install.command` 파일을 **더블 클릭**하여 실행합니다.
   - "개발자를 확인할 수 없어 열 수 없습니다" 경고 시:
     - 파일을 **우클릭(Control+클릭)** → **열기** 선택
2. 설치가 완료되면 엔터 키를 눌러 창을 닫습니다.
3. 게임을 실행하고 **설정 > 언어 > 한국어**를 선택합니다.

### Windows

1. `install.ps1` 파일을 **우클릭** → **PowerShell에서 실행**을 선택합니다.
2. 설치가 완료되면 엔터 키를 눌러 창을 닫습니다.
3. 게임을 실행하고 **설정 > 언어 > 한국어**를 선택합니다.

### Linux

```bash
chmod +x install_linux.sh
./install_linux.sh
```

## 제거 방법

### macOS
`uninstall.command` 파일을 더블 클릭하여 실행합니다.

### Windows
`uninstall.ps1` 파일을 우클릭 → PowerShell에서 실행합니다.

### Linux
```bash
./uninstall_linux.sh
```

## 폰트 정보

- **폰트**: WantedSans (Wanted Sans)
- **텍스처 크기**: 8192x8192
- **글자 수**: 11,323자
  - ASCII: 95자
  - 한글 자모: 51자 (ㄱ~ㅎ, ㅏ~ㅣ)
  - 한글 음절: 11,172자 (전체 유니코드 한글)
- **라이선스**: OFL (Open Font License)
- **다운로드**: https://github.com/wanteddev/wanted-sans

## 특징

- **고해상도 폰트**: 8192x8192 텍스처로 선명한 한글 표시
- **전체 한글 지원**: 11,172자 모든 한글 음절 지원
- **자동 폰트 다운로드**: 설치 시 WantedSans 폰트 자동 다운로드
- **바이너리 패치**: 게임의 텍스처 크기 제한을 자동으로 해제
- **자동 병합**: 게임 업데이트 시에도 번역 유지

## 파일 구조

```
hytale-korean-patch/
├── Fonts/
│   ├── WantedSans.json       # 폰트 메타데이터
│   └── WantedSans.png        # 폰트 아틀라스 (8192x8192)
├── Language/ko-KR/
│   ├── client.lang           # UI 번역
│   └── meta.lang             # 언어 메타정보
├── Assets/
│   ├── Server/Languages/ko-KR/
│   │   ├── server.lang       # 서버 메시지 번역
│   │   └── wordlists.lang    # 단어 목록
│   └── Common/Languages/ko-KR/
│       └── avatarCustomization/  # 아바타 관련 번역
├── patcher/
│   ├── macos/                # macOS 바이너리 패처
│   └── windows/              # Windows 바이너리 패처
├── src/charset/
│   └── charset_full.txt      # 글자셋 (11,323자)
├── scripts/
│   ├── install_windows.py    # Windows 설치 스크립트
│   └── merge_lang.py         # 언어 파일 병합 스크립트
├── install.command           # macOS 설치
├── install.ps1               # Windows 설치
├── install_linux.sh          # Linux 설치
├── uninstall.command         # macOS 제거
├── uninstall.ps1             # Windows 제거
└── uninstall_linux.sh        # Linux 제거
```

## 문제 해결

### 게임 업데이트 후 한글이 안 나와요
- 게임 업데이트 시 바이너리가 원본으로 복원됩니다.
- **설치 스크립트를 다시 실행**하세요.

### 글자가 깨져 보여요
- 게임을 완전히 종료 후 다시 실행해보세요.

### 게임이 실행되지 않아요
- 제거 스크립트를 실행하여 원본으로 복원한 후, 다시 설치해보세요.
- 그래도 안 되면 Hytale 런처에서 게임을 재설치하세요.

## 크레딧

- **폰트**: [Wanted Sans](https://github.com/wanteddev/wanted-sans) by Wanted
- **번역**: Gemini API 기반 자동 번역 + 수동 검수

## 기여하기

번역 개선이나 오타 수정은 언제나 환영합니다!

1. 이 저장소를 **Fork** 합니다.
2. `Assets` 또는 `Language` 폴더 내의 `.lang` 파일을 수정합니다.
3. **Pull Request (PR)** 를 보내주세요.

## 라이선스

- 폰트: OFL (Open Font License)
- 패치 스크립트: MIT License
