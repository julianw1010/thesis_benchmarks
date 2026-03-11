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

# Benchmark synchronization files
BENCH_READY="/tmp/alloctest-bench.ready"
BENCH_FLUSHED="/tmp/alloctest-bench.flushed"
BENCH_DONE="/tmp/alloctest-bench.done"
BENCH_STATS_CAPTURED="/tmp/alloctest-bench.stats_captured"
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

for ((i=start; i<=max_index; i++)); do
    echo "=== Running iteration=$i ==="

    rm -f "$BENCH_READY" "$BENCH_FLUSHED" "$BENCH_DONE" "$BENCH_STATS_CAPTURED" "$BENCH_PID_FILE"

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

    # Start timing
    SECONDS=0

    echo "Waiting for simulation to complete..."

    # Wait for BENCH_DONE (simulation finished, teardown not yet started)
    while [[ ! -f "$BENCH_DONE" ]]; do
        if ! kill -0 $SCRIPT_PID 2>/dev/null; then
            echo "WARNING: Benchmark exited before writing DONE file"
            break
        fi
        sleep 0.1
    done

    if [[ -f "$BENCH_DONE" ]]; then
        echo "Simulation complete — snapshotting simulation-only stats"
        echo -1 | sudo tee ${history_interface%/*}/snapshot > /dev/null 2>&1
        cat $history_interface > "${output_folder}/history_sim_${prefix}${i}.txt"
        echo "Simulation stats captured, releasing benchmark for teardown..."
        touch "$BENCH_STATS_CAPTURED"
    fi

    # Wait for full process exit (teardown phase)
    wait $SCRIPT_PID
    BENCH_EXIT_CODE=$?

    DURATION=$SECONDS

    if [[ ! -f "$BENCH_DONE" ]]; then
        echo "WARNING: Benchmark exited without writing DONE file (exit code: $BENCH_EXIT_CODE)"
        BENCH_CRASHED=1
    else
        BENCH_CRASHED=0
    fi

    # Collect stats
    STATS_FILE="${output_folder}/stats_${prefix}${i}.txt"
    {
        echo "Execution Time (seconds): $DURATION"
        echo "Benchmark Exit Code: $BENCH_EXIT_CODE"
        if [[ $BENCH_CRASHED -eq 1 ]]; then
            echo "WARNING: Benchmark crashed (no DONE file). Results may be partial."
        fi
    } | tee "$STATS_FILE"

    echo ""
    echo "Statistics saved to $STATS_FILE"

    # Save teardown-only history (counters were reset after simulation snapshot)
    cat $history_interface > "${output_folder}/history_teardown_${prefix}${i}.txt"
    # Also save as history_ for backwards compatibility
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
