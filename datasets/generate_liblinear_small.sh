#!/bin/bash
ROOT=$(dirname `readlink -f "$0"`)

if [ -f $ROOT/kdd12_5gb ]; then
    echo "kdd12_5gb already exists. Skipping generation."
    exit 0
fi

if [ ! -f $ROOT/kdd12 ]; then
    echo "kdd12 not found. Run prepare_liblinear_large.sh first."
    exit 1
fi

echo "Generating kdd12_5gb (first 5GB of kdd12)..."
head -c 5G $ROOT/kdd12 | head -n -1 > $ROOT/kdd12_5gb
echo "Done."
