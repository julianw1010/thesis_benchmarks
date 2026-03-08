#!/bin/bash
set -e

../launch_benchmark.sh 0 5 linux ./bench_canneal_mt 128 2400000 2000 ../../datasets/canneal_large 2400
../launch_benchmark.sh 1 5 linux ./bench_canneal_mt 128 2400000 2000 ../../datasets/canneal_large 2400
