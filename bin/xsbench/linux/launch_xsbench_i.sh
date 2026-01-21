#!/bin/bash
echo -1 | sudo tee /proc/mitosis/cache
echo 500000 | sudo tee /proc/mitosis/cache

# Find the starting point based on existing history files
start=0
for i in {4..0}; do
    if [[ -f "history_i_${i}.txt" ]]; then
        start=$((i + 1))
        break
    fi
done

if [[ $start -gt 4 ]]; then
    echo "All runs (0-4) already completed."
    exit 0
fi

echo "Continuing from i=$start"

for i in $(seq $start 4); do
    [[ $? -eq 130 ]] && { echo "Interrupted. Exiting..."; exit 1; }
    echo "=== Running iteration=$i ==="
    
    # Flush caches before every benchmark run
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches
    
    # Reset history
    echo -1 | sudo tee /proc/mitosis/history
    
    # Run benchmark
    script -e -q -c "numactl -P -i all /usr/bin/time --verbose -- ../bench_xsbench_mt -- -p 25000000 -g 400000" output_${i}.txt
    [[ $? -eq 130 ]] && { echo "Interrupted. Exiting..."; exit 1; }
    
    # Save history with suffix
    cat /proc/mitosis/history > history_i_${i}.txt
done
