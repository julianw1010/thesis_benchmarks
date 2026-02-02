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

# Detect CPU and set profiling mode
CPU_MODEL=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
echo "Detected CPU: $CPU_MODEL"

if [[ "$CPU_MODEL" == *"EPYC"* ]] || [[ "$CPU_MODEL" == *"Ryzen"* ]]; then
    PROFILE_MODE="amd_ibs"
    echo "Using AMD IBS profiling (per-process)"
elif [[ "$CPU_MODEL" == *"Xeon"* ]] || [[ "$CPU_MODEL" == *"Intel"* ]]; then
    PROFILE_MODE="intel_perf"
    PERF_EVENTS="cycles,instructions"

    # Check if this is Skylake+ (has walk_active) or older (has walk_duration)
    if perf list | grep -q 'dtlb_load_misses.walk_active'; then
        echo "Detected Skylake+ microarchitecture"
        PERF_EVENTS+=",dtlb_load_misses.walk_active"
        PERF_EVENTS+=",dtlb_store_misses.walk_active"
        PERF_EVENTS+=",itlb_misses.walk_active"
    else
        echo "Detected pre-Skylake microarchitecture"
        PERF_EVENTS+=",dtlb_load_misses.walk_duration"
        PERF_EVENTS+=",dtlb_store_misses.walk_duration"
        PERF_EVENTS+=",itlb_misses.walk_duration"
    fi

    echo "Using Intel perf counters (per-process)"
    echo "Perf events: $PERF_EVENTS"
else
    echo "Warning: Unknown CPU model, using generic perf counters"
    PROFILE_MODE="generic"
    PERF_EVENTS="cycles,instructions"
fi

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

    # Clean up synchronization files
    rm -f "$BENCH_READY" "$BENCH_DONE" "$BENCH_PID_FILE"

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

    # Read benchmark PID
    if [[ ! -f "$BENCH_PID_FILE" ]]; then
        echo "ERROR: Benchmark did not write PID file"
        kill $SCRIPT_PID 2>/dev/null
        exit 1
    fi
    BENCH_PID=$(cat "$BENCH_PID_FILE")
    echo "Benchmark PID: $BENCH_PID"

    # Verify PID is accessible before starting perf
    if [[ ! -d "/proc/$BENCH_PID" ]]; then
        echo "ERROR: /proc/$BENCH_PID does not exist — process already gone?"
        kill $SCRIPT_PID 2>/dev/null
        exit 1
    fi

    # Wait for all threads to be visible in /proc (avoids perf open failures)
    echo -n "Waiting for threads to stabilize..."
    PREV_THREADS=0
    STABLE_COUNT=0
    for attempt in $(seq 1 50); do
        CUR_THREADS=$(ls /proc/$BENCH_PID/task 2>/dev/null | wc -l)
        if [[ "$CUR_THREADS" -eq "$PREV_THREADS" && "$CUR_THREADS" -gt 0 ]]; then
            STABLE_COUNT=$((STABLE_COUNT + 1))
        else
            STABLE_COUNT=0
        fi
        PREV_THREADS=$CUR_THREADS
        # Consider stable after 3 consecutive identical readings
        if [[ $STABLE_COUNT -ge 3 ]]; then
            break
        fi
        sleep 0.1
    done
    echo " $CUR_THREADS threads found"

    # Start timing
    SECONDS=0

    # Start per-process profiling between READY and DONE
    PERF_OUTPUT="${output_folder}/perf_${prefix}${i}"
    PERF_ERR="${PERF_OUTPUT}.err"

    if [[ "$PROFILE_MODE" == "amd_ibs" ]]; then
        echo "Starting per-process IBS recording..."
        perf record -p "$BENCH_PID" -e ibs_op//p -c 10000003 -W -d -o "${PERF_OUTPUT}.data" 2>"$PERF_ERR" &
    else
        echo "Starting per-process perf stat..."
        perf stat -p "$BENCH_PID" -x, -e "$PERF_EVENTS" -o "${PERF_OUTPUT}.txt" 2>"$PERF_ERR" &
    fi
    PERF_PID=$!

    # Verify perf started
    sleep 0.2
    if ! kill -0 $PERF_PID 2>/dev/null; then
        echo "ERROR: perf failed to start"
        [[ -f "$PERF_ERR" ]] && cat "$PERF_ERR"
        kill $SCRIPT_PID 2>/dev/null
        exit 1
    fi

    echo "Profiling started (PID: $PERF_PID). Waiting for benchmark to complete..."
    while [[ ! -f "$BENCH_DONE" ]]; do
        if ! kill -0 $SCRIPT_PID 2>/dev/null; then
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

    # Check for perf errors/warnings in stderr
    if [[ -s "$PERF_ERR" ]] && grep -qi -E "fail|error|not counted|not supported|cannot" "$PERF_ERR"; then
        echo "ERROR: perf reported errors during iteration $i:"
        cat "$PERF_ERR"
        kill $SCRIPT_PID 2>/dev/null
        wait $SCRIPT_PID 2>/dev/null
        exit 1
    fi

    # Wait for script/benchmark to fully finish
    wait $SCRIPT_PID 2>/dev/null
    BENCH_EXIT_CODE=$?

    # Process profiling data
    STATS_FILE="${output_folder}/stats_${prefix}${i}.txt"
    echo "Processing profiling data..."

    if [[ "$PROFILE_MODE" == "amd_ibs" ]]; then
        {
            echo "Execution Time (seconds): $DURATION"
            perf script -i "${PERF_OUTPUT}.data" -F data_src,weight 2>/dev/null | \
                awk '/TLB L2 miss/ && $NF > 0 { sum += $NF; count++ }
                     END { printf "Walk Samples: %d\nAvg Walk Latency: %.1f cycles\n", count, count ? sum/count : 0 }'
        } | tee "$STATS_FILE"
    else
        {
            echo "Execution Time (seconds): $DURATION"
            echo "Benchmark Exit Code: $BENCH_EXIT_CODE"
            echo ""
            echo "=== Perf Counters ==="
            cat "${PERF_OUTPUT}.txt"
        } | tee "$STATS_FILE"
    fi

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
