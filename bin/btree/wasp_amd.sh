#!/bin/bash
set -e

../launch_benchmark.sh 0 5 wasp ./bench_btree_mt -- -n 1500000000
../launch_benchmark.sh 1 5 wasp ./bench_btree_mt -- -n 1500000000
