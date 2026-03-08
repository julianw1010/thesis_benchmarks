#!/bin/bash
set -e

../launch_benchmark.sh 0 5 linux ./bench_hashjoin_mt -- -o 1659000000 -i 100000000 -s 100000000 -n 7
../launch_benchmark.sh 1 5 linux ./bench_hashjoin_mt -- -o 1659000000 -i 100000000 -s 100000000 -n 7

