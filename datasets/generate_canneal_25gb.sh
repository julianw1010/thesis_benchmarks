#!/bin/bash
if [ -f canneal_25gb_int ]; then
    echo "canneal_25gb_int already exists. Skipping generation."
    exit 0
fi
[ ! -f fast_canneal_int ] && gcc -O3 -fopenmp -o fast_canneal_int fast_canneal_int.c
./fast_canneal_int 20000 20000 397000000 > canneal_25gb_int
