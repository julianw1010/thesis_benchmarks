#!/bin/bash

###############################################################################
# Script to run Figure 9 Evaluation of the paper (Simplified - Time only)
# 
# Paper: Mitosis - Mitosis: Transparently Self-Replicating Page-Tables 
#                  for Large-Memory Machines
###############################################################################

NR_PTCACHE_PAGES=1000000 # --- 2GB per socket
XSBENCH_ARGS=" -- -p 25000000 -g 300000 "
GRAPH500_ARGS=" -- -s 29 -e 21"
HASHJOIN_ARGS=" -- -o 1250000000 -i 10000000 -s 10000000"
BENCH_ARGS=""

# Proc interface paths (will be detected)
CACHE_PROC=""
HISTORY_PROC=""

#***********************Script-Arguments***********************
if [ $# -ne 2 ]; then
	echo "Run as: $0 benchmark config"
	exit
fi

BENCHMARK=$1
CONFIG=$2

detect_proc_interfaces()
{
	# Detect cache interface
	if [ -e /proc/mitosis/cache ]; then
		CACHE_PROC="/proc/mitosis/cache"
	elif [ -e /proc/hydra/cache ]; then
		CACHE_PROC="/proc/hydra/cache"
	else
		CACHE_PROC=""
	fi

	# Detect history interface
	if [ -e /proc/mitosis/history ]; then
		HISTORY_PROC="/proc/mitosis/history"
	elif [ -e /proc/hydra/history ]; then
		HISTORY_PROC="/proc/hydra/history"
	else
		HISTORY_PROC=""
	fi

	echo "Detected proc interfaces:"
	echo "  Cache:   ${CACHE_PROC:-not found}"
	echo "  History: ${HISTORY_PROC:-not found}"
}

validate_benchmark_config()
{
	CURR_BENCH=$1
	CURR_CONFIG=$2

	if [ $CURR_BENCH == "memcached" ] || [ $CURR_BENCH == "xsbench" ] || [ $CURR_BENCH == "graph500" ] ||
		[ $CURR_BENCH == "hashjoin" ] || [ $CURR_BENCH == "btree" ] || [ $CURR_BENCH == "canneal" ]; then
		:
	else
		echo "Invalid benchmark: $CURR_BENCH"
		exit
	fi
	if [ $CURR_CONFIG == "F" ] || [ $CURR_CONFIG == "FM" ] || [ $CURR_CONFIG == "I" ] || [ $CURR_CONFIG == "IM" ]; then
		:
	else
		echo "Invalid config: $CURR_CONFIG"
		exit
	fi
}

prepare_benchmark_name()
{
	PREFIX="bench_"
	POSTFIX="_mt"
	BIN=$PREFIX
	BIN+=$BENCHMARK
	BIN+=$POSTFIX
}

test_and_set_pathnames()
{
	SCRIPTS=$(readlink -f "`dirname $(readlink -f "$0")`")
	ROOT="$(dirname "$SCRIPTS")"
	BENCHPATH=$ROOT"/bin/$BIN"
	NUMACTL="/usr/local/bin/numactl"
	if [ ! -e $BENCHPATH ]; then
		echo "Benchmark binary is missing"
		exit
	fi
	if [ ! -e $NUMACTL ]; then
		echo "numactl is missing"
		exit
	fi
	DATADIR=$ROOT/results/$BENCHMARK
	RUNDIR=$DATADIR/$(hostname)-$CONFIG-$(date +"%Y%m%d-%H%M%S")
	mkdir -p $RUNDIR
	if [ $? -ne 0 ]; then
		echo "Error creating output directory: $RUNDIR"
	fi
	OUTFILE=$RUNDIR/timelog-$BENCHMARK-$(hostname)-$CONFIG.txt
	TIMEFILE=$RUNDIR/time-$BENCHMARK-$(hostname)-$CONFIG.txt
	BENCHLOG=$RUNDIR/output-$BENCHMARK-$(hostname)-$CONFIG.txt
	HISTORY_BEFORE=$RUNDIR/history-before-$BENCHMARK-$(hostname)-$CONFIG.txt
	HISTORY_AFTER=$RUNDIR/history-after-$BENCHMARK-$(hostname)-$CONFIG.txt
}

test_and_set_configs()
{
	CURR_CONFIG=$1

	NODESTR=$(numactl --hardware | grep available)
	NODE_MAX=$(echo ${NODESTR##*: } | cut -d " " -f 1)
	NODE_MAX=`expr $NODE_MAX - 1`
	CMD_PREFIX=$NUMACTL

	if [ $CURR_CONFIG == "I" ] || [ $CURR_CONFIG == "IM" ]; then
		CMD_PREFIX+=" --interleave=all"
	fi

	LAST_CHAR="${CURR_CONFIG: -1}"
	if [ $LAST_CHAR == "M" ]; then
		CMD_PREFIX+=" --pgtablerepl=all "
		
		# Check if cache interface is available
		if [ -z "$CACHE_PROC" ]; then
			echo "ERROR: Neither /proc/mitosis/cache nor /proc/hydra/cache found"
			exit
		fi
	fi		
	echo "Using cache interface: $CACHE_PROC"
	echo -1 | sudo tee $CACHE_PROC
	if [ $? -ne 0 ]; then
		echo "ERROR setting cache to -1"
		exit
	fi
	echo $NR_PTCACHE_PAGES | sudo tee $CACHE_PROC
	if [ $? -ne 0 ]; then
		echo "ERROR setting cache to $NR_PTCACHE_PAGES"
		exit
	fi
	

	if [ $BENCHMARK == "xsbench" ]; then
		BENCH_ARGS=$XSBENCH_ARGS
	elif [ $BENCHMARK == "graph500" ]; then
		BENCH_ARGS=$GRAPH500_ARGS
	elif [ $BENCHMARK == "hashjoin" ]; then
		BENCH_ARGS=$HASHJOIN_ARGS
	fi
}

prepare_datasets()
{
	SCRIPTS=$(readlink -f "`dirname $(readlink -f "$0")`")
	ROOT="$(dirname "$SCRIPTS")"
	if [ $1 == "canneal" ]; then
		$ROOT/datasets/prepare_canneal_datasets.sh large
	fi
}

reset_history()
{
	if [ -n "$HISTORY_PROC" ]; then
		echo "Resetting history via $HISTORY_PROC"
		echo -1 | sudo tee $HISTORY_PROC > /dev/null
	fi
}

save_history()
{
	local output_file=$1
	if [ -n "$HISTORY_PROC" ]; then
		echo "Saving history to $output_file"
		cat $HISTORY_PROC | tee $output_file
	else
		echo "History interface not available" | tee $output_file
	fi
}

launch_benchmark_config()
{
	rm -f /tmp/alloctest-bench.ready
	rm -f /tmp/alloctest-bench.done
	killall bench_stream 2>/dev/null

	# Sync and drop caches before run
	sync
	echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

	# Reset and save history before benchmark
	reset_history
	save_history $HISTORY_BEFORE

	LAUNCH_CMD="$CMD_PREFIX $BENCHPATH $BENCH_ARGS"
	echo "Command: $LAUNCH_CMD" | tee $OUTFILE
	echo "Run directory: $RUNDIR" | tee -a $OUTFILE
	echo "Start time: $(date)" | tee -a $OUTFILE
	echo "----------------------------------------" | tee -a $OUTFILE
	
	# Run benchmark with script for proper terminal output capture
	script -q -f -c "/usr/bin/time --verbose --output=$TIMEFILE $LAUNCH_CMD" $BENCHLOG &
	SCRIPT_PID=$!
	
	echo "Waiting for benchmark to be ready"
	
	while [ ! -f /tmp/alloctest-bench.ready ]; do
		sleep 0.1
	done
	
	# Start timing from ready signal
	SECONDS=0
	echo "Benchmark ready, starting timer..."
	
	while [ ! -f /tmp/alloctest-bench.done ]; do
		sleep 0.1
	done
	
	# Capture duration between ready and done
	DURATION=$SECONDS
	
	# Wait for script/benchmark to finish
	wait $SCRIPT_PID

	echo "----------------------------------------" | tee -a $OUTFILE
	echo "End time: $(date)" | tee -a $OUTFILE
	echo "Execution time (ready to done): $DURATION seconds" | tee -a $OUTFILE
	
	# Append time output to main log
	echo "----------------------------------------" | tee -a $OUTFILE
	echo "Time statistics:" | tee -a $OUTFILE
	cat $TIMEFILE | tee -a $OUTFILE

	# Save history after benchmark
	save_history $HISTORY_AFTER

	# Append history summary to output file
	echo "----------------------------------------" >> $OUTFILE
	echo "History after benchmark:" >> $OUTFILE
	cat $HISTORY_AFTER >> $OUTFILE
	
	# Append benchmark output to main log
	echo "----------------------------------------" >> $OUTFILE
	echo "Benchmark output:" >> $OUTFILE
	cat $BENCHLOG >> $OUTFILE
	
	echo "****success****" | tee -a $OUTFILE
	echo "$BENCHMARK : $CONFIG completed."
	echo ""
	echo "Results saved to:"
	echo "  Main log:        $OUTFILE"
	echo "  Benchmark output: $BENCHLOG"
	echo "  Time stats:      $TIMEFILE"
	echo "  History before:  $HISTORY_BEFORE"
	echo "  History after:   $HISTORY_AFTER"
	
	killall bench_stream 2>/dev/null
}

# --- detect proc interfaces first
detect_proc_interfaces

# --- prepare the setup
validate_benchmark_config $BENCHMARK $CONFIG
prepare_benchmark_name $BENCHMARK
test_and_set_pathnames
test_and_set_configs $CONFIG
prepare_datasets $BENCHMARK

# --- finally, launch the job
launch_benchmark_config
