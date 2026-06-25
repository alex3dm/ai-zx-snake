# Tools
ASM = pasmo
EMULATOR = fuse

# Files
SOURCE = src/main.asm
OUTPUT = build/game.tap
SNA_OUTPUT = build/game.sna

# Flags
ASM_FLAGS = --tapbas

.PHONY: all clean run

all: $(OUTPUT)

$(OUTPUT): $(SOURCE)
	@mkdir -p build
	$(ASM) $(ASM_FLAGS) $(SOURCE) $(OUTPUT)
	@echo "Build complete: $(OUTPUT)"

run: $(OUTPUT)
	$(EMULATOR) $(OUTPUT)

# Отладочная сборка с символами
debug: $(SOURCE)
	@mkdir -p build
	$(ASM) $(ASM_FLAGS) --err $(SOURCE) $(OUTPUT)

clean:
	rm -rf build/

# Размер бинарника
size: $(OUTPUT)
	@ls -la $(OUTPUT)