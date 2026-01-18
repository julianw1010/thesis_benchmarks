echo -1 | sudo tee /proc/mitosis/history
numactl -r all -i all /usr/bin/time --verbose -- ../bench_xsbench_mt -- -p 25000000 -g 400000
cat /proc/mitosis/history > history_r_i.txt
