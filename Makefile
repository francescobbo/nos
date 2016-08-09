MAKEFLAGS += -s

all:
	$(MAKE) -C boot
	$(MAKE) -C tools
	$(MAKE) -C arch/x86_64
	$(MAKE) -C kernel

	./tools/bin/install disk.img boot/stage1.o boot/stage2.o

clean:
	$(MAKE) -C boot clean
	$(MAKE) -C tools clean
	$(MAKE) -C arch/x86_64 clean
	$(MAKE) -C kernel clean
