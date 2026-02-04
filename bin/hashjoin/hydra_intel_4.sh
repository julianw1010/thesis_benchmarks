#!/bin/bash
set -e


echo 1 | sudo tee /proc/hydra/tlbflush_opt

for repl_order in 9; do
    echo "=== Setting repl_order=$repl_order ==="
    echo $repl_order | sudo tee /proc/hydra/repl_order

    ../launch_benchmark.sh 2 5 "intel_4/hydra/repl_order_${repl_order}" ./bench_hashjoin_mt -- -o 675000000 -i 135000000 -s 135000000 -n 10
    ../launch_benchmark.sh 3 5 "intel_4/hydra/repl_order_${repl_order}" ./bench_hashjoin_mt -- -o 675000000 -i 135000000 -s 135000000 -n 10
done
