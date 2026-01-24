#!/bin/bash
set -e


echo 1 | sudo tee /proc/hydra/tlbflush_opt

for repl_order in {0..9}; do
    echo "=== Setting repl_order=$repl_order ==="
    echo $repl_order | sudo tee /proc/hydra/repl_order
    
    ../launch_benchmark.sh 2 1 "hydra/repl_order_${repl_order}" ./bench_pr_spmv_mt -f ../../datasets/graphs/kron29.sg -n 3
    ../launch_benchmark.sh 3 1 "hydra/repl_order_${repl_order}" ./bench_pr_spmv_mt -f ../../datasets/graphs/kron29.sg -n 3
done
