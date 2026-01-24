#!/bin/bash

# Check for required arguments
if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <mode> <num_runs> <output_folder>"
    echo "  mode 0: First touch (numactl -P)"
    echo "  mode 1: Interleave (numactl -P -i all)"
    echo "  mode 2: First touch + replication (numactl -r all)"
    echo "  mode 3: Interleave + replication (numactl -r all -i all)"
    exit 1
fi

mode=$1
num_runs=$2
output_folder=$3
max_index=$((num_runs - 1))

# Create output folder if it doesn't exist
mkdir -p "$output_folder"

# Detect cache interface
if [[ -f /proc/mitosis/cache ]]; then
    cache_interface="/proc/mitosis/cache"
    history_interface="/proc/mitosis/history"
elif [[ -f /proc/hydra/cache ]]; then
    cache_interface="/proc/hydra/cache"
    history_interface="/proc/hydra/history"
else
    echo "Error: Neither /proc/mitosis/cache nor /proc/hydra/cache found"
    exit 1
fi
echo "Using interface: $cache_interface"

# Set numactl options and file prefix based on mode
case $mode in
    0)
        numactl_opts="-P"
        prefix=""
        ;;
    1)
        numactl_opts="-P -i all"
        prefix="i_"
        ;;
    2)
        numactl_opts="-r all"
        prefix="r_"
        ;;
    3)
        numactl_opts="-r all -i all"
        prefix="ri_"
        ;;
    *)
        echo "Error: Invalid mode $mode (must be 0-3)"
        exit 1
        ;;
esac

# Initialize cache
echo -1 | sudo tee $cache_interface
echo 500000 | sudo tee $cache_interface

# Find the starting point based on existing history files
start=0
for ((i=max_index; i>=0; i--)); do
    if [[ -f "${output_folder}/history_${prefix}${i}.txt" ]]; then
        start=$((i + 1))
        break
    fi
done

if [[ $start -gt $max_index ]]; then
    echo "All runs (0-$max_index) already completed for mode $mode."
    exit 0
fi

echo "Continuing from i=$start"
echo "Mode: $mode, numactl options: $numactl_opts"
echo "Output folder: $output_folder"

for ((i=start; i<=max_index; i++)); do
    [[ $? -eq 130 ]] && { echo "Interrupted. Exiting..."; exit 1; }
    echo "=== Running iteration=$i ==="

    # Kill any existing memcached
    sudo pkill memcached
    sleep 1

    # Flush caches
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches

    # Reset history
    echo -1 | sudo tee $history_interface

    # Launch memcached with appropriate numactl options (daemon mode, suppress output)
    echo "Starting memcached with numactl $numactl_opts..."
    numactl $numactl_opts -- memcached -m 220000 -t 32 -p 11211 -c 8192 -o hashpower=31 -d > /dev/null 2>&1
    sleep 2

    # Check if memcached started successfully
    if ! pgrep -x memcached > /dev/null; then
        echo "Error: memcached failed to start"
        exit 1
    fi

    # Populate memcached (SET operations)
    echo "Populating memcached..."
    memtier_benchmark \
        -s localhost -p 11211 --protocol=memcache_text \
        --key-minimum=1 --key-maximum=1730000000 --key-pattern=P:P \
        --ratio=1:0 --data-size=24 --threads=128 --clients=20 \
        --pipeline=100 -n 680000 --hide-histogram

    [[ $? -eq 130 ]] && { echo "Interrupted. Exiting..."; exit 1; }

    # Run benchmark (GET operations) with timing
    echo "Running benchmark..."
    script -e -q -c "/usr/bin/time --verbose -- memtier_benchmark \
        -s localhost -p 11211 --protocol=memcache_text \
        --key-minimum=1 --key-maximum=1730000000 --key-pattern=R:R \
        --ratio=0:1 --data-size=24 --threads=32 --clients=20 \
        --pipeline=100 --test-time=300" "${output_folder}/output_${prefix}${i}.txt"

    [[ $? -eq 130 ]] && { echo "Interrupted. Exiting..."; exit 1; }

    # Save history
    cat $history_interface > "${output_folder}/history_${prefix}${i}.txt"

    echo "=== Iteration $i complete ==="
done

# Cleanup: kill memcached at the end
sudo pkill memcached

echo "All runs completed. Results saved to: $output_folder"
