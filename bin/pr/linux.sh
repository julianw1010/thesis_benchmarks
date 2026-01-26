#!/bin/bash
set -e

../launch_benchmark.sh 0 1 linux/kron30 ./bench_pr_mt -f ../../datasets/graphs/kron30.sg -n 3
../launch_benchmark.sh 1 1 linux/kron30 ./bench_pr_mt -f ../../datasets/graphs/kron30.sg -n 3
../launch_benchmark.sh 0 1 linux/uni30 ./bench_pr_mt -f ../../datasets/graphs/uni30.sg -n 3
../launch_benchmark.sh 1 1 linux/uni30 ./bench_pr_mt -f ../../datasets/graphs/uni30.sg -n 3
../launch_benchmark.sh 0 1 linux/web ./bench_pr_mt -f ../../datasets/graphs/web.sg -n 3
../launch_benchmark.sh 1 1 linux/web ./bench_pr_mt -f ../../datasets/graphs/web.sg -n 3
../launch_benchmark.sh 0 1 linux/twitter ./bench_pr_mt -f ../../datasets/graphs/twitter.sg -n 3
../launch_benchmark.sh 1 1 linux/twitter ./bench_pr_mt -f ../../datasets/graphs/twitter.sg -n 3
../launch_benchmark.sh 0 1 linux/road ./bench_pr_mt -f ../../datasets/graphs/road.sg -n 3
../launch_benchmark.sh 1 1 linux/road ./bench_pr_mt -f ../../datasets/graphs/road.sg -n 3
