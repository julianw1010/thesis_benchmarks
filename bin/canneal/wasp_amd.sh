#!/bin/bash
set -e

../launch_benchmark.sh 0 5 wasp ./bench_canneal_mt 128 450000 2000 ../../datasets/canneal_large 260
../launch_benchmark.sh 1 5 wasp ./bench_canneal_mt 128 450000 2000 ../../datasets/canneal_large 260
