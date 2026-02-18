#!/bin/bash
set -e

../launch_benchmark.sh 0 1 linux ./bench_xsbench_mt -- -p 2500000 -g 200000
../launch_benchmark.sh 1 1 linux ./bench_xsbench_mt -- -p 2500000 -g 200000
