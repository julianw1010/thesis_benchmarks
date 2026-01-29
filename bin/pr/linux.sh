#!/bin/bash
set -e

../launch_benchmark.sh 0 1 linux/kron27 ./bench_pr_mt -f ../../datasets/graphs/kron27.sg -n 5
../launch_benchmark.sh 1 1 linux/kron27 ./bench_pr_mt -f ../../datasets/graphs/kron27.sg -n 5
../launch_benchmark.sh 0 1 linux/kron28 ./bench_pr_mt -f ../../datasets/graphs/kron28.sg -n 5
../launch_benchmark.sh 1 1 linux/kron28 ./bench_pr_mt -f ../../datasets/graphs/kron28.sg -n 5
../launch_benchmark.sh 0 1 linux/uni27 ./bench_pr_mt -f ../../datasets/graphs/uni27.sg -n 5
../launch_benchmark.sh 1 1 linux/uni27 ./bench_pr_mt -f ../../datasets/graphs/uni27.sg -n 5
../launch_benchmark.sh 0 1 linux/uni28 ./bench_pr_mt -f ../../datasets/graphs/uni28.sg -n 5
../launch_benchmark.sh 1 1 linux/uni28 ./bench_pr_mt -f ../../datasets/graphs/uni28.sg -n 5
../launch_benchmark.sh 0 1 linux/web ./bench_pr_mt -f ../../datasets/graphs/web.sg -n 5
../launch_benchmark.sh 1 1 linux/web ./bench_pr_mt -f ../../datasets/graphs/web.sg -n 5
../launch_benchmark.sh 0 1 linux/twitter ./bench_pr_mt -f ../../datasets/graphs/twitter.sg -n 5
../launch_benchmark.sh 1 1 linux/twitter ./bench_pr_mt -f ../../datasets/graphs/twitter.sg -n 5
../launch_benchmark.sh 0 1 linux/road ./bench_pr_mt -f ../../datasets/graphs/road.sg -n 5
../launch_benchmark.sh 1 1 linux/road ./bench_pr_mt -f ../../datasets/graphs/road.sg -n 5
