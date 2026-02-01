#!/bin/bash
set -e

../launch_benchmark.sh 2 5 intel_4/mitosis/100gb ./bench_xsbench_mt -- -p 10000000 -g 200000
../launch_benchmark.sh 3 5 intel_4/mitosis/100gb ./bench_xsbench_mt -- -p 10000000 -g 200000
