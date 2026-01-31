#!/bin/bash
if [ -f canneal_70gb_int ]; then
    echo "canneal_70gb_int already exists. Skipping generation."
    exit 0
fi
[ ! -f fast_canneal_int ] && gcc -O3 -fopenmp -o fast_canneal_int fast_canneal_int.c
./fast_canneal_int 34000 34000 1120000000 > canneal_70gb_int
