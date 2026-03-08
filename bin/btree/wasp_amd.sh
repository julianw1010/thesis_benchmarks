#!/bin/bash
set -e

../launch_benchmark.sh 0 5 wasp ./bench_btree_mt -- -n 3000000000 -l 1310000000
../launch_benchmark.sh 1 5 wasp ./bench_btree_mt -- -n 3000000000 -l 1310000000
