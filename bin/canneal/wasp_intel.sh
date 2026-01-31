#!/bin/bash
set -e

../launch_benchmark.sh 0 5 wasp ./bench_canneal_mt 64 500000 2000 ../../datasets/canneal_20gb_int 2400
../launch_benchmark.sh 1 5 wasp ./bench_canneal_mt 64 500000 2000 ../../datasets/canneal_20gb_int 2400
