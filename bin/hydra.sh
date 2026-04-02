#!/bin/bash
set -e
for script in ~/thesis_benchmarks/bin/*/hydra_amd.sh; do
    [[ "$script" == */memcached/* ]] && continue
    echo "=== Running: $script ==="
    bash "$script"
done
