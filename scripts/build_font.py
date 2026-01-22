#!/usr/bin/env python3
"""
한글 폰트 빌드 스크립트
baseline 조정으로 글자 위치 조절 가능
"""
import os
import sys
import json
import shutil
import subprocess
import zipfile
import urllib.request
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent.parent
FONT_NAME = "Pretendard"
FONT_URL = "https://github.com/orioncactus/pretendard/releases/download/v1.3.9/Pretendard-1.3.9.zip"
FONT_DIR = SCRIPT_DIR / "reference"
FONT_TTF = FONT_DIR / "public/static/alternative/Pretendard-Medium.ttf"
CHARSET_FILE = SCRIPT_DIR / "src/charset/charset_full.txt"
OUTPUT_DIR = SCRIPT_DIR / "Fonts"

# 조절 파라미터
BASELINE_OFFSET = 0.0  # 일단 0으로 (아티팩트 방지)
TEXTURE_PADDING = 4    # 기본 패딩

def download_font():
    if FONT_TTF.exists():
        print("✓ 폰트 존재")
        return
    
    print("📥 폰트 다운로드 중...")
    (SCRIPT_DIR / "reference").mkdir(exist_ok=True)
    font_zip = SCRIPT_DIR / "reference/WantedSans.zip"
    urllib.request.urlretrieve(FONT_URL, font_zip)
    
    with zipfile.ZipFile(font_zip, 'r') as zf:
        zf.extractall(SCRIPT_DIR / "reference")
    font_zip.unlink()
    print("✓ 다운로드 완료")

def generate_charset():
    if CHARSET_FILE.exists():
        with open(CHARSET_FILE, 'r', encoding='utf-8') as f:
            if not f.read(4).startswith('0x'):
                print("✓ 글자셋 존재")
                return
    
    print("📝 글자셋 생성 중...")
    CHARSET_FILE.parent.mkdir(parents=True, exist_ok=True)
    
    chars = []
    for i in range(0x20, 0x7F): chars.append(chr(i))
    for c in "°–—''\"\"•…": chars.append(c)
    for i in range(0x3131, 0x3164): chars.append(chr(i))
    for i in range(0xAC00, 0xD7A4): chars.append(chr(i))
    
    with open(CHARSET_FILE, 'w', encoding='utf-8') as f:
        f.write(''.join(chars))
    print(f"✓ {len(chars)}자 생성")

def build_msdf():
    print("🏗️  MSDF 아틀라스 생성 중 (8192x8192)...")
    OUTPUT_DIR.mkdir(exist_ok=True)
    
    cmd = [
        "npx", "msdf-bmfont-xml",
        "-f", "json",
        "-m", "8192,8192",
        "-s", "48",
        "-r", "8",
        "-t", "msdf",
        "-p", str(TEXTURE_PADDING),
        "--pot", "--square",
        "-i", str(CHARSET_FILE),
        "-o", FONT_NAME,
        str(FONT_TTF)
    ]
    
    subprocess.run(cmd, check=True, cwd=SCRIPT_DIR)
    print("✓ MSDF 생성 완료")

def convert_to_hytale():
    print(f"🔄 Hytale 포맷 변환 (baseline offset: {BASELINE_OFFSET})...")
    
    # JSON 파일 찾기
    json_candidates = [
        SCRIPT_DIR / f"{FONT_NAME}.json",
        SCRIPT_DIR / f"{FONT_NAME}-Medium.json",
        SCRIPT_DIR / "WantedSans-Medium.json"
    ]
    bmfont_json = next((f for f in json_candidates if f.exists()), None)
    
    # PNG 파일 찾기
    png_candidates = [
        SCRIPT_DIR / f"{FONT_NAME}.png",
        SCRIPT_DIR / f"{FONT_NAME}.0.png"
    ]
    bmfont_png = next((f for f in png_candidates if f.exists()), None)
    
    if not bmfont_json or not bmfont_png:
        print("❌ MSDF 출력 파일 없음")
        sys.exit(1)
    
    with open(bmfont_json, 'r', encoding='utf-8') as f:
        bmfont = json.load(f)
    
    info = bmfont.get('info', {})
    common = bmfont.get('common', {})
    df = bmfont.get('distanceField', {})
    chars = bmfont.get('chars', [])
    
    size = info.get('size', 48)
    tex_w = common.get('scaleW', 8192)
    tex_h = common.get('scaleH', 8192)
    base = common.get('base', size)
    
    hytale = {
        "atlas": {
            "type": df.get('fieldType', 'msdf'),
            "distanceRange": df.get('distanceRange', 8),
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
        left = xoff / size
        # BASELINE_OFFSET 적용: 양수면 위로
        top = -(base - yoff) / size - BASELINE_OFFSET
        right = (xoff + w) / size
        bottom = -(base - yoff - h) / size - BASELINE_OFFSET
        
        glyph = {
            "unicode": char_id,
            "advance": advance,
            "planeBounds": {"left": left, "top": top, "right": right, "bottom": bottom},
            "atlasBounds": {"left": x + 0.5, "top": y + 0.5, "right": x + w - 0.5, "bottom": y + h - 0.5}
        }
        hytale["glyphs"].append(glyph)
    
    for kern in bmfont.get('kernings', []):
        hytale["kerning"].append({
            "unicode1": kern['first'],
            "unicode2": kern['second'],
            "advance": kern['amount'] / size
        })
    
    # 저장
    with open(OUTPUT_DIR / f"{FONT_NAME}.json", 'w', encoding='utf-8') as f:
        json.dump(hytale, f, separators=(',', ': '))
    
    shutil.move(str(bmfont_png), str(OUTPUT_DIR / f"{FONT_NAME}.png"))
    bmfont_json.unlink()
    
    # 임시 파일 정리
    for f in SCRIPT_DIR.glob(f"{FONT_NAME}*.json"):
        f.unlink()
    for f in SCRIPT_DIR.glob(f"{FONT_NAME}*.png"):
        f.unlink()
    
    print(f"✓ {len(hytale['glyphs'])}자 변환 완료")

def main():
    print(f"=== 폰트 빌드 (baseline offset: {BASELINE_OFFSET}) ===\n")
    download_font()
    generate_charset()
    build_msdf()
    convert_to_hytale()
    print("\n✨ 빌드 완료!")
    print(f"   {OUTPUT_DIR / FONT_NAME}.json")
    print(f"   {OUTPUT_DIR / FONT_NAME}.png")

if __name__ == "__main__":
    main()
