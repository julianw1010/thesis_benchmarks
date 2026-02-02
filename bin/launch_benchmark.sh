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

mkdir -p "$output_folder"

CPU_MODEL=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
echo "Detected CPU: $CPU_MODEL"
echo "Stats collection: waspd (single PMU owner, no perf stat)"

# Benchmark synchronization files
BENCH_READY="/tmp/alloctest-bench.ready"
BENCH_DONE="/tmp/alloctest-bench.done"
BENCH_PID_FILE="/tmp/alloctest-bench.pid"

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

case $mode in
    0) numactl_opts="-P";             prefix=""    ;;
    1) numactl_opts="-P -i all";      prefix="i_"  ;;
    2) numactl_opts="-r all";         prefix="r_"  ;;
    3) numactl_opts="-r all -i all";  prefix="ri_" ;;
    *) echo "Error: Invalid mode $mode (must be 0-3)"; exit 1 ;;
esac

echo -1 | sudo tee $cache_interface > /dev/null
echo 250000 | sudo tee $cache_interface > /dev/null

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
    echo "=== Running iteration=$i ==="

    rm -f "$BENCH_READY" "$BENCH_DONE" "$BENCH_PID_FILE"

    # Flush caches before every benchmark run
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

    # Reset history
    echo -1 | sudo tee $history_interface > /dev/null

    # Launch benchmark
    LAUNCH_CMD="numactl $numactl_opts /usr/bin/time -v -o ${output_folder}/time_${prefix}${i}.txt -- $cmd"
    echo "Launch command: $LAUNCH_CMD"

    script -q -f -c "$LAUNCH_CMD" "${output_folder}/output_${prefix}${i}.txt" &
    SCRIPT_PID=$!

    echo "Waiting for benchmark to be ready..."
    while [[ ! -f "$BENCH_READY" ]]; do
        if ! kill -0 $SCRIPT_PID 2>/dev/null; then
            echo "ERROR: Benchmark died before becoming ready"
            cat "${output_folder}/output_${prefix}${i}.txt"
            exit 1
        fi
        sleep 0.1
    done
    echo "Benchmark is ready!"

    if [[ ! -f "$BENCH_PID_FILE" ]]; then
        echo "ERROR: Benchmark did not write PID file"
        kill $SCRIPT_PID 2>/dev/null
        exit 1
    fi
    BENCH_PID=$(cat "$BENCH_PID_FILE")
    echo "Benchmark PID: $BENCH_PID"

    if [[ ! -d "/proc/$BENCH_PID" ]]; then
        echo "ERROR: /proc/$BENCH_PID does not exist"
        kill $SCRIPT_PID 2>/dev/null
        exit 1
    fi

    # Clean any stale waspd stats file for this PID
    rm -f "/tmp/waspd-stats-${BENCH_PID}.csv"

    # Start timing
    SECONDS=0

    echo "Waiting for benchmark to complete (waspd collects counters)..."
    while [[ ! -f "$BENCH_DONE" ]]; do
        if ! kill -0 $SCRIPT_PID 2>/dev/null; then
            echo "Benchmark process ended"
            break
        fi
        sleep 0.5
    done

    DURATION=$SECONDS

    # Wait for script to fully finish
    wait $SCRIPT_PID 2>/dev/null
    BENCH_EXIT_CODE=$?

    # Wait briefly for waspd to detect process death and write stats
    WASPD_STATS="/tmp/waspd-stats-${BENCH_PID}.csv"
    echo "Waiting for waspd stats file..."
    for attempt in $(seq 1 20); do
        if [[ -f "$WASPD_STATS" ]]; then
            break
        fi
        sleep 0.5
    done

    # Process stats
    STATS_FILE="${output_folder}/stats_${prefix}${i}.txt"
    echo "Processing profiling data..."

    {
        echo "Execution Time (seconds): $DURATION"
        echo "Benchmark Exit Code: $BENCH_EXIT_CODE"
        echo "NOTE: Counters collected by waspd (single PMU owner)"
        echo ""
        if [[ -f "$WASPD_STATS" ]]; then
            echo "=== Perf Counters (from waspd) ==="
            cat "$WASPD_STATS"
            # Copy the raw CSV too
            cp "$WASPD_STATS" "${output_folder}/perf_${prefix}${i}.csv"
        else
            echo "WARNING: waspd stats file not found at $WASPD_STATS"
            echo "Make sure waspd is running and tracking the benchmark process."
        fi
    } | tee "$STATS_FILE"

    echo ""
    echo "Statistics saved to $STATS_FILE"

    # Save history
    cat $history_interface > "${output_folder}/history_${prefix}${i}.txt"

    echo "Iteration $i completed in $DURATION seconds"
    echo ""

    # Check for interrupt
    [[ $BENCH_EXIT_CODE -eq 130 ]] && { echo "Interrupted. Exiting..."; exit 1; }
done

echo "All iterations completed."
