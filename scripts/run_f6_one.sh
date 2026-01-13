#!/bin/bash

###############################################################################
# Script to run Figure 6 & 10 Evaluation of the paper
# 
# Paper: Mitosis - Mitosis: Transparently Self-Replicating Page-Tables 
#                  for Large-Memory Machines
# Authors: Reto Achermann, Jayneel Gandhi, Timothy Roscoe, 
#          Abhishek Bhattacharjee, and Ashish Panwar
#
# MODIFIED FOR 8-NODE SYSTEM:
#   Socket 0: nodes 0, 1, 2, 3
#   Socket 1: nodes 4, 5, 6, 7
#
# MODIFIED TO USE NODE 7 INSTEAD OF NODE 4
#
# MODIFIED TO CAPTURE MAX RSS using /usr/bin/time -v
###############################################################################

ROOT=$(dirname `readlink -f "$0"`)
MAIN="$(dirname "$ROOT")"

XSBENCH_ARGS=" -- -t 16 -g 32000 -p 1500000 "
LIBLINEAR_ARGS=" -- -s 6 -n 28 $MAIN/datasets/kdd12 "
CANNEAL_ARGS=" -- 1 50000 2000 $MAIN/datasets/canneal_3gb_int 400 "
HASHJOIN_ARGS=" -- -o 135000000 -i 1000000 -s 1000000 "

GUPS_ARGS=" -- 16"
BENCH_ARGS=""

# GNU time binary (not shell builtin)
GNU_TIME="/usr/bin/time"

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
        FIRST_CHAR=${CURR_CONFIG:0:1}
        if [ $FIRST_CHAR == "T" ]; then
                CURR_CONFIG=${CURR_CONFIG:1}
        fi
	if [ $CURR_BENCH == "gups" ] || [ $CURR_BENCH == "btree" ] || [ $CURR_BENCH == "hashjoin" ] ||
		[ $CURR_BENCH == "redis" ] || [ $CURR_BENCH == "xsbench" ] || [ $CURR_BENCH == "pagerank" ] ||
		[ $CURR_BENCH == "liblinear" ] || [ $CURR_BENCH == "canneal" ]; then
		: #echo "Benchmark: $CURR_BENCH"
	else
		echo "Invalid benchmark: $CURR_BENCH"
		exit
	fi

	if [ $CURR_CONFIG == "LPLD" ] || [ $CURR_CONFIG == "LPRD" ] || [ $CURR_CONFIG == "LPRDI" ] ||
		[ $CURR_CONFIG == "RPLD" ] || [ $CURR_CONFIG == "RPILD" ] || [ $CURR_CONFIG == "RPRD" ] ||
		[ $CURR_CONFIG == "RPIRDI" ]; then
		: #echo "Config: $CURR_CONFIG"
	else
		echo "Invalid config: $CURR_CONFIG"
		exit
	fi
}

prepare_benchmark_name()
{
	if [ $1 == "gups" ] || 	[ $1 == "btree" ] || [ $1 == "redis" ] || [ $1 == "hashjoin" ] || [ $1 == "xsbench" ]; then
		POSTFIX="_st"
	else
		POSTFIX="_mt"
	fi
	PREFIX="bench_"
	BIN=$PREFIX
	BIN+=$BENCHMARK
	BIN+=$POSTFIX
}

prepare_basic_config_params()
{
	CURR_CONFIG=$1
	FIRST_CHAR=${CURR_CONFIG:0:1}
	if [ $FIRST_CHAR == "T" ]; then
		CURR_CONFIG=${CURR_CONFIG:1}
	fi

	PT_NODE=0

	if [ $CURR_CONFIG == "LPLD" ] || [ $CURR_CONFIG == "LPRD" ] || [ $CURR_CONFIG == "LPRDI" ]; then
		CPU_NODE=0
	else
		CPU_NODE=7
	fi

	case $CURR_CONFIG in
		"LPLD")
			DATA_NODE=0
			;;
		"LPRD")
			DATA_NODE=7
			;;
		"LPRDI")
			DATA_NODE=7
			;;
		"RPLD")
			DATA_NODE=7
			;;
		"RPILD")
			DATA_NODE=7
			;;
		"RPRD")
			DATA_NODE=0
			;;
		"RPIRDI")
			DATA_NODE=0
			;;
	esac

	INT_NODE=0
	case $CURR_CONFIG in
		"LPRDI")
			INT_NODE=7
			;;
		"RPILD")
			INT_NODE=0
			;;
		"RPIRDI")
			INT_NODE=0
			;;
	esac

	if [ $BENCHMARK == "xsbench" ]; then
		BENCH_ARGS=$XSBENCH_ARGS
	elif [ $BENCHMARK == "liblinear" ]; then
		BENCH_ARGS=$LIBLINEAR_ARGS
	elif [ $BENCHMARK == "canneal" ]; then
		BENCH_ARGS=$CANNEAL_ARGS
	elif [ $BENCHMARK == "hashjoin" ]; then
		BENCH_ARGS=$HASHJOIN_ARGS
	elif [ $BENCHMARK == "gups" ]; then
		BENCH_ARGS=$GUPS_ARGS
	fi

	PT_SOCKET=$((PT_NODE / 4))
	CPU_SOCKET=$((CPU_NODE / 4))
	DATA_SOCKET=$((DATA_NODE / 4))
	INT_SOCKET=$((INT_NODE / 4))

	if [ $((PT_NODE / 4)) -eq $((CPU_NODE / 4)) ]; then
		PT_LOCALITY="LOCAL"
	else
		PT_LOCALITY="REMOTE"
	fi

	if [ $((DATA_NODE / 4)) -eq $((CPU_NODE / 4)) ]; then
		DATA_LOCALITY="LOCAL"
	else
		DATA_LOCALITY="REMOTE"
	fi

	echo "=========================================="
	echo "Configuration: $CURR_CONFIG"
	echo "  PT_NODE:   $PT_NODE (Socket $PT_SOCKET)"
	echo "  CPU_NODE:  $CPU_NODE (Socket $CPU_SOCKET)"
	echo "  DATA_NODE: $DATA_NODE (Socket $DATA_SOCKET)"
	echo "  INT_NODE:  $INT_NODE (Socket $INT_SOCKET)"
	echo "  PT is $PT_LOCALITY to CPU"
	echo "  Data is $DATA_LOCALITY to CPU"
	echo "=========================================="
}

prepare_all_pathnames()
{
	SCRIPTS=$(readlink -f "`dirname $(readlink -f "$0")`")
	ROOT="$(dirname "$SCRIPTS")"
	BENCHPATH=$ROOT"/bin/$BENCHMARK/$BIN"
	INT_BIN=$ROOT"/bin/bench_stream"
	NUMACTL="/usr/local/bin/numactl"
        if [ ! -e $BENCHPATH ]; then
            echo "Benchmark binary is missing: $BENCHPATH"
            exit
        fi
        if [ ! -e $NUMACTL ]; then
            NUMACTL=$(which numactl)
            if [ ! -e $NUMACTL ]; then
                echo "numactl is missing"
                exit
            fi
        fi
        if [ ! -e $INT_BIN ]; then
            echo "Interference binary is missing: $INT_BIN"
            exit
        fi
        if [ ! -e $GNU_TIME ]; then
            echo "GNU time is missing at $GNU_TIME"
            echo "Install with: sudo apt install time"
            exit
        fi
        DIR_SUFFIX=6
        FIRST_CHAR=${CONFIG:0:1}
        if [ $FIRST_CHAR == "T" ]; then
                DIR_SUFFIX=10
        fi
	DATADIR=$ROOT"/evaluation/measured/figure$DIR_SUFFIX/$BENCHMARK"
        RUNDIR=$DATADIR/$(hostname)-config-$BENCHMARK-$CONFIG-$(date +"%Y%m%d-%H%M%S")

	mkdir -p $RUNDIR
        if [ $? -ne 0 ]; then
                echo "Error creating output directory: $RUNDIR"
        fi
	OUTFILE=$RUNDIR/log-$BENCHMARK-$(hostname)-$CONFIG.dat
	TIME_FILE=$RUNDIR/time-$BENCHMARK-$(hostname)-$CONFIG.txt
	BENCH_OUTPUT=$RUNDIR/output-$BENCHMARK-$(hostname)-$CONFIG.txt
}

set_system_configs()
{
        echo $PT_NODE | sudo tee /proc/mitosis/mode > /dev/null
        if [ $? -ne 0 ]; then
                echo "ERROR setting pgtable allocation to node: $PT_NODE"
                exit
        fi
}

launch_interference()
{
	CURR_CONFIG=$1
	FIRST_CHAR=${CURR_CONFIG:0:1}
	if [ $FIRST_CHAR == "T" ]; then
		CURR_CONFIG=${CURR_CONFIG:1}
	fi
	if [ $CURR_CONFIG == "LPRDI" ] || [ $CURR_CONFIG == "RPILD" ] || [ $CURR_CONFIG == "RPIRDI" ]; then
		echo "Launching interference on node $INT_NODE"
		$NUMACTL -c $INT_NODE -m $INT_NODE $INT_BIN > /dev/null 2>&1 &
		if [ $? -ne 0 ]; then
			echo "Failure launching interference."
			exit
		fi
	fi
}

prepare_datasets()
{
	SCRIPTS=$(readlink -f "`dirname $(readlink -f "$0")`")
        ROOT="$(dirname "$SCRIPTS")"
	if [ $1 == "canneal" ]; then
		$ROOT/datasets/prepare_canneal_datasets.sh small
	elif [ $1 == "liblinear" ]; then
		$ROOT/datasets/prepare_liblinear_dataset.sh
	fi
}

launch_benchmark_config()
{
	# --- clean up exisiting state/processes
	rm /tmp/alloctest-bench.ready &>/dev/null
	rm /tmp/alloctest-bench.done &> /dev/null
	killall bench_stream &>/dev/null

        CMD_PREFIX=$NUMACTL
        CMD_PREFIX+=" -m $DATA_NODE -c $CPU_NODE "
	
	# Wrap with GNU time -v, output to TIME_FILE
	LAUNCH_CMD="$GNU_TIME -v -o $TIME_FILE $CMD_PREFIX $BENCHPATH $BENCH_ARGS"
	
	echo "Launch command: $LAUNCH_CMD"
	echo "Time output file: $TIME_FILE"
	echo "Benchmark output file: $BENCH_OUTPUT"
	echo $LAUNCH_CMD >> $OUTFILE

	# Record total start time
	TOTAL_START=$SECONDS

	# Run benchmark, capture all output (stdout+stderr) to file AND screen
	# Using 'script' for unbuffered real-time output to both terminal and file
	script -q -f -c "$LAUNCH_CMD" $BENCH_OUTPUT &
	BENCHMARK_PID=$!
	echo -e "\e[0mWaiting for benchmark: $BENCHMARK_PID to be ready"
	while [ ! -f /tmp/alloctest-bench.ready ]; do
		sleep 0.1
	done

	READY_TIME=$SECONDS
	READY_TO_DONE_START=$SECONDS

	launch_interference $CONFIG
	echo -e "\e[0mWaiting for benchmark to be done"
	while [ ! -f /tmp/alloctest-bench.done ]; do
		sleep 0.1
	done

	DONE_TIME=$SECONDS
	READY_TO_DONE_DURATION=$((DONE_TIME - READY_TO_DONE_START))

	wait $BENCHMARK_PID 2>/dev/null

	TOTAL_END=$SECONDS
	TOTAL_DURATION=$((TOTAL_END - TOTAL_START))

	# Parse max RSS from time output
	MAX_RSS_KB=""
	if [ -f $TIME_FILE ]; then
		MAX_RSS_KB=$(grep "Maximum resident set size" $TIME_FILE | awk '{print $NF}')
	fi

	# Convert to human readable
	if [ -n "$MAX_RSS_KB" ]; then
		MAX_RSS_MB=$((MAX_RSS_KB / 1024))
		MAX_RSS_GB=$(echo "scale=2; $MAX_RSS_KB / 1048576" | bc)
		MAX_RSS_DISPLAY="$MAX_RSS_KB kB ($MAX_RSS_MB MB / $MAX_RSS_GB GB)"
	else
		MAX_RSS_DISPLAY="N/A"
	fi

	echo ""
	echo "=========================================="
	echo "TIMING RESULTS:"
	echo "  Total runtime (start to finish): $TOTAL_DURATION seconds"
	echo "  Execution time (ready to done):  $READY_TO_DONE_DURATION seconds"
	echo "  Maximum Resident Set Size:       $MAX_RSS_DISPLAY"
	echo "=========================================="
	
	# Print full time -v output to screen
	echo ""
	echo "========== /usr/bin/time -v output =========="
	cat $TIME_FILE
	echo "============================================="

	# Save to log file
	echo "Total Runtime (seconds): $TOTAL_DURATION" >> $OUTFILE
	echo "Execution Time (ready to done, seconds): $READY_TO_DONE_DURATION" >> $OUTFILE
	echo "Maximum Resident Set Size (kB): $MAX_RSS_KB" >> $OUTFILE
	echo "Maximum Resident Set Size (MB): $MAX_RSS_MB" >> $OUTFILE
	echo "" >> $OUTFILE
	echo "===== TIME OUTPUT =====" >> $OUTFILE
	cat $TIME_FILE >> $OUTFILE
	echo "" >> $OUTFILE
	echo "===== BENCHMARK OUTPUT =====" >> $OUTFILE
	cat $BENCH_OUTPUT >> $OUTFILE
	echo "" >> $OUTFILE
	echo "****success****" >> $OUTFILE
	echo "$BENCHMARK : $CONFIG completed."
	echo ""
	echo "Output files saved to: $RUNDIR"
	echo "  - Log file:       $(basename $OUTFILE)"
	echo "  - Time stats:     $(basename $TIME_FILE)"
	echo "  - Bench output:   $(basename $BENCH_OUTPUT)"
	echo ""
	killall bench_stream &>/dev/null
}

# --- prepare setup
validate_benchmark_config $BENCHMARK $CONFIG
prepare_benchmark_name $BENCHMARK
prepare_basic_config_params $CONFIG
prepare_all_pathnames
prepare_datasets $BENCHMARK
set_system_configs $CONFIG

# --- finally, launch the job
launch_benchmark_config
