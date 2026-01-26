#!/bin/bash
set -e
echo 1 | sudo tee /proc/hydra/tlbflush_opt
for repl_order in 0 9; do
    echo "=== Setting repl_order=$repl_order ==="
    echo $repl_order | sudo tee /proc/hydra/repl_order
    
    ../launch_benchmark.sh 2 1 "hydra/kron27/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/kron27.sg -n 5
    ../launch_benchmark.sh 3 1 "hydra/kron27/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/kron27.sg -n 5
    ../launch_benchmark.sh 2 1 "hydra/kron28/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/kron28.sg -n 5
    ../launch_benchmark.sh 3 1 "hydra/kron28/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/kron28.sg -n 5
    ../launch_benchmark.sh 2 1 "hydra/kron29/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/kron29.sg -n 5
    ../launch_benchmark.sh 3 1 "hydra/kron29/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/kron29.sg -n 5
    ../launch_benchmark.sh 2 1 "hydra/kron30/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/kron30.sg -n 5
    ../launch_benchmark.sh 3 1 "hydra/kron30/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/kron30.sg -n 5
    ../launch_benchmark.sh 2 1 "hydra/uni27/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/uni27.sg -n 5
    ../launch_benchmark.sh 3 1 "hydra/uni27/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/uni27.sg -n 5
    ../launch_benchmark.sh 2 1 "hydra/uni28/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/uni28.sg -n 5
    ../launch_benchmark.sh 3 1 "hydra/uni28/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/uni28.sg -n 5
    ../launch_benchmark.sh 2 1 "hydra/uni29/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/uni29.sg -n 5
    ../launch_benchmark.sh 3 1 "hydra/uni29/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/uni29.sg -n 5
    ../launch_benchmark.sh 2 1 "hydra/uni30/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/uni30.sg -n 5
    ../launch_benchmark.sh 3 1 "hydra/uni30/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/uni30.sg -n 5
    ../launch_benchmark.sh 2 1 "hydra/web/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/web.sg -n 5
    ../launch_benchmark.sh 3 1 "hydra/web/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/web.sg -n 5
    ../launch_benchmark.sh 2 1 "hydra/twitter/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/twitter.sg -n 5
    ../launch_benchmark.sh 3 1 "hydra/twitter/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/twitter.sg -n 5
    ../launch_benchmark.sh 2 1 "hydra/road/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/road.sg -n 5
    ../launch_benchmark.sh 3 1 "hydra/road/repl_order_${repl_order}" ./bench_pr_mt -f ../../datasets/graphs/road.sg -n 5
done
