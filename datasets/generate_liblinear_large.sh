#!/bin/bash
ROOT=$(dirname `readlink -f "$0"`)
URL="https://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/binary/kdd12.xz"

if [ -f $ROOT/kdd12 ]; then
    echo "kdd12 already exists. Skipping download and extraction."
    exit 0
fi

echo "Downloading kdd12 dataset..."
wget -c $URL -P $ROOT
echo "Download Completed."
echo "Extracting now. This may take a while..."
xz -dk $ROOT/kdd12.xz
