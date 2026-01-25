#!/bin/bash
set -e

../launch_benchmark.sh 0 1 linux/kron29 ./bench_pr_mt -f ../../datasets/graphs/kron29.sg -n 10
../launch_benchmark.sh 1 1 linux/kron29 ./bench_pr_mt -f ../../datasets/graphs/kron29.sg -n 10
../launch_benchmark.sh 0 1 linux/uni29 ./bench_pr_mt -f ../../datasets/graphs/uni29.sg -n 10
../launch_benchmark.sh 1 1 linux/uni29 ./bench_pr_mt -f ../../datasets/graphs/uni29.sg -n 10
../launch_benchmark.sh 0 1 linux/web ./bench_pr_mt -f ../../datasets/graphs/web.sg -n 10
../launch_benchmark.sh 1 1 linux/web ./bench_pr_mt -f ../../datasets/graphs/web.sg -n 10
../launch_benchmark.sh 0 1 linux/twitter ./bench_pr_mt -f ../../datasets/graphs/twitter.sg -n 10
../launch_benchmark.sh 1 1 linux/twitter ./bench_pr_mt -f ../../datasets/graphs/twitter.sg -n 10
../launch_benchmark.sh 0 1 linux/road ./bench_pr_mt -f ../../datasets/graphs/road.sg -n 10
../launch_benchmark.sh 1 1 linux/road ./bench_pr_mt -f ../../datasets/graphs/road.sg -n 10
