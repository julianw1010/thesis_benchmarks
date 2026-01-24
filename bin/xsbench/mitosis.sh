#!/bin/bash
set -e

../launch_benchmark.sh 2 3 mitosis ./bench_xsbench_mt -- -p 25000000 -g 100000
../launch_benchmark.sh 3 3 mitosis ./bench_xsbench_mt -- -p 25000000 -g 100000
