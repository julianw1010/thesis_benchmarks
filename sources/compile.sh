find . -mindepth 1 -name Makefile -execdir make clean \;
make clean-all
make -j$(nproc) all
mv bin/converter ../datasets
mv bin/* ../bin
cd ../bin
./move.sh
