#!/bin/bash
set -e

../launch_benchmark.sh 2 5 intel_4/mitosis/ ./bench_hashjoin_mt -- -o 675000000 -i 135000000 -s 135000000 -n 10
../launch_benchmark.sh 3 5 intel_4/mitosis/ ./bench_hashjoin_mt -- -o 675000000 -i 135000000 -s 135000000 -n 10

