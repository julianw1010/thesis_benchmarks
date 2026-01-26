#!/bin/bash
set -e


echo 1 | sudo tee /proc/hydra/tlbflush_opt

for repl_order in {0,9}; do
    echo "=== Setting repl_order=$repl_order ==="
    echo $repl_order | sudo tee /proc/hydra/repl_order

    ../launch_benchmark.sh 2 3 "hydra/50gb/repl_order_${repl_order}" ./bench_xsbench_mt -- -p 25000000 -g 100000
    ../launch_benchmark.sh 3 3 "hydra/50gb/repl_order_${repl_order}" ./bench_xsbench_mt -- -p 25000000 -g 100000
    ../launch_benchmark.sh 2 3 "hydra/100gb/repl_order_${repl_order}" ./bench_xsbench_mt -- -p 25000000 -g 200000
    ../launch_benchmark.sh 3 3 "hydra/100gb/repl_order_${repl_order}" ./bench_xsbench_mt -- -p 25000000 -g 200000    
    ../launch_benchmark.sh 2 3 "hydra/200gb/repl_order_${repl_order}" ./bench_xsbench_mt -- -p 25000000 -g 400000
    ../launch_benchmark.sh 3 3 "hydra/200gb/repl_order_${repl_order}" ./bench_xsbench_mt -- -p 25000000 -g 400000
done
