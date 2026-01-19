for d in */; do (cd "$d" && make clean); done
make clean-all
make -j$(nproc) 
mv bin/* ../bin
cd ../bin
./move.sh
