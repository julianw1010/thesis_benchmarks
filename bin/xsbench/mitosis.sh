#!/bin/bash
set -e

../launch_benchmark.sh 2 5 mitosis/200gb ./bench_xsbench_mt -- -p 7500000 -g 200000
../launch_benchmark.sh 3 5 mitosis/200gb ./bench_xsbench_mt -- -p 7500000 -g 200000
