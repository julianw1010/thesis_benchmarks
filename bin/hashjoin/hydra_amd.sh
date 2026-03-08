#!/bin/bash
set -e


echo 1 | sudo tee /proc/hydra/tlbflush_opt

for repl_order in 9; do
    echo "=== Setting repl_order=$repl_order ==="
    echo $repl_order | sudo tee /proc/hydra/repl_order

    ../launch_benchmark.sh 2 5 "hydra/repl_order_${repl_order}" ./bench_hashjoin_mt -- -o 1659000000 -i 100000000 -s 100000000 -n 7
    ../launch_benchmark.sh 3 5 "hydra/repl_order_${repl_order}" ./bench_hashjoin_mt -- -o 1659000000 -i 100000000 -s 100000000 -n 7
done
