import os
from google import genai
import re
from dotenv import load_dotenv

load_dotenv()

MODEL_ID = os.getenv("GEMINI_MODEL_ID", "gemini-3-pro-preview")


def translate_batch(texts, api_key):
    if not texts:
        return {}
    
    client = genai.Client(api_key=api_key)
    
    prompt_prefix = """**당신은 "AAA급 샌드박스 RPG 게임 전문 로컬라이제이션 디렉터"입니다.**
당신의 임무는 제공된 영어 리소스 파일(`key = value` 형식)을 **완벽하고 자연스러운 한국어**로 번역하는 것입니다. 이 게임은 모험(Adventure), 건축(Creative), 모딩 툴(Asset Editor)이 결합된 게임(Hytale 스타일)입니다.

다음 가이드라인을 철저히 준수하십시오.

#### 1. 용어 및 고유명사 통일 (Glossary)
아래의 용어집을 최우선으로 적용하십시오.
*   **게임 모드:** Adventure Mode → 모험 모드, Creative Mode → 크리에이티브 모드
*   **종족/세력:**
    *   Kweebec → 퀴벡 (숲의 종족)
    *   Trork → 트로크 (오크/트롤 유사 종족)
    *   Feran → 페란 (여우/늑대 수인)
    *   Outlander → 아웃랜더 (적대 세력)
    *   Gaia → 가이아 / Orbis → 오르비스 (세계관 명칭)
    *   Void → 공허 / Scaraks → 스카락 (곤충형 적)
*   **시스템/툴 용어:**
    *   Prefab → 프리팹 (건축물 덩어리)
    *   Chunk → 청크 (맵 데이터 단위)
    *   Asset → 에셋
    *   Entity → 엔티티 (기술적 문맥) / 개체 (인게임 생물 문맥)
    *   Hitbox → 히트박스
    *   Spawn → 소환 (능동적) / 생성 (자동/수동적)
    *   Auth/Authentication → 인증
*   **아이템/장비 (중요 - 동음이의어 주의):**
    *   **Chest (보관함/가구) → 상자**
    *   **Chest (방어구 슬롯) → 흉갑 / 가슴**
    *   **Back (UI 버튼) → 뒤로**
    *   **Back (장비 슬롯/망토) → 등**
    *   Legs (방어구) → 하의 / 다리
    *   Hands (방어구) → 장갑 / 손

#### 2. 어조 및 톤 (Tone & Manner)
*   **UI/시스템 (간결함):** 명사형 종결을 선호합니다. (예: "Connecting..." → "연결 중...", "Settings" → "설정")
*   **설명문/Lore (몰입감):** 아이템 설명이나 `<i>...</i>` 태그 안의 텍스트는 판타지 소설처럼 서사적이고 우아하게 번역하십시오. (예: "A crude sword." → "조잡한 검입니다." 보다는 "거칠게 다듬어진 검입니다.")
*   **경고/에러:** 명확하고 정중하게 전달하십시오.

#### 3. 기술적 제약 사항 (Technical Constraints)
*   **변수 및 태그 보존:**
    *   `{{0}}`, `{{name}}`, `{{count, plural, ...}}`, `[TMP]`, `<color=...>`, `\\n` 등은 **절대 수정하거나 삭제하지 마십시오.**
    *   ICU 포맷(`{{count, plural, one {{1 item}} other {{{{count}} items}}}}`) 내부의 영어 단어(one, other 등)는 건드리지 말고, 출력되는 텍스트 부분만 한국어 어순에 맞춰 번역하십시오.
*   **식별자/아이템 ID 보존:** 밑줄(`_`)이 포함된 영문 식별자(예: `Wood_Ash_Roots`, `Battleaxe_Swing_Left`)는 **번역하지 말고 그대로 유지**하십시오.
*   **파일 구조 유지:** 입력된 `key = value` 형식을 유지하십시오. 주석(`#`)이나 빈 줄도 그대로 두십시오.

#### 4. 번역 예시 (Few-Shot Examples)

*   **입력:** `assetEditor.mainMenu.connection.connecting = Connecting to server...`
    *   **출력:** `assetEditor.mainMenu.connection.connecting = 서버에 연결 중...`
*   **입력:** `inventory.chest.title = Chest`
    *   **출력:** `inventory.chest.title = 상자`
*   **입력:** `benchCategories.Armor_Chest = Chest`
    *   **출력:** `benchCategories.Armor_Chest = 흉갑`
*   **입력:** `items.Description = <i>A sword used by ancient heroes.</i>`
    *   **출력:** `items.Description = <i>고대의 영웅들이 사용했던 검입니다.</i>`
*   **입력:** `hud.network.ping = High Latency (>200ms) - gameplay may be slow.`
    *   **출력:** `hud.network.ping = 지연 시간 매우 높음 (>200ms) - 게임 플레이가 느려질 수 있습니다.`

---

[작업 지시]
이제 위 규칙을 바탕으로 아래 내용을 번역하여 출력하십시오. **오직 번역된 결과물만 출력하십시오.**

[작업 대상]
"""
    
    content_to_translate = ""
    for i, (key, text) in enumerate(texts.items()):
        content_to_translate += f"[{i}] {text}\n"
    
    full_prompt = prompt_prefix + content_to_translate + "\n\nRespond only with the translations in the following format:\n[index] translated_text"
    
    try:
        response = client.models.generate_content(model=MODEL_ID, contents=full_prompt)
        results = {}
        translated_lines = [line.strip() for line in response.text.splitlines() if line.strip()]
        
        keys_list = list(texts.keys())
        for line in translated_lines:
            match = re.match(r'\[(\d+)\]\s*(.*)', line)
            if match:
                idx = int(match.group(1))
                if idx < len(keys_list):
                    results[keys_list[idx]] = match.group(2).strip()
        if results:
            return results

        if len(translated_lines) == len(keys_list):
            for idx, line in enumerate(translated_lines):
                cleaned = re.sub(r'^\[\d+\]\s*', '', line).strip()
                results[keys_list[idx]] = cleaned
        return results
    except Exception as e:
        print(f"Gemini translation error: {e}")
        return {}

def process_translation(file_path, api_key):
    if not os.path.exists(file_path):
        return

    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    to_translate = {}
    updates = {}

    def is_escape_only(text):
        stripped = text.strip()
        return not stripped or re.fullmatch(r'(\\[nrt])+', stripped)

    def is_identifier_example(text):
        stripped = text.strip()
        if not stripped:
            return False
        if "_" not in stripped:
            return False
        return re.fullmatch(r"[A-Za-z0-9_,\s]+", stripped) is not None

    def needs_translation(text):
        return (
            not is_escape_only(text)
            and not is_identifier_example(text)
            and not re.search(r'[가-힣]', text)
        )

    i = 0
    while i < len(lines):
        line = lines[i]
        if '# TODO: TranslateLine' in line and ' = ' not in line:
            raw = line.split(' # TODO: TranslateLine', 1)[0].rstrip('\n')
            trimmed = raw.rstrip()
            suffix = "\\" if trimmed.endswith('\\') else ""
            content = trimmed[:-1] if suffix else trimmed
            content = content.rstrip()
            if needs_translation(content):
                indent = raw[:len(raw) - len(raw.lstrip())]
                to_translate[str(i)] = content
                updates[str(i)] = {
                    "type": "line",
                    "indent": indent,
                    "suffix": suffix,
                }
            i += 1
            continue
        if '# TODO: Translate' in line and ' = ' in line:
            parts = line.split(' = ', 1)
            if len(parts) == 2:
                key_part = parts[0]
                raw_value = parts[1].split(' # TODO: Translate', 1)[0]
                raw_value = raw_value.rstrip('\n')
                line_suffix = "\\" if raw_value.rstrip().endswith('\\') else ""
                value = raw_value.rstrip().rstrip('\\').rstrip()
                to_translate[str(i)] = value
                updates[str(i)] = {
                    "type": "key",
                    "key_part": key_part,
                    "suffix": line_suffix,
                }

                if line_suffix:
                    j = i + 1
                    while j < len(lines):
                        cont_line = lines[j]
                        cont_no_nl = cont_line.rstrip('\n')
                        if ' = ' in cont_no_nl and not cont_no_nl.lstrip().startswith('#'):
                            break
                        cont_trimmed = cont_no_nl.rstrip()
                        cont_suffix = "\\" if cont_trimmed.endswith('\\') else ""
                        cont_content = cont_trimmed[:-1] if cont_suffix else cont_trimmed
                        cont_content = cont_content.rstrip()
                        if needs_translation(cont_content):
                            indent = cont_no_nl[:len(cont_no_nl) - len(cont_no_nl.lstrip())]
                            to_translate[str(j)] = cont_content
                            updates[str(j)] = {
                                "type": "cont",
                                "indent": indent,
                                "suffix": cont_suffix,
                            }
                        if not cont_suffix:
                            j += 1
                            break
                        j += 1
                    i = j
                    continue
        i += 1

    if not to_translate:
        print(f"No new strings to translate in {os.path.basename(file_path)}")
        return

    print(f"Translating {len(to_translate)} strings in {os.path.basename(file_path)} via Gemini...")
    translated_map = translate_batch(to_translate, api_key)

    for idx_str, meta in updates.items():
        if idx_str not in translated_map:
            continue
        idx = int(idx_str)
        translated = translated_map[idx_str].rstrip().rstrip('\\').rstrip()
        if meta["type"] == "key":
            suffix = meta["suffix"]
            if suffix:
                lines[idx] = f"{meta['key_part']} = {translated}\\\n"
            else:
                lines[idx] = f"{meta['key_part']} = {translated}\n"
        else:
            suffix = meta["suffix"]
            if suffix:
                lines[idx] = f"{meta['indent']}{translated}\\\n"
            else:
                lines[idx] = f"{meta['indent']}{translated}\n"

    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print(f"Successfully translated and updated {os.path.basename(file_path)}")
