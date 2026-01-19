sync
echo 3 | sudo tee /proc/sys/vm/drop_caches
echo -1 | sudo tee /proc/mitosis/history
rm history_i.txt output_i.txt
script -q -c "numactl -P -i all /usr/bin/time --verbose -- ../bench_xsbench_mt -- -p 25000000 -g 400000" output_i.txt
cat /proc/mitosis/history > history_i.txt
