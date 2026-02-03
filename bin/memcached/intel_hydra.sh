#!/bin/bash
set -e


echo 1 | sudo tee /proc/hydra/tlbflush_opt

for repl_order in 9; do
    echo "=== Setting repl_order=$repl_order ==="
    echo $repl_order | sudo tee /proc/hydra/repl_order
    
    ./launch_benchmark_intel.sh 2 3 "intel/hydra/repl_order_${repl_order}"
    ./launch_benchmark_intel.sh 3 3 "intel/hydra/repl_order_${repl_order}"
done
