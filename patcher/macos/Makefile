# Hytale Font Patch - macOS dylib Makefile
# Universal binary (x86_64 + arm64)

CC = clang
CFLAGS = -Wall -O2 -fPIC
LDFLAGS = -dynamiclib

SRC = src/fontpatch.c
OUTPUT = libfontpatch.dylib

# Universal binary
ARCHS = -arch x86_64 -arch arm64

.PHONY: all clean

all: $(OUTPUT)

$(OUTPUT): $(SRC)
	$(CC) $(CFLAGS) $(ARCHS) $(LDFLAGS) -o $@ $<

# Single architecture builds
x86_64: $(SRC)
	$(CC) $(CFLAGS) -arch x86_64 $(LDFLAGS) -o libfontpatch_x86_64.dylib $<

arm64: $(SRC)
	$(CC) $(CFLAGS) -arch arm64 $(LDFLAGS) -o libfontpatch_arm64.dylib $<

clean:
	rm -f $(OUTPUT) libfontpatch_x86_64.dylib libfontpatch_arm64.dylib
