#!/bin/bash
set -e

../launch_benchmark.sh 0 5 linux ./bench_canneal_mt 128 240000 2000 ../../datasets/canneal_30gb_int 240
../launch_benchmark.sh 1 5 linux ./bench_canneal_mt 128 240000 2000 ../../datasets/canneal_30gb_int 240
