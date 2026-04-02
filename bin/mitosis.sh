#!/bin/bash
set -e
for script in ~/thesis_benchmarks/bin/*/mitosis_amd.sh; do
    [[ "$script" == */memcached/* ]] && continue
    echo "=== Running: $script ==="
    cd "$(dirname "$script")" && bash "$(basename "$script")"
done
