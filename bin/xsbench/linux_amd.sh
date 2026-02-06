#!/bin/bash
set -e

../launch_benchmark.sh 0 5 amd/linux/ ./bench_xsbench_mt -- -p 25000000 -g 400000 -t 32
../launch_benchmark.sh 1 5 amd/linux/ ./bench_xsbench_mt -- -p 25000000 -g 400000 -t 32
