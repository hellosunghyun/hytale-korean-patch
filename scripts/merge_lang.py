#!/usr/bin/env python3
import sys
import os

def load_translations(patch_file):
    """
    번역 파일(patch_file)을 읽어서 {key: value} 딕셔너리로 반환합니다.
    주석이나 빈 줄은 무시합니다.
    """
    translations = {}
    if not os.path.exists(patch_file):
        return translations

    try:
        with open(patch_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                if '=' in line:
                    key, value = line.split('=', 1)
                    translations[key.strip()] = value.strip()
    except Exception as e:
        print(f"⚠️  번역 파일 읽기 오류 ({patch_file}): {e}", file=sys.stderr)
    
    return translations

def merge_lang_files(base_file, patch_file, output_file):
    """
    base_file(원본 영어)을 한 줄씩 읽으면서,
    patch_file(한국어)에 해당 키가 있다면 값을 교체하여
    output_file에 씁니다.
    """
    translations = load_translations(patch_file)
    replaced_count = 0
    total_count = 0

    # 출력 디렉토리 생성
    os.makedirs(os.path.dirname(output_file), exist_ok=True)

    try:
        with open(base_file, 'r', encoding='utf-8') as f_in, \
             open(output_file, 'w', encoding='utf-8') as f_out:
            
            for line in f_in:
                stripped = line.strip()
                
                # 주석이나 빈 줄은 그대로 복사
                if not stripped or stripped.startswith('#'):
                    f_out.write(line)
                    continue

                # 키-값 쌍인 경우 처리
                if '=' in stripped:
                    total_count += 1
                    key, original_val = stripped.split('=', 1)
                    key = key.strip()
                    
                    if key in translations:
                        # 번역이 있으면 교체 (줄바꿈 유지 등을 위해 포맷팅 주의)
                        # 원본 라인의 앞 공백(들여쓰기) 등은 유지하기 어려우므로 표준 포맷으로 작성
                        # Hytale은 보통 "key=value" 또는 "key = value" 사용
                        # 여기서는 깔끔하게 "key = value"로 통일하거나 원본 스타일 유지 가능
                        # 안전하게 새로 작성:
                        new_value = translations[key]
                        f_out.write(f"{key} = {new_value}\n")
                        replaced_count += 1
                    else:
                        # 번역 없으면 원본(영어) 유지
                        f_out.write(line)
                else:
                    # 포맷을 알 수 없는 줄은 그대로 복사
                    f_out.write(line)

        print(f"   ✓ 병합 완료: {os.path.basename(output_file)} (번역률: {replaced_count}/{total_count})")

    except Exception as e:
        print(f"❌ 병합 실패: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: python3 merge_lang.py <base_en_US> <patch_ko_KR> <output_ko_KR>")
        sys.exit(1)
    
    merge_lang_files(sys.argv[1], sys.argv[2], sys.argv[3])
