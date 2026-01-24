#!/bin/bash
set -e

../launch_benchmark.sh 2 1 mitosis ./bench_cc_sv_mt -f ../../datasets/graphs/kron29.sg -n 3
../launch_benchmark.sh 3 1 mitosis ./bench_cc_sv_mt -f ../../datasets/graphs/kron29.sg -n 3
