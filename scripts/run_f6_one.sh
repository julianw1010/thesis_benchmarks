#!/bin/bash
#
# run_f6_one.sh - Run a single benchmark with a specific NUMA configuration
#
# Usage: ./run_f6_one.sh <benchmark> <config>
#
# Benchmarks: gups, btree, hashjoin, redis, xsbench, pagerank, liblinear, canneal
# Configs:    LPLD, LPRD, LPRDI, RPLD, RPLDI, RPILD, RPRD, RPIRDI (optionally prefixed with 'T')
#
# Configuration naming convention:
#   L/R = Local/Remote CPU
#   P   = Page table (always local to node 0)
#   L/R = Local/Remote Data
#   D   = Data
#   I   = Interference (memory bandwidth contention)

# ==============================================================================
# CONSTANTS
# ==============================================================================

readonly ROOT=$(dirname "$(readlink -f "$0")")
readonly MAIN=$(dirname "$ROOT")
readonly GNU_TIME="/usr/bin/time"

# Benchmark-specific arguments
declare -A BENCH_ARGS_MAP=(
    [xsbench]=" -- -t 16 -g 32000 -p 500000 "
    [liblinear]=" -s 6 -n 28 $MAIN/datasets/kdd12_5gb "
    [canneal]=" -- 1 84000 2000 $MAIN/datasets/canneal_3gb_int 400 "
    [hashjoin]=" -- -o 135000000 -i 1000000 -s 1000000 -n 3 "
    [gups]=" -- 16"
    [pr]=" -f $MAIN/datasets/kron27.sg -n 1"
)

# Single-threaded benchmarks (others are multi-threaded)
readonly SINGLE_THREADED_BENCHMARKS="gups btree redis hashjoin xsbench canneal liblinear pr"

# Valid benchmarks and configs for validation
readonly VALID_BENCHMARKS="gups btree hashjoin redis xsbench pagerank liblinear canneal pr"
readonly VALID_CONFIGS="LPLD LPRD LPRDI RPLD RPLDI RPILD RPRD RPIRDI"

# ==============================================================================
# GLOBAL VARIABLES (set during initialization)
# ==============================================================================

BENCHMARK=""
CONFIG=""
CONFIG_BASE=""        # Config without optional 'T' prefix
HAS_T_PREFIX=false

# NUMA node assignments
PT_NODE=0             # Page table node (always 0)
CPU_NODE=0
DATA_NODE=0
INT_NODE=0

# Derived values
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
    if [[ $# -ne 2 ]]; then
        echo "Usage: $0 <benchmark> <config>"
        exit 1
    fi

    BENCHMARK="$1"
    CONFIG="$2"

    # Strip optional 'T' prefix to get base config
    if [[ "${CONFIG:0:1}" == "T" ]]; then
        HAS_T_PREFIX=true
        CONFIG_BASE="${CONFIG:1}"
    else
        HAS_T_PREFIX=false
        CONFIG_BASE="$CONFIG"
    fi

    # Validate benchmark
    if ! is_in_list "$BENCHMARK" "$VALID_BENCHMARKS"; then
        die "Invalid benchmark: $BENCHMARK (valid: $VALID_BENCHMARKS)"
    fi

    # Validate config
    if ! is_in_list "$CONFIG_BASE" "$VALID_CONFIGS"; then
        die "Invalid config: $CONFIG (valid: $VALID_CONFIGS, optionally prefixed with 'T')"
    fi
}

validate_dependencies() {
    [[ -e "$BENCHPATH" ]] || die "Benchmark binary missing: $BENCHPATH"
    [[ -e "$INT_BIN" ]]   || die "Interference binary missing: $INT_BIN"
    [[ -e "$GNU_TIME" ]]  || die "GNU time missing at $GNU_TIME (install with: sudo apt install time)"

    # Find numactl
    if [[ -e "/usr/local/bin/numactl" ]]; then
        NUMACTL="/usr/local/bin/numactl"
    else
        NUMACTL=$(which numactl) || die "numactl not found"
    fi
}

# ==============================================================================
# CONFIGURATION SETUP
# ==============================================================================

setup_numa_nodes() {
    # Page table node is always 0
    PT_NODE=0

    # CPU node: Local (0) for LP* configs, Remote (7) for RP* configs
    if [[ "$CONFIG_BASE" == LP* ]]; then
        CPU_NODE=0
    else
        CPU_NODE=7
    fi

    # Data node assignment
    case "$CONFIG_BASE" in
        LPLD)   DATA_NODE=0 ;;
        LPRD)   DATA_NODE=7 ;;
        LPRDI)  DATA_NODE=7 ;;
        RPLD)   DATA_NODE=7 ;;
        RPLDI)  DATA_NODE=7 ;;  # Local data (same node as CPU)
        RPILD)  DATA_NODE=7 ;;
        RPRD)   DATA_NODE=0 ;;
        RPIRDI) DATA_NODE=0 ;;
    esac

    # Interference node (only for configs with 'I' suffix)
    INT_NODE=0
    case "$CONFIG_BASE" in
        LPRDI)  INT_NODE=7 ;;
        RPLDI)  INT_NODE=7 ;;  # Local interference (same node as CPU/data)
        RPILD)  INT_NODE=0 ;;
        RPIRDI) INT_NODE=0 ;;
    esac
}

setup_benchmark_binary() {
    # Determine binary suffix based on threading model
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
    INT_BIN="$root_dir/bin/mem_saturate"

    # Output directory: figure6 normally, figure10 with 'T' prefix
    local dir_suffix=6
    if $HAS_T_PREFIX; then
        dir_suffix=10
    fi

    DATADIR="$root_dir/evaluation/measured/figure$dir_suffix/$BENCHMARK"
    RUNDIR="$DATADIR/$(hostname)-config-$BENCHMARK-$CONFIG-$(date +"%Y%m%d-%H%M%S")"

    mkdir -p "$RUNDIR" || die "Failed to create output directory: $RUNDIR"

    OUTFILE="$RUNDIR/log-$BENCHMARK-$(hostname)-$CONFIG.dat"
    TIME_FILE="$RUNDIR/time-$BENCHMARK-$(hostname)-$CONFIG.txt"
    BENCH_OUTPUT="$RUNDIR/output-$BENCHMARK-$(hostname)-$CONFIG.txt"
}

print_configuration() {
    local pt_socket=$((PT_NODE / 4))
    local cpu_socket=$((CPU_NODE / 4))
    local data_socket=$((DATA_NODE / 4))
    local int_socket=$((INT_NODE / 4))

    local pt_locality="REMOTE"
    local data_locality="REMOTE"
    [[ $((PT_NODE / 4)) -eq $((CPU_NODE / 4)) ]] && pt_locality="LOCAL"
    [[ $((DATA_NODE / 4)) -eq $((CPU_NODE / 4)) ]] && data_locality="LOCAL"

    echo "=========================================="
    echo "Configuration: $CONFIG_BASE"
    echo "  PT_NODE:   $PT_NODE (Socket $pt_socket)"
    echo "  CPU_NODE:  $CPU_NODE (Socket $cpu_socket)"
    echo "  DATA_NODE: $DATA_NODE (Socket $data_socket)"
    echo "  INT_NODE:  $INT_NODE (Socket $int_socket)"
    echo "  PT is $pt_locality to CPU"
    echo "  Data is $data_locality to CPU"
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

uses_interference() {
    [[ "$CONFIG_BASE" == "LPRDI" || "$CONFIG_BASE" == "RPLDI" || "$CONFIG_BASE" == "RPILD" || "$CONFIG_BASE" == "RPIRDI" ]]
}

launch_interference() {
    if uses_interference; then
        echo "Launching interference on node $INT_NODE"
        OMP_NUM_THREADS=7 $NUMACTL -N "$INT_NODE" -m "$INT_NODE" "$INT_BIN" > /dev/null 2>&1 &
        [[ $? -eq 0 ]] || die "Failed to launch interference"
    fi
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

    local launch_cmd="$GNU_TIME -v -o $TIME_FILE $NUMACTL -m $DATA_NODE -N $CPU_NODE $BENCHPATH $BENCH_ARGS"

    echo "Launch command: $launch_cmd"
    echo "Time output file: $TIME_FILE"
    echo "Benchmark output file: $BENCH_OUTPUT"
    echo "$launch_cmd" >> "$OUTFILE"

    # Start benchmark
    local total_start=$SECONDS
    script -q -f -c "$launch_cmd" "$BENCH_OUTPUT" &
    local benchmark_pid=$!

    # Wait for benchmark to be ready
    echo -e "\e[0mWaiting for benchmark: $benchmark_pid to be ready"
    while [[ ! -f /tmp/alloctest-bench.ready ]]; do
        sleep 0.1
    done
    local ready_to_done_start=$SECONDS

    # Launch interference (if applicable)
    launch_interference

    # Wait for benchmark to complete
    echo -e "\e[0mWaiting for benchmark to be done"
    while [[ ! -f /tmp/alloctest-bench.done ]]; do
        sleep 0.1
    done
    local done_time=$SECONDS

    wait "$benchmark_pid" 2>/dev/null || true

    # Calculate timings
    local total_duration=$((SECONDS - total_start))
    local ready_to_done_duration=$((done_time - ready_to_done_start))

    # Parse memory usage from time output
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
    echo "TIMING RESULTS:"
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
    setup_numa_nodes
    setup_paths

    validate_dependencies

    print_configuration
    configure_system

    run_benchmark
}

main "$@"
