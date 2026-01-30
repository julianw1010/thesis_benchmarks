#!/bin/bash
set -e

../launch_benchmark.sh 2 5 mitosis ./bench_canneal_mt 128 200000 2000 ../../datasets/canneal_40gb_int 400
../launch_benchmark.sh 3 5 mitosis ./bench_canneal_mt 128 200000 2000 ../../datasets/canneal_40gb_int 400
