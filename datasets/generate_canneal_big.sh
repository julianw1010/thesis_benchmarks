#!/bin/bash
if [ -f canneal_40gb_int ]; then
    echo "canneal_40gb_int already exists. Skipping generation."
    exit 0
fi
[ ! -f fast_canneal_int ] && gcc -O3 -fopenmp -o fast_canneal_int fast_canneal_int.c
./fast_canneal_int 26000 26000 635000000 > canneal_40gb_int
