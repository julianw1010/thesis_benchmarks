#!/bin/bash

# Set tlbflush opt once
echo 1 | sudo tee /proc/hydra/tlbflush_opt

for i in {0..9}; do
    echo "=== Running with repl_order=$i ==="
    
    # Reset history
    echo -1 | sudo tee /proc/hydra/history
    
    # Set replication order
    echo $i | sudo tee /proc/hydra/repl_order
    
    # Run benchmark
    numactl -r all -i all /usr/bin/time --verbose -- ../bench_xsbench_mt -- -p 25000000 -g 400000
    
    # Save history with suffix
    cat /proc/hydra/history > history_i_${i}.txt
done
