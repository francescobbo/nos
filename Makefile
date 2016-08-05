MAKEFLAGS += -s

all:
	$(MAKE) -C boot
	$(MAKE) -C tools

