MAKEFLAGS += -s

all:
	$(MAKE) -C boot
	$(MAKE) -C tools

	./tools/bin/install disk.img boot/bootsector.o

