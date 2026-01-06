for d in */; do (cd "$d" && make clean); done
make clean
make -j$(nproc)
mv bin/* ../bin
