from PIL import Image
import numpy as np
import json
import sys

def sharpen_and_update(png_path, json_path, final_json_path, final_png_path):
    # 1. Image Sharpening
    print(f"Sharpening {png_path}...")
    img = Image.open(png_path).convert('RGBA')
    arr = np.array(img)

    # Thresholding for pixel font sharpness
    for c in range(4):  # R, G, B, A
        arr[:,:,c] = np.where(arr[:,:,c] >= 127, 255, 0)

    Image.fromarray(arr, 'RGBA').save(final_png_path)
    print(f"Saved sharpened image to {final_png_path}")

    # 2. JSON Update (Metrics & Scaling)
    print(f"Updating JSON {json_path}...")
    with open(json_path, 'r') as f:
        data = json.load(f)

    # Tuning for sharpness and Hytale rendering
    data['atlas']['distanceRange'] = 0.01
    data['atlas']['distanceRangeMiddle'] = 0.5
    
    # Metrics from original Hytale font (NunitoSans)
    data['metrics']['ascender'] = -1.011
    data['metrics']['descender'] = 0.353
    data['metrics']['lineHeight'] = 1.364

    SCALE = 0.85  # Prevent UI clipping

    if 'glyphs' in data:
        for glyph in data['glyphs']:
            unicode_val = glyph['unicode']
            
            # Scale planeBounds
            if 'planeBounds' in glyph:
                glyph['planeBounds']['left'] *= SCALE
                glyph['planeBounds']['right'] *= SCALE
                glyph['planeBounds']['top'] *= SCALE
                glyph['planeBounds']['bottom'] *= SCALE
            
            # Adjust advance
            if 'advance' in glyph:
                # Wider English for readability
                if 32 <= unicode_val <= 126:
                    glyph['advance'] *= SCALE * 1.2
                else:
                    glyph['advance'] *= SCALE

    with open(final_json_path, 'w') as f:
        json.dump(data, f, separators=(',', ': '))
    print(f"Saved updated JSON to {final_json_path}")

if __name__ == "__main__":
    if len(sys.argv) < 5:
        print("Usage: python3 sharpen.py <input.png> <converted.json> <final.json> <final.png>")
        sys.exit(1)
    
    sharpen_and_update(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
