# Makefile for OpenScad stl file construction
# For fastest build on quad-proc, use:
#   make -j4

MODELS=helmholtz.stl

all: $(MODELS)

clean:
	rm -f $(MODELS)

# Generic stl file builder
%.stl : %.scad
	openscad -o $@ $<
