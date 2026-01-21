#!/bin/bash
echo -1 | sudo tee /proc/mitosis/cache
echo 500000 | sudo tee /proc/mitosis/cache

# Find the starting point based on existing history files
start=0
for i in {4..0}; do
    if [[ -f "history_${i}.txt" ]]; then
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
    script -e -q -c "numactl -P /usr/bin/time --verbose -- ../bench_canneal_mt 128 200000 2000 ../../../datasets/canneal_35gb_int 1000" output_${i}.txt
    [[ $? -eq 130 ]] && { echo "Interrupted. Exiting..."; exit 1; }
    
    # Save history with suffix
    cat /proc/mitosis/history > history_${i}.txt
done
