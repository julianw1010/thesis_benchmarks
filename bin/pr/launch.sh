#!/bin/bash
sync; echo 3 > /proc/sys/vm/drop_caches
rm -f /tmp/alloctest-bench.ready

numactl-wasp -r all ./bench_pr_mt -f ../../datasets/graphs/kron29.sg &
PID=$!

echo "Waiting for ready signal..."
while [ ! -f /tmp/alloctest-bench.ready ]; do sleep 0.1; done

echo "Flushing PT cache lines for PID $PID"
echo $PID > /proc/mitosis/flush

wait $PID
