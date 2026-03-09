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

#define HOT_DURATION_MS   5000
#define COLD_DURATION_MS  5000
#define REGION_SIZE       (512UL * 1024 * 1024)
#define NUM_THREADS       4
#define STRIDE            4096
#define BATCH             64

static atomic_int phase = 0;
static atomic_int running = 1;
static volatile char *region;

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

    while (atomic_load(&running)) {
        if (atomic_load(&phase) == 1) {
            for (int b = 0; b < BATCH; b++) {
                size_t idx = (rand_r(&seed) % num_pages) * STRIDE;
                volatile char v = region[idx];
                (void)v;
            }
        } else {
            struct timespec ts = {0, 1000000};
            nanosleep(&ts, NULL);
        }
    }
    return NULL;
}

int main(int argc, char *argv[]) {
    int cycles = 0;
    int max_cycles = 0;

    if (argc > 1) max_cycles = atoi(argv[1]);

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

    printf("PID %d — oscillating hot/cold every %d/%d ms (%d threads, %lu MB region)\n",
           getpid(), HOT_DURATION_MS, COLD_DURATION_MS,
           NUM_THREADS, REGION_SIZE / (1024 * 1024));

    while (atomic_load(&running)) {
        printf("[cycle %d] HOT  — random 4K-stride reads across %lu MB\n",
               cycles, REGION_SIZE / (1024 * 1024));
        fflush(stdout);
        atomic_store(&phase, 1);

        double deadline = now_ms() + HOT_DURATION_MS;
        while (now_ms() < deadline && atomic_load(&running))
            usleep(50000);

        printf("[cycle %d] COLD — sleeping\n", cycles);
        fflush(stdout);
        atomic_store(&phase, 0);

        deadline = now_ms() + COLD_DURATION_MS;
        while (now_ms() < deadline && atomic_load(&running))
            usleep(50000);

        cycles++;
        if (max_cycles > 0 && cycles >= max_cycles) break;
    }

    atomic_store(&running, 0);
    for (int i = 0; i < NUM_THREADS; i++)
        pthread_join(threads[i], NULL);

    munmap((void *)region, REGION_SIZE);

    printf("completed %d cycles\n", cycles);
    return 0;
}
