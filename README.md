# Hytale 한글 패치

Hytale 게임을 한국어로 플레이할 수 있게 해주는 패치입니다.

## 포함 내용

- **한글 폰트**: 갈무리9 (Galmuri9) 픽셀 폰트
- **번역 파일**: UI, 서버 메시지, 아바타 커스터마이징 등

## 다운로드 및 준비

먼저 패치 파일을 컴퓨터에 다운로드해야 합니다.

### 방법 1: ZIP 파일 다운로드 (초보자 권장)
1. 이 페이지 우측 상단의 초록색 **Code** 버튼을 클릭합니다.
2. **Download ZIP**을 선택하여 파일을 다운로드합니다.
3. 다운로드된 `hytale-korean-patch-master.zip` 파일을 더블 클릭하여 압축을 풉니다.
4. 압축이 풀린 폴더를 찾기 쉬운 곳(예: `문서` 또는 `바탕화면`)으로 이동합니다.

### 방법 2: Git Clone (개발자용)
터미널을 열고 아래 명령어로 리포지토리를 복제합니다:
```bash
git clone https://github.com/hellosunghyun/hytale-korean-patch.git
cd hytale-korean-patch
```

## 설치 방법

### macOS

1. 다운로드한 폴더를 엽니다.
2. `install.command` 파일을 **더블 클릭**하여 실행합니다.
   - ⚠️ 만약 "개발자를 확인할 수 없어 열 수 없습니다" 경고가 뜬다면:
     - 파일을 **우클릭(Control+클릭)** 하고 **열기**를 선택한 뒤, 팝업에서 **열기**를 누르세요.
     - 또는 터미널에서 `chmod +x install.command` 명령어로 권한을 부여해야 할 수도 있습니다.

3. 설치가 완료되면 엔터 키를 눌러 창을 닫습니다.
4. 게임을 실행하고 **설정 > 언어 > 한국어**를 선택합니다.

### Windows

1. 다운로드한 폴더를 엽니다.
2. `install.bat` 파일을 더블 클릭하여 실행합니다.
   - 이 파일은 권한 문제를 자동으로 해결하고 `install.ps1`을 실행해 줍니다.
   - 만약 실행이 안 된다면 `install.ps1`을 우클릭하여 **'PowerShell에서 실행'**을 선택하세요.
3. 설치가 완료되면 엔터 키를 눌러 창을 닫습니다.

### Linux

1. 터미널을 열고 폴더로 이동합니다.
2. 실행 권한을 부여하고 스크립트를 실행합니다:
```bash
chmod +x install_linux.sh
./install_linux.sh
```
   - Python3, npm(npx), unzip이 필요합니다. (없는 경우 자동 설치를 시도합니다)
   - Flatpak 버전도 지원하지만, 리눅스 환경 특성상 변수가 많을 수 있습니다.
   - **문제가 발생하면 직접 해결해보시고 PR 보내주시면 정말 감사하겠습니다!** 🐧❤️

### 특징

- **자동 병합 (Merge)**: 기존 게임 파일(영어)을 베이스로, 번역된 부분만 안전하게 교체합니다. 게임이 업데이트되어도 깨지지 않습니다.
- **폰트 자동 빌드**: 최신 갈무리9 폰트를 다운로드하여 게임에 맞는 포맷으로 자동 변환합니다.
- **백업 및 복구**: 설치 전 자동으로 백업하며, 제거 시 완벽하게 복구됩니다.

### 수동 설치

1. `Fonts/` 폴더의 파일들을 아래 경로에 복사합니다:
   - **macOS**: `~/Library/Application Support/Hytale/.../Shared/Fonts/`
   - **Windows**: `%APPDATA%\Hytale\install\release\package\game\latest\Client\Data\Shared\Fonts\`
   - **Linux**: `~/.local/share/Hytale/install/release/package/game/latest/Client/Data/Shared/Fonts/`
   
   - `Galmuri9-Final.json` → `NunitoSans-Medium.json` (이름 변경)
   - `Galmuri9-sharp.png` → `NunitoSans-Medium.png` (이름 변경)
   - 동일하게 `NunitoSans-ExtraBold`, `Lexend-Bold`, `NotoMono-Regular`도 교체

2. `Language/ko-KR/` 폴더를 아래 경로에 복사합니다:
   - **macOS**: `~/Library/Application Support/Hytale/.../Shared/Language/`
   - **Windows**: `%APPDATA%\Hytale\install\release\package\game\latest\Client\Data\Shared\Language\`
   - **Linux**: `~/.local/share/Hytale/install/release/package/game/latest/Client/Data/Shared/Language/`

3. **중요: 추가 번역 파일 복사 (서버/아바타)**
   - 리포지토리의 `Assets/Server/Languages/ko-KR/` 안의 파일들(`server.lang`, `wordlists.lang`)을 게임 설치 경로의 `Language/ko-KR/` 안에 복사합니다.
   - 리포지토리의 `Assets/Common/Languages/ko-KR/avatarCustomization/` 폴더를 통째로 게임 설치 경로의 `Language/ko-KR/` 안에 복사합니다.

> **참고**: 수동 설치 시에는 자동 병합(Merge) 기능이 적용되지 않으므로, 게임 업데이트 시 새로운 문장이 번역되지 않은 채로 나오거나 키(Key) 형태로 보일 수 있습니다. 가급적 **자동 설치 스크립트** 사용을 권장합니다.

## 제거 방법

### macOS
1. `uninstall.command` 파일을 **더블 클릭**하여 실행합니다.
2. 완료되면 엔터 키를 눌러 창을 닫습니다.

### Windows
1. `uninstall.bat` 파일을 더블 클릭하여 실행합니다.

### Linux
1. 터미널에서 실행합니다:
```bash
./uninstall_linux.sh
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

### 최신 버전이 나와도 바로 써도 되나요?
- **네, 가능합니다!** 이 패치는 게임 원본 파일을 덮어쓰지 않고, **실시간으로 병합(Merge)** 하는 방식을 사용합니다.
- 게임 업데이트로 새로운 문장이 추가되면 그 부분만 영어로 나오고, 기존 번역은 그대로 유지됩니다.
- 패치 파일만 업데이트하면 새로운 번역도 자동으로 적용됩니다.

### 글자가 깨져 보여요
- 게임을 완전히 종료 후 다시 실행해보세요.

### 일부 글자가 표시되지 않아요
- 희귀한 한글 조합은 제외되어 있습니다.
- 해당 글자가 자주 사용된다면 이슈로 알려주세요.

### 게임을 완전히 재설치하고 싶어요
패치 적용 중 문제가 생겨 게임을 초기화하고 싶다면 **Hytale 런처**에서 간편하게 재설치할 수 있습니다.

1. Hytale 런처를 실행합니다.
2. **설정(Settings)** 메뉴로 이동합니다.
3. 게임 제거(Uninstall) 또는 재설치 관련 옵션을 사용하세요.

### 폰트가 너무 작아요 / 커요
- 현재 버전은 고정 크기입니다.
- 게임 내 UI 스케일 설정을 조정해보세요.

## 크레딧

- **폰트**: [Galmuri](https://galmuri.quiple.dev/) by Quiple
- **번역**: Gemini API 기반 자동 번역 + 수동 검수

## 기여하기

Hytale 한글 패치는 오픈 소스 프로젝트입니다. 번역 개선이나 오타 수정은 언제나 환영합니다!

1. 이 저장소를 **Fork** 합니다.
2. `Assets` 또는 `Language` 폴더 내의 `.lang` 파일을 수정합니다.
3. **Pull Request (PR)** 를 보내주세요.
   - 여러분이 기여해주신 번역은 **1:1 대응 병합 방식** 덕분에 다음 설치 시 자동으로 반영됩니다.
   - 새로운 게임 업데이트가 나와도 번역 키(Key)만 맞다면 즉시 적용됩니다.

## 라이선스

- 폰트: OFL (Open Font License)
- 패치 스크립트: MIT License
