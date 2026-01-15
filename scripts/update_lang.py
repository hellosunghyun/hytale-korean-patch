import os
import sys
import platform
import re
import translate_gemini

def get_hytale_path():
    system = platform.system()
    home = os.path.expanduser("~")
    if system == "Windows":
        base_path = os.path.join(os.environ.get("APPDATA", home), "Hytale")
        lang_sub_path = "install/release/package/game/latest/Client/Data/Shared/Language/en-US"
    elif system == "Darwin":
        base_path = os.path.join(home, "Library/Application Support/Hytale")
        lang_sub_path = "install/release/package/game/latest/Client/Hytale.app/Contents/Resources/Data/Shared/Language/en-US"
    else:
        base_path = os.path.join(home, ".local/share/Hytale")
        lang_sub_path = "install/release/package/game/latest/Client/Data/Shared/Language/en-US"
    return os.path.join(base_path, lang_sub_path)

LANG_FILES = ["client.lang", "meta.lang"]
OUTPUT_DIR = "Language/ko-KR"

def update():
    local_path = get_hytale_path()
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    gemini_key = os.environ.get("GEMINI_API_KEY")

    for lang_file in LANG_FILES:
        src_path = os.path.join(local_path, lang_file)
        target_path = os.path.join(OUTPUT_DIR, lang_file)
        if not os.path.exists(src_path): continue

        # 1. 원본(영어) 및 기존(한국어) 읽기
        with open(src_path, 'r', encoding='utf-8') as f:
            en_lines = f.readlines()
        
        ko_data = {}
        ko_lines = []
        if os.path.exists(target_path):
            with open(target_path, 'r', encoding='utf-8') as f:
                ko_lines = f.readlines()
                # 줄 수와 상관없이 Key = Value 쌍만 긁어모음 (정규식 지양, 단순 분할)
                for line in ko_lines:
                    if ' = ' in line:
                        parts = line.split(' = ', 1)
                        ko_data[parts[0].strip()] = parts[1].split(' # TODO:')[0].strip()

        def strip_todo_marker(raw_line):
            return raw_line.replace(" # TODO: Translate", "")

        def is_identifier_example(text):
            stripped = text.strip()
            if not stripped:
                return False
            if "_" not in stripped:
                return False
            return re.fullmatch(r"[A-Za-z0-9_,\s]+", stripped) is not None

        ko_blocks = {}
        current_key = None
        current_lines = []
        for line in ko_lines:
            if ' = ' in line:
                if current_key is not None:
                    ko_blocks[current_key] = current_lines
                current_key = line.split(' = ', 1)[0].strip()
                current_lines = []
            else:
                if current_key is not None:
                    current_lines.append(strip_todo_marker(line))
        if current_key is not None:
            ko_blocks[current_key] = current_lines

        # 2. 원본 구조 100% 복제 (줄 수 불변)
        final_lines = []
        i = 0
        while i < len(en_lines):
            line = en_lines[i]
            if ' = ' in line:
                parts = line.split(' = ', 1)
                key_part = parts[0]
                key = key_part.strip()
                en_val = parts[1].strip()
                is_multiline = en_val.endswith('\\')

                if key in ko_data:
                    value = ko_data[key].rstrip()
                    value = value.rstrip('\\').rstrip()
                    if is_multiline:
                        final_lines.append(f"{key_part} = {value}\\\n")
                    else:
                        final_lines.append(f"{key_part} = {value}\n")
                else:
                    final_lines.append(line.rstrip() + " # TODO: Translate\n")

                if is_multiline:
                    i += 1
                    en_cont_lines = []
                    while i < len(en_lines):
                        cont_line = en_lines[i]
                        en_cont_lines.append(cont_line)
                        if not cont_line.rstrip().endswith('\\'):
                            break
                        i += 1
                    ko_cont_lines = ko_blocks.get(key, [])
                    for idx, cont_line in enumerate(en_cont_lines):
                        if idx < len(ko_cont_lines):
                            final_lines.append(ko_cont_lines[idx])
                            continue

                        raw_cont = cont_line.rstrip('\n')
                        if is_identifier_example(raw_cont.rstrip()):
                            final_lines.append(cont_line)
                            continue
                        if raw_cont.rstrip().endswith('\\'):
                            raw_no_backslash = raw_cont.rstrip()[:-1].rstrip()
                            final_lines.append(f"{raw_no_backslash} # TODO: TranslateLine\\\n")
                        else:
                            final_lines.append(f"{raw_cont} # TODO: TranslateLine\n")
                    i += 1
                    continue

                i += 1
                continue

            final_lines.append(line)
            i += 1

        with open(target_path, 'w', encoding='utf-8') as f:
            f.writelines(final_lines)
        
        print(f"✅ Re-synchronized {lang_file} strictly following original line structure")
        if gemini_key:
            translate_gemini.process_translation(target_path, gemini_key)

if __name__ == "__main__":
    update()
