
.PHONY: all clean

VASM = vasm6502_oldstyle -quiet -dotdir -c02
VASM_BIN_OPTS = -Fbin
VASM_O65_OPTS = -Fo65exe -DO65 -text=0x2000

all: ascon-test.bin ascon-test.o65

ascon-test.bin: ascon-test.s ascon-6502.s Makefile
	$(VASM) $(VASM_BIN_OPTS) -L ascon-test.lst -o ascon-test.bin ascon-test.s

ascon-test.o65: ascon-test.s ascon-6502.s Makefile
	$(VASM) $(VASM_O65_OPTS) -o ascon-test.o65 ascon-test.s

clean:
	rm -f *.bin *.lst *.o65
