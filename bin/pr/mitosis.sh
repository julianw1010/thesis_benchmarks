#!/bin/bash
set -e
../launch_benchmark.sh 2 1 mitosis/kron29 ./bench_pr_mt -f ../../datasets/graphs/kron29.sg -n 10
../launch_benchmark.sh 3 1 mitosis/kron29 ./bench_pr_mt -f ../../datasets/graphs/kron29.sg -n 10
../launch_benchmark.sh 2 1 mitosis/uni29 ./bench_pr_mt -f ../../datasets/graphs/uni29.sg -n 10
../launch_benchmark.sh 3 1 mitosis/uni29 ./bench_pr_mt -f ../../datasets/graphs/uni29.sg -n 10
../launch_benchmark.sh 2 1 mitosis/web ./bench_pr_mt -f ../../datasets/graphs/web.sg -n 10
../launch_benchmark.sh 3 1 mitosis/web ./bench_pr_mt -f ../../datasets/graphs/web.sg -n 10
../launch_benchmark.sh 2 1 mitosis/twitter ./bench_pr_mt -f ../../datasets/graphs/twitter.sg -n 10
../launch_benchmark.sh 3 1 mitosis/twitter ./bench_pr_mt -f ../../datasets/graphs/twitter.sg -n 10
../launch_benchmark.sh 2 1 mitosis/road ./bench_pr_mt -f ../../datasets/graphs/road.sg -n 10
../launch_benchmark.sh 3 1 mitosis/road ./bench_pr_mt -f ../../datasets/graphs/road.sg -n 10
