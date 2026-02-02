#!/bin/bash
set -e

../launch_benchmark.sh 2 5 intel/mitosis ./bench_canneal_mt 64 500000 2000 ../../datasets/canneal_20gb_int 2400
../launch_benchmark.sh 3 5 intel/mitosis ./bench_canneal_mt 64 500000 2000 ../../datasets/canneal_20gb_int 2400
