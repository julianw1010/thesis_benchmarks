// Copyright (c) 2015, The Regents of the University of California (Regents)
// See LICENSE.txt for license details

#include <algorithm>
#include <iostream>
#include <vector>
#include <unistd.h>

#include "benchmark.h"
#include "builder.h"
#include "command_line.h"
#include "graph.h"
#include "pvector.h"

#define CONFIG_SHM_FILE_NAME "/tmp/alloctest-bench"

/*
GAP Benchmark Suite
Kernel: PageRank (PR)
Author: Scott Beamer

Will return pagerank scores for all vertices once total change < epsilon

This legacy PR implementation uses the traditional iterative approach. This is
done to ease comparisons to other implementations (often use same algorithm),
but it is not necessarily the fastest way to implement it. It performs each
iteration as a sparse-matrix vector multiply (SpMV), and values are not visible
until the next iteration (like Jacobi-style method).
*/


using namespace std;

typedef float ScoreT;
const float kDamp = 0.85;

pvector<ScoreT> PageRankPull(const Graph &g, int max_iters, double epsilon = 0,
                             bool logging_enabled = false) {
  const ScoreT init_score = 1.0f / g.num_nodes();
  const ScoreT base_score = (1.0f - kDamp) / g.num_nodes();
  pvector<ScoreT> scores(g.num_nodes(), init_score);
  pvector<ScoreT> outgoing_contrib(g.num_nodes());
  for (int iter=0; iter < max_iters; iter++) {
    double error = 0;
    #pragma omp parallel for
    for (NodeID n=0; n < g.num_nodes(); n++)
      outgoing_contrib[n] = scores[n] / g.out_degree(n);
    #pragma omp parallel for reduction(+ : error) schedule(dynamic, 16384)
    for (NodeID u=0; u < g.num_nodes(); u++) {
      ScoreT incoming_total = 0;
      for (NodeID v : g.in_neigh(u))
        incoming_total += outgoing_contrib[v];
      ScoreT old_score = scores[u];
      scores[u] = base_score + kDamp * incoming_total;
      error += fabs(scores[u] - old_score);
    }
    if (logging_enabled)
      PrintStep(iter, error);
    if (error < epsilon)
      break;
  }
  return scores;
}


void PrintTopScores(const Graph &g, const pvector<ScoreT> &scores) {
  vector<pair<NodeID, ScoreT>> score_pairs(g.num_nodes());
  for (NodeID n=0; n < g.num_nodes(); n++) {
    score_pairs[n] = make_pair(n, scores[n]);
  }
  int k = 5;
  vector<pair<ScoreT, NodeID>> top_k = TopK(score_pairs, k);
  for (auto kvp : top_k)
    cout << kvp.second << ":" << kvp.first << endl;
}


// Verifies by asserting a single serial iteration in push direction has
//   error < target_error
bool PRVerifier(const Graph &g, const pvector<ScoreT> &scores,
                        double target_error) {
  const ScoreT base_score = (1.0f - kDamp) / g.num_nodes();
  pvector<ScoreT> incoming_sums(g.num_nodes(), 0);
  double error = 0;
  for (NodeID u : g.vertices()) {
    ScoreT outgoing_contrib = scores[u] / g.out_degree(u);
    for (NodeID v : g.out_neigh(u))
      incoming_sums[v] += outgoing_contrib;
  }
  for (NodeID n : g.vertices()) {
    error += fabs(base_score + kDamp * incoming_sums[n] - scores[n]);
    incoming_sums[n] = 0;
  }
  PrintTime("Total Error", error);
  return error < target_error;
}


int main(int argc, char* argv[]) {
  CLPageRank cli(argc, argv, "pagerank", 1e-4, 20);
  if (!cli.ParseArgs())
    return -1;
  Builder b(cli);
  Graph g = b.MakeGraph();

  // Signal ready (after graph is built, before computation)
  fprintf(stderr, "signalling readyness to %s\n", CONFIG_SHM_FILE_NAME ".ready");
  FILE *fd_ready = fopen(CONFIG_SHM_FILE_NAME ".ready", "w");
  if (fd_ready == NULL) {
    fprintf(stderr, "ERROR: could not create the ready file descriptor\n");
    exit(-1);
  }

  fclose(fd_ready);

  FILE *fd_pid = fopen(CONFIG_SHM_FILE_NAME ".pid", "w");
  if (fd_pid) {
          fprintf(fd_pid, "%d", getpid());
          fclose(fd_pid);
  }
  
  // Wait for external setup to complete
  const char *flush_signal = CONFIG_SHM_FILE_NAME ".flushed";
  for (int i = 0; i < 600; i++) {  // 30s timeout
    if (access(flush_signal, F_OK) == 0) {
      unlink(flush_signal);
      break;
    }
    usleep(50000);  // 50ms
  }  
  
  auto PRBound = [&cli] (const Graph &g) {
    return PageRankPull(g, cli.max_iters(), cli.tolerance(), cli.logging_en());
  };
  auto VerifierBound = [&cli] (const Graph &g, const pvector<ScoreT> &scores) {
    return PRVerifier(g, scores, cli.tolerance());
  };
  BenchmarkKernel(cli, g, PRBound, PrintTopScores, VerifierBound);
  
  // Signal done (after all work is complete)
  fprintf(stderr, "signalling done to %s\n", CONFIG_SHM_FILE_NAME ".done");
  FILE *fd_done = fopen(CONFIG_SHM_FILE_NAME ".done", "w");
  if (fd_done == NULL) {
    fprintf(stderr, "ERROR: could not create the done file descriptor\n");
    exit(-1);
  }
  fclose(fd_done);
  
  return 0;
}
