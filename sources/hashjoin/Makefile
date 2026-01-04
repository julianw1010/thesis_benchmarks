###############################################################################
# Makefile to build the HashJoin workload
###############################################################################

CC = gcc
CXX = g++

# Include flags if passed from parent, otherwise set default
CFLAGS ?= -O3 -march=native
CXXFLAGS ?= -O3 -march=native

# Sources for the library (excluding main.c)
LIB_SRC = src/hashjoin.c src/murmurhash.c
DEPS = src/config.h src/murmur3.h

# Object files
OBJS = $(LIB_SRC:.c=.o)
OBJS_OMP = $(LIB_SRC:.c=.omp.o)

all: libhashjoin.a libhashjoinomp.a

# Target for Single-Threaded Static Library
libhashjoin.a: $(OBJS)
	ar rcs $@ $(OBJS)

# Target for Multi-Threaded Static Library
libhashjoinomp.a: $(OBJS_OMP)
	ar rcs $@ $(OBJS_OMP)

# Compilation rule for standard objects
%.o: %.c $(DEPS)
	$(CC) $(CFLAGS) -c $< -o $@

# Compilation rule for OpenMP objects (using a different suffix to avoid conflict)
%.omp.o: %.c $(DEPS)
	$(CC) $(CFLAGS) -fopenmp -c $< -o $@

clean:
	rm -f src/*.o src/*.a *.a bin/*
