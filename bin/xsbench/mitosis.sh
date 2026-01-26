#!/bin/bash
set -e

../launch_benchmark.sh 2 3 mitosis/50gb ./bench_xsbench_mt -- -p 25000000 -g 100000
../launch_benchmark.sh 3 3 mitosis/50gb ./bench_xsbench_mt -- -p 25000000 -g 100000
../launch_benchmark.sh 2 3 mitosis/100gb ./bench_xsbench_mt -- -p 25000000 -g 200000
../launch_benchmark.sh 3 3 mitosis/100gb ./bench_xsbench_mt -- -p 25000000 -g 200000
../launch_benchmark.sh 2 3 mitosis/200gb ./bench_xsbench_mt -- -p 25000000 -g 400000
../launch_benchmark.sh 3 3 mitosis/200gb ./bench_xsbench_mt -- -p 25000000 -g 400000
