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
    PROFILE_MODE="amd_perf"
    echo "AMD CPU detected"

    PERF_EVENTS_G1="ls_dmnd_fills_from_sys.lcl_l2,ls_dmnd_fills_from_sys.int_cache,ls_dmnd_fills_from_sys.ext_cache_local,ls_dmnd_fills_from_sys.ext_cache_remote,ls_dmnd_fills_from_sys.mem_io_local,ls_dmnd_fills_from_sys.mem_io_remote"
    PERF_EVENTS_G2="cycles,instructions,l2_dtlb_misses,ls_tablewalker.dside,ls_tablewalker.iside,stalled-cycles-backend"

    PERF_EVENTS="${PERF_EVENTS_G1},${PERF_EVENTS_G2}"
    echo "Perf events: $PERF_EVENTS"

    # IBS configuration
    # cnt_ctl=1: count cycles (not dispatched ops), gives time-based sampling
    # val=100000: sample roughly every 100K cycles (~1 sample per 36us at 2.8GHz)
    IBS_EVENT="ibs_op/cnt_ctl=1/"
    IBS_ENABLED=1
    echo "IBS event: $IBS_EVENT"

elif [[ "$CPU_MODEL" == *"Xeon"* ]] || [[ "$CPU_MODEL" == *"Intel"* ]]; then
    PROFILE_MODE="intel_perf"
    IBS_ENABLED=0

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
    IBS_ENABLED=0
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

# Post-process IBS data into human-readable reports
process_ibs_data() {
    local perf_data="$1"
    local output_prefix="$2"

    if [[ ! -f "$perf_data" ]]; then
        echo "WARNING: IBS perf.data not found at $perf_data"
        return
    fi

    local size_mb
    size_mb=$(du -m "$perf_data" | cut -f1)
    echo "IBS data file: ${size_mb} MB"

    # 1. Top symbols by sample count
    echo "  Generating top symbols report..."
    perf report -i "$perf_data" --stdio --no-children \
        --sort=dso,symbol --percent-limit=0.5 \
        > "${output_prefix}_symbols.txt" 2>/dev/null

    # 2. Raw script output with data_src and weight (latency) fields
    #    data_src encodes: cache level, NUMA node, snoop result
    #    weight = measured load latency in cycles
    echo "  Extracting per-sample data source + latency..."
    perf script -i "$perf_data" \
        -F pid,tid,cpu,time,event,ip,sym,dso,addr,phys_addr,data_src,weight \
        > "${output_prefix}_script_raw.txt" 2>/dev/null

    # 3. Memory access latency histogram
    #    weight field = actual measured latency per sampled op
    echo "  Building latency histogram..."
    awk -F'[ \t]+' '
    /weight:/ {
        for (i=1; i<=NF; i++) {
            if ($i ~ /^weight:/) {
                split($i, a, ":");
                w = a[2] + 0;
                if (w > 0) {
                    total++;
                    sum += w;
                    if      (w <= 10)   bucket["0-10"]++;
                    else if (w <= 50)   bucket["11-50"]++;
                    else if (w <= 100)  bucket["51-100"]++;
                    else if (w <= 200)  bucket["101-200"]++;
                    else if (w <= 500)  bucket["201-500"]++;
                    else if (w <= 1000) bucket["501-1000"]++;
                    else                bucket["1001+"]++;
                }
            }
        }
    }
    END {
        if (total > 0) {
            printf "Load Latency Histogram (cycles)\n";
            printf "================================\n";
            printf "  %-12s %10s %6s\n", "Range", "Count", "%";
            printf "  %-12s %10d %5.1f%%\n", "0-10",      bucket["0-10"]+0,      (bucket["0-10"]+0)*100/total;
            printf "  %-12s %10d %5.1f%%\n", "11-50",     bucket["11-50"]+0,     (bucket["11-50"]+0)*100/total;
            printf "  %-12s %10d %5.1f%%\n", "51-100",    bucket["51-100"]+0,    (bucket["51-100"]+0)*100/total;
            printf "  %-12s %10d %5.1f%%\n", "101-200",   bucket["101-200"]+0,   (bucket["101-200"]+0)*100/total;
            printf "  %-12s %10d %5.1f%%\n", "201-500",   bucket["201-500"]+0,   (bucket["201-500"]+0)*100/total;
            printf "  %-12s %10d %5.1f%%\n", "501-1000",  bucket["501-1000"]+0,  (bucket["501-1000"]+0)*100/total;
            printf "  %-12s %10d %5.1f%%\n", "1001+",     bucket["1001+"]+0,     (bucket["1001+"]+0)*100/total;
            printf "  ---\n";
            printf "  Total samples: %d, Mean latency: %.1f cycles\n", total, sum/total;
        } else {
            printf "No latency data found (weight field may not be populated)\n";
        }
    }' "${output_prefix}_script_raw.txt" > "${output_prefix}_latency_hist.txt"
    cat "${output_prefix}_latency_hist.txt"

    # 4. Data source breakdown (where loads were served from)
    #    Uses perf mem report which decodes data_src into human-readable form
    echo "  Generating memory access source report..."
    perf mem report -i "$perf_data" --stdio --sort=mem,sym \
        --percent-limit=0.5 \
        > "${output_prefix}_mem_report.txt" 2>/dev/null

    # 5. NUMA locality summary from data_src field
    #    Extract snoop/cache level info from raw script
    echo "  Analyzing NUMA locality from data_src..."
    awk '
    /data_src:/ {
        for (i=1; i<=NF; i++) {
            if ($i ~ /^data_src:/) {
                split($i, a, ":");
                ds = strtonum(a[2]);
                total++;

                # Decode data_src bit fields (AMD IBS encoding)
                # Bits 0-3:   mem_op (load=1, store=2)
                # Bits 7-12:  mem_lvl (L1=1, LFB=2, L2=4, L3=8, Local DRAM=16, Remote DRAM1=32, Remote DRAM2=64)
                # Bits 13-16: mem_snoop (None=1, Hit=2, Miss=4, HitM=8)
                # Bits 21-22: mem_lock
                # Bits 24-25: mem_dtlb (L1=1, L2=2, Miss=4)
                # Bits 29-30: mem_lvl_num (more precise)
                # Bits 33-36: mem_remote (same_node=1, remote_node1=2, remote_node2=4)

                # Simplified: just count everything
                src_counts[ds]++;
            }
        }
    }
    END {
        printf "Data source distribution (top 20 raw data_src values):\n";
        n = asorti(src_counts, sorted, "@val_num_desc");
        for (i=1; i<=n && i<=20; i++) {
            printf "  data_src=0x%x: %d samples (%.1f%%)\n", sorted[i], src_counts[sorted[i]], src_counts[sorted[i]]*100/total;
        }
        printf "  Total: %d samples\n", total;
    }' "${output_prefix}_script_raw.txt" > "${output_prefix}_datasrc.txt" 2>/dev/null
    cat "${output_prefix}_datasrc.txt"

    # 6. perf c2c style analysis (cache-line contention)
    #    This is the most directly useful report for the Mitosis vs Hydra comparison
    echo "  Running c2c (cache contention) analysis..."
    perf c2c report -i "$perf_data" --stdio --stats \
        > "${output_prefix}_c2c_stats.txt" 2>/dev/null

    perf c2c report -i "$perf_data" --stdio \
        --percent-limit=0.1 \
        > "${output_prefix}_c2c_full.txt" 2>/dev/null

    echo "  IBS post-processing complete."
    echo "  Reports:"
    echo "    ${output_prefix}_symbols.txt      - Top functions by sample count"
    echo "    ${output_prefix}_latency_hist.txt  - Load latency distribution"
    echo "    ${output_prefix}_mem_report.txt    - Memory access source report"
    echo "    ${output_prefix}_datasrc.txt       - Raw data_src breakdown"
    echo "    ${output_prefix}_c2c_stats.txt     - Cache contention summary"
    echo "    ${output_prefix}_c2c_full.txt      - Cache contention detail"
    echo "    ${output_prefix}_script_raw.txt    - Raw per-sample data (large)"
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

    # --- perf stat (counters) ---
    PERF_OUTPUT="${output_folder}/perf_${prefix}${i}"
    PERF_ERR="${PERF_OUTPUT}.err"
    PERF_PID=""

    echo "Starting perf stat..."
    (trap - INT; exec perf stat -p $BENCH_PID -x, -e "$PERF_EVENTS" -o "${PERF_OUTPUT}.txt") 2>"$PERF_ERR" &
    PERF_PID=$!

    sleep 0.2
    if ! kill -0 $PERF_PID 2>/dev/null; then
        echo "ERROR: perf stat failed to start"
        [[ -f "$PERF_ERR" ]] && cat "$PERF_ERR"
        kill $SCRIPT_PID 2>/dev/null
        exit 1
    fi
    echo "perf stat started (PID: $PERF_PID)"

    # --- IBS recording (AMD only) ---
    IBS_PID=""
    IBS_DATA="${output_folder}/ibs_${prefix}${i}.data"
    IBS_ERR="${output_folder}/ibs_${prefix}${i}.err"

    if [[ "$IBS_ENABLED" -eq 1 ]]; then
        echo "Starting IBS recording..."

        # Record with:
        #   -e ibs_op//          IBS Op sampling (captures load latency + data source)
        #   -p $BENCH_PID        attach to benchmark process (all threads)
        #   -c 100000            sample period (~100K cycles between samples)
        #   --sample-cpu         record which CPU each sample came from
        #   -W                   record weight (load latency in cycles)
        #   -d                   record data addresses (for c2c analysis)
        #   --phys-data          record physical addresses (for NUMA node attribution)
        (trap - INT; exec perf record \
            -e "$IBS_EVENT" \
            -p $BENCH_PID \
            -c 100000 \
            --sample-cpu \
            -W \
            -d \
            --phys-data \
            -o "$IBS_DATA" \
        ) 2>"$IBS_ERR" &
        IBS_PID=$!

        sleep 0.5
        if ! kill -0 $IBS_PID 2>/dev/null; then
            echo "WARNING: IBS perf record failed to start"
            [[ -f "$IBS_ERR" ]] && cat "$IBS_ERR"
            echo "Continuing without IBS..."
            IBS_PID=""
            IBS_ENABLED_THIS_RUN=0
        else
            echo "IBS recording started (PID: $IBS_PID, output: $IBS_DATA)"
            IBS_ENABLED_THIS_RUN=1
        fi
    else
        IBS_ENABLED_THIS_RUN=0
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

    # Stop perf stat
    stop_perf $PERF_PID
    wait $PERF_PID 2>/dev/null

    # Stop IBS recording
    if [[ -n "$IBS_PID" ]]; then
        echo "Stopping IBS recording..."
        stop_perf $IBS_PID
        wait $IBS_PID 2>/dev/null

        if [[ -s "$IBS_ERR" ]] && grep -qi -E "fail|error|not supported" "$IBS_ERR"; then
            echo "WARNING: IBS perf record reported issues:"
            cat "$IBS_ERR"
        fi
    fi

    if [[ -s "$PERF_ERR" ]] && grep -qi -E "fail|error|not counted|not supported|cannot" "$PERF_ERR"; then
        echo "WARNING: perf stat reported issues during iteration $i:"
        cat "$PERF_ERR"
    fi

    # Validate perf output exists and is non-empty
    if [[ ! -s "${PERF_OUTPUT}.txt" ]]; then
        echo "ERROR: perf stat output file missing or empty for iteration $i"
        echo "--- perf stderr ---"
        cat "$PERF_ERR" 2>/dev/null
        echo "---"
        exit 1
    fi

    # Validate perf counter multiplexing
    if [[ "$PROFILE_MODE" == "amd_perf" ]]; then
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
        echo "=== Perf Counters ==="
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

    # Post-process IBS data
    if [[ "$IBS_ENABLED_THIS_RUN" -eq 1 && -f "$IBS_DATA" ]]; then
        echo ""
        echo "=== IBS Post-Processing ==="
        IBS_REPORT_PREFIX="${output_folder}/ibs_${prefix}${i}"
        process_ibs_data "$IBS_DATA" "$IBS_REPORT_PREFIX"

        # Append IBS summary to stats file
        {
            echo ""
            echo "=== IBS Latency Histogram ==="
            cat "${IBS_REPORT_PREFIX}_latency_hist.txt" 2>/dev/null
            echo ""
            echo "=== IBS Data Source Summary ==="
            cat "${IBS_REPORT_PREFIX}_datasrc.txt" 2>/dev/null
        } >> "$STATS_FILE"
    fi

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
