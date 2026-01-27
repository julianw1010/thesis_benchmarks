#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <stdint.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <signal.h>
#include <math.h>

/*
 * WASP Worst-Case Oscillator
 * 
 * This program oscillates between high and low memory access rates
 * with a configurable period (default 5 seconds) to trigger WASP's
 * hysteresis mechanism repeatedly, demonstrating worst-case overhead.
 *
 * During HIGH phase: Random page walks causing TLB misses + high MAR
 * During LOW phase:  Minimal memory activity
 *
 * With WASP's default 1s hysteresis and 5s period:
 *   - 2.5s HIGH: 1s ramp-up, then mitosis ENABLED for 1.5s
 *   - 2.5s LOW:  1s cooldown, then mitosis DISABLED for 1.5s
 *   - Cycle repeats indefinitely
 */

#define PAGE_SIZE       4096
#define CACHE_LINE_SIZE 64

/* Memory configuration for TLB pressure */
#define NUM_REGIONS     64          /* Number of separate mmap regions */
#define PAGES_PER_REGION 4096       /* Pages per region (16MB each) */
#define TOTAL_PAGES     (NUM_REGIONS * PAGES_PER_REGION)

/* Timing configuration */
static double PERIOD_SEC = 5.0;     /* Full oscillation period */
static double DUTY_CYCLE = 0.5;     /* Fraction of period spent in HIGH phase */

/* Access intensity */
static long ACCESSES_PER_MS_HIGH = 50000;  /* Accesses/ms during HIGH phase */
static long ACCESSES_PER_MS_LOW  = 100;    /* Accesses/ms during LOW phase */

/* Global state */
static volatile sig_atomic_t running = 1;
static char *regions[NUM_REGIONS];
static uint64_t *page_table;  /* Shuffle table for random access */
static size_t total_bytes;

/* Statistics */
static uint64_t total_accesses = 0;
static uint64_t phase_accesses = 0;
static int current_phase = 0;  /* 0 = LOW, 1 = HIGH */
static int phase_transitions = 0;

static inline uint64_t rdtsc(void) {
    uint32_t lo, hi;
    asm volatile("rdtsc" : "=a"(lo), "=d"(hi));
    return ((uint64_t)hi << 32) | lo;
}

static double get_time_sec(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec / 1000000.0;
}

/* Fisher-Yates shuffle for random page access order */
static void shuffle_pages(uint64_t *arr, size_t n, unsigned int seed) {
    for (size_t i = 0; i < n; i++) {
        arr[i] = i;
    }
    for (size_t i = n - 1; i > 0; i--) {
        size_t j = rand_r(&seed) % (i + 1);
        uint64_t tmp = arr[i];
        arr[i] = arr[j];
        arr[j] = tmp;
    }
}

static void signal_handler(int sig) {
    (void)sig;
    running = 0;
}

static void setup_memory(void) {
    total_bytes = (size_t)NUM_REGIONS * PAGES_PER_REGION * PAGE_SIZE;
    
    printf("Allocating %zu MB across %d regions...\n", 
           total_bytes / (1024 * 1024), NUM_REGIONS);
    
    /* Allocate separate regions to maximize TLB pressure */
    for (int i = 0; i < NUM_REGIONS; i++) {
        regions[i] = mmap(NULL, PAGES_PER_REGION * PAGE_SIZE,
                          PROT_READ | PROT_WRITE,
                          MAP_PRIVATE | MAP_ANONYMOUS | MAP_POPULATE,
                          -1, 0);
        if (regions[i] == MAP_FAILED) {
            perror("mmap");
            exit(1);
        }
        
        /* Touch all pages to ensure they're faulted in */
        for (size_t p = 0; p < PAGES_PER_REGION; p++) {
            regions[i][p * PAGE_SIZE] = (char)(i + p);
        }
    }
    
    /* Create shuffle table for random access pattern */
    page_table = malloc(TOTAL_PAGES * sizeof(uint64_t));
    if (!page_table) {
        perror("malloc page_table");
        exit(1);
    }
    shuffle_pages(page_table, TOTAL_PAGES, 0xDEADBEEF);
    
    printf("Memory setup complete: %d pages across %d regions\n",
           TOTAL_PAGES, NUM_REGIONS);
}

static void cleanup_memory(void) {
    for (int i = 0; i < NUM_REGIONS; i++) {
        if (regions[i]) {
            munmap(regions[i], PAGES_PER_REGION * PAGE_SIZE);
        }
    }
    free(page_table);
}

/*
 * Access memory in a pattern designed to cause TLB misses.
 * Uses the shuffle table to access pages in random order.
 */
static inline void do_memory_accesses(long count, unsigned int *seed) {
    volatile char sum = 0;
    
    for (long i = 0; i < count; i++) {
        /* Pick a random page from shuffle table */
        size_t idx = rand_r(seed) % TOTAL_PAGES;
        size_t page_idx = page_table[idx];
        
        /* Convert to region + offset */
        int region = page_idx / PAGES_PER_REGION;
        size_t page_in_region = page_idx % PAGES_PER_REGION;
        
        /* Access a random offset within the page */
        size_t offset = (page_in_region * PAGE_SIZE) + 
                        ((rand_r(seed) % (PAGE_SIZE / CACHE_LINE_SIZE)) * CACHE_LINE_SIZE);
        
        /* Perform the access */
        sum += regions[region][offset];
        
        /* Occasional write to dirty pages */
        if ((i & 0xFF) == 0) {
            regions[region][offset] = sum;
        }
    }
    
    /* Prevent optimization */
    if (sum == 0x7F) {
        printf("!");
    }
    
    total_accesses += count;
    phase_accesses += count;
}

/*
 * Perform a burst of sequential accesses (cache-friendly)
 * for the LOW phase - minimal TLB pressure
 */
static inline void do_low_accesses(long count, unsigned int *seed) {
    volatile char sum = 0;
    int region = rand_r(seed) % NUM_REGIONS;
    
    for (long i = 0; i < count; i++) {
        size_t offset = (i * CACHE_LINE_SIZE) % (PAGES_PER_REGION * PAGE_SIZE);
        sum += regions[region][offset];
    }
    
    if (sum == 0x7F) {
        printf("!");
    }
    
    total_accesses += count;
    phase_accesses += count;
}

static void print_status(double elapsed, double phase_time, int phase, 
                         double rate, double expected_rate) {
    static int last_phase = -1;
    
    if (phase != last_phase) {
        printf("\n");
        last_phase = phase;
    }
    
    const char *phase_str = phase ? "HIGH" : "LOW ";
    const char *color = phase ? "\033[32m" : "\033[33m";
    
    printf("\r%s[%s]\033[0m t=%.1fs phase=%.1fs rate=%.2e/s (target=%.2e) transitions=%d    ",
           color, phase_str, elapsed, phase_time, rate, expected_rate, phase_transitions);
    fflush(stdout);
}

int main(int argc, char *argv[]) {
    printf("=== WASP Worst-Case Oscillator ===\n\n");
    
    /* Parse arguments */
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-p") == 0 && i + 1 < argc) {
            PERIOD_SEC = atof(argv[++i]);
        } else if (strcmp(argv[i], "-d") == 0 && i + 1 < argc) {
            DUTY_CYCLE = atof(argv[++i]);
        } else if (strcmp(argv[i], "-H") == 0 && i + 1 < argc) {
            ACCESSES_PER_MS_HIGH = atol(argv[++i]);
        } else if (strcmp(argv[i], "-L") == 0 && i + 1 < argc) {
            ACCESSES_PER_MS_LOW = atol(argv[++i]);
        } else if (strcmp(argv[i], "-h") == 0) {
            printf("Usage: %s [options]\n", argv[0]);
            printf("  -p SEC    Oscillation period (default: %.1f)\n", PERIOD_SEC);
            printf("  -d FRAC   Duty cycle for HIGH phase (default: %.2f)\n", DUTY_CYCLE);
            printf("  -H RATE   Accesses per ms during HIGH (default: %ld)\n", ACCESSES_PER_MS_HIGH);
            printf("  -L RATE   Accesses per ms during LOW (default: %ld)\n", ACCESSES_PER_MS_LOW);
            printf("\nDesigned to trigger WASP enable/disable cycles.\n");
            printf("With default 1s hysteresis and 5s period:\n");
            printf("  - Mitosis toggles every 2.5s\n");
            printf("  - Maximum churn for worst-case overhead measurement\n");
            return 0;
        }
    }
    
    printf("Configuration:\n");
    printf("  Period:     %.1f seconds\n", PERIOD_SEC);
    printf("  Duty cycle: %.0f%% HIGH / %.0f%% LOW\n", 
           DUTY_CYCLE * 100, (1.0 - DUTY_CYCLE) * 100);
    printf("  HIGH rate:  %ld accesses/ms (%.2e/s)\n", 
           ACCESSES_PER_MS_HIGH, ACCESSES_PER_MS_HIGH * 1000.0);
    printf("  LOW rate:   %ld accesses/ms (%.2e/s)\n",
           ACCESSES_PER_MS_LOW, ACCESSES_PER_MS_LOW * 1000.0);
    printf("  PID:        %d\n\n", getpid());
    
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    setup_memory();
    
    printf("\nStarting oscillation... (Ctrl+C to stop)\n");
    printf("Watch WASP daemon for enable/disable transitions.\n\n");
    
    double start_time = get_time_sec();
    double last_print = start_time;
    double phase_start = start_time;
    unsigned int seed = (unsigned int)time(NULL);
    
    double high_duration = PERIOD_SEC * DUTY_CYCLE;
    double low_duration = PERIOD_SEC * (1.0 - DUTY_CYCLE);
    
    /* Start in LOW phase */
    current_phase = 0;
    phase_accesses = 0;
    
    while (running) {
        double now = get_time_sec();
        double elapsed = now - start_time;
        double phase_time = now - phase_start;
        
        /* Check for phase transition */
        double phase_duration = current_phase ? high_duration : low_duration;
        if (phase_time >= phase_duration) {
            current_phase = !current_phase;
            phase_start = now;
            phase_time = 0;
            phase_accesses = 0;
            phase_transitions++;
            
            /* Re-shuffle page table on each HIGH phase for variety */
            if (current_phase) {
                shuffle_pages(page_table, TOTAL_PAGES, seed++);
            }
        }
        
        /* Perform accesses based on current phase */
        if (current_phase) {
            /* HIGH phase: random page walks for TLB pressure */
            do_memory_accesses(ACCESSES_PER_MS_HIGH, &seed);
        } else {
            /* LOW phase: sequential access, minimal activity */
            do_low_accesses(ACCESSES_PER_MS_LOW, &seed);
        }
        
        /* Status update every 100ms */
        if (now - last_print >= 0.1) {
            double rate = phase_accesses / phase_time;
            double expected = current_phase ? 
                (ACCESSES_PER_MS_HIGH * 1000.0) : (ACCESSES_PER_MS_LOW * 1000.0);
            print_status(elapsed, phase_time, current_phase, rate, expected);
            last_print = now;
        }
        
        /* Small delay to allow phase timing to work */
        usleep(1000);  /* 1ms */
    }
    
    double total_time = get_time_sec() - start_time;
    
    printf("\n\n=== Statistics ===\n");
    printf("Total runtime:      %.1f seconds\n", total_time);
    printf("Total accesses:     %lu\n", total_accesses);
    printf("Average rate:       %.2e accesses/sec\n", total_accesses / total_time);
    printf("Phase transitions:  %d\n", phase_transitions);
    printf("Transitions/sec:    %.2f\n", phase_transitions / total_time);
    
    cleanup_memory();
    
    return 0;
}
