echo -1 | sudo tee /proc/mitosis/history
script -q -c "numactl -P /usr/bin/time --verbose -- ../bench_xsbench_mt -- -p 25000000 -g 400000" output.txt
cat /proc/mitosis/history > history.txt
