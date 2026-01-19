#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <pthread.h>
#include <immintrin.h>
#include <signal.h>
#include <time.h>
#include <unistd.h>

static volatile int running = 1;

void sigint_handler(int sig) {
    (void)sig;
    running = 0;
}

#define DEFAULT_SIZE_GB 4
#define DEFAULT_THREADS 32
#define CACHELINE 64

typedef struct {
    char *buf;
    size_t size;
    int id;
    uint64_t bytes_written;
} thread_arg_t;

void *saturate_write(void *arg) {
    thread_arg_t *t = (thread_arg_t *)arg;
    char *buf = t->buf;
    size_t size = t->size;
    __m256i val = _mm256_set1_epi64x(0xDEADBEEFCAFEBABE);
    t->bytes_written = 0;

    while (running) {
        for (size_t i = 0; i < size; i += CACHELINE) {
            _mm256_stream_si256((__m256i *)(buf + i), val);
            _mm256_stream_si256((__m256i *)(buf + i + 32), val);
        }
        _mm_sfence();
        t->bytes_written += size;
    }
    return NULL;
}

void *saturate_read(void *arg) {
    thread_arg_t *t = (thread_arg_t *)arg;
    char *buf = t->buf;
    size_t size = t->size;
    __m256i sum = _mm256_setzero_si256();
    t->bytes_written = 0;

    while (running) {
        for (size_t i = 0; i < size; i += CACHELINE) {
            sum = _mm256_add_epi64(sum, _mm256_load_si256((__m256i *)(buf + i)));
            sum = _mm256_add_epi64(sum, _mm256_load_si256((__m256i *)(buf + i + 32)));
        }
        t->bytes_written += size;
    }
    volatile __m256i sink = sum; (void)sink;
    return NULL;
}

void *saturate_readwrite(void *arg) {
    thread_arg_t *t = (thread_arg_t *)arg;
    char *buf = t->buf;
    size_t size = t->size;
    t->bytes_written = 0;

    while (running) {
        for (size_t i = 0; i < size; i += CACHELINE * 2) {
            __m256i v0 = _mm256_load_si256((__m256i *)(buf + i));
            __m256i v1 = _mm256_load_si256((__m256i *)(buf + i + 32));
            _mm256_stream_si256((__m256i *)(buf + i + CACHELINE), v0);
            _mm256_stream_si256((__m256i *)(buf + i + CACHELINE + 32), v1);
        }
        _mm_sfence();
        t->bytes_written += size;
    }
    return NULL;
}

int main(int argc, char **argv) {
    int nthreads = DEFAULT_THREADS;
    size_t size_gb = DEFAULT_SIZE_GB;
    int mode = 0;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-t") == 0 && i+1 < argc) nthreads = atoi(argv[++i]);
        else if (strcmp(argv[i], "-s") == 0 && i+1 < argc) size_gb = atol(argv[++i]);
        else if (strcmp(argv[i], "-m") == 0 && i+1 < argc) mode = atoi(argv[++i]);
        else if (strcmp(argv[i], "-h") == 0) {
            printf("Usage: %s [-t threads] [-s size_gb] [-m mode]\n", argv[0]);
            printf("  -t threads    Number of threads (default: %d)\n", DEFAULT_THREADS);
            printf("  -s size_gb    Total memory in GB (default: %d)\n", DEFAULT_SIZE_GB);
            printf("  -m mode       0=write, 1=read, 2=read+write (default: 0)\n");
            printf("\nRuns until Ctrl+C. Example:\n");
            printf("  numactl -m 4-7 -N 4-7 %s -t 32 -s 4\n", argv[0]);
            return 0;
        }
    }

    size_t total_size = size_gb * 1024UL * 1024UL * 1024UL;
    size_t per_thread = total_size / nthreads;
    per_thread = (per_thread / CACHELINE) * CACHELINE;

    printf("Memory Saturator (AVX2) for AMD EPYC\n");
    printf("=====================================\n");
    printf("  Threads: %d\n", nthreads);
    printf("  Total memory: %zu GB\n", size_gb);
    printf("  Per thread: %zu MB\n", per_thread / (1024*1024));
    printf("  Mode: %s\n", mode == 0 ? "write (NT)" : mode == 1 ? "read" : "read+write");
    printf("Allocating memory...\n");

    char **bufs = malloc(nthreads * sizeof(char *));
    for (int i = 0; i < nthreads; i++) {
        if (posix_memalign((void **)&bufs[i], 4096, per_thread) != 0) {
            perror("posix_memalign");
            return 1;
        }
        memset(bufs[i], 0xAA, per_thread);
    }

    printf("Starting saturation...\n\n");
    signal(SIGINT, sigint_handler);
    signal(SIGTERM, sigint_handler);

    // Block signals in worker threads so only main receives them
    sigset_t set;
    sigemptyset(&set);
    sigaddset(&set, SIGINT);
    sigaddset(&set, SIGTERM);
    pthread_sigmask(SIG_BLOCK, &set, NULL);
    pthread_t *threads = malloc(nthreads * sizeof(pthread_t));
    thread_arg_t *args = malloc(nthreads * sizeof(thread_arg_t));

    void *(*func)(void *) = mode == 0 ? saturate_write : mode == 1 ? saturate_read : saturate_readwrite;

    for (int i = 0; i < nthreads; i++) {
        args[i].buf = bufs[i];
        args[i].size = per_thread;
        args[i].id = i;
        args[i].bytes_written = 0;
        pthread_create(&threads[i], NULL, func, &args[i]);
    }

    // Unblock signals in main thread
    pthread_sigmask(SIG_UNBLOCK, &set, NULL);

    time_t start = time(NULL);
    uint64_t last_total = 0;
    printf("Running until Ctrl+C...\n\n");
    while (running) {
        sleep(1);
        if (!running) break;
        uint64_t total = 0;
        for (int i = 0; i < nthreads; i++) total += args[i].bytes_written;
        double instant_bw = (total - last_total) / (1024.0*1024.0*1024.0);
        double elapsed = (double)(time(NULL) - start);
        double avg_bw = elapsed > 0 ? (total / elapsed) / (1024.0*1024.0*1024.0) : 0;
        printf("\rInstant: %.2f GB/s | Avg: %.2f GB/s   ", instant_bw, avg_bw);
        fflush(stdout);
        last_total = total;
    }
    for (int i = 0; i < nthreads; i++) pthread_join(threads[i], NULL);

    printf("\nCaught signal, shutting down...\n");
    for (int i = 0; i < nthreads; i++) free(bufs[i]);
    free(bufs); free(threads); free(args);
    return 0;
}
