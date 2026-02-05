#!/bin/bash
set -e

../launch_benchmark.sh 0 5 amd/linux/ ./bench_gups_mt -- 128
../launch_benchmark.sh 1 5 amd/linux/ ./bench_gups_mt -- 128
