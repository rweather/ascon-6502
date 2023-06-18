
.PHONY: all clean

VASM = vasm6502_oldstyle
VASM_OPTS = -quiet -dotdir -Fbin -c02

all: ascon-test.bin

ascon-test.bin: ascon-test.s ascon-6502.s
	$(VASM) $(VASM_OPTS) -L ascon-test.lst -o ascon-test.bin ascon-test.s

clean:
	rm -f *.bin *.lst
