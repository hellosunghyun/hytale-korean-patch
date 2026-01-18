# Windows Font Patcher (version.dll)

Hytale 게임의 텍스처 크기 제한(512x512)을 4096x4096으로 확장하는 DLL입니다.

## 빌드 방법

### Visual Studio
1. 새 DLL 프로젝트 생성
2. `src/dllmain.cpp` 추가
3. 링커 설정에 `psapi.lib` 추가
4. Release x64로 빌드
5. 출력 파일을 `version.dll`로 이름 변경

### MinGW-w64
```bash
x86_64-w64-mingw32-g++ -shared -o version.dll src/dllmain.cpp -lpsapi
```

## 설치 방법

빌드된 `version.dll`을 다음 경로에 복사:
```
%APPDATA%\Hytale\install\release\package\game\latest\Client\
```

## 동작 원리

게임 바이너리에서 텍스처 크기를 설정하는 바이트 패턴을 찾아 수정합니다:

```
원본: BA 00 02 00 00 41 B8 00 02 00 00  (512x512)
수정: BA 00 20 00 00 41 B8 00 20 00 00  (8192x8192)
```

Ultimate ASI Loader 호환 방식으로, 게임 실행 시 자동으로 로드됩니다.
