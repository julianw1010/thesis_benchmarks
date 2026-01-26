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

# Extract the executable name (first part of cmd, without path)
# Handle "-- " prefix if present
cmd_clean="${cmd#-- }"
cmd_clean="${cmd_clean#--}"
cmd_clean="${cmd_clean# }"
CMD_EXECUTABLE=$(echo "$cmd_clean" | awk '{print $1}')
CMD_BASENAME=$(basename "$CMD_EXECUTABLE")

# Create output folder if it doesn't exist
mkdir -p "$output_folder"

# Perf events for page table replication analysis (AMD EPYC)
PERF_EVENTS="cycles,instructions,l1_dtlb_misses,l2_dtlb_misses,bp_l1_tlb_miss_l2_tlb_hit,bp_l1_tlb_miss_l2_tlb_miss,ls_tablewalker.dside,ls_tablewalker.iside,ls_any_fills_from_sys.mem_io_local,ls_any_fills_from_sys.mem_io_remote"

# Benchmark synchronization files
BENCH_READY="/tmp/alloctest-bench.ready"
BENCH_DONE="/tmp/alloctest-bench.done"

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
echo "Command: $cmd"
echo "Looking for process: $CMD_BASENAME"

for ((i=start; i<=max_index; i++)); do
    echo "=== Running iteration=$i ==="
    
    # Clean up synchronization files (benchmark creates these)
    rm -f "$BENCH_READY" "$BENCH_DONE"
    
    # Flush caches before every benchmark run
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    
    # Reset history
    echo -1 | sudo tee $history_interface > /dev/null
    
    # Launch benchmark with script for live output
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
    
    # Find the benchmark PID by executable name
    # Note: Linux truncates comm to 15 chars, so we match the first 15 chars
    CMD_MATCH="${CMD_BASENAME:0:15}"
    BENCHMARK_PID=$(pgrep "^${CMD_MATCH}" 2>/dev/null | head -1)
    
    if [[ -z "$BENCHMARK_PID" ]]; then
        echo "ERROR: Could not find benchmark PID for '$CMD_MATCH'"
        kill $SCRIPT_PID 2>/dev/null
        exit 1
    fi
    
    echo "Benchmark PID: $BENCHMARK_PID"
    
    # Start timing
    SECONDS=0
    
    # Start perf monitoring on the benchmark process
    echo "Starting perf on PID $BENCHMARK_PID..."
    perf stat -x, -e "$PERF_EVENTS" -p $BENCHMARK_PID -o "${output_folder}/perf_${prefix}${i}.txt" 2>&1 &
    PERF_PID=$!
    
    # Verify perf started
    sleep 0.2
    if ! kill -0 $PERF_PID 2>/dev/null; then
        echo "ERROR: perf failed to start"
        cat "${output_folder}/perf_${prefix}${i}.txt" 2>/dev/null
        kill $SCRIPT_PID 2>/dev/null
        exit 1
    fi
    
    echo "Perf monitoring started (PID: $PERF_PID). Waiting for benchmark to complete..."
    while [[ ! -f "$BENCH_DONE" ]]; do
        if ! kill -0 $BENCHMARK_PID 2>/dev/null; then
            echo "Benchmark process ended"
            break
        fi
        sleep 0.5
    done
    
    DURATION=$SECONDS
    
    # Stop perf gracefully
    kill -INT $PERF_PID 2>/dev/null
    sleep 0.5
    wait $PERF_PID 2>/dev/null
    
    # Wait for script/benchmark to fully finish
    wait $SCRIPT_PID 2>/dev/null
    BENCH_EXIT_CODE=$?
    
    # Append execution time to perf output
    echo "" >> "${output_folder}/perf_${prefix}${i}.txt"
    echo "Execution Time (seconds): $DURATION" >> "${output_folder}/perf_${prefix}${i}.txt"
    echo "Benchmark Exit Code: $BENCH_EXIT_CODE" >> "${output_folder}/perf_${prefix}${i}.txt"
    
    # Save history
    cat $history_interface > "${output_folder}/history_${prefix}${i}.txt"
    
    echo "Iteration $i completed in $DURATION seconds"
    echo ""
    
    # Check for interrupt
    [[ $BENCH_EXIT_CODE -eq 130 ]] && { echo "Interrupted. Exiting..."; exit 1; }
done

echo "All iterations completed."
