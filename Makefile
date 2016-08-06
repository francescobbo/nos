MAKEFLAGS += -s

all:
	$(MAKE) -C boot
	$(MAKE) -C tools

	./tools/bin/install disk.img boot/stage1.o boot/stage2.o
