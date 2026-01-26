#!/bin/bash
set -e

../launch_benchmark.sh 0 3 linux/50gb ./bench_xsbench_mt -- -p 250000 -g 10000
../launch_benchmark.sh 1 3 linux/50gb ./bench_xsbench_mt -- -p 25000000 -g 100000
../launch_benchmark.sh 0 3 linux/100gb ./bench_xsbench_mt -- -p 25000000 -g 200000
../launch_benchmark.sh 1 3 linux/100gb ./bench_xsbench_mt -- -p 25000000 -g 200000
../launch_benchmark.sh 0 3 linux/200gb ./bench_xsbench_mt -- -p 25000000 -g 400000
../launch_benchmark.sh 1 3 linux/200gb ./bench_xsbench_mt -- -p 25000000 -g 400000
