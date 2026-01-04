#!/bin/bash

###############################################################################
# Script to run Figure 9 Evaluation of the paper
# 
# Paper: Mitosis - Mitosis: Transparently Self-Replicating Page-Tables 
#                  for Large-Memory Machines
# Authors: Reto Achermann, Jayneel Gandhi, Timothy Roscoe, 
#          Abhishek Bhattacharjee, and Ashish Panwar
###############################################################################

#echo "************************************************************************"
#echo "ASPLOS'20 - Artifact Evaluation - Mitosis - Figure 9"
#echo "************************************************************************"

#ROOT=$(dirname `readlink -f "$0"`)
#source $ROOT/site_config.sh

#PERF_EVENTS=cycles,dTLB-loads,dTLB-load-misses,dTLB-stores,dTLB-store-misses,dtlb_load_misses.walk_duration,dtlb_store_misses.walk_duration
PERF_EVENTS=cycles,dTLB-loads,dTLB-load-misses,dTLB-stores,dTLB-store-misses,dtlb_load_misses.walk_duration,dtlb_store_misses.walk_duration,page_walker_loads.dtlb_l1,page_walker_loads.dtlb_l2,page_walker_loads.dtlb_l3,page_walker_loads.dtlb_memory,page_walker_loads.dtlb_l1,page_walker_loads.dtlb_l2,page_walker_loads.dtlb_l3,page_walker_loads.dtlb_memory,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses
NR_PTCACHE_PAGES=1100000 # --- 2GB per socket
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
		: #echo "Benchmark: $CURR_BENCH"
	else
		echo "Invalid benchmark: $CURR_BENCH"
		exit
	fi
        FIRST_CHAR=${CURR_CONFIG:0:1}
        if [ $FIRST_CHAR == "T" ]; then
                CURR_CONFIG=${CURR_CONFIG:1}
        fi
	if [ $CURR_CONFIG == "F" ] || [ $CURR_CONFIG == "FM" ] || [ $CURR_CONFIG == "FA" ] ||
		[ $CURR_CONFIG == "FAM" ] || [ $CURR_CONFIG == "I" ] || [ $CURR_CONFIG == "IM" ]; then
		: #echo "Config: $CURR_CONFIG"
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
	PERF="/usr/local/bin/perf"
	NUMACTL="/usr/local/bin/numactl"
        if [ ! -e $BENCHPATH ]; then
                echo "Benchmark binary is missing"
                exit
        fi
        if [ ! -e $PERF ]; then
                echo "Perf binary is missing"
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
	OUTFILE=$RUNDIR/perflog-$BENCHMARK-$(hostname)-$CONFIG.dat
}

test_and_set_configs()
{
        CURR_CONFIG=$1
        FIRST_CHAR=${CURR_CONFIG:0:1}

        # obtain the number of available nodes
        NODESTR=$(numactl --hardware | grep available)
        NODE_MAX=$(echo ${NODESTR##*: } | cut -d " " -f 1)
        NODE_MAX=`expr $NODE_MAX - 1`
        CMD_PREFIX=$NUMACTL

        # --- check interleaving
        if [ $CURR_CONFIG == "I" ] || [ $CURR_CONFIG == "IM" ] || [ $CURR_CONFIG == "TI" ] || [ $CURR_CONFIG == "TIM" ]; then
                CMD_PREFIX+=" --interleave=all"
        fi

        # --- check page table replication
        LAST_CHAR="${CURR_CONFIG: -1}"
        if [ $LAST_CHAR == "M" ]; then
                CMD_PREFIX+=" --pgtablerepl=all "
                # --- drain first then reserve
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
	# --- only for canneal and liblinear
	if [ $1 == "canneal" ]; then
		$ROOT/datasets/prepare_canneal_datasets.sh large
	fi
}

launch_benchmark_config()
{
	# --- clean up exisiting state/processes
	rm /tmp/alloctest-bench.ready
	rm /tmp/alloctest-bench.done
	killall bench_stream
	LAUNCH_CMD="$CMD_PREFIX $BENCHPATH $BENCH_ARGS"
	echo $LAUNCH_CMD >> $OUTFILE
	echo $LAUNCH_CMD
	$LAUNCH_CMD 2>&1 &
	BENCHMARK_PID=$!
	echo -e "\e[0mWaiting for benchmark: $BENCHMARK_PID to be ready"
	while [ ! -f /tmp/alloctest-bench.ready ]; do
		sleep 0.1
	done
	SECONDS=0
	$PERF stat -x, -o $OUTFILE --append -e $PERF_EVENTS -p $BENCHMARK_PID &
	PERF_PID=$!
	echo -e "\e[0mWaiting for benchmark to be done"
	while [ ! -f /tmp/alloctest-bench.done ]; do
		sleep 0.1
	done
	DURATION=$SECONDS
	kill -INT $PERF_PID
	wait $PERF_PID
	wait $BENCHMARK_PID
	echo "Execution Time (seconds): $DURATION" >> $OUTFILE
	echo "Execution Time (seconds): $DURATION"
	echo "****success****" >> $OUTFILE
	echo "****success****"
	echo "$BENCHMARK : $CONFIG completed."
        echo ""
	killall bench_stream
}

# --- prepare the setup
validate_benchmark_config $BENCHMARK $CONFIG
prepare_benchmark_name $BENCHMARK
test_and_set_pathnames
test_and_set_configs $CONFIG
prepare_datasets $BENCHMARK
# --- finally, launch the job
launch_benchmark_config
