mkdir -p graphs
./generate_canneal_small.sh
./generate_canneal_tiny.sh
./generate_canneal_medium.sh
./generate_canneal_large.sh
./generate_canneal_big.sh
./generate_canneal_huge.sh
./generate_liblinear_large.sh
./generate_liblinear_small.sh
./generate_graphs.sh
make -f twitterwebroad.mk
