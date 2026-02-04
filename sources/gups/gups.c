#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <unistd.h>
#include <ctype.h>
#include <inttypes.h>
#include <limits.h>
#include <sys/mman.h>
#include <string.h>
#include <numa.h>
#include <time.h>
#include <pthread.h>
#ifdef _OPENMP
#include <omp.h>
#endif

extern FILE *opt_file_out;

#ifdef _OPENMP
#define DEFAULT_NUPDATE (1UL << 34)
#else
#define DEFAULT_NUPDATE (3UL << 29)
#endif

#define POLY 0x0000000000000007UL
#define PERIOD 1317624576693539401L

static uint64_t
HPCC_starts(int64_t n)
{
    int i, j;
    uint64_t m2[64];
    uint64_t temp, ran;

    while (n < 0) n += PERIOD;
    while (n > PERIOD) n -= PERIOD;
    if (n == 0) return 0x1;

    temp = 0x1;
    for (i=0; i<64; i++) {
        m2[i] = temp;
        temp = (temp << 1) ^ ((int64_t) temp < 0 ? POLY : 0);
        temp = (temp << 1) ^ ((int64_t) temp < 0 ? POLY : 0);
    }

    for (i=62; i>=0; i--)
        if ((n >> i) & 1)
            break;

    ran = 0x2;
    while (i > 0) {
        temp = 0;
        for (j=0; j<64; j++)
            if ((ran >> j) & 1)
                temp ^= m2[j];
        ran = temp;
        i -= 1;
        if ((n >> i) & 1)
            ran = (ran << 1) ^ ((int64_t) ran < 0 ? POLY : 0);
    }

    return ran;
}

#define CONFIG_SHM_FILE_NAME "/tmp/alloctest-bench"

int real_main(int argc, char *argv[]);

int real_main(int argc, char *argv[])
{
    size_t mem = ((size_t)64UL << 30);
    uint64_t nupdate = DEFAULT_NUPDATE;

    if (argc >= 2) {
        mem = strtoull(argv[1], NULL, 10) << 30;
    }
    if (argc >= 3) {
        nupdate = strtoull(argv[2], NULL, 10);
    }

    /* nupdate must be divisible by 128 for the batched update loop */
    if (nupdate % 128 != 0) {
        nupdate = (nupdate / 128) * 128;
        if (nupdate == 0) nupdate = 128;
        fprintf(opt_file_out, "<gups note=\"nupdate rounded down to %" PRIu64 " (must be multiple of 128)\"></gups>\n", nupdate);
    }

    for (int i = 0; i < 64; i++) {
        if (1ULL << i > mem) {
            mem = 1ULL << (i - 1);
            break;
        }
    }

    fprintf(opt_file_out, "<gups tablesize=\"%zu\"></gups>\n", mem);

    uint64_t *Table = malloc(mem + 16);
    if (!Table) {
        fprintf(opt_file_out, "ERROR: Could not allocate table!\n");
        return -1;
    }

    size_t TableSize = mem / sizeof(uint64_t);
    fprintf(opt_file_out, "<gups table=\"%p\" tablesize=\"%zu\"></gups>\n", Table, TableSize);

#ifdef _OPENMP
    #pragma omp parallel for
#endif
    for (size_t i=0; i<TableSize; i++) {
        Table[i] = i;
    }

    FILE *fd2 = fopen(CONFIG_SHM_FILE_NAME ".ready", "w");
    if (fd2 == NULL) {
        fprintf(stderr, "ERROR: could not create the shared memory file descriptor\n");
        exit(-1);
    }

	FILE *fd_pid = fopen(CONFIG_SHM_FILE_NAME ".pid", "w");
	if (fd_pid) {
	    fprintf(fd_pid, "%d", getpid());
	    fclose(fd_pid);
	}

    usleep(250);

    struct timespec t_start, t_end;

#ifdef _OPENMP
    int nthreads;
    #pragma omp parallel
    {
        #pragma omp single
        nthreads = omp_get_num_threads();
    }
    fprintf(opt_file_out, "<gups threads=\"%d\"></gups>\n", nthreads);

    clock_gettime(CLOCK_MONOTONIC, &t_start);

    #pragma omp parallel
    {
        int tid = omp_get_thread_num();
        int nth = omp_get_num_threads();

        uint64_t updates_per_thread = nupdate / nth;
        uint64_t start_update = tid * updates_per_thread;

        uint64_t ran[128];
        for (size_t j = 0; j < 128; j++) {
            ran[j] = HPCC_starts(start_update + (updates_per_thread / 128) * j);
        }

        for (size_t i = 0; i < updates_per_thread / 128; i++) {
            for (size_t j = 0; j < 128; j++) {
                ran[j] = (ran[j] << 1) ^ ((int64_t) ran[j] < 0 ? POLY : 0);
                size_t elm = ran[j] % TableSize;
                #pragma omp atomic
                Table[elm] ^= ran[j];
                #pragma omp atomic
                Table[TableSize - 1 - elm] ^= ran[j];
            }
        }
    }

    clock_gettime(CLOCK_MONOTONIC, &t_end);
#else
    fprintf(opt_file_out, "<gups threads=\"1\"></gups>\n");

    clock_gettime(CLOCK_MONOTONIC, &t_start);

    uint64_t *ran = calloc(128, sizeof(uint64_t));
    for (size_t j=0; j<128; j++) {
        ran[j] = HPCC_starts((nupdate/128) * j);
    }

    for (size_t i=0; i<nupdate/128; i++) {
        for (size_t j=0; j<128; j++) {
            ran[j] = (ran[j] << 1) ^ ((int64_t) ran[j] < 0 ? POLY : 0);
            size_t elm = ran[j] % TableSize;
            Table[elm] ^= ran[j];
            Table[TableSize - elm] ^= ran[j];
        }
    }
    free(ran);

    clock_gettime(CLOCK_MONOTONIC, &t_end);
#endif

    double runtime = (t_end.tv_sec - t_start.tv_sec) + (t_end.tv_nsec - t_start.tv_nsec) / 1e9;
    double gups = (double)nupdate / runtime / 1e9;
    fprintf(opt_file_out, "<gups_runtime>%.3f</gups_runtime>\n", runtime);
    fprintf(opt_file_out, "<gups_rate>%.6f GUPS</gups_rate>\n", gups);
    fprintf(opt_file_out, "<gups_updates>%" PRIu64 "</gups_updates>\n", nupdate);

    return 0;
}
