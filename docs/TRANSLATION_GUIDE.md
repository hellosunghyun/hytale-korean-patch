# Hytale 한글 번역 가이드

> 이 문서는 번역을 직접 수정하거나 새로 만들려는 개발자를 위한 기술 문서입니다.
> 단순히 패치를 설치하려면 [README.md](../README.md)를 참조하세요.

## 개요
Hytale의 언어 파일은 `.lang` 형식으로, `키 = 값` 구조입니다. 한국어 번역은 `ko-KR` 폴더에 저장됩니다.

---

## 1. 이 패치의 번역 파일 구조

### 패치 폴더 구조
```
hytale-korean-patch/
├── Language/ko-KR/           # 클라이언트 언어 파일
│   ├── client.lang           # 메인 UI (~2260줄)
│   └── meta.lang             # 언어 이름 (한국어)
└── Assets/                   # Assets.zip 원본 구조
    ├── Server/Languages/ko-KR/
    │   ├── server.lang       # 서버 메시지 (~7800줄)
    │   └── wordlists.lang    # 룬 이름 등
    └── Common/Languages/ko-KR/
        └── avatarCustomization/  # 아바타 관련 (22개 파일)
```

### 게임 설치 경로 (macOS)
```
~/Library/Application Support/Hytale/install/release/package/game/latest/
├── Client/Hytale.app/.../Shared/
│   ├── Language/ko-KR/       # 여기에 모든 .lang 파일 설치
│   └── Fonts/                # 폰트 파일
└── Assets.zip                # ⚠️ 수정하면 크래시!
```

⚠️ **주의**: Assets.zip에 ko-KR 폴더를 추가하면 게임이 크래시됩니다. 
install.sh는 모든 파일을 Language/ko-KR/에 설치합니다.

---

## 2. .lang 파일 형식

```
# 주석 (# 또는 빈 줄)
키.이름.구조 = 번역 텍스트

# 플레이스홀더 예시
message.welcome = {playerName}님 환영합니다!
error.count = 오류 {0}개 발생
format.percent = 진행률: %s%%
```

### 규칙
1. **키는 변경 금지**: `=` 앞부분은 그대로 유지
2. **플레이스홀더 유지**: `{변수}`, `{0}`, `%s` 등
3. **줄바꿈 유지**: 원본과 같은 줄 수 유지
4. **인코딩**: UTF-8

---

## 3. 언어 파일 추출

### Assets.zip에서 추출
```bash
GAME_DIR="$HOME/Library/Application Support/Hytale/install/release/package/game/latest"
WORK_DIR="$HOME/Documents/Github/hytale/work/assets_lang"

# Server 언어 파일
unzip -o "$GAME_DIR/Assets.zip" "Server/Languages/en-US/*" -d "$WORK_DIR/"

# Common 언어 파일 (아바타 커스터마이징)
unzip -o "$GAME_DIR/Assets.zip" "Common/Languages/en-US/*" -d "$WORK_DIR/"
```

### 추출 결과 구조
```
work/assets_lang/
├── Server/Languages/en-US/
│   ├── server.lang
│   └── wordlists.lang
└── Common/Languages/en-US/
    └── avatarCustomization/*.lang
```

---

## 4. 번역 방법

### 4.1 수동 번역
`.lang` 파일을 텍스트 에디터로 열어 번역합니다.

### 4.2 AI 자동 번역 (Gemini API)

#### 환경 설정
```bash
# .env 파일 생성
echo "GEMINI_API_KEY=your-api-key-here" > .env

# Python 패키지
pip install google-genai
```

#### translate_server.py
```python
#!/usr/bin/env python3
"""server.lang 한국어 번역 스크립트 (병렬 처리)"""

import os
import asyncio
from pathlib import Path
from google import genai

# .env 로드
env_path = Path(__file__).parent / '.env'
if env_path.exists():
    for line in env_path.read_text().split('\n'):
        if '=' in line and not line.startswith('#'):
            key, val = line.split('=', 1)
            os.environ[key.strip()] = val.strip()

client = genai.Client(api_key=os.environ.get('GEMINI_API_KEY'))
MODEL_ID = 'gemini-2.0-flash'  # 또는 gemini-1.5-flash

MAX_CONCURRENT = 10  # 동시 요청 수
CHUNK_SIZE = 500     # 한 번에 번역할 줄 수


async def translate_chunk(chunk_idx, chunk, total, semaphore):
    async with semaphore:
        chunk_content = '\n'.join(chunk)
        print(f"[{chunk_idx+1}/{total}] 번역 중... ({len(chunk)}줄)")
        
        prompt = f'''너는 "상업 게임 로컬라이제이션 전문 번역가"다.

[중요 규칙]
1. 키(= 앞부분)는 절대 변경하지 말 것
2. 플레이스홀더 유지: {{0}}, {{playerName}}, %s 등
3. 파일 포맷 그대로 유지
4. 고유명사는 음차 또는 원문 유지
5. 오직 "번역된 파일 내용"만 출력 (설명 금지)

[입력]
{chunk_content}'''

        try:
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                None,
                lambda: client.models.generate_content(model=MODEL_ID, contents=prompt)
            )
            result = response.text.strip()
            
            # 코드블록 제거
            if result.startswith('```'):
                lines = result.split('\n')
                result = '\n'.join(lines[1:-1] if lines[-1].strip() == '```' else lines[1:])
            
            return (chunk_idx, result.split('\n'))
        except Exception as e:
            print(f"  ✗ [{chunk_idx+1}/{total}] 실패: {e}")
            return (chunk_idx, chunk)


async def main():
    input_file = Path('assets_lang/Server/Languages/en-US/server.lang')
    output_file = Path('assets_lang/Server/Languages/ko-KR/server.lang')
    output_file.parent.mkdir(parents=True, exist_ok=True)

    lines = input_file.read_text(encoding='utf-8').split('\n')
    print(f"총 {len(lines)}줄")
    
    chunks = [lines[i:i+CHUNK_SIZE] for i in range(0, len(lines), CHUNK_SIZE)]
    print(f"총 {len(chunks)}개 청크\n")

    semaphore = asyncio.Semaphore(MAX_CONCURRENT)
    tasks = [translate_chunk(i, chunk, len(chunks), semaphore) for i, chunk in enumerate(chunks)]
    results = await asyncio.gather(*tasks)
    
    results.sort(key=lambda x: x[0])
    all_lines = [line for _, chunk_lines in results for line in chunk_lines]
    
    output_file.write_text('\n'.join(all_lines), encoding='utf-8')
    print(f"\n완료! 저장됨: {output_file}")


if __name__ == "__main__":
    asyncio.run(main())
```

#### 실행
```bash
cd ~/Documents/Github/hytale
source .venv/bin/activate
python3 work/translate_server.py
```

---

## 5. 번역 파일 적용

### ko-KR 폴더 생성 및 복사
```bash
LANG_DIR="$HOME/Library/Application Support/Hytale/install/release/package/game/latest/Client/Hytale.app/Contents/Resources/Data/Shared/Language/ko-KR"
WORK_DIR="$HOME/Documents/Github/hytale/work/assets_lang"

# 폴더 생성
mkdir -p "$LANG_DIR/avatarCustomization"

# server.lang, wordlists.lang 복사
cp "$WORK_DIR/Server/Languages/ko-KR/server.lang" "$LANG_DIR/"
cp "$WORK_DIR/Server/Languages/ko-KR/wordlists.lang" "$LANG_DIR/"

# 아바타 커스터마이징 파일 복사
cp "$WORK_DIR/Common/Languages/ko-KR/avatarCustomization/"*.lang "$LANG_DIR/avatarCustomization/"
```

### meta.lang 생성
```bash
cat > "$LANG_DIR/meta.lang" << 'EOF'
language.name = 한국어
language.region = 대한민국
EOF
```

---

## 6. 번역해야 할 파일 목록

| 파일 | 줄 수 | 설명 |
|------|-------|------|
| client.lang | ~2260 | 메인 UI (보통 이미 번역됨) |
| server.lang | ~7800 | 서버 메시지, 아이템, 블록 등 |
| wordlists.lang | ~24 | 룬 이름 등 단어 목록 |
| avatarCustomization/*.lang | ~20파일 | 아바타 관련 |

### 아바타 커스터마이징 파일
```
faces.lang          - 얼굴
eyes.lang           - 눈
eyebrows.lang       - 눈썹
mouths.lang         - 입
haircuts.lang       - 헤어스타일
facialhair.lang     - 수염
bodyCharacteristics.lang - 체형
capes.lang          - 망토
shoes.lang          - 신발
tops.lang           - 상의
pants.lang          - 하의
undertops.lang      - 속옷 상의
underwear.lang      - 속옷 하의
overpants.lang      - 겉옷 하의
headaccessory.lang  - 머리 악세서리
faceaccessory.lang  - 얼굴 악세서리
earaccessory.lang   - 귀 악세서리
emotes.lang         - 감정표현
```

---

## 7. 트러블슈팅

### 게임에서 번역이 안 보임
1. 게임 설정에서 언어를 한국어로 변경
2. 파일이 올바른 위치에 있는지 확인
3. 파일 인코딩이 UTF-8인지 확인

### 일부 텍스트만 영어로 표시
- 해당 키가 번역 파일에 없음
- 원본 영어 파일과 키 비교 필요

### 플레이스홀더 오류
- `{변수명}` 형태가 정확히 유지되었는지 확인
- 중괄호 `{}` 짝이 맞는지 확인

### Assets.zip 수정 시 크래시
- Assets.zip 수정하지 말고 게임 폴더에 직접 복사

### 줄 수 불일치 (AI 번역)
- 청크 크기 줄이기 (500 → 300)
- 번역 후 줄 수 검증 추가

---

## 8. 작업 폴더 구조

```
work/
├── assets_lang/
│   ├── Server/Languages/
│   │   ├── en-US/          # 원본 영어
│   │   │   ├── server.lang
│   │   │   └── wordlists.lang
│   │   └── ko-KR/          # 번역된 한국어
│   │       ├── server.lang
│   │       └── wordlists.lang
│   └── Common/Languages/
│       ├── en-US/avatarCustomization/
│       └── ko-KR/avatarCustomization/
├── translate_server.py     # 번역 스크립트
└── .env                    # API 키 (GEMINI_API_KEY=...)
```

---

## 9. 유용한 명령어

### 번역 진행률 확인
```bash
# 원본 키 개수
grep -c "=" assets_lang/Server/Languages/en-US/server.lang

# 번역된 키 개수  
grep -c "=" assets_lang/Server/Languages/ko-KR/server.lang
```

### 누락된 키 찾기
```bash
# 원본에만 있는 키
diff <(grep "^[^#].*=" en-US/server.lang | cut -d= -f1 | sort) \
     <(grep "^[^#].*=" ko-KR/server.lang | cut -d= -f1 | sort)
```

### 번역에 사용된 한글 추출 (폰트용)
```bash
cat ko-KR/*.lang ko-KR/avatarCustomization/*.lang | grep -o '[가-힣]' | sort -u | tr -d '\n' > used_hangul.txt
```

---

## 10. 배포용 패치 만들기

### 폴더 구조
```
HytaleKoreanPatch/
├── Language/ko-KR/
│   ├── client.lang
│   ├── server.lang
│   ├── wordlists.lang
│   ├── meta.lang
│   └── avatarCustomization/*.lang
├── Fonts/
│   ├── NunitoSans-Medium.json
│   ├── NunitoSans-Medium.png
│   ├── NunitoSans-ExtraBold.json
│   ├── NunitoSans-ExtraBold.png
│   ├── Lexend-Bold.json
│   ├── Lexend-Bold.png
│   ├── NotoMono-Regular.json
│   └── NotoMono-Regular.png
├── install.sh
└── README.md
```

### install.sh
```bash
#!/bin/bash
GAME_DIR="$HOME/Library/Application Support/Hytale/install/release/package/game/latest/Client/Hytale.app/Contents/Resources/Data/Shared"

# 언어 파일 복사
cp -r Language/ko-KR "$GAME_DIR/Language/"

# 폰트 백업 및 교체
for font in NunitoSans-Medium NunitoSans-ExtraBold Lexend-Bold NotoMono-Regular; do
  if [ ! -f "$GAME_DIR/Fonts/${font}.json.backup" ]; then
    cp "$GAME_DIR/Fonts/${font}.json" "$GAME_DIR/Fonts/${font}.json.backup"
    cp "$GAME_DIR/Fonts/${font}.png" "$GAME_DIR/Fonts/${font}.png.backup"
  fi
  cp "Fonts/${font}.json" "$GAME_DIR/Fonts/"
  cp "Fonts/${font}.png" "$GAME_DIR/Fonts/"
done

echo "한글 패치 설치 완료!"
echo "게임에서 설정 > 언어 > 한국어를 선택하세요."
```
