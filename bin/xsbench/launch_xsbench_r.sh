resethistory
numactl -r all /usr/bin/time --verbose -- ./bench_xsbench_mt -- -p 25000000 -g 400000
if [ -e /proc/mitosis/history ]; then cat /proc/mitosis/history > history_r.txt; elif [ -e /proc/hydra/history ]; then cat /proc/hydra/history > history_r.txt; else echo "Neither path exists"; fi
