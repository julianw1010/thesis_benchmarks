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

#***********************Script-Arguments***********************
if [ $# -ne 2 ]; then
	echo "Run as: $0 benchmark config"
	exit
fi

BENCHMARK=$1
CONFIG=$2

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
	DATADIR=$ROOT"/evaluation/measured/figure9/$BENCHMARK"
	RUNDIR=$DATADIR/$(hostname)-config-$BENCHMARK-$CONFIG-$(date +"%Y%m%d-%H%M%S")
	mkdir -p $RUNDIR
	if [ $? -ne 0 ]; then
		echo "Error creating output directory: $RUNDIR"
	fi
	OUTFILE=$RUNDIR/timelog-$BENCHMARK-$(hostname)-$CONFIG.dat
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
		echo -1 | sudo tee /proc/mitosis/cache
		if [ $? -ne 0 ]; then
			echo "ERROR setting cache to $0"
			exit
		fi
		echo $NR_PTCACHE_PAGES | sudo tee /proc/mitosis/cache
		if [ $? -ne 0 ]; then
			echo "ERROR setting cache to $NR_PTCACHE_PAGES"
			exit
		fi
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

launch_benchmark_config()
{
	rm -f /tmp/alloctest-bench.ready
	rm -f /tmp/alloctest-bench.done
	killall bench_stream 2>/dev/null

	LAUNCH_CMD="$CMD_PREFIX $BENCHPATH $BENCH_ARGS"
	echo "Command: $LAUNCH_CMD" | tee $OUTFILE
	
	/usr/bin/time --verbose $LAUNCH_CMD 2>&1 | tee -a $OUTFILE &
	BENCHMARK_PID=$!
	echo "Waiting for benchmark: $BENCHMARK_PID to be ready"
	
	while [ ! -f /tmp/alloctest-bench.ready ]; do
		sleep 0.1
	done
	
	echo "Waiting for benchmark to be done"
	
	while [ ! -f /tmp/alloctest-bench.done ]; do
		sleep 0.1
	done
	
	wait $BENCHMARK_PID
	
	echo "****success****" | tee -a $OUTFILE
	echo "$BENCHMARK : $CONFIG completed."
	
	killall bench_stream 2>/dev/null
}

# --- prepare the setup
validate_benchmark_config $BENCHMARK $CONFIG
prepare_benchmark_name $BENCHMARK
test_and_set_pathnames
test_and_set_configs $CONFIG
prepare_datasets $BENCHMARK
# --- finally, launch the job
launch_benchmark_config
