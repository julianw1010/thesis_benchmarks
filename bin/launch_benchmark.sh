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
    PROFILE_MODE="none"
    echo "AMD CPU detected, skipping profiling"
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
BENCH_FLUSHED="/tmp/alloctest-bench.flushed"
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

    rm -f "$BENCH_READY" "$BENCH_FLUSHED" "$BENCH_DONE" "$BENCH_PID_FILE"

    # Reset history
    echo -1 | sudo tee $history_interface > /dev/null

    # Launch benchmark (caches are flushed AFTER the benchmark signals ready)
    LAUNCH_CMD="numactl-wasp $numactl_opts /usr/bin/time -v -o ${output_folder}/time_${prefix}${i}.txt -- $cmd"
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

    # Flush caches now that the benchmark has allocated/initialized
    echo "Flushing page cache..."
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    touch "$BENCH_FLUSHED"
    echo "Caches flushed, benchmark signaled to proceed"

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

    # Start SYSTEM-WIDE perf between READY and DONE (Intel/generic only)
    # NOTE: "trap - INT" resets SIGINT from SIG_IGN (inherited from non-interactive
    # bash backgrounding) back to default, so kill -INT works later.
    PERF_OUTPUT="${output_folder}/perf_${prefix}${i}"
    PERF_ERR="${PERF_OUTPUT}.err"
    PERF_PID=""

    if [[ "$PROFILE_MODE" != "none" ]]; then
        echo "Starting system-wide perf stat..."
        (trap - INT; exec perf stat -a -x, -e "$PERF_EVENTS" -o "${PERF_OUTPUT}.txt") 2>"$PERF_ERR" &
        PERF_PID=$!

        sleep 0.2
        if ! kill -0 $PERF_PID 2>/dev/null; then
            echo "ERROR: perf failed to start"
            [[ -f "$PERF_ERR" ]] && cat "$PERF_ERR"
            kill $SCRIPT_PID 2>/dev/null
            exit 1
        fi
        echo "Profiling started (perf PID: $PERF_PID, system-wide)"
    fi

    echo "Waiting for benchmark to complete..."
    wait $SCRIPT_PID
    BENCH_EXIT_CODE=$?

    DURATION=$SECONDS

    # Check if benchmark signaled completion properly
    if [[ ! -f "$BENCH_DONE" ]]; then
        echo "WARNING: Benchmark exited without writing DONE file (exit code: $BENCH_EXIT_CODE)"
        BENCH_CRASHED=1
    else
        BENCH_CRASHED=0
    fi

    # Stop perf gracefully (if it was started)
    if [[ -n "$PERF_PID" ]]; then
        stop_perf $PERF_PID
        wait $PERF_PID 2>/dev/null

        if [[ -s "$PERF_ERR" ]] && grep -qi -E "fail|error|not counted|not supported|cannot" "$PERF_ERR"; then
            echo "ERROR: perf reported errors during iteration $i:"
            cat "$PERF_ERR"
            exit 1
        fi

        # Validate perf output exists and is non-empty
        if [[ ! -s "${PERF_OUTPUT}.txt" ]]; then
            echo "ERROR: perf output file missing or empty for iteration $i"
            echo "--- perf stderr ---"
            cat "$PERF_ERR" 2>/dev/null
            echo "---"
            exit 1
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
    fi

    # Collect stats
    STATS_FILE="${output_folder}/stats_${prefix}${i}.txt"
    echo "Processing profiling data..."

    {
        echo "Execution Time (seconds): $DURATION"
        echo "Benchmark Exit Code: $BENCH_EXIT_CODE"
        if [[ $BENCH_CRASHED -eq 1 ]]; then
            echo "WARNING: Benchmark crashed (no DONE file). Results may be partial."
        fi
        echo ""
        if [[ -n "$PERF_PID" ]]; then
            echo "=== Perf Counters (system-wide) ==="
            cat "${PERF_OUTPUT}.txt"
        else
            echo "(No profiling data — AMD CPU)"
        fi
    } | tee "$STATS_FILE"

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
