ASM = nasm
ASMFLAGS = -f elf64 -w+all -w+error -w-unknown-warning -w-reloc-rel

LD = ld
LDFLAGS = --fatal-warnings

TARGET = freverse
SRC = freverse.asm
OBJ = freverse.o

.PHONY: all clean

all: $(TARGET)

$(OBJ): $(SRC)
	$(ASM) $(ASMFLAGS) -o $@ $<

$(TARGET): $(OBJ)
	$(LD) $(LDFLAGS) -o $@ $^

clean:
	rm -f $(OBJ) $(TARGET)
	
