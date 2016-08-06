all: stage1.o stage2.o

stage1.o: stage1.asm
	nasm -fbin $< -o $@

stage2.o: stage2.asm
	nasm -fbin $< -o $@
