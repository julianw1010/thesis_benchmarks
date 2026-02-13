#!/bin/bash
set -e

../launch_benchmark.sh 0 5 linux ./bench_xsbench_mt -- -p 2500000 -g 200000
../launch_benchmark.sh 1 5 linux ./bench_xsbench_mt -- -p 2500000 -g 200000
