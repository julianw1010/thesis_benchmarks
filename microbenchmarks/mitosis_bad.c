#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/wait.h>
#include <time.h>
#include <errno.h>

#define REGION_SIZE      (512UL * 1024 * 1024)
#define PAGE_SZ          4096
#define MPROTECT_ITERS   200
#define MMAP_CHURN_ITERS 50000
#define CHURN_SIZE       (64 * PAGE_SZ)

static double now_sec(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec / 1e9;
}

static void phase_mprotect_storm(void) {
    void *region = mmap(NULL, REGION_SIZE, PROT_READ | PROT_WRITE,
                        MAP_PRIVATE | MAP_ANONYMOUS | MAP_POPULATE, -1, 0);
    if (region == MAP_FAILED) { perror("mmap"); exit(1); }
    memset(region, 0xAB, REGION_SIZE);

    double t0 = now_sec();
    for (int i = 0; i < MPROTECT_ITERS; i++) {
        mprotect(region, REGION_SIZE, PROT_READ);
        mprotect(region, REGION_SIZE, PROT_READ | PROT_WRITE);
    }
    double elapsed = now_sec() - t0;

    unsigned long total = (REGION_SIZE / PAGE_SZ) * MPROTECT_ITERS * 2UL;
    printf("Phase 1 - mprotect storm:\n");
    printf("  %lu PTE mutations in %.3f s (%.1f M ops/s)\n\n",
           total, elapsed, total / elapsed / 1e6);

    munmap(region, REGION_SIZE);
}

static void phase_cow_storm(void) {
    void *region = mmap(NULL, REGION_SIZE, PROT_READ | PROT_WRITE,
                        MAP_PRIVATE | MAP_ANONYMOUS | MAP_POPULATE, -1, 0);
    if (region == MAP_FAILED) { perror("mmap"); exit(1); }
    memset(region, 0xCD, REGION_SIZE);

    double t0 = now_sec();
    pid_t pid = fork();
    if (pid < 0) { perror("fork"); exit(1); }

    volatile char *p = (volatile char *)region;
    for (unsigned long off = 0; off < REGION_SIZE; off += PAGE_SZ) {
        p[off] = (char)(off ^ 0xFF);
    }

    if (pid == 0) {
        _exit(0);
    } else {
        waitpid(pid, NULL, 0);
    }

    double elapsed = now_sec() - t0;
    unsigned long faults = (REGION_SIZE / PAGE_SZ) * 2;
    printf("Phase 2 - COW fault storm:\n");
    printf("  %lu COW faults in %.3f s (%.1f K faults/s)\n\n",
           faults, elapsed, faults / elapsed / 1e3);

    munmap(region, REGION_SIZE);
}

static void phase_mmap_churn(void) {
    double t0 = now_sec();
    for (int i = 0; i < MMAP_CHURN_ITERS; i++) {
        void *p = mmap(NULL, CHURN_SIZE, PROT_READ | PROT_WRITE,
                       MAP_PRIVATE | MAP_ANONYMOUS | MAP_POPULATE, -1, 0);
        if (p == MAP_FAILED) { perror("mmap"); exit(1); }
        memset(p, 0xEF, CHURN_SIZE);
        munmap(p, CHURN_SIZE);
    }
    double elapsed = now_sec() - t0;

    unsigned long total_pages = (unsigned long)MMAP_CHURN_ITERS * (CHURN_SIZE / PAGE_SZ);
    printf("Phase 3 - mmap/munmap churn:\n");
    printf("  %d iterations (%lu pages) in %.3f s (%.1f K iter/s)\n\n",
           MMAP_CHURN_ITERS, total_pages, elapsed,
           MMAP_CHURN_ITERS / elapsed / 1e3);
}

int main(void) {
    printf("PID: %d\n", getpid());
    printf("Region size: %lu MB, page size: %d\n\n", REGION_SIZE / (1024*1024), PAGE_SZ);

    phase_mprotect_storm();
    phase_cow_storm();
    phase_mmap_churn();

    printf("Done.\n");
    return 0;
}
