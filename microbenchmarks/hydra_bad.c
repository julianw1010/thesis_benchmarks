#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <pthread.h>
#include <numa.h>
#include <numaif.h>
#include <sched.h>
#include <errno.h>

#define PAGE_SIZE 4096
#define PAGES_PER_REGION (512 * 256)
#define REGION_SIZE ((size_t)PAGES_PER_REGION * PAGE_SIZE)
#define ITERATIONS 3

static int num_nodes;
static void **regions;
static pthread_barrier_t barrier;

typedef struct {
    int node_id;
    uint64_t populate_ns;
    uint64_t read_ns[ITERATIONS];
    volatile uint64_t sink;
} thread_arg_t;

static uint64_t now_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ULL + ts.tv_nsec;
}

static void pin_to_node(int node) {
    struct bitmask *mask = numa_allocate_cpumask();
    numa_node_to_cpus(node, mask);
    int cpu = -1;
    for (unsigned i = 0; i < numa_bitmask_nbytes(mask) * 8; i++) {
        if (numa_bitmask_isbitset(mask, i)) {
            cpu = i;
            break;
        }
    }
    numa_free_cpumask(mask);
    if (cpu < 0) {
        fprintf(stderr, "no cpu on node %d\n", node);
        exit(1);
    }
    cpu_set_t cpuset;
    CPU_ZERO(&cpuset);
    CPU_SET(cpu, &cpuset);
    pthread_setaffinity_np(pthread_self(), sizeof(cpuset), &cpuset);
}

static void *worker(void *arg) {
    thread_arg_t *ta = (thread_arg_t *)arg;
    int me = ta->node_id;

    pin_to_node(me);

    volatile char *my_region = (volatile char *)regions[me];
    uint64_t t0 = now_ns();
    for (size_t p = 0; p < PAGES_PER_REGION; p++) {
        my_region[p * PAGE_SIZE] = (char)(p & 0xff);
    }
    ta->populate_ns = now_ns() - t0;

    pthread_barrier_wait(&barrier);

    for (int iter = 0; iter < ITERATIONS; iter++) {
        if (iter > 0) {
            madvise(regions[me], REGION_SIZE, MADV_DONTNEED);
            for (size_t p = 0; p < PAGES_PER_REGION; p++) {
                my_region[p * PAGE_SIZE] = (char)(p & 0xff);
            }
            pthread_barrier_wait(&barrier);
        }

        uint64_t sum = 0;
        t0 = now_ns();
        for (int n = 0; n < num_nodes; n++) {
            if (n == me) continue;
            volatile char *remote = (volatile char *)regions[n];
            for (size_t p = 0; p < PAGES_PER_REGION; p++) {
                sum += remote[p * PAGE_SIZE];
            }
        }
        ta->read_ns[iter] = now_ns() - t0;
        ta->sink = sum;

        pthread_barrier_wait(&barrier);
    }

    return NULL;
}

int main(int argc, char **argv) {
    if (numa_available() < 0) {
        fprintf(stderr, "NUMA not available\n");
        return 1;
    }

    num_nodes = numa_max_node() + 1;
    printf("nodes: %d\n", num_nodes);
    printf("region per node: %zu MB (%d pages)\n",
           REGION_SIZE / (1024 * 1024), PAGES_PER_REGION);
    printf("iterations: %d\n\n", ITERATIONS);

    regions = calloc(num_nodes, sizeof(void *));
    for (int n = 0; n < num_nodes; n++) {
        regions[n] = mmap(NULL, REGION_SIZE, PROT_READ | PROT_WRITE,
                          MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
        if (regions[n] == MAP_FAILED) {
            perror("mmap");
            return 1;
        }
        unsigned long nodemask = 1UL << n;
        if (mbind(regions[n], REGION_SIZE, MPOL_BIND, &nodemask,
                  num_nodes + 1, MPOL_MF_MOVE) < 0) {
            perror("mbind");
            return 1;
        }
    }

    pthread_barrier_init(&barrier, NULL, num_nodes);

    thread_arg_t *args = calloc(num_nodes, sizeof(thread_arg_t));
    pthread_t *threads = calloc(num_nodes, sizeof(pthread_t));

    for (int n = 0; n < num_nodes; n++) {
        args[n].node_id = n;
        pthread_create(&threads[n], NULL, worker, &args[n]);
    }

    for (int n = 0; n < num_nodes; n++) {
        pthread_join(threads[n], NULL);
    }

    printf("%-6s %12s", "node", "populate_ms");
    for (int i = 0; i < ITERATIONS; i++)
        printf(" %10s%d", "read_ms_", i);
    printf("\n");

    for (int n = 0; n < num_nodes; n++) {
        printf("%-6d %12.2f", n, args[n].populate_ns / 1e6);
        for (int i = 0; i < ITERATIONS; i++)
            printf(" %11.2f", args[n].read_ns[i] / 1e6);
        printf("\n");
    }

    uint64_t total_faults = (uint64_t)(num_nodes - 1) * PAGES_PER_REGION * num_nodes;
    printf("\ntotal cross-node page touches per iteration: %lu\n", total_faults);

    for (int n = 0; n < num_nodes; n++)
        munmap(regions[n], REGION_SIZE);

    free(regions);
    free(args);
    free(threads);
    return 0;
}
