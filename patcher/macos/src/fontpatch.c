/**
 * Hytale Font Patch - macOS dylib
 * 게임의 텍스처 크기 제한(512x512)을 8192x8192으로 확장합니다.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <unistd.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <mach/mach.h>
#include <sys/mman.h>

#ifdef __arm64__
// ARM64 패턴: movz w1, #0x200; movz w2, #0x200
static const unsigned char PATTERN_512[] = {
    0x01, 0x40, 0x80, 0x52,
    0x02, 0x40, 0x80, 0x52
};
static const unsigned char PATTERN_8192[] = {
    0x01, 0x00, 0x84, 0x52,
    0x02, 0x00, 0x84, 0x52
};
static const size_t PATTERN_SIZE = 8;
#else
// x86_64 패턴
static const unsigned char PATTERN_512[] = {
    0xBA, 0x00, 0x02, 0x00, 0x00,
    0x41, 0xB8, 0x00, 0x02, 0x00, 0x00
};
static const unsigned char PATTERN_8192[] = {
    0xBA, 0x00, 0x20, 0x00, 0x00,
    0x41, 0xB8, 0x00, 0x20, 0x00, 0x00
};
static const size_t PATTERN_SIZE = 11;
#endif

static FILE *logfile = NULL;

static void log_msg(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);

    if (logfile) {
        vfprintf(logfile, fmt, args);
        fprintf(logfile, "\n");
        fflush(logfile);
    }

    va_end(args);
}

static int apply_patch(void) {
    // 로그 파일 열기
    const char *home = getenv("HOME");
    char logpath[512];
    snprintf(logpath, sizeof(logpath), "%s/fontpatch.log", home ? home : "/tmp");
    logfile = fopen(logpath, "w");

    log_msg("=== FontPatch started ===");
    log_msg("Architecture: %s",
#ifdef __arm64__
        "arm64"
#else
        "x86_64"
#endif
    );

    const struct mach_header_64 *header =
        (const struct mach_header_64 *)_dyld_get_image_header(0);

    if (!header) {
        log_msg("ERROR: No header");
        if (logfile) fclose(logfile);
        return -1;
    }

    intptr_t slide = _dyld_get_image_vmaddr_slide(0);
    log_msg("Header: %p, Slide: 0x%lx", (void*)header, (unsigned long)slide);

    const struct load_command *cmd =
        (const struct load_command *)((char *)header + sizeof(struct mach_header_64));

    int patch_count = 0;

    for (uint32_t i = 0; i < header->ncmds; i++) {
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64 *seg =
                (const struct segment_command_64 *)cmd;

            if (strcmp(seg->segname, "__TEXT") == 0) {
                unsigned char *base = (unsigned char *)(seg->vmaddr + slide);
                size_t size = seg->vmsize;

                log_msg("__TEXT: base=%p, size=0x%zx", (void*)base, size);

                for (size_t j = 0; j <= size - PATTERN_SIZE; j++) {
                    if (memcmp(base + j, PATTERN_512, PATTERN_SIZE) == 0) {
                        unsigned char *patch_addr = base + j;
                        log_msg("Pattern found at offset 0x%zx", j);

                        size_t page_size = getpagesize();
                        void *page_start = (void *)((uintptr_t)patch_addr & ~(page_size - 1));

                        kern_return_t kr = vm_protect(
                            mach_task_self(),
                            (vm_address_t)page_start,
                            page_size * 2,
                            FALSE,
                            VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE
                        );

                        if (kr == KERN_SUCCESS) {
                            memcpy(patch_addr, PATTERN_8192, PATTERN_SIZE);
                            vm_protect(mach_task_self(), (vm_address_t)page_start,
                                       page_size * 2, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
                            patch_count++;
                            log_msg("  -> Patched (#%d)", patch_count);
                        } else {
                            log_msg("  -> vm_protect failed: %d", kr);
                        }

                        j += PATTERN_SIZE - 1;
                    }
                }
            }
        }
        cmd = (const struct load_command *)((char *)cmd + cmd->cmdsize);
    }

    log_msg("Total patches applied: %d", patch_count);
    log_msg("=== FontPatch complete ===");

    if (logfile) fclose(logfile);
    return patch_count > 0 ? patch_count : -3;
}

__attribute__((constructor))
static void font_patch_init(void) {
    apply_patch();
}
