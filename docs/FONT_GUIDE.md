# Hytale 한글 폰트 가이드

> 이 문서는 한글 폰트 패치를 직접 만들거나 수정하려는 개발자를 위한 기술 문서입니다.
> 단순히 패치를 설치하려면 [README.md](../README.md)를 참조하세요.

## 개요
Hytale는 MSDF(Multi-channel Signed Distance Field) 폰트 아틀라스를 사용합니다. 한글 폰트를 적용하려면 MSDF 형식으로 변환해야 합니다.

---

## 1. 게임 폴더 구조

### macOS 경로
```
~/Library/Application Support/Hytale/install/release/package/game/latest/
├── Client/Hytale.app/Contents/Resources/Data/Shared/
│   ├── Fonts/           # 폰트 파일 (.json, .png)
│   └── Language/ko-KR/  # 언어 파일 (.lang)
└── Assets.zip           # 서버/아바타 언어 파일 (수정 시 크래시 주의!)
```

### 주요 폰트 파일
| 파일명 | 용도 |
|--------|------|
| NunitoSans-Medium.json/.png | 기본 UI 폰트 |
| NunitoSans-ExtraBold.json/.png | 굵은 UI 폰트 |
| Lexend-Bold.json/.png | 제목/강조 폰트 |
| NotoMono-Regular.json/.png | 고정폭 폰트 (코드 등) |

### 이 패치에 포함된 파일
```
Fonts/
├── Galmuri9-Final.json   # 변환된 폰트 메타데이터
└── Galmuri9-sharp.png    # 선명화된 폰트 아틀라스
```

---

## 2. 필요 도구

### Node.js 패키지
```bash
npm install -g msdf-bmfont-xml
```

### Python 패키지
```bash
pip install pillow numpy
```

---

## 3. 폰트 아틀라스 생성

### 3.1 글자 목록 준비 (charset.txt)
이 패치에서 사용하는 글자셋은 `src/charset/charset_final.txt`에 있습니다.

**구성 (1960자)**:
- ASCII: 95자
- 한글 자모: 51자 (ㄱ~ㅎ, ㅏ~ㅣ)
- 한글 음절: ~1814자 (KSX1001 기반, 희귀 조합 제외)

**제외된 희귀 조합**:
- 겹받침: ㄳ ㄵ ㄶ ㄺ ㄻ ㄼ ㄽ ㄾ ㄿ ㅀ ㅄ
- 희귀 이중모음+받침: ㅒ ㅖ ㅙ ㅞ ㅢ ㅛ ㅠ ㅑ ㅕ + 받침

**팁**: 번역 파일(.lang)에서 사용된 한글만 추출:
```bash
cat *.lang | grep -o '[가-힣]' | sort -u | tr -d '\n' > used_hangul.txt
```

### 3.2 MSDF 아틀라스 생성

**제약사항**: 
- 텍스처 크기: 512x512 (필수)
- 약 1000자 포함 시 14~16px 사이즈 사용

```bash
npx msdf-bmfont \
  -f json \
  -m 512,512 \
  -s 16 \
  -r 2 \
  -t msdf \
  -p 0 \
  --pot --square \
  -i charset.txt \
  -o output-16px \
  YourFont.ttf
```

**옵션 설명**:
| 옵션 | 설명 |
|------|------|
| `-f json` | JSON 형식 출력 |
| `-m 512,512` | 텍스처 크기 (512x512 필수) |
| `-s 16` | 폰트 사이즈 (픽셀폰트는 원본 크기 권장) |
| `-r 2` | distanceRange (1은 에러, 2~4 권장) |
| `-t msdf` | MSDF 타입 |
| `-p 0` | 패딩 없음 |
| `--pot --square` | 2의 제곱, 정사각형 |

---

## 4. 폰트 형식 변환

msdf-bmfont 출력(BMFont 형식)을 Hytale 형식으로 변환해야 합니다.

### convert_font.py

```python
#!/usr/bin/env python3
"""Convert msdf-bmfont JSON to Hytale game format."""
import json
import sys

def convert_bmfont_to_hytale(input_path: str, output_path: str):
    with open(input_path, 'r') as f:
        bmfont = json.load(f)
    
    info = bmfont.get('info', {})
    common = bmfont.get('common', {})
    df = bmfont.get('distanceField', {})
    chars = bmfont.get('chars', [])
    
    size = info.get('size', 16)
    tex_w = common.get('scaleW', 512)
    tex_h = common.get('scaleH', 512)
    base = common.get('base', size)
    
    # 원본 게임 metrics 사용 (위치 정렬용)
    hytale = {
        "atlas": {
            "type": df.get('fieldType', 'msdf'),
            "distanceRange": df.get('distanceRange', 2),
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
        
        # planeBounds: baseline 기준 상대 위치
        left = xoff / size
        top = -(base - yoff) / size
        right = (xoff + w) / size
        bottom = -(base - yoff - h) / size
        
        glyph = {
            "unicode": char_id,
            "advance": advance,
            "planeBounds": {
                "left": left,
                "top": top,
                "right": right,
                "bottom": bottom
            },
            "atlasBounds": {
                "left": x + 0.5,
                "top": y + 0.5,
                "right": x + w - 0.5,
                "bottom": y + h - 0.5
            }
        }
        hytale["glyphs"].append(glyph)
    
    with open(output_path, 'w') as f:
        json.dump(hytale, f, separators=(',', ': '))
    
    print(f"Converted {len(hytale['glyphs'])} glyphs to {output_path}")

if __name__ == '__main__':
    convert_bmfont_to_hytale(sys.argv[1], sys.argv[2])
```

**사용법**:
```bash
python3 convert_font.py input.json output.json
```

---

## 5. 픽셀 폰트 선명화 (선택사항)

MSDF는 벡터 폰트에 최적화되어 픽셀 폰트가 흐릿해집니다. PNG를 후처리하여 선명하게 만들 수 있습니다:

```python
from PIL import Image
import numpy as np

img = Image.open('font-atlas.png').convert('RGBA')
arr = np.array(img)

# threshold 128: 중간값 (140=얇게, 120=두껍게)
for c in range(3):  # R, G, B
    channel = arr[:,:,c]
    arr[:,:,c] = np.where(channel >= 128, 255, 0)

result = Image.fromarray(arr, 'RGBA')
result.save('font-atlas-sharp.png')
```

---

## 6. 폰트 적용

### 백업 먼저!
```bash
FONTS_DIR="$HOME/Library/Application Support/Hytale/install/release/package/game/latest/Client/Hytale.app/Contents/Resources/Data/Shared/Fonts"

cp "$FONTS_DIR/NunitoSans-Medium.json" "$FONTS_DIR/NunitoSans-Medium.json.original"
cp "$FONTS_DIR/NunitoSans-Medium.png" "$FONTS_DIR/NunitoSans-Medium.png.original"
```

### 모든 폰트 교체
```bash
for font in "NunitoSans-Medium" "NunitoSans-ExtraBold" "Lexend-Bold" "NotoMono-Regular"; do
  cp your-font.json "$FONTS_DIR/${font}.json"
  cp your-font.png "$FONTS_DIR/${font}.png"
done
```

---

## 7. 트러블슈팅

### 글자가 안 보임
- charset에 해당 글자가 없음
- JSON 변환 시 unicode 값 확인

### 글자가 위/아래로 치우침
- `metrics`의 `ascender`, `descender` 값을 원본과 동일하게 설정
- `planeBounds` 계산 시 `base` 값 올바르게 사용

### 글자가 두껍거나 얇음
- 후처리 threshold 값 조정 (120~150)

### 글자가 흐릿함 (픽셀 폰트)
- 폰트 사이즈를 원본 픽셀 크기에 맞춤 (예: 네오둥근모 16px)
- 후처리로 선명화

### distanceRange 1 에러
- 최소값은 2

### 512x512 초과 에러
- 글자 수 줄이기 또는 폰트 사이즈 줄이기

---

## 8. 현재 사용 중인 폰트 및 설정

### 사용 폰트
**Galmuri9.ttf** (갈무리9)
- 타입: 픽셀 폰트 (9px 기반)
- 다운로드: https://galmuri.quiple.dev/
- 라이선스: OFL (Open Font License)

### 글자셋 (KSX1001 기반 최적화)
- **총 1960자**: ASCII 95 + 한글 자모 51 + 한글 음절 ~1814
- KSX1001에서 희귀 조합 제거:
  - 겹받침: ㄳ ㄵ ㄶ ㄺ ㄻ ㄼ ㄽ ㄾ ㄿ ㅀ ㅄ
  - 희귀 이중모음+받침: ㅒ ㅖ ㅙ ㅞ ㅢ ㅛ ㅠ ㅑ ㅕ + 받침
- 자모 추가: ㄱㄲㄳ...ㅎ, ㅏㅐ...ㅣ (51자)

### 생성 명령어
```bash
npx msdf-bmfont \
  -f json \
  -m 512,512 \
  -s 10 \
  -r 2 \
  -t msdf \
  -p 0 \
  --pot --square \
  -i work/font_atlas/ksx_filtered.txt \
  -o work/font_atlas/Galmuri9-ksx \
  Galmuri9.ttf
```

### 설정 값
| 항목 | 값 | 설명 |
|------|-----|------|
| 텍스처 크기 | 512x512 | 게임 제약 |
| 폰트 사이즈 | 10px | 512x512에 1960자 최적화 |
| distanceRange | 2 (생성) → 0.01 (JSON) | 선명도 최대화 |
| distanceRangeMiddle | 0.5 | 추가 선명화 |
| 글리프 수 | 1960개 | ASCII 95 + 자모 51 + 한글 ~1814 |
| 렌더링 스케일 | 0.85x | UI 잘림 방지 |
| 영어 간격 | 1.2x | 가독성 향상 |

### 후처리 (선명화 + 스케일 + 간격)
```python
from PIL import Image
import numpy as np
import json

# 1. PNG 이진화 (모든 채널)
img = Image.open('Galmuri9-ksx.png').convert('RGBA')
arr = np.array(img)

for c in range(4):  # R, G, B, A 모두
    arr[:,:,c] = np.where(arr[:,:,c] >= 127, 255, 0)

Image.fromarray(arr, 'RGBA').save('Galmuri9-sharp.png')

# 2. JSON 조정
with open('Galmuri9-Final.json', 'r') as f:
    data = json.load(f)

data['atlas']['distanceRange'] = 0.01
data['atlas']['distanceRangeMiddle'] = 0.5
data['metrics']['ascender'] = -1.011
data['metrics']['descender'] = 0.353
data['metrics']['lineHeight'] = 1.364

SCALE = 0.85  # UI 잘림 방지

for glyph in data['glyphs']:
    unicode = glyph['unicode']
    # planeBounds 스케일
    glyph['planeBounds']['left'] *= SCALE
    glyph['planeBounds']['right'] *= SCALE
    glyph['planeBounds']['top'] *= SCALE
    glyph['planeBounds']['bottom'] *= SCALE
    # 영어(ASCII)만 간격 1.2배
    if 32 <= unicode <= 126:
        glyph['advance'] *= SCALE * 1.2
    else:
        glyph['advance'] *= SCALE

with open('Galmuri9-Final.json', 'w') as f:
    json.dump(data, f, separators=(',', ': '))
```

### metrics 설정 (원본 게임 값 사용)
```json
{
  "emSize": 1,
  "lineHeight": 1.364,
  "ascender": -1.011,
  "descender": 0.353,
  "underlineY": 0.101,
  "underlineThickness": 0.037
}
```

### 생성된 파일
```
work/font_atlas/
├── ksx_filtered.txt         # 1960자 (최적화된 글자셋)
├── Galmuri9.json            # msdf-bmfont 출력 (BMFont 형식)
├── Galmuri9-ksx.png         # 원본 아틀라스
├── Galmuri9-Final.json      # Hytale 형식 + 스케일/간격 조정
└── Galmuri9-sharp.png       # 선명화된 아틀라스
```

### 적용된 게임 폰트
| 게임 폰트 | 용도 |
|----------|------|
| NunitoSans-Medium | 기본 UI |
| NunitoSans-ExtraBold | 굵은 UI |
| Lexend-Bold | 제목 |
| NotoMono-Regular | 고정폭 |

### meta.lang 설정
```
name = 한국어
```

---

## 9. 다른 폰트 추천

### 픽셀 폰트
| 폰트명 | 크기 | 특징 |
|--------|------|------|
| 네오둥근모 (NeoDunggeunmo) | 16px | 레트로 감성, 선명함 |
| 둥근모꼴 (ThinDungGeunMo) | 16px | 더 얇은 버전 |
| 갈무리 (Galmuri) | 11px | 작은 사이즈, 가독성 좋음 |

### 일반 폰트 (벡터)
| 폰트명 | 특징 |
|--------|------|
| Wanted Sans | 현대적, 게임에 잘 어울림 |
| Noto Sans KR | 범용, 가독성 좋음 |
| Pretendard | 깔끔한 고딕체 |

⚠️ **픽셀 폰트 주의사항**: MSDF는 벡터용이라 픽셀 폰트가 흐릿해짐. 후처리(threshold) 필수.

---

## 10. 빠른 시작 (네오둥근모)

```bash
# 아틀라스 생성
npx msdf-bmfont -f json -m 512,512 -s 16 -r 2 -t msdf -p 0 --pot --square \
  -i charset.txt -o NeoDunggeunmo-16px NeoDunggeunmoPro-Regular.ttf

# 형식 변환
python3 convert_font.py NeoDunggeunmoPro-Regular.json NeoDunggeunmo-Final.json

# 선명화 (선택)
python3 sharpen.py NeoDunggeunmo-16px.png NeoDunggeunmo-sharp.png

# 적용
cp NeoDunggeunmo-Final.json "$FONTS_DIR/NunitoSans-Medium.json"
cp NeoDunggeunmo-sharp.png "$FONTS_DIR/NunitoSans-Medium.png"
```

---

## 11. 파일 구조 예시

```
work/
├── font_atlas/
│   ├── full_charset.txt          # 글자 목록
│   ├── NeoDunggeunmoPro-Regular.json  # msdf-bmfont 출력
│   ├── NeoDunggeunmo-16px.png    # msdf-bmfont 출력 PNG
│   ├── NeoDunggeunmo-Final.json  # Hytale 형식 변환
│   └── NeoDunggeunmo-sharp.png   # 선명화된 PNG
├── convert_font.py               # 변환 스크립트
└── sharpen.py                    # 선명화 스크립트
```

---

## 12. 원본 복원

```bash
FONTS_DIR="$HOME/Library/Application Support/Hytale/install/release/package/game/latest/Client/Hytale.app/Contents/Resources/Data/Shared/Fonts"

for font in "NunitoSans-Medium" "NunitoSans-ExtraBold" "Lexend-Bold" "NotoMono-Regular"; do
  cp "$FONTS_DIR/${font}.json.original" "$FONTS_DIR/${font}.json"
  cp "$FONTS_DIR/${font}.png.original" "$FONTS_DIR/${font}.png"
done
```
