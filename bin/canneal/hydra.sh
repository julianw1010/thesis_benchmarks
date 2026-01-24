#!/bin/bash
set -e


echo 1 | sudo tee /proc/hydra/tlbflush_opt

for repl_order in {0..9}; do
    echo "=== Setting repl_order=$repl_order ==="
    echo $repl_order | sudo tee /proc/hydra/repl_order
    
    ../launch_benchmark.sh 2 3 "hydra/repl_order_${repl_order}" ./bench_canneal_mt 64 200000 2000 ../../datasets/canneal_10gb_int 400
    ../launch_benchmark.sh 3 3 "hydra/repl_order_${repl_order}" ./bench_canneal_mt 64 200000 2000 ../../datasets/canneal_10gb_int 400
done
