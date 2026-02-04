#!/bin/bash
set -e

../launch_benchmark.sh 0 5 intel_4/wasp/ ./bench_hashjoin_mt -- -o 675000000 -i 135000000 -s 135000000 -n 10
../launch_benchmark.sh 1 5 intel_4/wasp/ ./bench_hashjoin_mt -- -o 675000000 -i 135000000 -s 135000000 -n 10

