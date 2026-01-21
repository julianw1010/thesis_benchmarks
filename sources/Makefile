################################################################################
# Makefile to generate binaries for the paper
#
# Fast Local Page-Tables for Virtualized NUMA Servers with vMitosis [ASPLOS'21]
#
# Authors: Ashish Panwar, Reto Achermann, Abhishek Bhattacharjee, Arkaprava Basu,
#          K. Gopinath and Jayneel Gandhi
#################################################################################

all: btree canneal gups xsbench redis stream hashjoin liblinear gapbs-all

clean-all: clean-btree clean-canneal clean-gups clean-xsbench \
	clean-redis clean-stream clean-hashjoin clean-liblinear clean-gapbs


###############################################################################
# Workloads
###############################################################################

CC = gcc
CXX = g++

INCLUDES=-Icommon

# cflags used
CFLAGS=-O3 -march=native -static
CXXFLAGS=-O3 -march=native -static

# common libraries used
COMMON_LIBS=-lrt -ldl -lnuma -lpthread -lm

# common main functions for multithreaded, single threaded and page-table dump
COMMON_MAIN_M=common/main-mt.c
COMMON_MAIN_S=common/main-st.c
COMMON_MAIN_D=common/main-ptdump.c

sources/mitosis-workloads/README.md:
	echo "initialized git submodules"
	git submodule init 
	git submodule update


###############################################################################
# BTree
###############################################################################

btree/libbtree.a : 
	+$(MAKE) -C btree libbtree.a

btree/libbtreeomp.a : 
	+$(MAKE) -C btree libbtreeomp.a

bin/bench_btree_st : btree/libbtree.a $(COMMON_MAIN_S)
	$(CC) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) $(COMMON_MAIN_S) \
		btree/libbtree.a  -o $@  $(COMMON_LIBS) 

bin/bench_btree_mt : btree/libbtreeomp.a $(COMMON_MAIN_M) 
	$(CC) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) $(COMMON_MAIN_M) \
		btree/libbtreeomp.a -fopenmp -o $@  $(COMMON_LIBS) 		

bin/bench_btree_dump : btree/libbtree.a $(COMMON_MAIN_D)
	$(CC) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) $(COMMON_MAIN_D) \
		btree/libbtree.a  -o $@  $(COMMON_LIBS) 

btree : bin/bench_btree_st bin/bench_btree_dump bin/bench_btree_mt

clean-btree :
	+$(MAKE) -C btree clean
	rm bin/bench_btree_*


###############################################################################
# Canneal
###############################################################################

canneal/libcanneal.a :
	+$(MAKE) -C canneal

canneal/libcannealmt.a :
	+$(MAKE) -C canneal


bin/bench_canneal_mt : canneal/libcannealmt.a  $(COMMON_MAIN_M)
	$(CXX) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) -fopenmp $(COMMON_MAIN_M) \
		canneal/libcannealmt.a  -o $@  $(COMMON_LIBS) -lgomp

bin/bench_canneal_st : canneal/libcanneal.a  $(COMMON_MAIN_S) 
	$(CXX) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) $(COMMON_MAIN_S) \
		canneal/libcanneal.a -fopenmp -o $@  $(COMMON_LIBS) 

canneal : bin/bench_canneal_st bin/bench_canneal_mt

clean-canneal :
	+$(MAKE) -C canneal clean
	rm bin/bench_canneal*

###############################################################################
# GAPBS Benchmarks (pr, cc, cc_sv, pr_spmv, bc, bfs)
###############################################################################

GAP_KERNELS = pr cc cc_sv pr_spmv bc bfs

# Single-threaded versions
gapbs/bench_pr_st:
	+$(MAKE) -C gapbs bench_pr_st
gapbs/bench_cc_st:
	+$(MAKE) -C gapbs bench_cc_st
gapbs/bench_cc_sv_st:
	+$(MAKE) -C gapbs bench_cc_sv_st
gapbs/bench_pr_spmv_st:
	+$(MAKE) -C gapbs bench_pr_spmv_st
gapbs/bench_bc_st:
	+$(MAKE) -C gapbs bench_bc_st
gapbs/bench_bfs_st:
	+$(MAKE) -C gapbs bench_bfs_st

# Multi-threaded versions
gapbs/bench_pr_mt:
	+$(MAKE) -C gapbs bench_pr_mt
gapbs/bench_cc_mt:
	+$(MAKE) -C gapbs bench_cc_mt
gapbs/bench_cc_sv_mt:
	+$(MAKE) -C gapbs bench_cc_sv_mt
gapbs/bench_pr_spmv_mt:
	+$(MAKE) -C gapbs bench_pr_spmv_mt
gapbs/bench_bc_mt:
	+$(MAKE) -C gapbs bench_bc_mt
gapbs/bench_bfs_mt:
	+$(MAKE) -C gapbs bench_bfs_mt

# Copy to bin directory - single-threaded
bin/bench_pr_st: gapbs/bench_pr_st
	cp gapbs/bench_pr_st $@
bin/bench_cc_st: gapbs/bench_cc_st
	cp gapbs/bench_cc_st $@
bin/bench_cc_sv_st: gapbs/bench_cc_sv_st
	cp gapbs/bench_cc_sv_st $@
bin/bench_pr_spmv_st: gapbs/bench_pr_spmv_st
	cp gapbs/bench_pr_spmv_st $@
bin/bench_bc_st: gapbs/bench_bc_st
	cp gapbs/bench_bc_st $@
bin/bench_bfs_st: gapbs/bench_bfs_st
	cp gapbs/bench_bfs_st $@

# Copy to bin directory - multi-threaded
bin/bench_pr_mt: gapbs/bench_pr_mt
	cp gapbs/bench_pr_mt $@
bin/bench_cc_mt: gapbs/bench_cc_mt
	cp gapbs/bench_cc_mt $@
bin/bench_cc_sv_mt: gapbs/bench_cc_sv_mt
	cp gapbs/bench_cc_sv_mt $@
bin/bench_pr_spmv_mt: gapbs/bench_pr_spmv_mt
	cp gapbs/bench_pr_spmv_mt $@
bin/bench_bc_mt: gapbs/bench_bc_mt
	cp gapbs/bench_bc_mt $@
bin/bench_bfs_mt: gapbs/bench_bfs_mt
	cp gapbs/bench_bfs_mt $@

# Aggregate targets
gapbs-st: bin/bench_pr_st bin/bench_cc_st bin/bench_cc_sv_st bin/bench_pr_spmv_st bin/bench_bc_st bin/bench_bfs_st
gapbs-mt: bin/bench_pr_mt bin/bench_cc_mt bin/bench_cc_sv_mt bin/bench_pr_spmv_mt bin/bench_bc_mt bin/bench_bfs_mt
gapbs-all: gapbs-st gapbs-mt

# Legacy target (keep for backward compatibility)
pr: bin/bench_pr_st

clean-gapbs:
	+$(MAKE) -C gapbs clean
	rm -f bin/bench_pr_st bin/bench_pr_mt \
	      bin/bench_cc_st bin/bench_cc_mt \
	      bin/bench_cc_sv_st bin/bench_cc_sv_mt \
	      bin/bench_pr_spmv_st bin/bench_pr_spmv_mt \
	      bin/bench_bc_st bin/bench_bc_mt \
	      bin/bench_bfs_st bin/bench_bfs_mt

# Keep old clean-pr for backward compatibility
clean-pr: clean-gapbs

###############################################################################
# Gups
###############################################################################

gups/libgups.a :
	+$(MAKE) -C gups libgups.a

gups/libgupsmp.a :
	+$(MAKE) -C gups libgupsmp.a

gups/libgupstoy.a :
	+$(MAKE) -C gups libgupstoy.a

bin/bench_gups_st: gups/libgups.a
	$(CC) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) $(COMMON_MAIN_S) \
		gups/libgups.a -o $@ $(COMMON_LIBS)

bin/bench_gups_mt: gups/libgupsmp.a
	$(CC) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) -fopenmp $(COMMON_MAIN_M) \
		gups/libgupsmp.a -o $@ $(COMMON_LIBS)

bin/bench_gups_toy: gups/libgupstoy.a
	$(CC) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) $(COMMON_MAIN_S) \
		gups/libgupstoy.a -o $@ $(COMMON_LIBS)

gups: bin/bench_gups_st bin/bench_gups_mt bin/bench_gups_toy

clean-gups:
	+$(MAKE) -C gups clean
	rm -f bin/bench_gups*

###############################################################################
# HashJoin
###############################################################################


hashjoin/libhashjoin.a : 
	+$(MAKE) -C hashjoin libhashjoin.a	

hashjoin/libhashjoinomp.a : 
	+$(MAKE) -C hashjoin libhashjoinomp.a		

bin/bench_hashjoin_st: hashjoin/libhashjoin.a
	$(CC) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) $(COMMON_MAIN_S) \
		hashjoin/libhashjoin.a -o $@  $(COMMON_LIBS)

bin/bench_hashjoin_mt: hashjoin/libhashjoinomp.a
	$(CC) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) -fopenmp \
		$(COMMON_MAIN_M) hashjoin/libhashjoinomp.a -o $@  $(COMMON_LIBS)

bin/bench_hashjoin_dump: hashjoin/libhashjoinomp.a
	$(CC) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) -fopenmp \
		$(COMMON_MAIN_D) hashjoin/libhashjoinomp.a -o $@  $(COMMON_LIBS)

hashjoin : bin/bench_hashjoin_st bin/bench_hashjoin_mt bin/bench_hashjoin_dump

clean-hashjoin :
	+$(MAKE) -C hashjoin clean
	rm bin/bench_hashjoin*

###############################################################################
# LibLinear
###############################################################################

liblinear/train :
	+$(MAKE) -C liblinear train

bin/bench_liblinear_st : liblinear/train
	cp liblinear/train $@

liblinear : bin/bench_liblinear_st

clean-liblinear :
	+$(MAKE) -C liblinear clean
	rm -f bin/bench_liblinear*

###############################################################################
# Redis
###############################################################################

REDISLIBS=redis/src/libredis-server.a \
          redis/deps/lua/src/liblua.a \
          redis/deps/hiredis/libhiredis.a

REDISLIBSOMP=redis/src/libredis-server-omp.a \
             redis/deps/lua/src/liblua.a \
             redis/deps/hiredis/libhiredis.a

redis/src/libredis-server.a:
	+$(MAKE) -C redis/src/ libredis-server.a

redis/src/libredis-server-omp.a: 
	+$(MAKE) -C redis/src/ libredis-server-omp.a

redis/deps/lua/src/liblua.a: 
	+$(MAKE) -C redis/deps/lua

redis/deps/hiredis/libhiredis.a: 
	+$(MAKE) -C $(@D)

bin/bench_redis_st: $(REDISLIBS) $(COMMON_MAIN_S)
	$(CC) $(INCLUDES) $(CFLAGS) -DDISABLE_SIGNAL_IN_MAIN \
		$(COMMON_MAIN_S) $(REDISLIBS) $(COMMON_LIBS) \
		-o $@

bin/bench_redis_mt: $(REDISLIBSOMP) $(COMMON_MAIN_M)
	$(CC) $(INCLUDES) $(CFLAGS) -fopenmp -DDISABLE_SIGNAL_IN_MAIN \
		$(COMMON_MAIN_M) $(REDISLIBSOMP) $(COMMON_LIBS) \
		-o $@

redis : bin/bench_redis_st bin/bench_redis_mt

clean-redis :
	+$(MAKE) -C redis clean
	rm -f bin/bench_redis*

###############################################################################
# XSBench
###############################################################################

XSBENCHSRC=xsbench/src

$(XSBENCHSRC)/libxsbench.a : 
	+$(MAKE) -C $(XSBENCHSRC) libxsbench.a 

$(XSBENCHSRC)/libxsbenchomp.a : 
	+$(MAKE) -C $(XSBENCHSRC) libxsbenchomp.a 

bin/bench_xsbench_mt: $(XSBENCHSRC)/libxsbenchomp.a $(COMMON_MAIN_M)
	$(CC) $(INCLUDES) $(CFLAGS) -fopenmp -DDISABLE_SIGNAL_IN_MAIN \
		$(COMMON_MAIN_M) $(XSBENCHSRC)/libxsbenchomp.a $(COMMON_LIBS) \
		-o $@

bin/bench_xsbench_st: $(XSBENCHSRC)/libxsbench.a $(COMMON_MAIN_S)
	$(CC) $(INCLUDES) $(CFLAGS) -DDISABLE_SIGNAL_IN_MAIN \
		$(COMMON_MAIN_S) $(XSBENCHSRC)/libxsbench.a $(COMMON_LIBS) \
		-o $@

bin/bench_xsbench_dump: $(XSBENCHSRC)/libxsbenchomp.a $(COMMON_MAIN_D)
	$(CC) $(INCLUDES) $(CFLAGS) -fopenmp -DDISABLE_SIGNAL_IN_MAIN \
		$(COMMON_MAIN_D) $(XSBENCHSRC)/libxsbenchomp.a $(COMMON_LIBS) \
		-o $@

xsbench : bin/bench_xsbench_mt bin/bench_xsbench_st bin/bench_xsbench_dump

clean-xsbench :
	+$(MAKE) -C $(XSBENCHSRC) clean
	rm -f bin/bench_xsbench*

###############################################################################
# Memcached
###############################################################################

memcached/libmemcached.a : 
	+$(MAKE) -C memcached libmemcached.a 

bin/bench_memcached_mt: memcached/libmemcached.a  $(COMMON_MAIN_M)
	$(CC) $(INCLUDES) $(CFLAGS) -fopenmp -DDISABLE_SIGNAL_IN_MAIN \
		$(COMMON_MAIN_M) memcached/libmemcached.a $(COMMON_LIBS) -levent \
		-o $@

memcached : bin/bench_memcached_mt

clean-memcached :
	+$(MAKE) -C memcached clean
	rm bin/bench_memcached*


###############################################################################
# Memops
###############################################################################

bin/bench_memops :
	+$(MAKE) -C memops bench_memops
	cp memops/bench_memops bin

memops: bin/bench_memops 
	
clean-memops :
	+$(MAKE) -C memops clean


###############################################################################
# Stream
###############################################################################

bin/bench_stream :
	+$(MAKE) -C stream stream
	cp stream/stream bin/bench_stream

#bin/bench_stream_numa :
#	+$(MAKE) -C stream stream_numa
#	cp stream/stream_numa bin/bench_stream_numa	

stream: bin/bench_stream #bin/bench_stream_numa 

clean-stream :
	+$(MAKE) -C stream clean
	rm bin/bench_stream

###############################################################################
# Clean
###############################################################################

clean: clean-all
	rm -rf bin/*
