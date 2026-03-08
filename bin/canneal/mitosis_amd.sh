#!/bin/bash
set -e

../launch_benchmark.sh 2 5 mitosis ./bench_canneal_mt 128 450000 2000 ../../datasets/canneal_large 260
../launch_benchmark.sh 3 5 mitosis ./bench_canneal_mt 128 450000 2000 ../../datasets/canneal_large 260
