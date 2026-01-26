#!/bin/bash

for xy in {27..30}; do
    if [[ ! -f "graphs/kron${xy}.sg" ]]; then
        ./converter -g "$xy" -b "graphs/kron${xy}.sg"
    else
        echo "graphs/kron${xy}.sg already exists, skipping"
    fi
    if [[ ! -f "graphs/uni${xy}.sg" ]]; then
        ./converter -u "$xy" -b "graphs/uni${xy}.sg"
    else
        echo "graphs/uni${xy}.sg already exists, skipping"
    fi
done
