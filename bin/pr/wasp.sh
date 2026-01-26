#!/bin/bash
set -e
../launch_benchmark.sh 0 1 wasp/kron30 ./bench_pr_mt -f ../../datasets/graphs/kron30.sg -n 3
../launch_benchmark.sh 1 1 wasp/kron30 ./bench_pr_mt -f ../../datasets/graphs/kron30.sg -n 3
../launch_benchmark.sh 0 1 wasp/uni30 ./bench_pr_mt -f ../../datasets/graphs/uni30.sg -n 3
../launch_benchmark.sh 1 1 wasp/uni30 ./bench_pr_mt -f ../../datasets/graphs/uni30.sg -n 3
../launch_benchmark.sh 0 1 wasp/web ./bench_pr_mt -f ../../datasets/graphs/web.sg -n 3
../launch_benchmark.sh 1 1 wasp/web ./bench_pr_mt -f ../../datasets/graphs/web.sg -n 3
../launch_benchmark.sh 0 1 wasp/twitter ./bench_pr_mt -f ../../datasets/graphs/twitter.sg -n 3
../launch_benchmark.sh 1 1 wasp/twitter ./bench_pr_mt -f ../../datasets/graphs/twitter.sg -n 3
../launch_benchmark.sh 0 1 wasp/road ./bench_pr_mt -f ../../datasets/graphs/road.sg -n 3
../launch_benchmark.sh 1 1 wasp/road ./bench_pr_mt -f ../../datasets/graphs/road.sg -n 3
