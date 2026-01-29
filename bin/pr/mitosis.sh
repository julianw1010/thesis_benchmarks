#!/bin/bash
set -e
../launch_benchmark.sh 2 1 mitosis/kron27 ./bench_pr_mt -f ../../datasets/graphs/kron27.sg -n 5
../launch_benchmark.sh 3 1 mitosis/kron27 ./bench_pr_mt -f ../../datasets/graphs/kron27.sg -n 5
../launch_benchmark.sh 2 1 mitosis/kron28 ./bench_pr_mt -f ../../datasets/graphs/kron28.sg -n 5
../launch_benchmark.sh 3 1 mitosis/kron28 ./bench_pr_mt -f ../../datasets/graphs/kron28.sg -n 5
../launch_benchmark.sh 2 1 mitosis/uni27 ./bench_pr_mt -f ../../datasets/graphs/uni27.sg -n 5
../launch_benchmark.sh 3 1 mitosis/uni27 ./bench_pr_mt -f ../../datasets/graphs/uni27.sg -n 5
../launch_benchmark.sh 2 1 mitosis/uni28 ./bench_pr_mt -f ../../datasets/graphs/uni28.sg -n 5
../launch_benchmark.sh 3 1 mitosis/uni28 ./bench_pr_mt -f ../../datasets/graphs/uni28.sg -n 5
../launch_benchmark.sh 2 1 mitosis/web ./bench_pr_mt -f ../../datasets/graphs/web.sg -n 5
../launch_benchmark.sh 3 1 mitosis/web ./bench_pr_mt -f ../../datasets/graphs/web.sg -n 5
../launch_benchmark.sh 2 1 mitosis/twitter ./bench_pr_mt -f ../../datasets/graphs/twitter.sg -n 5
../launch_benchmark.sh 3 1 mitosis/twitter ./bench_pr_mt -f ../../datasets/graphs/twitter.sg -n 5
../launch_benchmark.sh 2 1 mitosis/road ./bench_pr_mt -f ../../datasets/graphs/road.sg -n 5
../launch_benchmark.sh 3 1 mitosis/road ./bench_pr_mt -f ../../datasets/graphs/road.sg -n 5
