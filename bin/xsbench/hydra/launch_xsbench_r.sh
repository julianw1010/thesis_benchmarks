#!/bin/bash
echo -1 | sudo tee /proc/hydra/cache
echo 500000 | sudo tee /proc/hydra/cache
# Set tlbflush opt once
echo 1 | sudo tee /proc/hydra/tlbflush_opt

# Find the starting point based on existing history files
start_i=0
start_j=0
for i in {9..0}; do
    for j in {2..0}; do
        if [[ -f "history_${i}_${j}.txt" ]]; then
            if [[ $j -eq 2 ]]; then
                start_i=$((i + 1))
                start_j=0
            else
                start_i=$i
                start_j=$((j + 1))
            fi
            break 2
        fi
    done
done

if [[ $start_i -gt 9 ]]; then
    echo "All runs (0-9, 3 iterations each) already completed."
    exit 0
fi

echo "Continuing from i=$start_i, j=$start_j"

for i in $(seq $start_i 9); do
    j_start=0
    [[ $i -eq $start_i ]] && j_start=$start_j
    
    for j in $(seq $j_start 2); do
        [[ $? -eq 130 ]] && { echo "Interrupted. Exiting..."; exit 1; }
        echo "=== Running with repl_order=$i, iteration=$j ==="
        
        # Flush caches before every benchmark run
        sync
        echo 3 | sudo tee /proc/sys/vm/drop_caches
        
        # Reset history
        echo -1 | sudo tee /proc/hydra/history
        
        # Set replication order
        echo $i | sudo tee /proc/hydra/repl_order
        
        # Run benchmark
        script -e -q -c "numactl -r all /usr/bin/time --verbose -- ../bench_xsbench_mt -- -p 25000000 -g 400000" output_${i}_${j}.txt
        [[ $? -eq 130 ]] && { echo "Interrupted. Exiting..."; exit 1; }
        
        # Save history with suffix
        cat /proc/hydra/history > history_${i}_${j}.txt
    done
done
