#!/usr/bin/env python3
"""
Hytale 한글 패치 설치 스크립트 (Windows)
고해상도 폰트 + 메모리 패처 지원
"""
import os
import sys
import shutil
import subprocess
import zipfile
import json
from pathlib import Path

# ==========================================
# 환경 설정
# ==========================================
SCRIPT_DIR = Path(__file__).resolve().parent.parent
LOCAL_APPDATA = os.environ.get('LOCALAPPDATA', '')
APPDATA = os.environ.get('APPDATA', '')

POSSIBLE_PATHS = [
    Path(APPDATA) / "Hytale/install/release/package/game/latest/Client/Data/Shared",
    Path(APPDATA) / "Hytale/install/release/package/game/latest/Client/Shared",
    Path(LOCAL_APPDATA) / "Hytale/install/release/package/game/latest/Client/Data/Shared",
    Path(LOCAL_APPDATA) / "Hytale/install/release/package/game/latest/Client/Shared",
]

# 폰트 설정 (레포에 포함된 빌드 완료 폰트 사용)
FONT_NAME = "WantedSans"
FONT_JSON = SCRIPT_DIR / "Fonts" / f"{FONT_NAME}.json"
FONT_PNG = SCRIPT_DIR / "Fonts" / f"{FONT_NAME}.png"


def check_font():
    """레포에 포함된 폰트 파일 확인"""
    print("\n📦 폰트 파일 확인 중...")

    if not FONT_JSON.exists() or not FONT_PNG.exists():
        print("❌ 폰트 파일이 없습니다.")
        print(f"   필요한 파일:")
        print(f"   - {FONT_JSON}")
        print(f"   - {FONT_PNG}")
        print("\n   git pull로 최신 버전을 받아주세요.")
        sys.exit(1)

    print("   ✓ 폰트 파일 확인됨")


def find_game_dir():
    print("\n🔍 Hytale 설치 경로 찾는 중...")
    for path in POSSIBLE_PATHS:
        if path.exists():
            print(f"   ✓ 찾음: {path}")
            return path

    print("❌ Hytale 게임 폴더를 찾을 수 없습니다.")
    print("게임이 설치된 경로를 직접 입력해주세요 (Client/Data/Shared 폴더 경로):")
    custom_path = input("> ").strip()

    if custom_path:
        custom_path = Path(custom_path)
        if custom_path.exists():
            return custom_path
        print(f"❌ 유효하지 않은 경로입니다: {custom_path}")
    return None


def patch_binary(game_dir: Path):
    """바이너리 직접 패치 (512 → 8192)"""
    print("\n🔧 바이너리 패치 중...")

    # HytaleClient.exe 찾기
    exe_path = None
    current = game_dir
    for _ in range(5):
        check_exe = current / "HytaleClient.exe"
        if check_exe.exists():
            exe_path = check_exe
            break
        current = current.parent

    if not exe_path:
        for parent in game_dir.parents:
            check_exe = parent / "HytaleClient.exe"
            if check_exe.exists():
                exe_path = check_exe
                break

    if not exe_path or not exe_path.exists():
        print("   ⚠️ HytaleClient.exe를 찾을 수 없어 바이너리 패치를 건너뜁니다.")
        return False

    # 백업
    backup_path = exe_path.with_suffix('.exe.backup_original')
    if not backup_path.exists():
        shutil.copy2(exe_path, backup_path)
        print("   ✓ 원본 바이너리 백업됨")

    # 바이너리 읽기
    with open(exe_path, 'rb') as f:
        data = bytearray(f.read())

    # x86_64 패턴 패치
    # 512 (0x200) 패턴들:
    # - BA 00 02 00 00 = mov edx, 0x200
    # - 41 B8 00 02 00 00 = mov r8d, 0x200
    # - B9 00 02 00 00 = mov ecx, 0x200
    # - 41 B9 00 02 00 00 = mov r9d, 0x200
    #
    # 8192 (0x2000)로 변경: 00 02 -> 00 20

    patch_count = 0
    i = 0
    while i < len(data) - 11:
        # 패턴 1: BA 00 02 00 00 41 B8 00 02 00 00 (mov edx, mov r8d)
        if (data[i] == 0xBA and data[i+1] == 0x00 and data[i+2] == 0x02 and
            data[i+3] == 0x00 and data[i+4] == 0x00 and
            data[i+5] == 0x41 and data[i+6] == 0xB8 and
            data[i+7] == 0x00 and data[i+8] == 0x02 and
            data[i+9] == 0x00 and data[i+10] == 0x00):
            # 512 -> 8192: 00 02 -> 00 20
            data[i+2] = 0x20
            data[i+8] = 0x20
            patch_count += 1
            i += 11
            continue

        # 패턴 2: B9 00 02 00 00 41 B9 00 02 00 00 (mov ecx, mov r9d)
        if (data[i] == 0xB9 and data[i+1] == 0x00 and data[i+2] == 0x02 and
            data[i+3] == 0x00 and data[i+4] == 0x00 and
            data[i+5] == 0x41 and data[i+6] == 0xB9 and
            data[i+7] == 0x00 and data[i+8] == 0x02 and
            data[i+9] == 0x00 and data[i+10] == 0x00):
            data[i+2] = 0x20
            data[i+8] = 0x20
            patch_count += 1
            i += 11
            continue

        # 패턴 3: 41 B8 00 02 00 00 41 B9 00 02 00 00 (mov r8d, mov r9d)
        if (data[i] == 0x41 and data[i+1] == 0xB8 and
            data[i+2] == 0x00 and data[i+3] == 0x02 and
            data[i+4] == 0x00 and data[i+5] == 0x00 and
            data[i+6] == 0x41 and data[i+7] == 0xB9 and
            data[i+8] == 0x00 and data[i+9] == 0x02 and
            data[i+10] == 0x00 and data[i+11] == 0x00):
            data[i+3] = 0x20
            data[i+9] = 0x20
            patch_count += 1
            i += 12
            continue

        i += 1

    if patch_count == 0:
        print("   ⚠️ 패치할 패턴을 찾지 못했습니다.")
        print("   이미 패치되었거나 게임 버전이 다를 수 있습니다.")
        return False

    # 패치된 바이너리 저장
    with open(exe_path, 'wb') as f:
        f.write(data)

    print(f"   ✓ {patch_count}개 패턴 패치 완료 (512 -> 8192)")
    return True


def install_patch(game_dir: Path):
    print("\n💾 게임 패치 적용 중...")

    fonts_dir = game_dir / "Fonts"
    lang_dir = game_dir / "Language/ko-KR"
    lang_dir_backup = game_dir / "Language/ko-KR_backup"

    font_json = FONT_JSON
    font_png = FONT_PNG

    # 폰트 설치
    print("   [폰트 설치]")
    fonts_to_replace = ["NunitoSans-Medium", "NunitoSans-ExtraBold", "Lexend-Bold", "NotoMono-Regular"]
    for font_name in fonts_to_replace:
        target_json = fonts_dir / f"{font_name}.json"
        target_png = fonts_dir / f"{font_name}.png"

        if target_json.exists() and not (fonts_dir / f"{font_name}.json.backup").exists():
            shutil.copy2(target_json, fonts_dir / f"{font_name}.json.backup")
            shutil.copy2(target_png, fonts_dir / f"{font_name}.png.backup")

        shutil.copy2(font_json, target_json)
        shutil.copy2(font_png, target_png)
    print("   ✓ 폰트 교체 완료")

    # 언어 파일 설치
    print("   [언어 파일 설치]")

    if lang_dir.exists() and not lang_dir_backup.exists():
        shutil.copytree(lang_dir, lang_dir_backup)

    temp_work = SCRIPT_DIR / "temp_work"
    if temp_work.exists():
        shutil.rmtree(temp_work)
    temp_work.mkdir()

    try:
        # Assets.zip 찾기
        assets_zip = None
        current_path = game_dir
        for _ in range(6):
            check_path = current_path / "Assets.zip"
            if check_path.exists():
                assets_zip = check_path
                break
            current_path = current_path.parent

        if assets_zip and assets_zip.exists():
            with zipfile.ZipFile(assets_zip, 'r') as zf:
                target_files = [f for f in zf.namelist()
                               if f.startswith("Server/Languages/en-US/") or
                                  f.startswith("Common/Languages/en-US/")]
                zf.extractall(temp_work, members=target_files)

        # Client base files
        client_en_dir = game_dir / "Language/en-US"
        if client_en_dir.exists():
            dest = temp_work / "Client"
            dest.mkdir(parents=True, exist_ok=True)
            for f in client_en_dir.glob("*.lang"):
                shutil.copy2(f, dest)

        lang_dir.mkdir(parents=True, exist_ok=True)
        (lang_dir / "avatarCustomization").mkdir(parents=True, exist_ok=True)

        merge_script = SCRIPT_DIR / "scripts/merge_lang.py"

        def run_merge(base, patch, out):
            if not base.exists():
                base.parent.mkdir(parents=True, exist_ok=True)
                base.touch()
            subprocess.run([sys.executable, str(merge_script), str(base), str(patch), str(out)], check=True)

        # Client
        run_merge(temp_work / "Client/client.lang",
                  SCRIPT_DIR / "Language/ko-KR/client.lang",
                  lang_dir / "client.lang")

        shutil.copy2(SCRIPT_DIR / "Language/ko-KR/meta.lang", lang_dir / "meta.lang")

        # Server
        server_base = temp_work / "Server/Languages/en-US"
        server_patch = SCRIPT_DIR / "Assets/Server/Languages/ko-KR"
        for f in ["server.lang", "wordlists.lang"]:
            run_merge(server_base / f, server_patch / f, lang_dir / f)

        # Avatar
        avatar_base = temp_work / "Common/Languages/en-US/avatarCustomization"
        avatar_patch = SCRIPT_DIR / "Assets/Common/Languages/ko-KR/avatarCustomization"
        if avatar_patch.exists():
            for patch_file in avatar_patch.glob("*.lang"):
                base_file = avatar_base / patch_file.name
                run_merge(base_file, patch_file, lang_dir / "avatarCustomization" / patch_file.name)

        print("   ✓ 언어 파일 설치 완료")

    finally:
        if temp_work.exists():
            shutil.rmtree(temp_work)


def main():
    print("=== Hytale 한글 패치 설치 (Windows - 고해상도 폰트) ===")

    check_font()

    game_dir = find_game_dir()
    if not game_dir:
        input("엔터를 누르면 종료합니다...")
        sys.exit(1)

    try:
        patch_binary(game_dir)
    except Exception as e:
        print(f"⚠️ 바이너리 패치 중 오류: {e}")

    try:
        install_patch(game_dir)
    except Exception as e:
        print(f"❌ 설치 중 오류 발생: {e}")
        import traceback
        traceback.print_exc()
        input("엔터를 누르면 종료합니다...")
        sys.exit(1)

    print("\n✨ 설치 완료!")
    print("\n📌 중요 안내:")
    print("   1. 기본 런처로 게임을 실행하세요.")
    print("   2. 게임 업데이트 후에는 이 스크립트를 다시 실행하세요.")
    print("      (바이너리가 원본으로 복원되기 때문)")
    print("   3. 게임 설정에서 언어 > 한국어를 선택하세요.")
    input("\n엔터를 누르면 종료합니다...")


if __name__ == "__main__":
    main()
