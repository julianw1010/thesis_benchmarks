#!/bin/bash

# Check for required arguments
if [[ $# -lt 4 ]]; then
    echo "Usage: $0 <mode> <num_runs> <output_folder> <command...>"
    echo "  mode 0: First touch (numactl -P)"
    echo "  mode 1: Interleave (numactl -P -i all)"
    echo "  mode 2: First touch + replication (numactl -r all)"
    echo "  mode 3: Interleave + replication (numactl -r all -i all)"
    exit 1
fi

mode=$1
num_runs=$2
output_folder=$3
shift 3
cmd="$@"

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
echo "Command: $cmd"

for ((i=start; i<=max_index; i++)); do
    [[ $? -eq 130 ]] && { echo "Interrupted. Exiting..."; exit 1; }
    echo "=== Running iteration=$i ==="
    
    # Flush caches before every benchmark run
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches
    
    # Reset history
    echo -1 | sudo tee $history_interface
    
    # Run benchmark
    script -e -q -c "numactl $numactl_opts /usr/bin/time --verbose -- $cmd" "${output_folder}/output_${prefix}${i}.txt"
    [[ $? -eq 130 ]] && { echo "Interrupted. Exiting..."; exit 1; }
    
    # Save history with suffix
    cat $history_interface > "${output_folder}/history_${prefix}${i}.txt"
done
