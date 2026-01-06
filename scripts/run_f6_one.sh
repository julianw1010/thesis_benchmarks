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
#   Socket 1: nodes 0, 1, 2, 3
#   Socket 2: nodes 4, 5, 6, 7
###############################################################################

#echo "************************************************************************"
#echo "ASPLOS'20 - Artifact Evaluation - Mitosis - Figure 6, 10"
#echo "************************************************************************"

ROOT=$(dirname `readlink -f "$0"`)
MAIN="$(dirname "$ROOT")"
#source $ROOT/site_config.sh

XSBENCH_ARGS=" -- -t 16 -g 18000 -p 1500000"
LIBLINEAR_ARGS=" -- -s 6 -n 28 $MAIN/datasets/kdd12 "
CANNEAL_ARGS=" -- 1 150000 2000 $MAIN/datasets/canneal_small 500 "
HASHJOIN_ARGS=" -- -o 115000000 -i 10000000 -s 10000000 "
GUPS_ARGS=" -- 16"
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
	if [ $1 == "gups" ] || 	[ $1 == "btree" ] || [ $1 == "redis" ] || [ $1 == "hashjoin" ]; then
		POSTFIX="_st"
	else
		POSTFIX="_mt"
	fi
	PREFIX="bench_"
        #POSTFIX="_toy"
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

	###########################################################################
	# NODE ASSIGNMENT FOR 8-NODE SYSTEM
	# Socket 1: nodes 0, 1, 2, 3
	# Socket 2: nodes 4, 5, 6, 7
	#
	# We use node 0 to represent socket 1, node 4 to represent socket 2
	#
	# Configuration meanings (from paper Table 2, Figure 5):
	#   LP = Local Page-table (PT on same socket as CPU)
	#   RP = Remote Page-table (PT on different socket from CPU)
	#   LD = Local Data (Data on same socket as CPU)
	#   RD = Remote Data (Data on different socket from CPU)
	#   I  = Interference (memory-intensive process on target resource's node)
	#
	# Workload Migration Scenario:
	#   - Workload runs on CPU_NODE
	#   - Page tables are allocated on PT_NODE
	#   - Data is allocated on DATA_NODE
	#   - Interference runs on INT_NODE (if applicable)
	###########################################################################

	# Page table node - always on socket 1 (node 0) as the "original" location
	PT_NODE=0

	# --- Setup CPU node ---
	# "Local PT" configs (LP-*): CPU runs on same socket as PT (socket 1)
	# "Remote PT" configs (RP-*): CPU runs on different socket from PT (socket 2)
	if [ $CURR_CONFIG == "LPLD" ] || [ $CURR_CONFIG == "LPRD" ] || [ $CURR_CONFIG == "LPRDI" ]; then
		CPU_NODE=0   # Socket 1 - same as PT_NODE, so PT is LOCAL
	else
		CPU_NODE=4   # Socket 2 - different from PT_NODE, so PT is REMOTE
	fi

	# --- Setup data node ---
	# "*LD" configs: Data should be LOCAL to CPU (same socket as CPU)
	# "*RD" configs: Data should be REMOTE from CPU (different socket from CPU)
	case $CURR_CONFIG in
		"LPLD")
			# Local PT, Local Data: CPU=0(S1), PT=0(S1), Data=0(S1)
			DATA_NODE=0
			;;
		"LPRD")
			# Local PT, Remote Data: CPU=0(S1), PT=0(S1), Data=4(S2)
			DATA_NODE=4
			;;
		"LPRDI")
			# Local PT, Remote Data + Interference: CPU=0(S1), PT=0(S1), Data=4(S2)
			DATA_NODE=4
			;;
		"RPLD")
			# Remote PT, Local Data: CPU=4(S2), PT=0(S1), Data=4(S2)
			DATA_NODE=4
			;;
		"RPILD")
			# Remote PT + Interference, Local Data: CPU=4(S2), PT=0(S1), Data=4(S2)
			DATA_NODE=4
			;;
		"RPRD")
			# Remote PT, Remote Data: CPU=4(S2), PT=0(S1), Data=0(S1)
			DATA_NODE=0
			;;
		"RPIRDI")
			# Remote PT + Interference, Remote Data + Interference: CPU=4(S2), PT=0(S1), Data=0(S1)
			DATA_NODE=0
			;;
	esac

	# --- Setup interference node ---
	# Interference should run on the same node as the resource being stressed
	# LPRDI: Interfere with remote DATA (on socket 2)
	# RPILD: Interfere with remote PT (on socket 1)
	# RPIRDI: Interfere with both PT and DATA (both on socket 1)
	INT_NODE=0  # Default, not used unless interference config
	case $CURR_CONFIG in
		"LPRDI")
			# Interfere on DATA node (socket 2, where data is remote from CPU)
			INT_NODE=4
			;;
		"RPILD")
			# Interfere on PT node (socket 1, where PT is remote from CPU)
			INT_NODE=0
			;;
		"RPIRDI")
			# Interfere on PT & DATA node (both on socket 1, remote from CPU)
			INT_NODE=0
			;;
	esac

	# --- Setup benchmark arguments ---
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

	# Debug output
	echo "=========================================="
	echo "Configuration: $CURR_CONFIG"
	echo "  PT_NODE:   $PT_NODE (Socket $((PT_NODE < 4 ? 1 : 2)))"
	echo "  CPU_NODE:  $CPU_NODE (Socket $((CPU_NODE < 4 ? 1 : 2)))"
	echo "  DATA_NODE: $DATA_NODE (Socket $((DATA_NODE < 4 ? 1 : 2)))"
	echo "  INT_NODE:  $INT_NODE (Socket $((INT_NODE < 4 ? 1 : 2)))"
	echo "  PT is $([ $PT_NODE -lt 4 ] && [ $CPU_NODE -lt 4 ] || [ $PT_NODE -ge 4 ] && [ $CPU_NODE -ge 4 ] && echo 'LOCAL' || echo 'REMOTE') to CPU"
	echo "  Data is $([ $DATA_NODE -lt 4 ] && [ $CPU_NODE -lt 4 ] || [ $DATA_NODE -ge 4 ] && [ $CPU_NODE -ge 4 ] && echo 'LOCAL' || echo 'REMOTE') to CPU"
	echo "=========================================="
}

prepare_all_pathnames()
{
	SCRIPTS=$(readlink -f "`dirname $(readlink -f "$0")`")
	ROOT="$(dirname "$SCRIPTS")"
	BENCHPATH=$ROOT"/bin/$BIN"
	INT_BIN=$ROOT"/bin/bench_stream"
	NUMACTL="/usr/local/bin/numactl"
        if [ ! -e $BENCHPATH ]; then
            echo "Benchmark binary is missing: $BENCHPATH"
            exit
        fi
        if [ ! -e $NUMACTL ]; then
            # Try system numactl
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
        # where to put the output file (based on CONFIG)
        DIR_SUFFIX=6
        FIRST_CHAR=${CONFIG:0:1}
        if [ $FIRST_CHAR == "T" ]; then
                DIR_SUFFIX=10
        fi
	DATADIR=$ROOT"/evaluation/measured/figure$DIR_SUFFIX/$BENCHMARK"
        thp=$(cat /sys/kernel/mm/transparent_hugepage/enabled)
        thp=$(echo $thp | awk '{print $1}')
        RUNDIR=$DATADIR/$(hostname)-config-$BENCHMARK-$CONFIG-$(date +"%Y%m%d-%H%M%S")

	mkdir -p $RUNDIR
        if [ $? -ne 0 ]; then
                echo "Error creating output directory: $RUNDIR"
        fi
	OUTFILE=$RUNDIR/log-$BENCHMARK-$(hostname)-$CONFIG.dat
}

set_system_configs()
{
        CURR_CONFIG=$1
        FIRST_CHAR=${CURR_CONFIG:0:1}
        thp="never"
        if [ $FIRST_CHAR == "T" ]; then
                thp="always"
        fi
        echo $thp | sudo tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null
        if [ $? -ne 0 ]; then
                echo  "ERROR setting thp to: $thp"
                exit
        fi
        echo $thp | sudo tee /sys/kernel/mm/transparent_hugepage/defrag > /dev/null
        if [ $? -ne 0 ]; then
                echo "ERROR setting thp to: $thp"
                exit
        fi

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
	# --- only for canneal and liblinear
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
	LAUNCH_CMD="$CMD_PREFIX $BENCHPATH $BENCH_ARGS"
	echo "Launch command: $LAUNCH_CMD"
	echo $LAUNCH_CMD >> $OUTFILE
	$LAUNCH_CMD > /dev/null 2>&1 &
	BENCHMARK_PID=$!
	echo -e "\e[0mWaiting for benchmark: $BENCHMARK_PID to be ready"
	while [ ! -f /tmp/alloctest-bench.ready ]; do
		sleep 0.1
	done
	SECONDS=0
	launch_interference $CONFIG
	echo -e "\e[0mWaiting for benchmark to be done"
	while [ ! -f /tmp/alloctest-bench.done ]; do
		sleep 0.1
	done
	DURATION=$SECONDS
	wait $BENCHMARK_PID 2>/dev/null
	echo "Execution Time (seconds): $DURATION" >> $OUTFILE
	echo "****success****" >> $OUTFILE
	echo "$BENCHMARK : $CONFIG completed."
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
