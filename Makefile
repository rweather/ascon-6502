
.PHONY: all clean

VASM = vasm6502_oldstyle -quiet -dotdir
VASM_BIN_OPTS = -Fbin
VASM_O65_OPTS = -Fo65exe -DO65 -text=0x2000

all: ascon-test-appleii.bin ascon-test-eater6502.bin ascon-test-o65.o65

ascon-test-appleii.bin: ascon-test.s ascon-6502.s platform/appleii.s Makefile
	$(VASM) $(VASM_BIN_OPTS) -DAPPLEII -L ascon-test-appleii.lst -o ascon-test-appleii.bin ascon-test.s

ascon-test-eater6502.bin: ascon-test.s ascon-6502.s platform/eater6502.s Makefile
	$(VASM) $(VASM_BIN_OPTS) -c02 -DEATER6502 -L ascon-test-eater6502.lst -o ascon-test-eater6502.bin ascon-test.s

ascon-test-o65.o65: ascon-test.s ascon-6502.s platform/appleii.s Makefile
	$(VASM) $(VASM_O65_OPTS) -DAPPLEII -o ascon-test-o65.o65 ascon-test.s

clean:
	rm -f *.bin *.lst *.o65
