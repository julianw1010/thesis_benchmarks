#!/bin/bash
set -e

../launch_benchmark.sh 2 3 mitosis ./bench_btree_mt -- -n 1500000000
../launch_benchmark.sh 3 3 mitosis ./bench_btree_mt -- -n 1500000000
