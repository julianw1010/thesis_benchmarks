#!/bin/bash
set -e

../launch_benchmark.sh 0 5 intel_4/linux/100gb ./bench_gups_mt -- 64 10000000000
../launch_benchmark.sh 1 5 intel_4/linux/100gb ./bench_gups_mt -- 64 10000000000

