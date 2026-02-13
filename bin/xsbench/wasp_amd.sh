#!/bin/bash
set -e

../launch_benchmark.sh 0 5 wasp ./bench_xsbench_mt -- -p 25000000 -g 600000
../launch_benchmark.sh 1 5 wasp ./bench_xsbench_mt -- -p 25000000 -g 600000
