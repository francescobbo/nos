CXX := x86_64-elf-g++
OUTPUT := libarch.a
SOURCES := $(shell find . -type f -name "*.cpp")
OBJECTS := $(SOURCES:.cpp=.o)
CXXFLAGS := -ffreestanding -mcmodel=large -mno-red-zone -c

all: $(OUTPUT)

clean:
	rm -f $(OUTPUT) $(OBJECTS)

$(OUTPUT): $(OBJECTS)
	$(AR) -crv $@ $(OBJECTS) > /dev/null

.cpp.o:
	$(CXX) $(CXXFLAGS) $< -o $@
