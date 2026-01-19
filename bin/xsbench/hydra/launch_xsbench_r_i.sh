#!/bin/bash
interrupted=0
trap "interrupted=1; echo 'Interrupted. Exiting...'" SIGINT
echo -1 | sudo tee /proc/hydra/cache
echo 500000 | sudo tee /proc/hydra/cache

sync
echo 3 | sudo tee /proc/sys/vm/drop_caches

# Set tlbflush opt once
echo 1 | sudo tee /proc/hydra/tlbflush_opt

# Find the starting point based on existing history files
start=0
for i in {9..0}; do
    if [[ -f "history_i_${i}.txt" ]]; then
        start=$((i + 1))
        break
    fi
done

if [[ $start -gt 9 ]]; then
    echo "All runs (0-9) already completed."
    exit 0
fi

echo "Continuing from i=$start"

for i in $(seq $start 9); do
    [[ $? -eq 130 ]] && { echo "Interrupted. Exiting..."; exit 1; }
    echo "=== Running with repl_order=$i ==="
    
    # Reset history
    echo -1 | sudo tee /proc/hydra/history
    
    # Set replication order
    echo $i | sudo tee /proc/hydra/repl_order
    
    # Run benchmark
    script -e -q -c "numactl -r all -i all /usr/bin/time --verbose -- ../bench_xsbench_mt -- -p 25000000 -g 400000" output_i_${i}.txt
    [[ $? -eq 130 ]] && { echo "Interrupted. Exiting..."; exit 1; }
    
    # Save history with suffix
    cat /proc/hydra/history > history_i_${i}.txt
done
