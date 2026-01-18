echo -1 | sudo tee /proc/hydra/history
numactl -r all /usr/bin/time --verbose -- ../bench_xsbench_mt -- -p 25000000 -g 400000
cat /proc/hydra/history > history_r.txt
