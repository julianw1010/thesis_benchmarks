#!/bin/bash
if [ -f canneal_30gb_int ]; then
    echo "canneal_30gb_int already exists. Skipping generation."
    exit 0
fi
[ ! -f fast_canneal_int ] && gcc -O3 -fopenmp -o fast_canneal_int fast_canneal_int.c
./fast_canneal_int 22000 22000 476000000 > canneal_30gb_int
