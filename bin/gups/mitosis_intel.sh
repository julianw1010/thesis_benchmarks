#!/bin/bash
set -e

../launch_benchmark.sh 2 5 intel/mitosis/100gb ./bench_xsbench_mt -- -p 25000000 -g 600000
../launch_benchmark.sh 3 5 intel/mitosis/100gb ./bench_xsbench_mt -- -p 25000000 -g 600000
