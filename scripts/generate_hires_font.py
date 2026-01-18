#!/usr/bin/env python3
"""
고해상도 MSDF 폰트 아틀라스 생성 스크립트

요구사항:
- msdf-atlas-gen (https://github.com/Chlumsky/msdf-atlas-gen)
  - macOS: brew install msdf-atlas-gen
  - Windows: GitHub releases에서 바이너리 다운로드

사용법:
  python generate_hires_font.py [font.ttf] [output_name]
  python generate_hires_font.py WantedSans-Medium.ttf WantedSans
"""
import os
import sys
import subprocess
import shutil
import json
from pathlib import Path

# 설정
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent
CHARSET_FILE = PROJECT_DIR / "src/charset/charset_full.txt"

# msdf-atlas-gen 설정 (4096x4096, 48px)
ATLAS_DIMENSIONS = (4096, 4096)
FONT_SIZE = 48
PIXEL_RANGE = 8  # MSDF distance range


def find_msdf_atlas_gen():
    """msdf-atlas-gen 실행 파일 찾기"""
    # PATH에서 찾기
    exe = shutil.which("msdf-atlas-gen")
    if exe:
        return exe

    # Windows: 로컬 폴더에서 찾기
    if os.name == 'nt':
        local_exe = PROJECT_DIR / "tools/msdf-atlas-gen.exe"
        if local_exe.exists():
            return str(local_exe)

    return None


def generate_charset():
    """charset_full.txt 생성 (없을 경우)"""
    if CHARSET_FILE.exists():
        print(f"   ✓ 글자셋 파일 확인됨: {CHARSET_FILE.name}")
        return

    print("   글자셋 파일 생성 중...")
    CHARSET_FILE.parent.mkdir(parents=True, exist_ok=True)

    chars = []

    # 1. ASCII (0x20-0x7E)
    for i in range(0x20, 0x7F):
        chars.append(chr(i))

    # 2. Extended Latin (common symbols)
    extended = "°–—''""•…€£¥©®™±×÷←→↑↓"
    chars.extend(extended)

    # 3. Korean Jamo (ㄱ-ㅎ, ㅏ-ㅣ)
    for i in range(0x3131, 0x3164):  # Compatibility Jamo
        chars.append(chr(i))

    # 4. Korean Syllables (가-힣) - 11,172자
    for i in range(0xAC00, 0xD7A4):
        chars.append(chr(i))

    # 5. CJK Punctuation
    cjk_punct = "。、「」『』【】〈〉《》〔〕"
    chars.extend(cjk_punct)

    # 6. Fullwidth ASCII
    for i in range(0xFF01, 0xFF5F):
        chars.append(chr(i))

    # Write as space-separated hex values (msdf-atlas-gen charset format)
    with open(CHARSET_FILE, 'w', encoding='utf-8') as f:
        hex_codes = [f"0x{ord(c):X}" for c in chars]
        f.write(" ".join(hex_codes))

    print(f"   ✓ 글자셋 생성 완료: {len(chars)}자")


def convert_to_hytale_format(atlas_json_path: Path, output_json_path: Path):
    """msdf-atlas-gen JSON 출력을 Hytale 포맷으로 변환"""
    with open(atlas_json_path, 'r', encoding='utf-8') as f:
        atlas_data = json.load(f)

    atlas_info = atlas_data.get('atlas', {})
    metrics = atlas_data.get('metrics', {})
    glyphs = atlas_data.get('glyphs', [])

    # Hytale format
    hytale = {
        "atlas": {
            "type": atlas_info.get('type', 'msdf'),
            "distanceRange": atlas_info.get('distanceRange', PIXEL_RANGE),
            "distanceRangeMiddle": atlas_info.get('distanceRangeMiddle', 0),
            "size": atlas_info.get('size', FONT_SIZE),
            "width": atlas_info.get('width', ATLAS_DIMENSIONS[0]),
            "height": atlas_info.get('height', ATLAS_DIMENSIONS[1]),
            "yOrigin": "top"
        },
        "metrics": {
            "emSize": metrics.get('emSize', 1),
            "lineHeight": metrics.get('lineHeight', 1.2),
            "ascender": metrics.get('ascender', -0.8),
            "descender": metrics.get('descender', 0.2),
            "underlineY": metrics.get('underlineY', 0.1),
            "underlineThickness": metrics.get('underlineThickness', 0.05)
        },
        "glyphs": [],
        "kerning": atlas_data.get('kerning', [])
    }

    # Convert glyphs
    for g in glyphs:
        glyph = {
            "unicode": g.get('unicode'),
            "advance": g.get('advance', 0)
        }

        # planeBounds (normalized coordinates)
        if 'planeBounds' in g:
            pb = g['planeBounds']
            glyph['planeBounds'] = {
                "left": pb.get('left', 0),
                "top": -pb.get('top', 0),  # Flip for top-origin
                "right": pb.get('right', 0),
                "bottom": -pb.get('bottom', 0)
            }

        # atlasBounds (pixel coordinates)
        if 'atlasBounds' in g:
            ab = g['atlasBounds']
            glyph['atlasBounds'] = {
                "left": ab.get('left', 0),
                "top": ab.get('top', 0),
                "right": ab.get('right', 0),
                "bottom": ab.get('bottom', 0)
            }

        hytale['glyphs'].append(glyph)

    with open(output_json_path, 'w', encoding='utf-8') as f:
        json.dump(hytale, f, separators=(',', ': '))

    print(f"   ✓ Hytale 포맷 변환 완료: {len(hytale['glyphs'])}자")


def generate_atlas(font_path: Path, output_name: str):
    """msdf-atlas-gen으로 고해상도 MSDF 아틀라스 생성"""
    msdf_exe = find_msdf_atlas_gen()
    if not msdf_exe:
        print("❌ msdf-atlas-gen을 찾을 수 없습니다.")
        print("   macOS: brew install msdf-atlas-gen")
        print("   Windows: https://github.com/Chlumsky/msdf-atlas-gen/releases 에서 다운로드")
        return False

    output_dir = PROJECT_DIR / "Fonts"
    output_dir.mkdir(exist_ok=True)

    temp_json = PROJECT_DIR / f"{output_name}_temp.json"
    output_png = output_dir / f"{output_name}.png"
    output_json = output_dir / f"{output_name}.json"

    # msdf-atlas-gen 실행
    cmd = [
        msdf_exe,
        "-font", str(font_path),
        "-charset", str(CHARSET_FILE),
        "-type", "msdf",
        "-pxrange", str(PIXEL_RANGE),
        "-size", str(FONT_SIZE),
        "-dimensions", f"{ATLAS_DIMENSIONS[0]}", f"{ATLAS_DIMENSIONS[1]}",
        "-yorigin", "top",
        "-imageout", str(output_png),
        "-json", str(temp_json)
    ]

    print(f"   실행 중: {' '.join(cmd[:4])}...")

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        if result.stderr:
            print(f"   경고: {result.stderr[:200]}")
    except subprocess.CalledProcessError as e:
        print(f"❌ msdf-atlas-gen 실행 실패: {e}")
        if e.stderr:
            print(f"   오류: {e.stderr[:500]}")
        return False

    # Hytale 포맷으로 변환
    if temp_json.exists():
        convert_to_hytale_format(temp_json, output_json)
        temp_json.unlink()  # 임시 파일 삭제

    print(f"   ✓ 아틀라스 생성 완료: {output_png.name}, {output_json.name}")
    return True


def main():
    print("=== 고해상도 MSDF 폰트 아틀라스 생성기 ===")
    print(f"    해상도: {ATLAS_DIMENSIONS[0]}x{ATLAS_DIMENSIONS[1]}")
    print(f"    폰트 크기: {FONT_SIZE}px")
    print("")

    # 인자 처리
    if len(sys.argv) >= 3:
        font_path = Path(sys.argv[1])
        output_name = sys.argv[2]
    elif len(sys.argv) >= 2:
        font_path = Path(sys.argv[1])
        output_name = font_path.stem
    else:
        # 기본값: WantedSans-Medium
        font_path = PROJECT_DIR / "reference/WantedSans-1.0.3/ttf/WantedSans-Medium.ttf"
        output_name = "WantedSans"

    if not font_path.exists():
        print(f"❌ 폰트 파일을 찾을 수 없습니다: {font_path}")
        sys.exit(1)

    print(f"📁 폰트: {font_path.name}")
    print(f"📁 출력: {output_name}")
    print("")

    # 1. 글자셋 확인/생성
    print("1️⃣  글자셋 준비...")
    generate_charset()

    # 2. 아틀라스 생성
    print("")
    print("2️⃣  MSDF 아틀라스 생성...")
    if not generate_atlas(font_path, output_name):
        sys.exit(1)

    print("")
    print("✨ 완료!")


if __name__ == "__main__":
    main()
