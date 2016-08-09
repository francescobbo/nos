all: bin/install bin/mkimage

bin/install: install.cpp
	g++ -std=c++14 -o $@ $<

bin/mkimage: mkimage.cpp
	g++ -std=c++14 -o $@ $<

clean:
	rm -f bin/install bin/mkimage
