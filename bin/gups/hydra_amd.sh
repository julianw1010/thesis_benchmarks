#!/bin/bash
set -e


echo 1 | sudo tee /proc/hydra/tlbflush_opt

for repl_order in 9; do
    echo "=== Setting repl_order=$repl_order ==="
    echo $repl_order | sudo tee /proc/hydra/repl_order

    ../launch_benchmark.sh 2 5 "amd/hydra/repl_order_${repl_order}/" ./bench_gups_mt -- 128
    ../launch_benchmark.sh 3 5 "amd/hydra/repl_order_${repl_order}/" ./bench_gups_mt -- 128
done
