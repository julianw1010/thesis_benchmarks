#!/bin/bash
if [ -f canneal_55gb_int ]; then
    echo "canneal_55gb_int already exists. Skipping generation."
    exit 0
fi
[ ! -f fast_canneal_int ] && gcc -O3 -fopenmp -o fast_canneal_int fast_canneal_int.c
./fast_canneal_int 30000 30000 873000000 > canneal_55gb_int
