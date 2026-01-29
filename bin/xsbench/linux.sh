#!/bin/bash
set -e

../launch_benchmark.sh 0 5 linux/200gb ./bench_xsbench_mt -- -p 5000000 -g 200000
../launch_benchmark.sh 1 5 linux/200gb ./bench_xsbench_mt -- -p 5000000 -g 200000
