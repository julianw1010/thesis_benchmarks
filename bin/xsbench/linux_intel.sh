#!/bin/bash
set -e

../launch_benchmark.sh 0 5 intel/linux/100gb ./bench_xsbench_mt -- -p 7500000 -g 200000
../launch_benchmark.sh 1 5 intel/linux/100gb ./bench_xsbench_mt -- -p 7500000 -g 200000
