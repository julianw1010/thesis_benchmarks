sudo pkill memcached
numactl -P memcached -m 220000 -t 32 -p 11211 -c 8192 -d
memtier_benchmark \
    -s localhost -p 11211 --protocol=memcache_text \
    --key-minimum=1 --key-maximum=1730000000 --key-pattern=P:P \
    --ratio=1:0 --data-size=24 --threads=128 --clients=20 \
    --pipeline=100 -n 680000 --hide-histogram
memtier_benchmark \
    -s localhost -p 11211 --protocol=memcache_text \
    --key-minimum=1 --key-maximum=1730000000 --key-pattern=R:R \
    --ratio=0:1 --data-size=24 --threads=32 --clients=20 \
    --pipeline=100 --test-time=300
