echo -1 | sudo tee /proc/mitosis/cache
trap "echo 'Interrupted. Exiting...'; exit 1" SIGINT
echo 500000 | sudo tee /proc/mitosis/cache
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches
echo -1 | sudo tee /proc/mitosis/history
rm history_r.txt output_r.txt
script -q -c "numactl -r all /usr/bin/time --verbose -- ../bench_xsbench_mt -- -p 25000000 -g 400000" output_r.txt
cat /proc/mitosis/history > history_r.txt
