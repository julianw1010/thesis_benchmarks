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

NUM_CPUS=$(nproc)

# Determine perf events based on CPU
if [[ "$CPU_MODEL" == *"EPYC"* ]] || [[ "$CPU_MODEL" == *"Ryzen"* ]]; then
    PROFILE_MODE="amd_ibs"
    echo "Using AMD IBS profiling (system-wide)"
elif [[ "$CPU_MODEL" == *"Xeon"* ]] || [[ "$CPU_MODEL" == *"Intel"* ]]; then
    PROFILE_MODE="intel_perf"

    if perf list | grep -q 'dtlb_load_misses.walk_active'; then
        echo "Detected Skylake+ microarchitecture"
        PERF_EVENTS="cycles,dtlb_load_misses.walk_active"
    else
        echo "Detected pre-Skylake microarchitecture"
        PERF_EVENTS="cycles,dtlb_load_misses.walk_duration"
    fi

    echo "Perf events: $PERF_EVENTS"
else
    echo "Warning: Unknown CPU model, using generic perf counters"
    PROFILE_MODE="generic"
    PERF_EVENTS="cycles"
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

# Helper: gracefully stop perf (SIGINT only — it's the only signal that flushes properly)
stop_perf() {
    local pid=$1
    local timeout=30
    kill -INT "$pid" 2>/dev/null
    for attempt in $(seq 1 $((timeout * 2))); do
        kill -0 "$pid" 2>/dev/null || return 0
        sleep 0.5
    done
    echo "ERROR: perf (PID $pid) did not exit after ${timeout}s on SIGINT. Aborting."
    echo "       Manual intervention required: kill -INT $pid"
    exit 1
}

for ((i=start; i<=max_index; i++)); do
    echo "=== Running iteration=$i ==="

    rm -f "$BENCH_READY" "$BENCH_DONE" "$BENCH_PID_FILE"

    # Flush caches before every benchmark run
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

    # Reset history
    echo -1 | sudo tee $history_interface > /dev/null

    # Launch benchmark
    LAUNCH_CMD="numactl --physcpubind=0,1,4,5,8,9,12,13,16,17,20,21,24,25,28,29,32,33,36,37,40,41,44,45,48,49,52,53,56,57,60,61 $numactl_opts /usr/bin/time -v -o ${output_folder}/time_${prefix}${i}.txt -- $cmd"
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

    # Wait for all threads to stabilize
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
        if [[ $STABLE_COUNT -ge 3 ]]; then
            break
        fi
        sleep 0.1
    done
    echo " $CUR_THREADS threads found"

    # Start timing
    SECONDS=0

    # Start SYSTEM-WIDE perf between READY and DONE
    # NOTE: "trap - INT" resets SIGINT from SIG_IGN (inherited from non-interactive
    # bash backgrounding) back to default, so kill -INT works later.
    PERF_OUTPUT="${output_folder}/perf_${prefix}${i}"
    PERF_ERR="${PERF_OUTPUT}.err"

    if [[ "$PROFILE_MODE" == "amd_ibs" ]]; then
        echo "Starting system-wide IBS recording..."
        (trap - INT; exec perf record -a -e ibs_op//p -c 10000003 -W -d -o "${PERF_OUTPUT}.data") 2>"$PERF_ERR" &
    else
        echo "Starting system-wide perf stat..."
        (trap - INT; exec perf stat -a -x, -e "$PERF_EVENTS" -o "${PERF_OUTPUT}.txt") 2>"$PERF_ERR" &
    fi
    PERF_PID=$!

    sleep 0.2
    if ! kill -0 $PERF_PID 2>/dev/null; then
        echo "ERROR: perf failed to start"
        [[ -f "$PERF_ERR" ]] && cat "$PERF_ERR"
        kill $SCRIPT_PID 2>/dev/null
        exit 1
    fi
    echo "Profiling started (perf PID: $PERF_PID, system-wide)"

    echo "Waiting for benchmark to complete..."
    BENCH_CRASHED=0
    while [[ ! -f "$BENCH_DONE" ]]; do
        if ! kill -0 $SCRIPT_PID 2>/dev/null; then
            echo "WARNING: Benchmark process ended without writing DONE file (likely crashed)"
            BENCH_CRASHED=1
            break
        fi
        sleep 0.5
    done

    DURATION=$SECONDS

    # Stop perf gracefully
    stop_perf $PERF_PID
    wait $PERF_PID 2>/dev/null

    if [[ -s "$PERF_ERR" ]] && grep -qi -E "fail|error|not counted|not supported|cannot" "$PERF_ERR"; then
        echo "ERROR: perf reported errors during iteration $i:"
        cat "$PERF_ERR"
        kill $SCRIPT_PID 2>/dev/null
        wait $SCRIPT_PID 2>/dev/null
        exit 1
    fi

    # Validate perf output exists and is non-empty
    if [[ "$PROFILE_MODE" == "intel_perf" || "$PROFILE_MODE" == "generic" ]]; then
        if [[ ! -s "${PERF_OUTPUT}.txt" ]]; then
            echo "ERROR: perf output file missing or empty for iteration $i"
            echo "--- perf stderr ---"
            cat "$PERF_ERR" 2>/dev/null
            echo "---"
            kill $SCRIPT_PID 2>/dev/null
            wait $SCRIPT_PID 2>/dev/null
            exit 1
        fi
    elif [[ "$PROFILE_MODE" == "amd_ibs" ]]; then
        if [[ ! -s "${PERF_OUTPUT}.data" ]]; then
            echo "ERROR: perf record output missing or empty for iteration $i"
            echo "--- perf stderr ---"
            cat "$PERF_ERR" 2>/dev/null
            echo "---"
            kill $SCRIPT_PID 2>/dev/null
            wait $SCRIPT_PID 2>/dev/null
            exit 1
        fi
    fi

    # Kill benchmark process tree now that we have all the data we need
    echo "Cleaning up benchmark processes..."
    kill -TERM $SCRIPT_PID $BENCH_PID 2>/dev/null
    pkill -TERM -P $SCRIPT_PID 2>/dev/null
    sleep 0.5
    kill -KILL $SCRIPT_PID $BENCH_PID 2>/dev/null
    pkill -KILL -P $SCRIPT_PID 2>/dev/null
    wait $SCRIPT_PID 2>/dev/null

    # Determine exit code
    if [[ $BENCH_CRASHED -eq 1 ]]; then
        BENCH_EXIT_CODE=139
    else
        BENCH_EXIT_CODE=0
    fi

    # Validate perf counter multiplexing (Intel only)
    if [[ "$PROFILE_MODE" == "intel_perf" ]]; then
        FIRST_LINE=$(grep -m1 'cycles' "${PERF_OUTPUT}.txt" 2>/dev/null)
        if [[ -n "$FIRST_LINE" ]]; then
            MUX_PCT=$(echo "$FIRST_LINE" | awk -F, '{printf "%.1f", $5}')
            echo "Perf stat scaling: ${MUX_PCT}% time on HW (perf auto-scales values)"
            MUX_LOW=$(awk "BEGIN { print ($MUX_PCT + 0 < 10) ? 1 : 0 }")
            if [[ "$MUX_LOW" -eq 1 ]]; then
                echo "WARNING: Heavy multiplexing (${MUX_PCT}% on HW). Scaled values may be noisy."
            fi
        fi
    fi

    # Collect stats
    STATS_FILE="${output_folder}/stats_${prefix}${i}.txt"
    echo "Processing profiling data..."

    if [[ "$PROFILE_MODE" == "amd_ibs" ]]; then
        {
            echo "Execution Time (seconds): $DURATION"
            echo "Benchmark Exit Code: $BENCH_EXIT_CODE"
            if [[ $BENCH_CRASHED -eq 1 ]]; then
                echo "WARNING: Benchmark crashed (no DONE file). Results may be partial."
            fi
            echo ""
            perf script -i "${PERF_OUTPUT}.data" -F data_src,weight 2>/dev/null | \
                awk '/TLB L2 miss/ && $NF > 0 { sum += $NF; count++ }
                     END { printf "Walk Samples: %d\nAvg Walk Latency: %.1f cycles\n", count, count ? sum/count : 0 }'
        } | tee "$STATS_FILE"
    else
        {
            echo "Execution Time (seconds): $DURATION"
            echo "Benchmark Exit Code: $BENCH_EXIT_CODE"
            if [[ $BENCH_CRASHED -eq 1 ]]; then
                echo "WARNING: Benchmark crashed (no DONE file). Results may be partial."
            fi
            echo ""
            echo "=== Perf Counters (system-wide) ==="
            cat "${PERF_OUTPUT}.txt"
        } | tee "$STATS_FILE"
    fi

    echo ""
    echo "Statistics saved to $STATS_FILE"

    # Save history
    cat $history_interface > "${output_folder}/history_${prefix}${i}.txt"

    if [[ $BENCH_CRASHED -eq 1 ]]; then
        echo "WARNING: Iteration $i completed in $DURATION seconds BUT benchmark crashed."
        echo "         Check ${output_folder}/output_${prefix}${i}.txt for details."
    else
        echo "Iteration $i completed in $DURATION seconds"
    fi
    echo ""
done

echo "All iterations completed."
