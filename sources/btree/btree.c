/*
 *  bpt.c
 */
#define Version "1.16.1"
/*
 *  bpt:  B+ Tree Implementation
 *  Copyright (c) 2018  Amittai Aviram  http://www.amittai.com
 *  All rights reserved.
 *  (License text omitted for brevity - same BSD 3-clause as original)
 */

#define CONFIG_SHM_FILE_NAME "/tmp/alloctest-bench"

#ifdef _OPENMP
#define NELEMENTS (2900UL << 20)
#define NLOOKUP 2000000000UL
#else
#define NELEMENTS (200UL << 20)
#define NLOOKUP 20000000
#endif

#include <stdbool.h>
#ifdef _WIN32
#define bool char
#define false 0
#define true 1
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/mman.h>

#ifdef _OPENMP
#include <omp.h>
#endif

#define DEFAULT_ORDER 4
#define MIN_ORDER 3
#define MAX_ORDER 256
#define BUFFER_SIZE 256
#define ALIGNMET (1UL << 21)

size_t allocator_stat = 0;

static inline void *allocate(size_t size) {
    void *memptr = mmap(NULL, size, PROT_READ | PROT_WRITE,
                        MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE, -1, 0);
    if (memptr == MAP_FAILED) {
        printf("ENOMEM\n");
        exit(1);
    }
    allocator_stat += size;
    return memptr;
}

static inline void *allocate_align64(size_t size) {
    void *memptr;
    if (posix_memalign(&memptr, 64, size)) {
        printf("ENOMEM\n");
        exit(1);
    }
    allocator_stat += size;
    memset(memptr, 0, size);
    return memptr;
}

// TYPES
typedef struct record {
    union {
        uint64_t value;
        struct record *next;
    };
} record;

typedef struct node {
    void ** pointers;
    uint64_t * keys;
    struct node * parent;
    bool is_leaf;
    uint64_t num_keys;
    struct node * next;
} node;

// GLOBALS
uint64_t order = DEFAULT_ORDER;
node * queue = NULL;
bool verbose_output = false;

// FUNCTION PROTOTYPES
void enqueue(node * new_node);
node * dequeue(void);
uint64_t height(node * const root);
uint64_t path_to_root(node * const root, node * child);
void print_leaves(node * const root);
void print_tree(node * const root);
void find_and_print(node * const root, uint64_t key, bool verbose);
node * find_leaf(node * const root, uint64_t key, bool verbose);
record * find(node * root, uint64_t key, bool verbose, node ** leaf_out);
uint64_t cut(uint64_t length);

record * make_record(uint64_t value);
node * make_node(void);
node * make_leaf(void);
uint64_t get_left_index(node * parent, node * left);
node * insert_into_leaf(node * leaf, uint64_t key, record * pointer);
node * insert_into_leaf_after_splitting(node * root, node * leaf, uint64_t key, record * pointer);
node * insert_into_node(node * root, node * parent, uint64_t left_index, uint64_t key, node * right);
node * insert_into_node_after_splitting(node * root, node * parent, uint64_t left_index, uint64_t key, node * right);
node * insert_into_parent(node * root, node * left, uint64_t key, node * right);
node * insert_into_new_root(node * left, uint64_t key, node * right);
node * start_new_tree(uint64_t key, record * pointer);
node * insert(node * root, uint64_t key, uint64_t value);

uint64_t get_neighbor_index(node * n);
node * adjust_root(node * root);
node * coalesce_nodes(node * root, node * n, node * neighbor, uint64_t neighbor_index, uint64_t k_prime);
node * redistribute_nodes(node * root, node * n, node * neighbor, uint64_t neighbor_index, uint64_t k_prime_index, uint64_t k_prime);
node * delete_entry(node * root, node * n, uint64_t key, void * pointer);
node * delete(node * root, uint64_t key);

// OUTPUT AND UTILITIES
void enqueue(node * new_node) {
    node * c;
    if (queue == NULL) {
        queue = new_node;
        queue->next = NULL;
    } else {
        c = queue;
        while(c->next != NULL) c = c->next;
        c->next = new_node;
        new_node->next = NULL;
    }
}

node * dequeue(void) {
    node * n = queue;
    queue = queue->next;
    n->next = NULL;
    return n;
}

void print_leaves(node * const root) {
    if (root == NULL) { printf("Empty tree.\n"); return; }
    uint64_t i;
    node * c = root;
    while (!c->is_leaf) c = c->pointers[0];
    while (true) {
        for (i = 0; i < c->num_keys; i++) {
            if (verbose_output) printf("%p ", c->pointers[i]);
            printf("%ld ", c->keys[i]);
        }
        if (verbose_output) printf("%p ", c->pointers[order - 1]);
        if (c->pointers[order - 1] != NULL) {
            printf(" | ");
            c = c->pointers[order - 1];
        } else break;
    }
    printf("\n");
}

uint64_t height(node * const root) {
    uint64_t h = 0;
    node * c = root;
    while (!c->is_leaf) { c = c->pointers[0]; h++; }
    return h;
}

uint64_t path_to_root(node * const root, node * child) {
    uint64_t length = 0;
    node * c = child;
    while (c != root) { c = c->parent; length++; }
    return length;
}

void print_tree(node * const root) {
    node * n = NULL;
    uint64_t i = 0, rank = 0, new_rank = 0;
    if (root == NULL) { printf("Empty tree.\n"); return; }
    queue = NULL;
    enqueue(root);
    while(queue != NULL) {
        n = dequeue();
        if (n->parent != NULL && n == n->parent->pointers[0]) {
            new_rank = path_to_root(root, n);
            if (new_rank != rank) { rank = new_rank; printf("\n"); }
        }
        if (verbose_output) printf("(%p)", n);
        for (i = 0; i < n->num_keys; i++) {
            if (verbose_output) printf("%p ", n->pointers[i]);
            printf("%ld ", n->keys[i]);
        }
        if (!n->is_leaf)
            for (i = 0; i <= n->num_keys; i++) enqueue(n->pointers[i]);
        if (verbose_output) {
            if (n->is_leaf) printf("%p ", n->pointers[order - 1]);
            else printf("%p ", n->pointers[n->num_keys]);
        }
        printf("| ");
    }
    printf("\n");
}

void find_and_print(node * const root, uint64_t key, bool verbose) {
    record * r = find(root, key, verbose, NULL);
    if (r == NULL) printf("Record not found under key %ld.\n", key);
    else printf("Record at %p -- key %ld, value %ld.\n", r, key, r->value);
}

node * find_leaf(node * const root, uint64_t key, bool verbose) {
    if (root == NULL) { if (verbose) printf("Empty tree.\n"); return root; }
    uint64_t i = 0;
    node * c = root;
    while (!c->is_leaf) {
        i = 0;
        while (i < c->num_keys) {
            if (key >= c->keys[i]) i++;
            else break;
        }
        c = (node *)c->pointers[i];
    }
    return c;
}

record * find(node * root, uint64_t key, bool verbose, node ** leaf_out) {
    if (root == NULL) {
        if (leaf_out != NULL) *leaf_out = NULL;
        return NULL;
    }
    uint64_t i = 0;
    node * leaf = find_leaf(root, key, verbose);
    for (i = 0; i < leaf->num_keys; i++)
        if (leaf->keys[i] == key) break;
    if (leaf_out != NULL) *leaf_out = leaf;
    if (i == leaf->num_keys) return NULL;
    else return (record *)leaf->pointers[i];
}

uint64_t cut(uint64_t length) {
    if (length % 2 == 0) return length/2;
    else return length/2 + 1;
}

// SLAB ALLOCATORS
#define NODE_SLAB_GROW (1<<18)
struct node *free_nodes = NULL;

node *alloc_node() {
    if (!free_nodes) {
        node *n = allocate(NODE_SLAB_GROW);
        for (size_t i = 0; i < NODE_SLAB_GROW / sizeof(struct node); i++) {
            n[i].next = free_nodes;
            free_nodes = &n[i];
        }
    }
    node *nd = free_nodes;
    free_nodes = nd->next;
    return nd;
}

void free_node(node *n) {
    n->next = free_nodes;
    free_nodes = n;
}

#define RECORD_SLAB_GROW (1<<18)
struct record *free_recs = NULL;

record *alloc_record() {
    if (!free_recs) {
        record *r = allocate(RECORD_SLAB_GROW);
        for (size_t i = 0; i < RECORD_SLAB_GROW / sizeof(struct record); i++) {
            r[i].next = free_recs;
            free_recs = &r[i];
        }
    }
    record *rec = free_recs;
    free_recs = rec->next;
    return rec;
}

void free_record(record *r) {
    r->next = free_recs;
    free_recs = r;
}

record * make_record(uint64_t value) {
    record * new_record = (record *)alloc_record();
    if (new_record == NULL) { perror("Record creation."); exit(EXIT_FAILURE); }
    new_record->value = value;
    return new_record;
}

node * make_node(void) {
    node * new_node = alloc_node();
    if (new_node == NULL) { perror("Node creation."); exit(EXIT_FAILURE); }
    new_node->keys = allocate_align64((order - 1) * sizeof(uint64_t));
    new_node->pointers = allocate_align64(order * sizeof(void *));
    new_node->is_leaf = false;
    new_node->num_keys = 0;
    new_node->parent = NULL;
    new_node->next = NULL;
    return new_node;
}

node * make_leaf(void) {
    node * leaf = make_node();
    leaf->is_leaf = true;
    return leaf;
}

uint64_t get_left_index(node * parent, node * left) {
    uint64_t left_index = 0;
    while (left_index <= parent->num_keys && parent->pointers[left_index] != left)
        left_index++;
    return left_index;
}

node * insert_into_leaf(node * leaf, uint64_t key, record * pointer) {
    uint64_t i, insertion_point = 0;
    while (insertion_point < leaf->num_keys && leaf->keys[insertion_point] < key)
        insertion_point++;
    for (i = leaf->num_keys; i > insertion_point; i--) {
        leaf->keys[i] = leaf->keys[i - 1];
        leaf->pointers[i] = leaf->pointers[i - 1];
    }
    leaf->keys[insertion_point] = key;
    leaf->pointers[insertion_point] = pointer;
    leaf->num_keys++;
    return leaf;
}

node * insert_into_leaf_after_splitting(node * root, node * leaf, uint64_t key, record * pointer) {
    node * new_leaf = make_leaf();
    uint64_t * temp_keys = allocate_align64((order+1) * sizeof(uint64_t));
    void ** temp_pointers = allocate_align64((order+1) * sizeof(void *));
    uint64_t insertion_index = 0, split, new_key, i, j;

    while (insertion_index < order - 1 && leaf->keys[insertion_index] < key)
        insertion_index++;
    for (i = 0, j = 0; i < leaf->num_keys; i++, j++) {
        if (j == insertion_index) j++;
        temp_keys[j] = leaf->keys[i];
        temp_pointers[j] = leaf->pointers[i];
    }
    temp_keys[insertion_index] = key;
    temp_pointers[insertion_index] = pointer;
    leaf->num_keys = 0;
    split = cut(order - 1);
    for (i = 0; i < split; i++) {
        leaf->pointers[i] = temp_pointers[i];
        leaf->keys[i] = temp_keys[i];
        leaf->num_keys++;
    }
    for (i = split, j = 0; i < order; i++, j++) {
        new_leaf->pointers[j] = temp_pointers[i];
        new_leaf->keys[j] = temp_keys[i];
        new_leaf->num_keys++;
    }
    free(temp_pointers);
    free(temp_keys);
    new_leaf->pointers[order - 1] = leaf->pointers[order - 1];
    leaf->pointers[order - 1] = new_leaf;
    for (i = leaf->num_keys; i < order - 1; i++) leaf->pointers[i] = NULL;
    for (i = new_leaf->num_keys; i < order - 1; i++) new_leaf->pointers[i] = NULL;
    new_leaf->parent = leaf->parent;
    new_key = new_leaf->keys[0];
    return insert_into_parent(root, leaf, new_key, new_leaf);
}

node * insert_into_node(node * root, node * n, uint64_t left_index, uint64_t key, node * right) {
    uint64_t i;
    for (i = n->num_keys; i > left_index; i--) {
        n->pointers[i + 1] = n->pointers[i];
        n->keys[i] = n->keys[i - 1];
    }
    n->pointers[left_index + 1] = right;
    n->keys[left_index] = key;
    n->num_keys++;
    return root;
}

node * insert_into_node_after_splitting(node * root, node * old_node, uint64_t left_index,
        uint64_t key, node * right) {
    uint64_t i, j, split, k_prime;
    node * new_node, * child;
    node ** temp_pointers = allocate_align64((order + 1) * sizeof(node *));
    uint64_t * temp_keys = allocate_align64(order * sizeof(uint64_t));

    for (i = 0, j = 0; i < old_node->num_keys + 1; i++, j++) {
        if (j == left_index + 1) j++;
        temp_pointers[j] = old_node->pointers[i];
    }
    for (i = 0, j = 0; i < old_node->num_keys; i++, j++) {
        if (j == left_index) j++;
        temp_keys[j] = old_node->keys[i];
    }
    temp_pointers[left_index + 1] = right;
    temp_keys[left_index] = key;

    split = cut(order);
    new_node = make_node();
    old_node->num_keys = 0;
    for (i = 0; i < split - 1; i++) {
        old_node->pointers[i] = temp_pointers[i];
        old_node->keys[i] = temp_keys[i];
        old_node->num_keys++;
    }
    old_node->pointers[i] = temp_pointers[i];
    k_prime = temp_keys[split - 1];
    for (++i, j = 0; i < order; i++, j++) {
        new_node->pointers[j] = temp_pointers[i];
        new_node->keys[j] = temp_keys[i];
        new_node->num_keys++;
    }
    new_node->pointers[j] = temp_pointers[i];
    free(temp_pointers);
    free(temp_keys);
    new_node->parent = old_node->parent;
    for (i = 0; i <= new_node->num_keys; i++) {
        child = new_node->pointers[i];
        child->parent = new_node;
    }
    return insert_into_parent(root, old_node, k_prime, new_node);
}

node * insert_into_parent(node * root, node * left, uint64_t key, node * right) {
    uint64_t left_index;
    node * parent = left->parent;
    if (parent == NULL) return insert_into_new_root(left, key, right);
    left_index = get_left_index(parent, left);
    if (parent->num_keys < order - 1)
        return insert_into_node(root, parent, left_index, key, right);
    return insert_into_node_after_splitting(root, parent, left_index, key, right);
}

node * insert_into_new_root(node * left, uint64_t key, node * right) {
    node * root = make_node();
    root->keys[0] = key;
    root->pointers[0] = left;
    root->pointers[1] = right;
    root->num_keys++;
    root->parent = NULL;
    left->parent = root;
    right->parent = root;
    return root;
}

node * start_new_tree(uint64_t key, record * pointer) {
    node * root = make_leaf();
    root->keys[0] = key;
    root->pointers[0] = pointer;
    root->pointers[order - 1] = NULL;
    root->parent = NULL;
    root->num_keys++;
    return root;
}

node * insert(node * root, uint64_t key, uint64_t value) {
    record * record_pointer = find(root, key, false, NULL);
    if (record_pointer != NULL) {
        record_pointer->value = value;
        return root;
    }
    record_pointer = make_record(value);
    if (root == NULL) return start_new_tree(key, record_pointer);
    node * leaf = find_leaf(root, key, false);
    if (leaf->num_keys < order - 1) {
        leaf = insert_into_leaf(leaf, key, record_pointer);
        return root;
    }
    return insert_into_leaf_after_splitting(root, leaf, key, record_pointer);
}

// ============================================================================
// OPTIMIZED BULK LOADING FOR SORTED DATA
// ============================================================================

/*
 * Bulk load a B+ tree from sorted keys in O(n) time.
 * This is MUCH faster than inserting one by one.
 */
node * bulk_load(uint64_t *keys, record **records, size_t n) {
    if (n == 0) return NULL;
    
    size_t keys_per_leaf = order - 1;
    size_t num_leaves = (n + keys_per_leaf - 1) / keys_per_leaf;
    
    // Step 1: Create all leaf nodes
    node **leaves = allocate(num_leaves * sizeof(node *));
    size_t key_idx = 0;
    
    for (size_t i = 0; i < num_leaves; i++) {
        leaves[i] = make_leaf();
        size_t count = 0;
        while (count < keys_per_leaf && key_idx < n) {
            leaves[i]->keys[count] = keys[key_idx];
            leaves[i]->pointers[count] = records[key_idx];
            count++;
            key_idx++;
        }
        leaves[i]->num_keys = count;
        
        // Link leaves together
        if (i > 0) {
            leaves[i-1]->pointers[order - 1] = leaves[i];
        }
    }
    leaves[num_leaves - 1]->pointers[order - 1] = NULL;
    
    // If only one leaf, it's the root
    if (num_leaves == 1) {
        return leaves[0];
    }
    
    // Step 2: Build internal nodes level by level
    node **current_level = leaves;
    size_t current_count = num_leaves;
    
    while (current_count > 1) {
        size_t ptrs_per_node = order;
        size_t num_parents = (current_count + ptrs_per_node - 1) / ptrs_per_node;
        node **parent_level = allocate(num_parents * sizeof(node *));
        
        size_t child_idx = 0;
        for (size_t i = 0; i < num_parents; i++) {
            parent_level[i] = make_node();
            parent_level[i]->is_leaf = false;
            
            // First pointer
            parent_level[i]->pointers[0] = current_level[child_idx];
            current_level[child_idx]->parent = parent_level[i];
            child_idx++;
            
            // Add keys and remaining pointers
            size_t key_count = 0;
            while (key_count < order - 1 && child_idx < current_count) {
                // Key is the first key of the child
                node *child = current_level[child_idx];
                uint64_t separator;
                if (child->is_leaf) {
                    separator = child->keys[0];
                } else {
                    // For internal nodes, find leftmost leaf key
                    node *temp = child;
                    while (!temp->is_leaf) temp = temp->pointers[0];
                    separator = temp->keys[0];
                }
                parent_level[i]->keys[key_count] = separator;
                parent_level[i]->pointers[key_count + 1] = child;
                child->parent = parent_level[i];
                key_count++;
                child_idx++;
            }
            parent_level[i]->num_keys = key_count;
        }
        
        current_level = parent_level;
        current_count = num_parents;
    }
    
    return current_level[0];
}

/*
 * Fast insert for unique keys (skips duplicate check)
 * Use this when you KNOW the key doesn't exist yet.
 */
node * insert_unique(node * root, uint64_t key, record * rec) {
    if (root == NULL) return start_new_tree(key, rec);
    
    node * leaf = find_leaf(root, key, false);
    
    if (leaf->num_keys < order - 1) {
        // Fast path: append to end if key is largest (sorted insertion)
        if (leaf->num_keys == 0 || key > leaf->keys[leaf->num_keys - 1]) {
            leaf->keys[leaf->num_keys] = key;
            leaf->pointers[leaf->num_keys] = rec;
            leaf->num_keys++;
            return root;
        }
        insert_into_leaf(leaf, key, rec);
        return root;
    }
    
    return insert_into_leaf_after_splitting(root, leaf, key, rec);
}

// ============================================================================
// DELETION (unchanged from original)
// ============================================================================

uint64_t get_neighbor_index(node * n) {
    uint64_t i;
    for (i = 0; i <= n->parent->num_keys; i++)
        if (n->parent->pointers[i] == n) return i - 1;
    printf("Search for nonexistent pointer to node in parent.\n");
    exit(EXIT_FAILURE);
}

node * remove_entry_from_node(node * n, uint64_t key, node * pointer) {
    uint64_t i, num_pointers;
    i = 0;
    while (n->keys[i] != key) i++;
    for (++i; i < n->num_keys; i++) n->keys[i - 1] = n->keys[i];
    num_pointers = n->is_leaf ? n->num_keys : n->num_keys + 1;
    i = 0;
    while (n->pointers[i] != pointer) i++;
    for (++i; i < num_pointers; i++) n->pointers[i - 1] = n->pointers[i];
    n->num_keys--;
    if (n->is_leaf)
        for (i = n->num_keys; i < order - 1; i++) n->pointers[i] = NULL;
    else
        for (i = n->num_keys + 1; i < order; i++) n->pointers[i] = NULL;
    return n;
}

node * adjust_root(node * root) {
    node * new_root;
    if (root->num_keys > 0) return root;
    if (!root->is_leaf) {
        new_root = root->pointers[0];
        new_root->parent = NULL;
    } else new_root = NULL;
    free(root->keys);
    free(root->pointers);
    free_node(root);
    return new_root;
}

node * coalesce_nodes(node * root, node * n, node * neighbor, uint64_t neighbor_index, uint64_t k_prime) {
    uint64_t i, j, neighbor_insertion_index, n_end;
    node * tmp;
    if (neighbor_index == -1) { tmp = n; n = neighbor; neighbor = tmp; }
    neighbor_insertion_index = neighbor->num_keys;
    if (!n->is_leaf) {
        neighbor->keys[neighbor_insertion_index] = k_prime;
        neighbor->num_keys++;
        n_end = n->num_keys;
        for (i = neighbor_insertion_index + 1, j = 0; j < n_end; i++, j++) {
            neighbor->keys[i] = n->keys[j];
            neighbor->pointers[i] = n->pointers[j];
            neighbor->num_keys++;
            n->num_keys--;
        }
        neighbor->pointers[i] = n->pointers[j];
        for (i = 0; i < neighbor->num_keys + 1; i++) {
            tmp = (node *)neighbor->pointers[i];
            tmp->parent = neighbor;
        }
    } else {
        for (i = neighbor_insertion_index, j = 0; j < n->num_keys; i++, j++) {
            neighbor->keys[i] = n->keys[j];
            neighbor->pointers[i] = n->pointers[j];
            neighbor->num_keys++;
        }
        neighbor->pointers[order - 1] = n->pointers[order - 1];
    }
    root = delete_entry(root, n->parent, k_prime, n);
    free(n->keys);
    free(n->pointers);
    free_node(n);
    return root;
}

node * redistribute_nodes(node * root, node * n, node * neighbor, uint64_t neighbor_index,
        uint64_t k_prime_index, uint64_t k_prime) {
    uint64_t i;
    node * tmp;
    if (neighbor_index != -1) {
        if (!n->is_leaf) n->pointers[n->num_keys + 1] = n->pointers[n->num_keys];
        for (i = n->num_keys; i > 0; i--) {
            n->keys[i] = n->keys[i - 1];
            n->pointers[i] = n->pointers[i - 1];
        }
        if (!n->is_leaf) {
            n->pointers[0] = neighbor->pointers[neighbor->num_keys];
            tmp = (node *)n->pointers[0];
            tmp->parent = n;
            neighbor->pointers[neighbor->num_keys] = NULL;
            n->keys[0] = k_prime;
            n->parent->keys[k_prime_index] = neighbor->keys[neighbor->num_keys - 1];
        } else {
            n->pointers[0] = neighbor->pointers[neighbor->num_keys - 1];
            neighbor->pointers[neighbor->num_keys - 1] = NULL;
            n->keys[0] = neighbor->keys[neighbor->num_keys - 1];
            n->parent->keys[k_prime_index] = n->keys[0];
        }
    } else {
        if (n->is_leaf) {
            n->keys[n->num_keys] = neighbor->keys[0];
            n->pointers[n->num_keys] = neighbor->pointers[0];
            n->parent->keys[k_prime_index] = neighbor->keys[1];
        } else {
            n->keys[n->num_keys] = k_prime;
            n->pointers[n->num_keys + 1] = neighbor->pointers[0];
            tmp = (node *)n->pointers[n->num_keys + 1];
            tmp->parent = n;
            n->parent->keys[k_prime_index] = neighbor->keys[0];
        }
        for (i = 0; i < neighbor->num_keys - 1; i++) {
            neighbor->keys[i] = neighbor->keys[i + 1];
            neighbor->pointers[i] = neighbor->pointers[i + 1];
        }
        if (!n->is_leaf) neighbor->pointers[i] = neighbor->pointers[i + 1];
    }
    n->num_keys++;
    neighbor->num_keys--;
    return root;
}

node * delete_entry(node * root, node * n, uint64_t key, void * pointer) {
    uint64_t min_keys;
    node * neighbor;
    uint64_t neighbor_index, k_prime_index, k_prime, capacity;
    n = remove_entry_from_node(n, key, pointer);
    if (n == root) return adjust_root(root);
    min_keys = n->is_leaf ? cut(order - 1) : cut(order) - 1;
    if (n->num_keys >= min_keys) return root;
    neighbor_index = get_neighbor_index(n);
    k_prime_index = neighbor_index == -1 ? 0 : neighbor_index;
    k_prime = n->parent->keys[k_prime_index];
    neighbor = neighbor_index == -1 ? n->parent->pointers[1] : n->parent->pointers[neighbor_index];
    capacity = n->is_leaf ? order : order - 1;
    if (neighbor->num_keys + n->num_keys < capacity)
        return coalesce_nodes(root, n, neighbor, neighbor_index, k_prime);
    else
        return redistribute_nodes(root, n, neighbor, neighbor_index, k_prime_index, k_prime);
}

node * delete(node * root, uint64_t key) {
    node * key_leaf = NULL;
    record * key_record = find(root, key, false, &key_leaf);
    if (key_record != NULL && key_leaf != NULL) {
        root = delete_entry(root, key_leaf, key, key_record);
        free_record(key_record);
    }
    return root;
}

void destroy_tree_nodes(node * root) {
    uint64_t i;
    if (root->is_leaf)
        for (i = 0; i < root->num_keys; i++) free(root->pointers[i]);
    else
        for (i = 0; i < root->num_keys + 1; i++) destroy_tree_nodes(root->pointers[i]);
    free(root->pointers);
    free(root->keys);
    free_node(root);
}

node * destroy_tree(node * root) {
    destroy_tree_nodes(root);
    return NULL;
}

// ============================================================================
// PRNG (unchanged)
// ============================================================================

#define N    16
#define MASK    ((1 << (N - 1)) + (1 << (N - 1)) - 1)
#define LOW(x)    ((unsigned)(x) & MASK)
#define HIGH(x)    LOW((x) >> N)
#define MUL(x, y, z)    { int32_t l = (long)(x) * (long)(y); (z)[0] = LOW(l); (z)[1] = HIGH(l); }
#define CARRY(x, y)    ((int32_t)(x) + (long)(y) > MASK)
#define ADDEQU(x, y, z)    (z = CARRY(x, (y)), x = LOW(x + (y)))
#define X0    0x330E
#define X1    0xABCD
#define X2    0x1234
#define A0    0xE66D
#define A1    0xDEEC
#define A2    0x5
#define C    0xB
#define SET3(x, x0, x1, x2)    ((x)[0] = (x0), (x)[1] = (x1), (x)[2] = (x2))
#define SEED(x0, x1, x2) (SET3(x, x0, x1, x2), SET3(a, A0, A1, A2), c = C)

static uint64_t x[3] = { X0, X1, X2 }, a[3] = { A0, A1, A2 }, c = C;
static void next(void);

uint64_t redisLrand48() {
    next();
    return (((uint64_t)x[2] << (N - 1)) + (x[1] >> 1));
}

void redisSrand48(int32_t seedval) {
    SEED(X0, LOW(seedval), HIGH(seedval));
}

static void next(void) {
    uint64_t p[2], q[2], r[2], carry0, carry1;
    MUL(a[0], x[0], p);
    ADDEQU(p[0], c, carry0);
    ADDEQU(p[1], carry0, carry1);
    MUL(a[0], x[1], q);
    ADDEQU(p[1], q[0], carry0);
    MUL(a[1], x[0], r);
    x[2] = LOW(carry0 + carry1 + CARRY(p[1], r[0]) + q[1] + r[1] +
            a[0] * x[2] + a[1] * x[1] + a[2] * x[0]);
    x[1] = LOW(p[1] + r[0]);
    x[0] = LOW(p[0]);
}

// ============================================================================
// MAIN - Using bulk load for maximum speed
// ============================================================================

struct element {
    uint64_t payload;
};

int real_main(int argc, char ** argv) {
    node * root = NULL;
    
    printf("BTree Elements: %zuM\n", NELEMENTS/1000000);
    printf("BTree #Lookups: %zuM\n", NLOOKUP/1000000);
    verbose_output = false;
    order = 16;
    
    redisSrand48(0xcafebabe);
    
    // Allocate element storage (two arrays for scattered insertion)
    struct element *elms = allocate((NELEMENTS / 2) * sizeof(struct element));
    
    printf("Allocator after elements: %zu MB\n", allocator_stat >> 20);
    
    // ========================================================================
    // SCATTERED INSERTION (complex tree for page table benchmarking)
    // Same pattern as original but using insert_unique (skips duplicate check)
    // ========================================================================
    struct element *elms2 = allocate((NELEMENTS / 2) * sizeof(struct element));
    
    printf("Starting scattered insertion (for page table complexity)...\n");
    struct timeval ins_start, ins_end;
    gettimeofday(&ins_start, NULL);
    
    size_t progress_interval = NELEMENTS / 10;
    for (size_t i = 0; i < NELEMENTS; i += 2) {
        elms[i/2].payload = i;
        elms2[i/2].payload = NELEMENTS - i - 1;
        
        record *rec1 = make_record((uint64_t)&elms[i/2]);
        record *rec2 = make_record((uint64_t)&elms2[i/2]);
        
        // Insert low key and high key alternately (scatters tree across memory)
        root = insert_unique(root, i, rec1);
        root = insert_unique(root, NELEMENTS - i - 1, rec2);
        
        if (i % progress_interval == 0) {
            printf("  Inserted %zu%% (%zuM elements)\n", 
                   (i * 100) / NELEMENTS, i / 1000000);
        }
    }
    
    gettimeofday(&ins_end, NULL);
    double ins_time = (ins_end.tv_sec - ins_start.tv_sec) + 
                      (ins_end.tv_usec - ins_start.tv_usec) / 1000000.0;
    printf("Scattered insertion complete in %.2f seconds\n", ins_time);
    
    printf("Allocator total: %zu MB\n", allocator_stat >> 20);
    printf("Tree height: %lu\n", height(root));
    
    // Signal ready
    fprintf(stderr, "signalling readyness to %s\n", CONFIG_SHM_FILE_NAME ".ready");
    FILE *fd2 = fopen(CONFIG_SHM_FILE_NAME ".ready", "w");
    if (fd2 == NULL) {
        fprintf(stderr, "ERROR: could not create the shared memory file descriptor\n");
        exit(-1);
    }
    usleep(250);
    
    // Lookup phase
    uint64_t sum = 0;
    struct timeval start, end;
    gettimeofday(&start, NULL);
    
#ifdef _OPENMP
#pragma omp parallel reduction(+:sum)
{
    // Thread-local PRNG state to avoid data races
    uint64_t local_x[3] = { X0, X1, X2 };
    uint64_t local_a[3] = { A0, A1, A2 };
    uint64_t local_c = C;
    
    // Seed based on thread id
    int tid = omp_get_thread_num();
    local_x[1] = LOW(0xcafebabe + tid * 12345);
    local_x[2] = HIGH(0xcafebabe + tid * 12345);
    
    #pragma omp for
    for (size_t i = 0; i < NLOOKUP; i++) {
        // Inline PRNG to avoid shared state
        uint64_t p[2], q[2], r[2], carry0, carry1;
        MUL(local_a[0], local_x[0], p);
        ADDEQU(p[0], local_c, carry0);
        ADDEQU(p[1], carry0, carry1);
        MUL(local_a[0], local_x[1], q);
        ADDEQU(p[1], q[0], carry0);
        MUL(local_a[1], local_x[0], r);
        local_x[2] = LOW(carry0 + carry1 + CARRY(p[1], r[0]) + q[1] + r[1] +
                local_a[0] * local_x[2] + local_a[1] * local_x[1] + local_a[2] * local_x[0]);
        local_x[1] = LOW(p[1] + r[0]);
        local_x[0] = LOW(p[0]);
        size_t rdn = (((uint64_t)local_x[2] << (N - 1)) + (local_x[1] >> 1));
        
        record * r1 = find(root, rdn % NELEMENTS, false, NULL);
        if (r1) {
            struct element *e = (struct element *)r1->value;
            if (e) sum += e->payload;
        }
        
        record * r2 = find(root, ((rdn + 1) << 2) % NELEMENTS, false, NULL);
        if (r2) {
            struct element *e = (struct element *)r2->value;
            if (e) sum += e->payload;
        }
    }
}
#else
    for (size_t i = 0; i < NLOOKUP; i++) {
        size_t rdn = redisLrand48();
        record * r = find(root, rdn % NELEMENTS, false, NULL);
        if (r) {
            struct element *e = (struct element *)r->value;
            if (e) sum += e->payload;
        }
        r = find(root, ((rdn + 1) << 2) % NELEMENTS, false, NULL);
        if (r) {
            struct element *e = (struct element *)r->value;
            if (e) sum += e->payload;
        }
    }
#endif
    
    gettimeofday(&end, NULL);
    printf("got %zu sum in %zu seconds\n", sum, end.tv_sec - start.tv_sec);
    
    // Signal done
    fprintf(stderr, "signalling done to %s\n", CONFIG_SHM_FILE_NAME ".done");
    FILE *fd1 = fopen(CONFIG_SHM_FILE_NAME ".done", "w");
    if (fd1 == NULL) {
        fprintf(stderr, "ERROR: could not create the shared memory file descriptor\n");
        exit(-1);
    }
    
    return EXIT_SUCCESS;
}
