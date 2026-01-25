#!/bin/bash

# Directories to process
dirs=("bc" "pr" "cc" "cc_sv" "pr_spmv" "bfs")

# Subfolders to process
subfolders=("linux" "wasp" "mitosis")

for dir in "${dirs[@]}"; do
    # Handle linux, wasp, mitosis subfolders
    for sub in "${subfolders[@]}"; do
        if [ -d "$dir/$sub" ]; then
            mkdir -p "$dir/$sub/kron29"
            find "$dir/$sub" -maxdepth 1 -type f -exec mv {} "$dir/$sub/kron29/" \;
            echo "Moved files from $dir/$sub to $dir/$sub/kron29/"
        fi
    done
    
    # Handle hydra subfolder - move repl_order_X into kron29/repl_order_X
    if [ -d "$dir/hydra" ]; then
        mkdir -p "$dir/hydra/kron29"
        for repl in "$dir/hydra/repl_order_"*; do
            if [ -d "$repl" ]; then
                mv "$repl" "$dir/hydra/kron29/"
                echo "Moved $repl to $dir/hydra/kron29/"
            fi
        done
    fi
done

echo "Done!"
