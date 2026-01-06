#===============================================================================
# User Options
#===============================================================================
OPTIMIZE    = yes
DEBUG       = no
PROFILE     = no
MPI         = no
PAPI        = no
VEC_INFO    = no
VERIFY      = no
BINARY_DUMP = no
BINARY_READ = no

#===============================================================================
# Program name & source code list
#===============================================================================
program = XSBench

source = \
Main.c \
io.c \
Simulation.c \
CalculateXS.c \
GridInit.c \
XSutils.c \
Materials.c

#===============================================================================
# Sets Flags
#===============================================================================

CC = gcc

# Base flags
BASE_CFLAGS := -std=gnu99 -Wall

# Debug Flags
ifeq ($(DEBUG),yes)
  BASE_CFLAGS += -g
  LDFLAGS += -g
endif

# Profiling Flags
ifeq ($(PROFILE),yes)
  BASE_CFLAGS += -pg
  LDFLAGS += -pg
endif

# Optimization Flags
ifeq ($(OPTIMIZE),yes)
  BASE_CFLAGS += -O3
endif

# Linker Flags
LDFLAGS = -lm

# PAPI
ifeq ($(PAPI),yes)
  source += papi.c
  BASE_CFLAGS += -DPAPI
  LDFLAGS += -lpapi
endif

# MPI
ifeq ($(MPI),yes)
  CC = mpicc
  BASE_CFLAGS += -DMPI
endif

# Verification
ifeq ($(VERIFY),yes)
  BASE_CFLAGS += -DVERIFICATION
endif

# Binary dump/read
ifeq ($(BINARY_DUMP),yes)
  BASE_CFLAGS += -DBINARY_DUMP
endif
ifeq ($(BINARY_READ),yes)
  BASE_CFLAGS += -DBINARY_READ
endif

#===============================================================================
# OpenMP and non-OpenMP flags
#===============================================================================

CFLAGS_OMP := $(BASE_CFLAGS) -fopenmp -flto
CFLAGS_ST := $(BASE_CFLAGS) -flto

#===============================================================================
# Object files
#===============================================================================

obj_omp = $(source:.c=_omp.o)
obj_st = $(source:.c=_st.o)

#===============================================================================
# Targets to Build
#===============================================================================

$(program): $(obj_omp) XSbench_header.h Makefile
	$(CC) $(CFLAGS_OMP) $(obj_omp) -o $@ $(LDFLAGS)

libxsbenchomp.a: $(obj_omp) XSbench_header.h Makefile
	ar rcs $@ $(obj_omp)

libxsbench.a: $(obj_st) XSbench_header.h Makefile
	ar rcs $@ $(obj_st)

%_omp.o: %.c XSbench_header.h Makefile
	$(CC) $(CFLAGS_OMP) -c $< -o $@

%_st.o: %.c XSbench_header.h Makefile
	$(CC) $(CFLAGS_ST) -c $< -o $@

clean:
	rm -rf $(program) *_omp.o *_st.o *.a

edit:
	vim -p $(source) papi.c XSbench_header.h

run:
	./$(program)
