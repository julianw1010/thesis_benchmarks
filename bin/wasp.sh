echo "Please make sure the wasp daemon is running"
#!/bin/bash
set -e
for script in ~/thesis_benchmarks/bin/*/wasp_amd.sh; do
    [[ "$script" == */memcached/* ]] && continue
    echo "=== Running: $script ==="
    bash "$script"
done
