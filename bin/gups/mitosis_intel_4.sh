#!/bin/bash
set -e

../launch_benchmark.sh 2 5 intel_4/mitosis/ ./bench_gups_mt -- 64 10000000000
../launch_benchmark.sh 3 5 intel_4/mitosis/ ./bench_gups_mt -- 64 10000000000

