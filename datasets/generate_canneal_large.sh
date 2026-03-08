if [ -f canneal_large ]; then
    echo "canneal_35gb_int already exists. Skipping generation."
    exit 0
fi
[ ! -f fast_canneal_int ] && gcc -O3 -fopenmp -o fast_canneal_int fast_canneal_int.c
./fast_canneal_int 29000 29000 816000000 > canneal_large
