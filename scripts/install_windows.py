import os
import sys
import shutil
import urllib.request
import subprocess
import platform
import zipfile  # Missing import added
from pathlib import Path

# ==========================================
# 환경 설정
# ==========================================
SCRIPT_DIR = Path(__file__).resolve().parent.parent
LOCAL_APPDATA = os.environ.get('LOCALAPPDATA', '')
APPDATA = os.environ.get('APPDATA', '')

# Hytale 경로 후보 (우선순위 순)
POSSIBLE_PATHS = [
    # 1. Local AppData (일반적인 게임 설치 위치)
    Path(LOCAL_APPDATA) / "Hytale/install/release/package/game/latest/Client/Data/Shared",
    Path(LOCAL_APPDATA) / "Hytale/install/release/package/game/latest/Client/Shared",
    
    # 2. Roaming AppData (런처 데이터 위치)
    Path(APPDATA) / "Hytale/install/release/package/game/latest/Client/Data/Shared",
    Path(APPDATA) / "Hytale/install/release/package/game/latest/Client/Shared",
]

FONT_URL = "https://quiple.dev/_astro/Galmuri9.ttf"
FONT_TTF = SCRIPT_DIR / "Galmuri9.ttf"
CHARSET_FILE = SCRIPT_DIR / "src/charset/charset_final.txt"

def find_game_dir():
    print("🔍 Hytale 설치 경로 찾는 중...")
    for path in POSSIBLE_PATHS:
        if path.exists():
            print(f"   ✓ 찾음: {path}")
            return path
    
    print("❌ Hytale 게임 폴더를 찾을 수 없습니다.")
    print("   예상 경로에 폴더가 없습니다:")
    for path in POSSIBLE_PATHS:
        print(f"   - {path}")
    return None

def download_font():
    if not FONT_TTF.exists():
        print(f"📥 폰트 다운로드 중... ({FONT_URL})")
        try:
            urllib.request.urlretrieve(FONT_URL, FONT_TTF)
            print("   ✓ 다운로드 완료")
        except Exception as e:
            print(f"❌ 폰트 다운로드 실패: {e}")
            sys.exit(1)
    else:
        print("   ✓ 폰트 파일 확인됨")

def build_font():
    print("\n🏗️  폰트 빌드 시작...")
    
    # Check node/npx
    if shutil.which('npx') is None:
        print("❌ Node.js (npx)가 설치되어 있지 않습니다.")
        print("   Node.js 공식 홈페이지에서 설치해주세요: https://nodejs.org/")
        sys.exit(1)

    # 1. MSDF Atlas
    print("   1) MSDF 아틀라스 생성 (시간이 좀 걸립니다)...")
    cmd = [
        "npx.cmd" if os.name == 'nt' else "npx",
        "msdf-bmfont-xml",
        "-f", "json",
        "-m", "512,512",
        "-s", "10",
        "-r", "2",
        "-t", "msdf",
        "-p", "0",
        "--pot", "--square",
        "-i", str(CHARSET_FILE),
        "-o", "Galmuri9-fixed",
        str(FONT_TTF)
    ]
    
    # Windows에서 shell=True가 필요할 수 있음
    try:
        subprocess.run(cmd, check=True, cwd=SCRIPT_DIR, shell=(os.name == 'nt'))
    except subprocess.CalledProcessError:
        print("❌ msdf-bmfont 실행 실패. Node.js가 올바르게 설치되었는지 확인하세요.")
        sys.exit(1)

    # 2. Convert
    print("   2) Hytale 포맷으로 변환...")
    subprocess.run([sys.executable, str(SCRIPT_DIR / "scripts/convert_font.py"), 
                   "Galmuri9.json", "Galmuri9-converted.json"], 
                   cwd=SCRIPT_DIR, check=True)

    # 3. Sharpen
    print("   3) 폰트 선명화 및 최종 저장...")
    fonts_out = SCRIPT_DIR / "Fonts"
    fonts_out.mkdir(exist_ok=True)
    
    subprocess.run([sys.executable, str(SCRIPT_DIR / "scripts/sharpen.py"),
                   "Galmuri9-fixed.png", "Galmuri9-converted.json",
                   str(fonts_out / "Galmuri9-Final.json"),
                   str(fonts_out / "Galmuri9-sharp.png")],
                   cwd=SCRIPT_DIR, check=True)
    
    print("   ✓ 폰트 빌드 성공")
    
    # Cleanup
    for f in ["Galmuri9.json", "Galmuri9-fixed.png", "Galmuri9-converted.json"]:
        try:
            (SCRIPT_DIR / f).unlink()
        except: pass

def install_patch(game_dir):
    print("\n💾 게임 패치 적용 중...")
    
    fonts_dir = game_dir / "Fonts"
    lang_dir = game_dir / "Language/ko-KR"
    lang_dir_backup = game_dir / "Language/ko-KR_backup"
    
    # 1. Fonts
    print("   [폰트 설치]")
    fonts_to_replace = ["NunitoSans-Medium", "NunitoSans-ExtraBold", "Lexend-Bold", "NotoMono-Regular"]
    for font_name in fonts_to_replace:
        target_json = fonts_dir / f"{font_name}.json"
        target_png = fonts_dir / f"{font_name}.png"
        
        # Backup
        if target_json.exists() and not (fonts_dir / f"{font_name}.json.backup").exists():
            shutil.copy2(target_json, fonts_dir / f"{font_name}.json.backup")
            shutil.copy2(target_png, fonts_dir / f"{font_name}.png.backup")
            
        # Copy
        shutil.copy2(SCRIPT_DIR / "Fonts/Galmuri9-Final.json", target_json)
        shutil.copy2(SCRIPT_DIR / "Fonts/Galmuri9-sharp.png", target_png)
    print("   ✓ 폰트 교체 완료")

    # 2. Languages
    print("   [언어 파일 설치]")
    
    # Backup existing lang dir
    if lang_dir.exists() and not lang_dir_backup.exists():
        shutil.copytree(lang_dir, lang_dir_backup)
        print(f"   ✓ 기존 언어 폴더 백업됨: {lang_dir_backup.name}")
    
    # Create temp dir for extraction
    temp_work = SCRIPT_DIR / "temp_work"
    if temp_work.exists(): shutil.rmtree(temp_work)
    temp_work.mkdir()
    
    try:
        # Extract Assets.zip (스마트 탐색)
        assets_zip = None
        
        # Shared 폴더에서 상위로 이동하며 Assets.zip 찾기
        current_path = game_dir
        for _ in range(6): # 최대 6단계 상위까지 검사
            check_path = current_path / "Assets.zip"
            if check_path.exists():
                assets_zip = check_path
                break
            current_path = current_path.parent
            
        if assets_zip and assets_zip.exists():
            print(f"   1) 원본(영어) 파일 추출 중... (Found: {assets_zip.name})")
            with zipfile.ZipFile(assets_zip, 'r') as zf:
                # Filter files to extract
                target_files = [f for f in zf.namelist() if f.startswith("Server/Languages/en-US/") or f.startswith("Common/Languages/en-US/")]
                zf.extractall(temp_work, members=target_files)
        else:
            print("   ⚠️ Assets.zip을 찾을 수 없습니다. 원본 병합을 건너뜁니다.")

        # Client base files
        # Shared 폴더의 상위/상위... 에서 en-US 폴더 찾기
        # 보통 .../Language/en-US 또는 .../Client/Data/Shared/../Language/en-US ??
        # macOS: Shared/Language/en-US 가 아님. Shared와 형제인 Language 폴더?
        # macOS GameDir: .../Data/Shared
        # Client En: .../Data/Shared/Language/en-US (X) -> 보통 ../Language/en-US 가 아니라 ko-KR처럼 Shared/Language/en-US 일수도 있음
        
        # macOS Install.sh 로직: CLIENT_EN_DIR="$GAME_DIR/Language/en-US"
        # 즉 .../Shared/Language/en-US
        
        client_en_dir = game_dir / "Language/en-US"
        if not client_en_dir.exists():
             # 혹시 모를 다른 구조 대비
             client_en_dir = game_dir.parent / "Language/en-US"

        if client_en_dir.exists():
            dest = temp_work / "Client"
            dest.mkdir(parents=True, exist_ok=True)
            for f in client_en_dir.glob("*.lang"):
                shutil.copy2(f, dest)
        
        print("   2) 한국어 번역 병합 (Merge) 중...")
        lang_dir.mkdir(parents=True, exist_ok=True)
        (lang_dir / "avatarCustomization").mkdir(parents=True, exist_ok=True)

        # Helper to run merge script
        merge_script = SCRIPT_DIR / "scripts/merge_lang.py"
        
        def run_merge(base, patch, out):
            if not base.exists(): 
                # Create empty if base missing
                base.parent.mkdir(parents=True, exist_ok=True)
                base.touch()
            subprocess.run([sys.executable, str(merge_script), str(base), str(patch), str(out)], check=True)

        # Merge Client
        run_merge(temp_work / "Client/client.lang", 
                  SCRIPT_DIR / "Language/ko-KR/client.lang", 
                  lang_dir / "client.lang")
        
        shutil.copy2(SCRIPT_DIR / "Language/ko-KR/meta.lang", lang_dir / "meta.lang")

        # Merge Server
        server_base = temp_work / "Server/Languages/en-US"
        server_patch = SCRIPT_DIR / "Assets/Server/Languages/ko-KR"
        for f in ["server.lang", "wordlists.lang"]:
            run_merge(server_base / f, server_patch / f, lang_dir / f)

        # Merge Avatar
        avatar_base = temp_work / "Common/Languages/en-US/avatarCustomization"
        avatar_patch = SCRIPT_DIR / "Assets/Common/Languages/ko-KR/avatarCustomization"
        
        if avatar_patch.exists():
            for patch_file in avatar_patch.glob("*.lang"):
                base_file = avatar_base / patch_file.name
                run_merge(base_file, patch_file, lang_dir / "avatarCustomization" / patch_file.name)

        print("   ✓ 언어 파일 병합 및 설치 완료")

    finally:
        if temp_work.exists(): shutil.rmtree(temp_work)

def main():
    print("=== Hytale 한글 패치 설치 (Windows) ===")
    
    # 1. Game Dir Check
    game_dir = find_game_dir()
    if not game_dir:
        input("엔터를 누르면 종료합니다...")
        sys.exit(1)
        
    # 2. Download Font
    download_font()
    
    # 3. Build Font
    try:
        build_font()
    except Exception as e:
        print(f"❌ 폰트 빌드 중 오류 발생: {e}")
        input("엔터를 누르면 종료합니다...")
        sys.exit(1)
        
    # 4. Install
    try:
        install_patch(game_dir)
    except Exception as e:
        print(f"❌ 설치 중 오류 발생: {e}")
        import traceback
        traceback.print_exc()
        input("엔터를 누르면 종료합니다...")
        sys.exit(1)
        
    print("\n✨ 설치 완료! 게임 설정에서 한국어를 선택하세요.")

if __name__ == "__main__":
    main()
