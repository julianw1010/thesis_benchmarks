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

# Determine reset interface based on kernel version
KERNEL_VERSION=$(uname -r)
if [[ "$KERNEL_VERSION" == *"wasp"* ]]; then
    reset_interface="/proc/mitosis/reset"
elif [[ "$KERNEL_VERSION" == *"hydra"* ]]; then
    reset_interface="/proc/hydra/reset"
else
    echo "Error: uname -r ('$KERNEL_VERSION') contains neither 'wasp' nor 'hydra'"
    exit 1
fi
echo "Using reset interface: $reset_interface"

# Determine perf events based on CPU
if [[ "$CPU_MODEL" == *"EPYC"* ]] || [[ "$CPU_MODEL" == *"Ryzen"* ]]; then
    PROFILE_MODE="amd_perf"
    echo "AMD CPU detected"

    # Group 1: Data cache fills by source (the key mitosis metric)
    # Group 2: TLB misses, page walks, cycles, instructions
    # Split into two groups to minimize multiplexing on 6 PMC counters
    PERF_EVENTS_G1="ls_dmnd_fills_from_sys.lcl_l2,ls_dmnd_fills_from_sys.int_cache,ls_dmnd_fills_from_sys.ext_cache_local,ls_dmnd_fills_from_sys.ext_cache_remote,ls_dmnd_fills_from_sys.mem_io_local,ls_dmnd_fills_from_sys.mem_io_remote"
    PERF_EVENTS_G2="cycles,instructions,l2_dtlb_misses,ls_tablewalker.dside,ls_tablewalker.iside,stalled-cycles-backend"

    PERF_EVENTS="${PERF_EVENTS_G1},${PERF_EVENTS_G2}"
    echo "Perf events: $PERF_EVENTS"

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

# Select numactl variant based on output folder
if [[ "$output_folder" == *"hydra"* ]]; then
    NUMACTL_BIN="numactl-hydra"
else
    NUMACTL_BIN="numactl-wasp"
fi
echo "Using numactl binary: $NUMACTL_BIN"

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

    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

    # Launch benchmark (caches are flushed AFTER the benchmark signals ready)
    LAUNCH_CMD="$NUMACTL_BIN $numactl_opts /usr/bin/time -v -o ${output_folder}/time_${prefix}${i}.txt -- $cmd"
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

    # Reset replication state before the benchmark proceeds
    echo "Resetting replication state via $reset_interface..."
    echo 1 | sudo tee "$reset_interface" > /dev/null

    touch "$BENCH_FLUSHED"
    echo "Caches flushed, replication reset, benchmark signaled to proceed"

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
    PERF_PID=""

    echo "Starting system-wide perf stat..."
    (trap - INT; exec perf stat -p $BENCH_PID -x, -e "$PERF_EVENTS" -o "${PERF_OUTPUT}.txt") 2>"$PERF_ERR" &
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

    # Stop perf gracefully
    stop_perf $PERF_PID
    wait $PERF_PID 2>/dev/null

    if [[ -s "$PERF_ERR" ]] && grep -qi -E "fail|error|not counted|not supported|cannot" "$PERF_ERR"; then
        echo "WARNING: perf reported issues during iteration $i:"
        cat "$PERF_ERR"
    fi

    # Validate perf output exists and is non-empty
    if [[ ! -s "${PERF_OUTPUT}.txt" ]]; then
        echo "ERROR: perf output file missing or empty for iteration $i"
        echo "--- perf stderr ---"
        cat "$PERF_ERR" 2>/dev/null
        echo "---"
        exit 1
    fi

    # Validate perf counter multiplexing
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
    elif [[ "$PROFILE_MODE" == "amd_perf" ]]; then
        # Check multiplexing for AMD — column 5 in CSV is the percentage of time counted
        MUX_WARN=0
        while IFS=, read -r count unit event runtime pct _rest; do
            if [[ -n "$pct" && "$pct" != "100.00" ]]; then
                MUX_WARN=1
                break
            fi
        done < <(grep -v '^#' "${PERF_OUTPUT}.txt" | grep -v '^$')
        if [[ "$MUX_WARN" -eq 1 ]]; then
            echo "NOTE: Some AMD perf counters were multiplexed (12 events > 6 PMCs). Values are scaled by perf."
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
        echo "=== Perf Counters (system-wide) ==="
        cat "${PERF_OUTPUT}.txt"

        # AMD: print human-readable summary of fill sources
        if [[ "$PROFILE_MODE" == "amd_perf" ]]; then
            echo ""
            echo "=== Data Cache Fill Source Summary ==="
            LCL_L2=$(grep 'ls_dmnd_fills_from_sys.lcl_l2' "${PERF_OUTPUT}.txt" | head -1 | cut -d, -f1)
            INT_CACHE=$(grep 'ls_dmnd_fills_from_sys.int_cache' "${PERF_OUTPUT}.txt" | head -1 | cut -d, -f1)
            EXT_LOCAL=$(grep 'ls_dmnd_fills_from_sys.ext_cache_local' "${PERF_OUTPUT}.txt" | head -1 | cut -d, -f1)
            EXT_REMOTE=$(grep 'ls_dmnd_fills_from_sys.ext_cache_remote' "${PERF_OUTPUT}.txt" | head -1 | cut -d, -f1)
            MEM_LOCAL=$(grep 'ls_dmnd_fills_from_sys.mem_io_local' "${PERF_OUTPUT}.txt" | head -1 | cut -d, -f1)
            MEM_REMOTE=$(grep 'ls_dmnd_fills_from_sys.mem_io_remote' "${PERF_OUTPUT}.txt" | head -1 | cut -d, -f1)

            TOTAL=$(( ${LCL_L2:-0} + ${INT_CACHE:-0} + ${EXT_LOCAL:-0} + ${EXT_REMOTE:-0} + ${MEM_LOCAL:-0} + ${MEM_REMOTE:-0} ))

            if [[ $TOTAL -gt 0 ]]; then
                echo "  Local L2:            ${LCL_L2:-0}  ($(awk "BEGIN{printf \"%.1f\", ${LCL_L2:-0}*100/$TOTAL}")%)"
                echo "  Local L3/CCX:        ${INT_CACHE:-0}  ($(awk "BEGIN{printf \"%.1f\", ${INT_CACHE:-0}*100/$TOTAL}")%)"
                echo "  Remote CCX same node:${EXT_LOCAL:-0}  ($(awk "BEGIN{printf \"%.1f\", ${EXT_LOCAL:-0}*100/$TOTAL}")%)"
                echo "  Remote CCX diff node:${EXT_REMOTE:-0}  ($(awk "BEGIN{printf \"%.1f\", ${EXT_REMOTE:-0}*100/$TOTAL}")%)"
                echo "  Local DRAM:          ${MEM_LOCAL:-0}  ($(awk "BEGIN{printf \"%.1f\", ${MEM_LOCAL:-0}*100/$TOTAL}")%)"
                echo "  Remote DRAM:         ${MEM_REMOTE:-0}  ($(awk "BEGIN{printf \"%.1f\", ${MEM_REMOTE:-0}*100/$TOTAL}")%)"
                echo "  ---"
                REMOTE_TOTAL=$(( ${EXT_REMOTE:-0} + ${MEM_REMOTE:-0} ))
                echo "  Remote fill ratio:   $(awk "BEGIN{printf \"%.1f\", $REMOTE_TOTAL*100/$TOTAL}")%"
                echo "  Total fills:         $TOTAL"
            fi
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
