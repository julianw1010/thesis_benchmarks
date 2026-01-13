// netlist.cpp - OPTIMIZED with mmap + parallel parsing
//
// Copyright 2007 Princeton University - All rights reserved.
// Modified for fast loading

#include "location_t.h"
#include "netlist.h"
#include "netlist_elem.h"
#include "rng.h"

#include <iostream>
#include <fstream>
#include <assert.h>
#include <cstring>
#include <cstdlib>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <omp.h>
#include <atomic>

using namespace std;

void netlist::release(netlist_elem* elem) { return; }

routing_cost_t netlist::total_routing_cost()
{
    routing_cost_t rval = 0;
    #pragma omp parallel for reduction(+:rval)
    for (unsigned i = 0; i < _num_elements; i++) {
        netlist_elem* elem = &_elements[i];
        rval += elem->routing_cost_given_loc(*(elem->present_loc.Get()));
    }
    return rval / 2;
}

void netlist::shuffle(Rng* rng)
{
    for (int i = 0; i < _max_x * _max_y * 1000; i++){
        netlist_elem *a, *b;
        get_random_pair(&a, &b, rng);
        swap_locations(a, b);
    }
}

void netlist::swap_locations(netlist_elem* elem_a, netlist_elem* elem_b)
{
    elem_a->present_loc.Swap(elem_b->present_loc);
}

netlist_elem* netlist::get_random_element(long* elem_id, long different_from, Rng* rng)
{
    long id = rng->rand(_num_elements);
    while (id == different_from) id = rng->rand(_num_elements);
    *elem_id = id;
    return &_elements[id];
}

void netlist::get_random_pair(netlist_elem** a, netlist_elem** b, Rng* rng)
{
    long id_a = rng->rand(_num_elements);
    long id_b = rng->rand(_num_elements);
    while (id_b == id_a) id_b = rng->rand(_num_elements);
    *a = &_elements[id_a];
    *b = &_elements[id_b];
}

netlist_elem* netlist::netlist_elem_from_loc(location_t& loc)
{
    assert(false);
    return NULL;
}

netlist_elem* netlist::netlist_elem_from_name(std::string& name)
{
    return &_elements[std::stol(name)];
}

// Fast integer parsing
static inline long fast_parse_long(const char*& p)
{
    long val = 0;
    while (*p >= '0' && *p <= '9') {
        val = val * 10 + (*p - '0');
        p++;
    }
    return val;
}

static inline void skip_ws(const char*& p)
{
    while (*p == ' ' || *p == '\t') p++;
}

netlist::netlist(const std::string& filename)
{
    // Open and mmap the file
    int fd = open(filename.c_str(), O_RDONLY);
    assert(fd >= 0);
    
    struct stat sb;
    fstat(fd, &sb);
    size_t file_size = sb.st_size;
    
    char* file_data = (char*)mmap(NULL, file_size, PROT_READ, MAP_PRIVATE | MAP_POPULATE, fd, 0);
    assert(file_data != MAP_FAILED);
    madvise(file_data, file_size, MADV_SEQUENTIAL);
    
    const char* p = file_data;
    const char* end = file_data + file_size;
    
    // Parse header
    _num_elements = fast_parse_long(p); skip_ws(p);
    _max_x = fast_parse_long(p); skip_ws(p);
    _max_y = fast_parse_long(p);
    while (p < end && *p != '\n') p++;
    if (p < end) p++;
    
    _chip_size = _max_x * _max_y;
    assert(_num_elements < _chip_size);
    
    cout << "File size: " << file_size / (1024*1024) << " MB" << endl;
    cout << "Elements: " << _num_elements << ", Grid: " << _max_x << "x" << _max_y << endl;
    
    // Allocate elements
    _elements.resize(_chip_size);
    
    // Pre-reserve fanin/fanout for actual elements only
    cout << "Pre-allocating vectors..." << endl;
    #pragma omp parallel for
    for (unsigned i = 0; i < _num_elements; i++) {
        _elements[i].fanin.reserve(8);
        _elements[i].fanout.reserve(8);
    }
    
    cout << "locs created" << endl;
    
    // Create locations
    vector<location_t> y_vec(_max_y);
    _locations.resize(_max_x, y_vec);
    
    #pragma omp parallel for collapse(2)
    for (int x = 0; x < _max_x; x++) {
        for (int y = 0; y < _max_y; y++) {
            _locations[x][y].x = x;
            _locations[x][y].y = y;
        }
    }
    
    // Assign locations to elements
    unsigned i_elem = 0;
    for (int x = 0; x < _max_x; x++) {
        for (int y = 0; y < _max_y; y++) {
            _elements[i_elem].present_loc.Set(&_locations[x][y]);
            i_elem++;
        }
    }
    cout << "locs assigned" << endl;
    
    // Find line offsets for parallel parsing
    const char* data_start = p;
    size_t data_size = end - data_start;
    
    int num_threads = omp_get_max_threads();
    cout << "Parsing with " << num_threads << " threads..." << endl;
    
    // Create spinlocks for fanout updates
    std::vector<std::atomic_flag> elem_locks(_num_elements);
    for (unsigned i = 0; i < _num_elements; i++) {
        elem_locks[i].clear();
    }
    
    std::atomic<long> total_parsed(0);
    
    #pragma omp parallel
    {
        int tid = omp_get_thread_num();
        int nthreads = omp_get_num_threads();
        
        // Divide file into chunks
        size_t chunk_size = data_size / nthreads;
        const char* my_start = data_start + tid * chunk_size;
        const char* my_end = (tid == nthreads - 1) ? end : data_start + (tid + 1) * chunk_size;
        
        // Align to line boundaries
        if (tid != 0) {
            while (my_start < end && *(my_start - 1) != '\n') my_start++;
        }
        if (tid != nthreads - 1) {
            while (my_end < end && *my_end != '\n') my_end++;
            if (my_end < end) my_end++;
        }
        
        const char* lp = my_start;
        long local_count = 0;
        
        while (lp < my_end) {
            // Skip whitespace/newlines
            while (lp < my_end && (*lp == '\n' || *lp == '\r' || *lp == ' ' || *lp == '\t')) lp++;
            if (lp >= my_end) break;
            
            // Parse: id \t type \t conn0 \t conn1 \t conn2 \t conn3 \t conn4 \n
            long id = fast_parse_long(lp);
            skip_ws(lp);
            
            fast_parse_long(lp); // type - ignored
            skip_ws(lp);
            
            netlist_elem* elem = &_elements[id];
            elem->item_name = std::to_string(id);
            
            // Parse 5 connections
            for (int c = 0; c < 5; c++) {
                long conn_id = fast_parse_long(lp);
                skip_ws(lp);
                
                netlist_elem* fanin_elem = &_elements[conn_id];
                elem->fanin.push_back(fanin_elem);
                
                // Lock for fanout update
                while (elem_locks[conn_id].test_and_set(std::memory_order_acquire));
                fanin_elem->fanout.push_back(elem);
                elem_locks[conn_id].clear(std::memory_order_release);
            }
            
            // Skip to next line
            while (lp < my_end && *lp != '\n') lp++;
            if (lp < my_end) lp++;
            
            local_count++;
            if ((local_count % 5000000) == 0) {
                long tot = total_parsed.fetch_add(5000000) + 5000000;
                #pragma omp critical
                cout << "Parsed: " << tot << " elements" << endl;
            }
        }
        total_parsed.fetch_add(local_count % 5000000);
    }
    
    // Cleanup mmap
    munmap(file_data, file_size);
    close(fd);
    
    cout << "netlist created. " << total_parsed.load() << " elements." << endl;
}

netlist_elem* netlist::create_elem_if_necessary(std::string& name)
{
    return &_elements[std::stol(name)];
}

void netlist::print_locations(const std::string& filename)
{
    ofstream fout(filename.c_str());
    assert(fout.is_open());
    for (unsigned i = 0; i < _num_elements; i++) {
        netlist_elem* elem = &_elements[i];
        fout << elem->item_name << "\t" << elem->present_loc.Get()->x << "\t" << elem->present_loc.Get()->y << endl;
    }
}
