if [ -f canneal_35gb_int ]; then
    echo "canneal_35gb_int already exists. Skipping generation."
    exit 0
fi
[ ! -f fast_canneal_int ] && gcc -O3 -fopenmp -o fast_canneal_int fast_canneal_int.c
./fast_canneal_int 19000 19000 343000000 > canneal_20gb_int
