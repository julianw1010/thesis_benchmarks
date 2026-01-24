#!/bin/bash

# Create subfolders if they don't exist
mkdir -p canneal btree hashjoin gups redis xsbench pr stream liblinear memcached
mkdir -p bc bfs cc cc_sv pr_spmv

# Move benchmarks to their respective subfolders
mv bench_canneal_* canneal/ 2>/dev/null
mv bench_btree_* btree/ 2>/dev/null
mv bench_hashjoin_* hashjoin/ 2>/dev/null
mv bench_gups_* gups/ 2>/dev/null
mv bench_redis_* redis/ 2>/dev/null
mv bench_xsbench_* xsbench/ 2>/dev/null
mv bench_liblinear_* liblinear/ 2>/dev/null
mv bench_stream stream/ 2>/dev/null
mv bench_memcached memcached/ 2>/dev/null
mv bench_memtier memcached/ 2>/dev/null

# GAP benchmarks (order matters: longer prefixes first)
mv bench_pr_spmv_* pr_spmv/ 2>/dev/null
mv bench_pr_* pr/ 2>/dev/null
mv bench_bc_* bc/ 2>/dev/null
mv bench_bfs_* bfs/ 2>/dev/null
mv bench_cc_sv_* cc_sv/ 2>/dev/null
mv bench_cc_* cc/ 2>/dev/null
