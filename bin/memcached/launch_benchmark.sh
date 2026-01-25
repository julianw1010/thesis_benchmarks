#!/bin/bash

# Disable job control (prevents "Killed" messages)
set +m

# Cleanup function
cleanup() {
    echo ""
    echo "Caught interrupt, cleaning up..."
    sudo pkill -9 -f '[b]ench_memcached' 2>/dev/null || true
    sudo pkill -9 -f '[b]ench_memtier' 2>/dev/null || true
    wait 2>/dev/null || true
    # Reset terminal in case script command messed it up
    stty sane 2>/dev/null || true
    exit 1
}

# Trap Ctrl+C and other termination signals
trap cleanup SIGINT SIGTERM EXIT

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
echo -1 | sudo tee $cache_interface > /dev/null
echo 500000 | sudo tee $cache_interface > /dev/null

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

# Function to kill memcached silently using setsid to fully detach
kill_memcached() {
    sudo pkill -9 -f '[b]ench_memcached' 2>/dev/null || true
}

for ((i=start; i<=max_index; i++)); do
    echo "=== Running iteration=$i ==="

    # Kill any existing memcached
    echo "Stopping any existing memcached..."
    kill_memcached
    sleep 2

    # Wait for port to be free
    port_wait=0
    while ss -tln | grep -q ':11211 '; do
        echo "Waiting for port 11211 to be free..."
        kill_memcached
        sleep 1
        port_wait=$((port_wait + 1))
        if [[ $port_wait -gt 30 ]]; then
            echo "Error: Port 11211 still in use after 30 seconds"
            exit 1
        fi
    done

    # Flush caches
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

    # Reset history
    echo -1 | sudo tee $history_interface

    # Launch memcached with appropriate numactl options (background, with timing)
    echo "Starting memcached with numactl $numactl_opts..."
    numactl $numactl_opts /usr/bin/time --verbose -- ./bench_memcached -m 220000 -t 32 -p 11211 -c 8192 -o hashpower=31 > "${output_folder}/output_${prefix}${i}.txt" 2>&1 &
    memcached_pid=$!

    # Wait for memcached to actually be listening
    echo "Waiting for memcached to be ready..."
    for attempt in {1..30}; do
        if ss -tln | grep -q ':11211 '; then
            echo "memcached is ready (attempt $attempt)"
            break
        fi
        sleep 1
    done

    # Final check - is memcached actually listening?
    if ! ss -tln | grep -q ':11211 '; then
        echo "Error: memcached failed to bind to port 11211"
        exit 1
    fi

    # Populate memcached (SET operations)
    echo "Populating memcached..."
    ./bench_memtier \
        -s localhost -p 11211 --protocol=memcache_text \
        --key-minimum=1 --key-maximum=100000000 --key-pattern=P:P \
        --ratio=1:0 --data-size=24 \
        --threads=10 --clients=10 \
        -n 1000000 --hide-histogram

    # Run benchmark (GET operations)
    echo "Running benchmark..."
    ./bench_memtier \
        -s localhost -p 11211 --protocol=memcache_text \
        --key-minimum=1 --key-maximum=100000000 --key-pattern=R:R \
        --ratio=0:1 --data-size=24 --threads=32 --clients=20 \
        --pipeline=100 --test-time=10

    # Kill memcached and wait for time stats to be written
    kill_memcached
    wait $memcached_pid 2>/dev/null || true
    sleep 0.5

    # Save history
    cat $history_interface > "${output_folder}/history_${prefix}${i}.txt"

    echo "=== Iteration $i complete ==="
done

# Remove EXIT trap before normal exit to avoid duplicate cleanup
trap - EXIT

# Cleanup: kill memcached at the end
kill_memcached

echo "All runs completed. Results saved to: $output_folder"
