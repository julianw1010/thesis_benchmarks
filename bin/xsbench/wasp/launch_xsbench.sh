interrupted=0
trap "interrupted=1; echo 'Interrupted. Exiting...'" SIGINT
echo -1 | sudo tee /proc/mitosis/cache
echo 500000 | sudo tee /proc/mitosis/cache
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches
echo -1 | sudo tee /proc/mitosis/history
rm history.txt output.txt
script -e -q -c "numactl -P /usr/bin/time --verbose -- ../bench_xsbench_mt -- -p 25000000 -g 400000" output.txt
[[ $? -eq 130 ]] && { echo "Interrupted. Exiting..."; exit 1; }
cat /proc/mitosis/history > history.txt
