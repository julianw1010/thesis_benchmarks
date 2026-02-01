#!/bin/bash
set -e

../launch_benchmark.sh 0 5 intel/wasp/100gb ./bench_xsbench_mt -- -p 2500000 -g 60000
../launch_benchmark.sh 1 5 intel/wasp/100gb ./bench_xsbench_mt -- -p 25000000 -g 600000
