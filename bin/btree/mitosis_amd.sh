#!/bin/bash
set -e

../launch_benchmark.sh 2 5 mitosis ./bench_btree_mt -- -n 3000000000 -l 1310000000
../launch_benchmark.sh 3 5 mitosis ./bench_btree_mt -- -n 3000000000 -l 1310000000
