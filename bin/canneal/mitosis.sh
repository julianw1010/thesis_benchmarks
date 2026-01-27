#!/bin/bash
set -e

../launch_benchmark.sh 2 3 mitosis ./bench_canneal_mt 64 200000 2000 ../../datasets/canneal_35gb_int 400
../launch_benchmark.sh 3 3 mitosis ./bench_canneal_mt 64 200000 2000 ../../datasets/canneal_35gb_int 400
