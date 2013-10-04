# Makefile for OpenScad stl file construction
# For fastest build on quad-proc, use:
#   make -j4


MODELS=helmholtz whistle

FILES=$(foreach f, $(MODELS), $(f).stl)

all: $(FILES)

clean:
	rm -f $(FILES)

# Generic stl file builder
%.stl : %.scad
	openscad -o $@ $<
