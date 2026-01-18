/**
 * Hytale Font Patch - Windows DLL
 *
 * 게임의 텍스처 크기 제한(512x512)을 4096x4096으로 확장합니다.
 *
 * 빌드 방법:
 *   Visual Studio에서 DLL 프로젝트로 빌드하거나
 *   MinGW: g++ -shared -o version.dll dllmain.cpp -lpsapi
 *
 * 설치 방법:
 *   빌드된 version.dll을 게임의 Client 폴더에 복사합니다.
 *   (Ultimate ASI Loader 호환 방식)
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <psapi.h>

// 원본 바이트 패턴: mov edx, 0x200 (512), mov r8d, 0x200 (512)
// BA 00 02 00 00 41 B8 00 02 00 00
static const BYTE PATTERN_512[] = {
    0xBA, 0x00, 0x02, 0x00, 0x00,  // mov edx, 0x200
    0x41, 0xB8, 0x00, 0x02, 0x00, 0x00  // mov r8d, 0x200
};

// 8192 = 0x2000
static const BYTE TARGET_SIZE = 0x20;

void ApplyFontPatch() {
    MODULEINFO moduleInfo;
    HANDLE hProcess = GetCurrentProcess();
    HMODULE hModule = GetModuleHandle(NULL);

    if (!GetModuleInformation(hProcess, hModule, &moduleInfo, sizeof(moduleInfo))) {
        return;
    }

    BYTE* baseAddr = (BYTE*)moduleInfo.lpBaseOfDll;
    DWORD moduleSize = moduleInfo.SizeOfImage;
    const size_t patternSize = sizeof(PATTERN_512);

    // 메모리에서 패턴 검색
    for (DWORD i = 0; i < moduleSize - patternSize; i++) {
        BOOL found = TRUE;

        for (size_t j = 0; j < patternSize; j++) {
            if (baseAddr[i + j] != PATTERN_512[j]) {
                found = FALSE;
                break;
            }
        }

        if (found) {
            LPVOID patchAddr = (LPVOID)(baseAddr + i);
            DWORD oldProtect = 0;

            // 메모리 보호 해제 후 패치
            if (VirtualProtect(patchAddr, patternSize, PAGE_EXECUTE_READWRITE, &oldProtect)) {
                // 0x200 (512) → 0x1000 (4096)로 변경
                // offset +1: edx의 immediate 값 (0x00 0x02 → 0x00 0x10)
                // offset +7: r8d의 immediate 값 (0x00 0x02 → 0x00 0x10)
                *(BYTE*)((DWORD_PTR)patchAddr + 2) = TARGET_SIZE;
                *(BYTE*)((DWORD_PTR)patchAddr + 8) = TARGET_SIZE;

                // 메모리 보호 복원
                VirtualProtect(patchAddr, patternSize, oldProtect, &oldProtect);
            }

            return; // 첫 번째 매치만 패치
        }
    }
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved) {
    switch (ul_reason_for_call) {
    case DLL_PROCESS_ATTACH:
        DisableThreadLibraryCalls(hModule);
        ApplyFontPatch();
        break;
    case DLL_PROCESS_DETACH:
    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
        break;
    }
    return TRUE;
}
