#!/bin/bash
if [ -f canneal_20gb_int ]; then
    echo "canneal_20gb_int already exists. Skipping generation."
    exit 0
fi
[ ! -f fast_canneal_int ] && gcc -O3 -fopenmp -o fast_canneal_int fast_canneal_int.c
./fast_canneal_int 20000 20000 317600000 > canneal_20gb_int
