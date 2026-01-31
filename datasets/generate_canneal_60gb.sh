#!/bin/bash
if [ -f canneal_60gb_int ]; then
    echo "canneal_60gb_int already exists. Skipping generation."
    exit 0
fi
[ ! -f fast_canneal_int ] && gcc -O3 -fopenmp -o fast_canneal_int fast_canneal_int.c
./fast_canneal_int 31000 31000 952000000 > canneal_60gb_int
