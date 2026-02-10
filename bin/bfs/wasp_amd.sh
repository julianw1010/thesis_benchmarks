#!/bin/bash
set -e
../launch_benchmark.sh 0 1 wasp/kron27 ./bench_bfs_mt -f ../../datasets/graphs/kron27.sg -n 5
../launch_benchmark.sh 1 1 wasp/kron27 ./bench_bfs_mt -f ../../datasets/graphs/kron27.sg -n 5
../launch_benchmark.sh 0 1 wasp/kron28 ./bench_bfs_mt -f ../../datasets/graphs/kron28.sg -n 5
../launch_benchmark.sh 1 1 wasp/kron28 ./bench_bfs_mt -f ../../datasets/graphs/kron28.sg -n 5
../launch_benchmark.sh 0 1 wasp/kron29 ./bench_bfs_mt -f ../../datasets/graphs/kron29.sg -n 5
../launch_benchmark.sh 1 1 wasp/kron29 ./bench_bfs_mt -f ../../datasets/graphs/kron29.sg -n 5
../launch_benchmark.sh 0 1 wasp/kron30 ./bench_bfs_mt -f ../../datasets/graphs/kron30.sg -n 5
../launch_benchmark.sh 1 1 wasp/kron30 ./bench_bfs_mt -f ../../datasets/graphs/kron30.sg -n 5
../launch_benchmark.sh 0 1 wasp/uni27 ./bench_bfs_mt -f ../../datasets/graphs/uni27.sg -n 5
../launch_benchmark.sh 1 1 wasp/uni27 ./bench_bfs_mt -f ../../datasets/graphs/uni27.sg -n 5
../launch_benchmark.sh 0 1 wasp/uni28 ./bench_bfs_mt -f ../../datasets/graphs/uni28.sg -n 5
../launch_benchmark.sh 1 1 wasp/uni28 ./bench_bfs_mt -f ../../datasets/graphs/uni28.sg -n 5
../launch_benchmark.sh 0 1 wasp/uni29 ./bench_bfs_mt -f ../../datasets/graphs/uni29.sg -n 5
../launch_benchmark.sh 1 1 wasp/uni29 ./bench_bfs_mt -f ../../datasets/graphs/uni29.sg -n 5
../launch_benchmark.sh 0 1 wasp/uni30 ./bench_bfs_mt -f ../../datasets/graphs/uni30.sg -n 5
../launch_benchmark.sh 1 1 wasp/uni30 ./bench_bfs_mt -f ../../datasets/graphs/uni30.sg -n 5
../launch_benchmark.sh 0 1 wasp/web ./bench_bfs_mt -f ../../datasets/graphs/web.sg -n 5
../launch_benchmark.sh 1 1 wasp/web ./bench_bfs_mt -f ../../datasets/graphs/web.sg -n 5
../launch_benchmark.sh 0 1 wasp/twitter ./bench_bfs_mt -f ../../datasets/graphs/twitter.sg -n 5
../launch_benchmark.sh 1 1 wasp/twitter ./bench_bfs_mt -f ../../datasets/graphs/twitter.sg -n 5
../launch_benchmark.sh 0 1 wasp/road ./bench_bfs_mt -f ../../datasets/graphs/road.sg -n 5
../launch_benchmark.sh 1 1 wasp/road ./bench_bfs_mt -f ../../datasets/graphs/road.sg -n 5
