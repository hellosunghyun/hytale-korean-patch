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
    
    size = info.get('size', 32)
    tex_w = common.get('scaleW', 1024)
    tex_h = common.get('scaleH', 1024)
    line_height = common.get('lineHeight', size) / size
    base = common.get('base', size)
    
    # Use original game metrics for proper positioning
    hytale = {
        "atlas": {
            "type": df.get('fieldType', 'msdf'),
            "distanceRange": df.get('distanceRange', 4),
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
        
        # Normalize to em units
        advance = xadv / size
        
        # planeBounds: relative to baseline (base)
        # baseline is at y=base from top of cell
        # yoffset is from top of cell to top of glyph
        left = xoff / size
        top = -(base - yoff) / size  # distance from baseline to top (negative = above)
        right = (xoff + w) / size
        bottom = -(base - yoff - h) / size  # distance from baseline to bottom (positive = below)
        
        # atlasBounds: pixel coordinates with 0.5 offset
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
    
    # Add kerning if present
    for kern in bmfont.get('kernings', []):
        hytale["kerning"].append({
            "unicode1": kern['first'],
            "unicode2": kern['second'],
            "advance": kern['amount'] / size
        })
    
    with open(output_path, 'w') as f:
        json.dump(hytale, f, separators=(',', ': '))
    
    print(f"Converted {len(hytale['glyphs'])} glyphs to {output_path}")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: convert_font.py input.json output.json")
        sys.exit(1)
    convert_bmfont_to_hytale(sys.argv[1], sys.argv[2])
