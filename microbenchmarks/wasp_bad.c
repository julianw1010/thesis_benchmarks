#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <sched.h>
#include <pthread.h>
#include <stdatomic.h>
#include <signal.h>
#include <math.h>
#include <stdint.h>

#define HOT_DURATION_MS   5000
#define COLD_DURATION_MS  5000
#define REGION_SIZE       (512UL * 1024 * 1024)
#define NUM_THREADS       4
#define STRIDE            4096
#define BATCH             256
#define MAX_CYCLES        256

static atomic_int phase = 0;
static atomic_int running = 1;
static atomic_uint_fast64_t global_ops = 0;
static volatile char *region;
static int baseline_mode = 0;

typedef struct {
    double hot_throughput;
    double hot_duration_actual;
} cycle_stats_t;

static cycle_stats_t cycles[MAX_CYCLES];

static double now_ms(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec * 1000.0 + tv.tv_usec / 1000.0;
}

static void sighandler(int sig) {
    (void)sig;
    atomic_store(&running, 0);
}

static void *worker(void *arg) {
    int id = (int)(long)arg;
    unsigned int seed = (unsigned int)(id * 7919 + 31337);
    size_t num_pages = REGION_SIZE / STRIDE;
    uint64_t local_ops = 0;

    while (atomic_load(&running)) {
        if (atomic_load(&phase) == 1) {
            for (int b = 0; b < BATCH; b++) {
                size_t idx = (rand_r(&seed) % num_pages) * STRIDE;
                volatile char v = region[idx];
                (void)v;
            }
            local_ops += BATCH;
            if (local_ops >= 10000) {
                atomic_fetch_add(&global_ops, local_ops);
                local_ops = 0;
            }
        } else {
            if (local_ops > 0) {
                atomic_fetch_add(&global_ops, local_ops);
                local_ops = 0;
            }
            struct timespec ts = {0, 1000000};
            nanosleep(&ts, NULL);
        }
    }
    atomic_fetch_add(&global_ops, local_ops);
    return NULL;
}

static void print_summary(int num_cycles) {
    double sum_thr = 0, sum_thr2 = 0;
    int valid = 0;

    printf("\n========== RESULTS ==========\n");
    printf("%-6s %12s %10s\n", "Cycle", "Mops/s", "HotMs");
    printf("------------------------------------\n");

    for (int i = 0; i < num_cycles; i++) {
        cycle_stats_t *c = &cycles[i];
        double mops = c->hot_throughput / 1e6;
        printf("%-6d %12.2f %10.1f\n", i, mops, c->hot_duration_actual);
        sum_thr += c->hot_throughput;
        sum_thr2 += c->hot_throughput * c->hot_throughput;
        valid++;
    }

    if (valid == 0) return;

    double mean = sum_thr / valid;
    double var  = (sum_thr2 / valid) - (mean * mean);
    double sd   = (var > 0) ? sqrt(var) : 0;
    double cv   = (mean > 0) ? (sd / mean) * 100.0 : 0;

    printf("------------------------------------\n");
    printf("Mean throughput:  %.2f Mops/s\n", mean / 1e6);
    printf("Stddev:           %.2f Mops/s\n", sd / 1e6);
    printf("CoV:              %.1f%%\n", cv);
    printf("Mode:             %s\n", baseline_mode ? "BASELINE (hot only)" : "OSCILLATING");
    printf("Config:           hot=%dms cold=%dms threads=%d region=%luMB\n",
           HOT_DURATION_MS, COLD_DURATION_MS, NUM_THREADS,
           REGION_SIZE / (1024 * 1024));
}

int main(int argc, char *argv[]) {
    int max_cycles = 20;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-b") == 0 || strcmp(argv[i], "--baseline") == 0)
            baseline_mode = 1;
        else if (strcmp(argv[i], "-n") == 0 && i + 1 < argc)
            max_cycles = atoi(argv[++i]);
        else if (strcmp(argv[i], "-h") == 0) {
            printf("Usage: %s [-b|--baseline] [-n cycles]\n", argv[0]);
            printf("  -b    Baseline mode: stay hot, no oscillation\n");
            printf("  -n N  Number of cycles [default: 20]\n");
            return 0;
        }
    }
    if (max_cycles > MAX_CYCLES) max_cycles = MAX_CYCLES;

    signal(SIGINT, sighandler);
    signal(SIGTERM, sighandler);

    region = mmap(NULL, REGION_SIZE, PROT_READ | PROT_WRITE,
                  MAP_PRIVATE | MAP_ANONYMOUS | MAP_POPULATE, -1, 0);
    if (region == MAP_FAILED) {
        perror("mmap");
        return 1;
    }
    memset((void *)region, 0xAB, REGION_SIZE);

    pthread_t threads[NUM_THREADS];
    for (int i = 0; i < NUM_THREADS; i++)
        pthread_create(&threads[i], NULL, worker, (void *)(long)i);

    printf("PID %d — %s mode, %d cycles, %d threads, %lu MB region\n",
           getpid(), baseline_mode ? "baseline" : "oscillating",
           max_cycles, NUM_THREADS, REGION_SIZE / (1024 * 1024));

    for (int c = 0; c < max_cycles && atomic_load(&running); c++) {
        cycle_stats_t *s = &cycles[c];
        memset(s, 0, sizeof(*s));

        atomic_store(&global_ops, 0);
        atomic_store(&phase, 1);
        double hot_start = now_ms();

        double deadline = now_ms() + HOT_DURATION_MS;
        while (now_ms() < deadline && atomic_load(&running))
            usleep(50000);

        double hot_end = now_ms();
        uint64_t ops = atomic_load(&global_ops);
        s->hot_duration_actual = hot_end - hot_start;
        s->hot_throughput = (double)ops / (s->hot_duration_actual / 1000.0);

        printf("[%3d] %.2f Mops/s\n", c, s->hot_throughput / 1e6);
        fflush(stdout);

        if (!baseline_mode) {
            atomic_store(&phase, 0);
            deadline = now_ms() + COLD_DURATION_MS;
            while (now_ms() < deadline && atomic_load(&running))
                usleep(50000);
        }
    }

    atomic_store(&running, 0);
    for (int i = 0; i < NUM_THREADS; i++)
        pthread_join(threads[i], NULL);
    munmap((void *)region, REGION_SIZE);

    print_summary(max_cycles);
    return 0;
}
