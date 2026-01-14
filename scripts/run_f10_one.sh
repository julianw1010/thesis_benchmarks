#!/bin/bash
#
# run_f10_one.sh - Run a single benchmark with Mitosis page table replication
#
# Usage: ./run_f10_one.sh <benchmark>
#
# Benchmarks: gups, btree, hashjoin, redis, xsbench, pagerank, liblinear, canneal
#
# This script runs the RPI-LD configuration with Mitosis replication enabled (-r all).
# This tests whether replicating page tables eliminates the PT walk penalty.
#
# Configuration:
#   CPU_NODE=7   (Remote CPU)
#   DATA_NODE=7  (Local to CPU)
#   PT_NODE=0    (Page tables on node 0, but replicated to all nodes via -r all)
#   INT_NODE=0   (Interference on node 0)

# ==============================================================================
# CONSTANTS
# ==============================================================================

readonly ROOT=$(dirname "$(readlink -f "$0")")
readonly MAIN=$(dirname "$ROOT")
readonly GNU_TIME="/usr/bin/time"
readonly CONFIG="RPILD_MITOSIS"

# NUMA node assignments (fixed for RPI-LD)
readonly PT_NODE=0
readonly CPU_NODE=7
readonly DATA_NODE=7
readonly INT_NODE=0

# Benchmark-specific arguments
declare -A BENCH_ARGS_MAP=(
    [xsbench]=" -- -t 16 -g 32000 -p 500000 "
    [liblinear]=" -s 6 -n 28 $MAIN/datasets/kdd12_5gb "
    [canneal]=" -- 1 84000 2000 $MAIN/datasets/canneal_3gb_int 400 "
    [hashjoin]=" -- -o 135000000 -i 1000000 -s 1000000 -n 3 "
    [gups]=" -- 16"
    [pr]=" -f $MAIN/datasets/kron27.sg -n 1"
)

# Single-threaded benchmarks
readonly SINGLE_THREADED_BENCHMARKS="gups btree redis hashjoin xsbench canneal liblinear pr"
readonly VALID_BENCHMARKS="gups btree hashjoin redis xsbench pr liblinear canneal"

# ==============================================================================
# GLOBAL VARIABLES
# ==============================================================================

BENCHMARK=""
BENCH_ARGS=""
BIN=""
BENCHPATH=""
INT_BIN=""
NUMACTL=""
DATADIR=""
RUNDIR=""
OUTFILE=""
TIME_FILE=""
BENCH_OUTPUT=""

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

die() {
    echo "ERROR: $1" >&2
    exit 1
}

is_in_list() {
    local item="$1"
    local list="$2"
    [[ " $list " == *" $item "* ]]
}

# ==============================================================================
# VALIDATION
# ==============================================================================

validate_arguments() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 <benchmark>"
        echo "Benchmarks: $VALID_BENCHMARKS"
        exit 1
    fi

    BENCHMARK="$1"

    if ! is_in_list "$BENCHMARK" "$VALID_BENCHMARKS"; then
        die "Invalid benchmark: $BENCHMARK (valid: $VALID_BENCHMARKS)"
    fi
}

validate_dependencies() {
    [[ -e "$BENCHPATH" ]] || die "Benchmark binary missing: $BENCHPATH"
    [[ -e "$INT_BIN" ]]   || die "Interference binary missing: $INT_BIN"
    [[ -e "$GNU_TIME" ]]  || die "GNU time missing at $GNU_TIME (install with: sudo apt install time)"

    if [[ -e "/usr/local/bin/numactl" ]]; then
        NUMACTL="/usr/local/bin/numactl"
    else
        NUMACTL=$(which numactl) || die "numactl not found"
    fi
}

# ==============================================================================
# CONFIGURATION SETUP
# ==============================================================================

setup_benchmark_binary() {
    local suffix="_mt"
    if is_in_list "$BENCHMARK" "$SINGLE_THREADED_BENCHMARKS"; then
        suffix="_st"
    fi
    BIN="bench_${BENCHMARK}${suffix}"
}

setup_benchmark_args() {
    BENCH_ARGS="${BENCH_ARGS_MAP[$BENCHMARK]:-}"
}

setup_paths() {
    local scripts_dir
    scripts_dir=$(readlink -f "$(dirname "$(readlink -f "$0")")")
    local root_dir
    root_dir=$(dirname "$scripts_dir")

    BENCHPATH="$root_dir/bin/$BENCHMARK/$BIN"
    INT_BIN="$root_dir/bin/stream/bench_stream"

    DATADIR="$root_dir/evaluation/measured/figure10/$BENCHMARK"
    RUNDIR="$DATADIR/$(hostname)-config-$BENCHMARK-$CONFIG-$(date +"%Y%m%d-%H%M%S")"

    mkdir -p "$RUNDIR" || die "Failed to create output directory: $RUNDIR"

    OUTFILE="$RUNDIR/log-$BENCHMARK-$(hostname)-$CONFIG.dat"
    TIME_FILE="$RUNDIR/time-$BENCHMARK-$(hostname)-$CONFIG.txt"
    BENCH_OUTPUT="$RUNDIR/output-$BENCHMARK-$(hostname)-$CONFIG.txt"
}

print_configuration() {
    echo "=========================================="
    echo "Configuration: RPI-LD with Mitosis Replication"
    echo "  PT_NODE:   $PT_NODE (with -r all replication)"
    echo "  CPU_NODE:  $CPU_NODE"
    echo "  DATA_NODE: $DATA_NODE (LOCAL to CPU)"
    echo "  INT_NODE:  $INT_NODE"
    echo "  numactl flags: -m $DATA_NODE -N $CPU_NODE -r all"
    echo "=========================================="
}

# ==============================================================================
# SYSTEM CONFIGURATION
# ==============================================================================

configure_system() {
    echo "$PT_NODE" | sudo tee /proc/mitosis/mode > /dev/null \
        || die "Failed to set page table allocation to node: $PT_NODE"
}

# ==============================================================================
# BENCHMARK EXECUTION
# ==============================================================================

launch_interference() {
    echo "Launching interference on node $INT_NODE"
    OMP_NUM_THREADS=8 $NUMACTL -N "$INT_NODE" -m "$INT_NODE" "$INT_BIN" > /dev/null 2>&1 &
    [[ $? -eq 0 ]] || die "Failed to launch interference"
}

cleanup() {
    rm -f /tmp/alloctest-bench.ready /tmp/alloctest-bench.done
    killall bench_stream &>/dev/null || true
}

format_memory_size() {
    local kb="$1"
    if [[ -n "$kb" ]]; then
        local mb=$((kb / 1024))
        local gb
        gb=$(echo "scale=2; $kb / 1048576" | bc)
        echo "$kb kB ($mb MB / $gb GB)"
    else
        echo "N/A"
    fi
}

run_benchmark() {
    cleanup

    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches

    # Key difference: -r all enables Mitosis page table replication
    local launch_cmd="$GNU_TIME -v -o $TIME_FILE $NUMACTL -m $DATA_NODE -N $CPU_NODE -r all $BENCHPATH $BENCH_ARGS"

    echo "Launch command: $launch_cmd"
    echo "Time output file: $TIME_FILE"
    echo "Benchmark output file: $BENCH_OUTPUT"
    echo "$launch_cmd" >> "$OUTFILE"

    local total_start=$SECONDS
    script -q -f -c "$launch_cmd" "$BENCH_OUTPUT" &
    local benchmark_pid=$!

    echo -e "\e[0mWaiting for benchmark: $benchmark_pid to be ready"
    while [[ ! -f /tmp/alloctest-bench.ready ]]; do
        sleep 0.1
    done
    local ready_to_done_start=$SECONDS

    launch_interference

    echo -e "\e[0mWaiting for benchmark to be done"
    while [[ ! -f /tmp/alloctest-bench.done ]]; do
        sleep 0.1
    done
    local done_time=$SECONDS

    wait "$benchmark_pid" 2>/dev/null || true

    local total_duration=$((SECONDS - total_start))
    local ready_to_done_duration=$((done_time - ready_to_done_start))

    local max_rss_kb=""
    if [[ -f "$TIME_FILE" ]]; then
        max_rss_kb=$(grep "Maximum resident set size" "$TIME_FILE" | awk '{print $NF}')
    fi

    print_results "$total_duration" "$ready_to_done_duration" "$max_rss_kb"
    save_results "$total_duration" "$ready_to_done_duration" "$max_rss_kb"

    cleanup
}

print_results() {
    local total_duration="$1"
    local exec_duration="$2"
    local max_rss_kb="$3"

    echo ""
    echo "=========================================="
    echo "TIMING RESULTS (RPI-LD + Mitosis Replication):"
    echo "  Total runtime (start to finish): $total_duration seconds"
    echo "  Execution time (ready to done):  $exec_duration seconds"
    echo "  Maximum Resident Set Size:       $(format_memory_size "$max_rss_kb")"
    echo "=========================================="
    echo ""
    echo "========== /usr/bin/time -v output =========="
    cat "$TIME_FILE"
    echo "============================================="
}

save_results() {
    local total_duration="$1"
    local exec_duration="$2"
    local max_rss_kb="$3"
    local max_rss_mb=$((max_rss_kb / 1024))

    {
        echo "Total Runtime (seconds): $total_duration"
        echo "Execution Time (ready to done, seconds): $exec_duration"
        echo "Maximum Resident Set Size (kB): $max_rss_kb"
        echo "Maximum Resident Set Size (MB): $max_rss_mb"
        echo ""
        echo "===== TIME OUTPUT ====="
        cat "$TIME_FILE"
        echo ""
        echo "===== BENCHMARK OUTPUT ====="
        cat "$BENCH_OUTPUT"
        echo ""
        echo "****success****"
    } >> "$OUTFILE"

    echo "$BENCHMARK : $CONFIG completed."
    echo ""
    echo "Output files saved to: $RUNDIR"
    echo "  - Log file:       $(basename "$OUTFILE")"
    echo "  - Time stats:     $(basename "$TIME_FILE")"
    echo "  - Bench output:   $(basename "$BENCH_OUTPUT")"
    echo ""
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    validate_arguments "$@"

    setup_benchmark_binary
    setup_benchmark_args
    setup_paths

    validate_dependencies

    print_configuration
    configure_system

    run_benchmark
}

main "$@"
