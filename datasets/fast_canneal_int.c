// fast_canneal_int.c
// Compile: gcc -O3 -fopenmp -o fast_canneal_int fast_canneal_int.c
// Output format uses integers directly - much faster to parse

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>

int main(int argc, char *argv[]) {
    if (argc != 4) {
        fprintf(stderr, "Usage: %s x y num_elements\n", argv[0]);
        return 1;
    }

    long x = atol(argv[1]);
    long y = atol(argv[2]);
    long num_elements = atol(argv[3]);

    if (x <= 1 || y <= 1 || num_elements >= x * y) {
        fprintf(stderr, "Invalid params: need x>1, y>1, num_elements < x*y\n");
        return 1;
    }

    // Print header
    printf("%ld\t%ld\t%ld\n", num_elements, x, y);
    fflush(stdout);

    int num_threads = omp_get_max_threads();
    long chunk_size = (num_elements + num_threads - 1) / num_threads;

    #pragma omp parallel
    {
        int tid = omp_get_thread_num();
        unsigned int seed = tid + 12345;

        long start = tid * chunk_size;
        long end = start + chunk_size;
        if (end > num_elements) end = num_elements;

        // 64MB buffer per thread
        size_t buf_size = 64 * 1024 * 1024;
        char *buffer = malloc(buf_size);
        size_t buf_pos = 0;

        for (long i = start; i < end; i++) {
            // Format: id\ttype\tconn0\tconn1\tconn2\tconn3\tconn4\n
            // No "END" needed - fixed 5 connections
            int type = 1 + (rand_r(&seed) % 2);
            
            buf_pos += sprintf(buffer + buf_pos, "%ld\t%d", i, type);
            
            for (int j = 0; j < 5; j++) {
                long conn = ((long)rand_r(&seed) * rand_r(&seed)) % num_elements;
                if (conn < 0) conn = -conn;
                buf_pos += sprintf(buffer + buf_pos, "\t%ld", conn);
            }
            buffer[buf_pos++] = '\n';

            if (buf_pos > buf_size - 512) {
                #pragma omp critical
                fwrite(buffer, 1, buf_pos, stdout);
                buf_pos = 0;
            }
        }

        if (buf_pos > 0) {
            #pragma omp critical
            fwrite(buffer, 1, buf_pos, stdout);
        }
        free(buffer);
    }
    return 0;
}
