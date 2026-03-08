#!/bin/bash
set -e

../launch_benchmark.sh 2 5 mitosis ./bench_hashjoin_mt -- -o 1659000000 -i 100000000 -s 100000000 -n 7
../launch_benchmark.sh 3 5 mitosis ./bench_hashjoin_mt -- -o 1659000000 -i 100000000 -s 100000000 -n 7
