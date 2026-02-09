if [ -f canneal_3gb_int ]; then
    echo "canneal_3gb_int already exists. Skipping generation."
    exit 0
fi
[ ! -f fast_canneal_int ] && gcc -O3 -fopenmp -o fast_canneal_int fast_canneal_int.c
./fast_canneal_int 7800 7800 57700000 > canneal_small
