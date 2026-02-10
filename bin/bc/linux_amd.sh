#!/bin/bash
set -e
../launch_benchmark.sh 0 1 linux/kron27 ./bench_bc_mt -f ../../datasets/graphs/kron27.sg -n 5
../launch_benchmark.sh 1 1 linux/kron27 ./bench_bc_mt -f ../../datasets/graphs/kron27.sg -n 5
../launch_benchmark.sh 0 1 linux/kron28 ./bench_bc_mt -f ../../datasets/graphs/kron28.sg -n 5
../launch_benchmark.sh 1 1 linux/kron28 ./bench_bc_mt -f ../../datasets/graphs/kron28.sg -n 5
../launch_benchmark.sh 0 1 linux/kron29 ./bench_bc_mt -f ../../datasets/graphs/kron29.sg -n 5
../launch_benchmark.sh 1 1 linux/kron29 ./bench_bc_mt -f ../../datasets/graphs/kron29.sg -n 5
../launch_benchmark.sh 0 1 linux/kron30 ./bench_bc_mt -f ../../datasets/graphs/kron30.sg -n 5
../launch_benchmark.sh 1 1 linux/kron30 ./bench_bc_mt -f ../../datasets/graphs/kron30.sg -n 5
../launch_benchmark.sh 0 1 linux/uni27 ./bench_bc_mt -f ../../datasets/graphs/uni27.sg -n 5
../launch_benchmark.sh 1 1 linux/uni27 ./bench_bc_mt -f ../../datasets/graphs/uni27.sg -n 5
../launch_benchmark.sh 0 1 linux/uni28 ./bench_bc_mt -f ../../datasets/graphs/uni28.sg -n 5
../launch_benchmark.sh 1 1 linux/uni28 ./bench_bc_mt -f ../../datasets/graphs/uni28.sg -n 5
../launch_benchmark.sh 0 1 linux/uni29 ./bench_bc_mt -f ../../datasets/graphs/uni29.sg -n 5
../launch_benchmark.sh 1 1 linux/uni29 ./bench_bc_mt -f ../../datasets/graphs/uni29.sg -n 5
../launch_benchmark.sh 0 1 linux/uni30 ./bench_bc_mt -f ../../datasets/graphs/uni30.sg -n 5
../launch_benchmark.sh 1 1 linux/uni30 ./bench_bc_mt -f ../../datasets/graphs/uni30.sg -n 5
../launch_benchmark.sh 0 1 linux/web ./bench_bc_mt -f ../../datasets/graphs/web.sg -n 5
../launch_benchmark.sh 1 1 linux/web ./bench_bc_mt -f ../../datasets/graphs/web.sg -n 5
../launch_benchmark.sh 0 1 linux/twitter ./bench_bc_mt -f ../../datasets/graphs/twitter.sg -n 5
../launch_benchmark.sh 1 1 linux/twitter ./bench_bc_mt -f ../../datasets/graphs/twitter.sg -n 5
../launch_benchmark.sh 0 1 linux/road ./bench_bc_mt -f ../../datasets/graphs/road.sg -n 5
../launch_benchmark.sh 1 1 linux/road ./bench_bc_mt -f ../../datasets/graphs/road.sg -n 5
