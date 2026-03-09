#!/bin/bash
for f in *.c; do
    gcc "$f" -o "${f%.c}"
done
