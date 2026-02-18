#!/bin/bash
set -e

../launch_benchmark.sh 2 1 mitosis ./bench_xsbench_mt -- -p 2500000 -g 200000
../launch_benchmark.sh 3 1 mitosis ./bench_xsbench_mt -- -p 2500000 -g 200000
