OUTPUT := ../nos
LDFLAGS := -z max-page-size=0x1000 -nostdlib -T ../linker.ld -L ../arch/x86_64

all: $(OUTPUT)

clean:
	rm -f $(OUTPUT)

$(OUTPUT): ../arch/x86_64/libarch.a
	$(LD) $(LDFLAGS) -larch -o $@
