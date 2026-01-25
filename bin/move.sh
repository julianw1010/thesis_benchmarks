#!/bin/bash

# Directories to process
dirs=("bc" "pr" "cc" "cc_sv" "pr_spmv" "bfs")

# Subfolders to move
subfolders=("linux" "hydra" "wasp" "mitosis")

for dir in "${dirs[@]}"; do
    mkdir -p "$dir/oldresults"
    
    for sub in "${subfolders[@]}"; do
        if [ -d "$dir/$sub" ]; then
            mv "$dir/$sub" "$dir/oldresults/"
            echo "Moved $dir/$sub to $dir/oldresults/"
        fi
    done
done

echo "Done!"
