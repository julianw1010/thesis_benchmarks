#!/bin/bash
set -e

../launch_benchmark.sh 0 1 linux ./bench_bfs_mt -f ../../datasets/graphs/kron29.sg -n 3
../launch_benchmark.sh 1 1 linux ./bench_bfs_mt -f ../../datasets/graphs/kron29.sg -n 3
