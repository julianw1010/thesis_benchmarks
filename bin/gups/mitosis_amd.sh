#!/bin/bash
set -e

../launch_benchmark.sh 2 5 amd/mitosis/ ./bench_gups_mt -- 128
../launch_benchmark.sh 3 5 amd/mitosis/ ./bench_gups_mt -- 128
