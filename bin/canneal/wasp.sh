#!/bin/bash
set -e

../launch_benchmark.sh 0 5 wasp ./bench_canneal_mt 128 200000 2000 ../../datasets/canneal_40gb_int 400
../launch_benchmark.sh 1 5 wasp ./bench_canneal_mt 128 200000 2000 ../../datasets/canneal_40gb_int 400
