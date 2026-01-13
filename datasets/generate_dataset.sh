[ ! -f fast_canneal_int ] && gcc -O3 -fopenmp -o fast_canneal_int fast_canneal_int.c
./fast_canneal_int 24000 24000 555000000 > canneal_35gb_int
