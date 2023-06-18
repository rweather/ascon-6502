
.PHONY: all clean

VASM = vasm6502_oldstyle
VASM_OPTS = -quiet -dotdir -Fbin -c02

all: ascon-6502.bin

ascon-6502.bin: ascon-6502.s
	$(VASM) $(VASM_OPTS) -L ascon-6502.lst -o ascon-6502.bin ascon-6502.s

clean:
	rm -f *.bin *.lst
