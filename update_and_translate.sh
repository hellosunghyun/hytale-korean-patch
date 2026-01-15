#!/bin/bash

echo "🚀 Hytale 최신 언어 파일 업데이트를 시작합니다..."

echo "📥 저장소 최신 상태를 가져오는 중..."
git pull origin master

echo "📦 필수 패키지 확인 및 설치 중..."
python3 -m pip install -q requests google-genai python-dotenv --break-system-packages

# .env 파일이 없으면 참고 경로에서 복사 시도
if [ ! -f .env ] && [ -f /Users/hellosunghyun/Documents/Github/hytale/work/.env ]; then
    cp /Users/hellosunghyun/Documents/Github/hytale/work/.env .env
    echo "📄 .env 파일을 작업 폴더에서 가져왔습니다."
fi

# .env 파일 존재 시 로딩
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

if [ -z "$GEMINI_API_KEY" ]; then
    echo "⚠️ GEMINI_API_KEY 환경 변수가 설정되어 있지 않습니다."
    echo "💡 자동 번역을 사용하려면 API 키를 설정해주세요: export GEMINI_API_KEY='your_key_here'"
fi

echo "🔍 로컬에 설치된 Hytale 데이터를 확인하고 비교하는 중..."
python3 scripts/update_lang.py

if [ $? -eq 0 ]; then
    echo "✅ 최신 파일 비교 및 병합 완료!"
    
    DIFF_COUNT=$(git status --porcelain Language/ko-KR | wc -l)
    
    if [ $DIFF_COUNT -gt 0 ]; then
        echo "✨ 새로운 번역 대상(Key)이 발견되었습니다!"
        git status Language/ko-KR
        echo "------------------------------------------"
        echo "💡 Language/ko-KR 폴더의 파일을 확인하세요."
    else
        echo "😎 이미 최신 빌드이며, 추가된 키가 없습니다."
    fi
else
    echo "❌ 업데이트 중 오류가 발생했습니다. 로그를 확인해 주세요."
    exit 1
fi

echo "🏁 완료!"
