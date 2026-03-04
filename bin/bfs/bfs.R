###############################################################################
###                              bfs.R                                      ###
###############################################################################

library(ggplot2)

# =============================================================================
# RAW DATA: Trial Times (seconds) – BFS Benchmark
# 128 threads, n=5, repl_order_9 for Hydra
# Source: rawdata.txt
# =============================================================================

data <- list(
  # --- LINUX First-Touch (output_0.txt) ---
  linux_ft_kron27  = c(0.63982, 1.20474, 0.77114, 1.03549, 0.48598),
  linux_ft_kron28  = c(1.05482, 0.94049, 3.45409, 1.06262, 2.43932),
  linux_ft_kron29  = c(6.38843, 2.09237, 2.20668, 3.62679, 2.61544),
  linux_ft_kron30  = c(4.16872, 5.52448, 4.32555, 5.83671, 4.09305),
  linux_ft_uni27   = c(3.22802, 2.24690, 3.17975, 3.34297, 2.98308),
  linux_ft_uni28   = c(14.36372, 14.82500, 17.61697, 16.48123, 13.49463),
  linux_ft_uni29   = c(6.80425, 7.16116, 46.53002, 6.22426, 7.43749),
  linux_ft_uni30   = c(11.40271, 10.77471, 13.50089, 12.46368, 11.04642),
  linux_ft_twitter = c(0.33198, 0.30629, 0.31360, 0.37446, 0.36670),
  linux_ft_web     = c(0.87929, 0.96631, 0.87084, 0.86778, 0.95765),
  linux_ft_road    = c(1.15316, 0.67735, 0.88717, 0.94605, 1.06606),

  # --- LINUX Interleaved (output_i_0.txt) ---
  linux_il_kron27  = c(0.32320, 0.20976, 0.17425, 0.20008, 0.21839),
  linux_il_kron28  = c(0.43266, 0.38565, 0.50182, 0.36882, 0.42580),
  linux_il_kron29  = c(1.08213, 0.74006, 0.70924, 0.81357, 0.97159),
  linux_il_kron30  = c(1.41108, 2.51166, 1.47215, 3.06755, 1.32456),
  linux_il_uni27   = c(0.47744, 0.37879, 0.38036, 0.39491, 0.38551),
  linux_il_uni28   = c(1.93730, 1.68875, 2.50430, 2.00835, 1.81624),
  linux_il_uni29   = c(1.85578, 2.00288, 6.41877, 1.65351, 1.88333),
  linux_il_uni30   = c(3.24491, 3.28220, 3.10030, 3.08838, 3.49586),
  linux_il_twitter = c(0.16031, 0.17091, 0.19213, 0.20934, 0.15207),
  linux_il_web     = c(0.25415, 0.24750, 0.23123, 0.24025, 0.24304),
  linux_il_road    = c(1.10815, 1.04911, 0.94607, 0.98434, 1.06885),

  # --- MITOSIS Replicated (output_r_0.txt) ---
  mitosis_ft_kron27  = c(0.71499, 1.16607, 0.73443, 1.21090, 0.58334),
  mitosis_ft_kron28  = c(1.24644, 1.14900, 3.18357, 1.17404, 2.35529),
  mitosis_ft_kron29  = c(6.53415, 2.38476, 2.44523, 3.98637, 2.94873),
  mitosis_ft_kron30  = c(5.00984, 6.05173, 4.88529, 6.86609, 4.66005),
  mitosis_ft_uni27   = c(3.80165, 2.34865, 3.28383, 3.85603, 3.34138),
  mitosis_ft_uni28   = c(13.59592, 16.33659, 17.92850, 17.70297, 14.24454),
  mitosis_ft_uni29   = c(6.03750, 6.28913, 46.37400, 5.63849, 6.11774),
  mitosis_ft_uni30   = c(11.79463, 12.58149, 13.88212, 14.18134, 12.94354),
  mitosis_ft_twitter = c(0.37837, 0.39256, 0.35565, 0.39616, 0.37469),
  mitosis_ft_web     = c(0.91689, 1.00631, 0.88933, 0.89280, 0.97646),
  mitosis_ft_road    = c(1.31817, 1.22666, 1.01631, 1.12588, 1.22259),

  # --- MITOSIS Replicated+Interleaved (output_ri_0.txt) ---
  mitosis_il_kron27  = c(0.42238, 0.29677, 0.27077, 0.29344, 0.31311),
  mitosis_il_kron28  = c(0.61957, 0.53836, 0.63071, 0.54482, 0.55537),
  mitosis_il_kron29  = c(1.33255, 1.02752, 1.05564, 1.05377, 1.23106),
  mitosis_il_kron30  = c(1.99130, 2.78213, 2.02267, 3.32835, 1.91099),
  mitosis_il_uni27   = c(0.58954, 0.48145, 0.51467, 0.51814, 0.51160),
  mitosis_il_uni28   = c(2.13000, 1.91317, 2.69050, 2.18703, 1.99378),
  mitosis_il_uni29   = c(2.46803, 2.58518, 6.66885, 2.30389, 2.50429),
  mitosis_il_uni30   = c(4.46937, 4.47504, 4.23035, 4.20331, 4.56284),
  mitosis_il_twitter = c(0.22972, 0.22286, 0.25108, 0.30251, 0.19797),
  mitosis_il_web     = c(0.35187, 0.33934, 0.29783, 0.29576, 0.30869),
  mitosis_il_road    = c(1.34631, 1.24989, 1.14571, 1.19215, 1.25148),

  # --- WASP First-Touch (output_0.txt) ---
  wasp_ft_kron27  = c(0.62568, 1.02531, 0.74199, 1.59214, 0.58999),
  wasp_ft_kron28  = c(0.99482, 1.02333, 3.16038, 1.23941, 2.36526),
  wasp_ft_kron29  = c(8.78257, 2.34712, 2.50030, 3.56171, 2.85227),
  wasp_ft_kron30  = c(9.22883, 13.79496, 11.17412, 6.31884, 11.55982),
  wasp_ft_uni27   = c(3.00215, 2.62016, 2.53134, 2.58392, 2.54132),
  wasp_ft_uni28   = c(17.46302, 15.78121, 17.58495, 16.12784, 15.65797),
  wasp_ft_uni29   = c(8.27482, 6.17707, 53.53543, 6.15990, 6.55394),
  wasp_ft_uni30   = c(17.57179, 19.76651, 13.46898, 21.38284, 20.26274),
  wasp_ft_twitter = c(0.33518, 0.29949, 0.51242, 0.37618, 0.35637),
  wasp_ft_web     = c(0.97102, 0.96507, 0.97509, 0.90333, 1.02155),
  wasp_ft_road    = c(1.48844, 1.26118, 1.09204, 1.14499, 1.26124),

  # --- WASP Interleaved (output_i_0.txt) ---
  wasp_il_kron27  = c(0.31879, 0.20324, 0.24176, 0.20307, 0.21800),
  wasp_il_kron28  = c(0.47111, 0.38523, 0.55506, 0.36727, 1.75929),
  wasp_il_kron29  = c(1.08980, 0.73693, 3.56700, 1.07367, 1.23430),
  wasp_il_kron30  = c(1.42310, 8.01944, 3.42901, 8.28997, 3.61052),
  wasp_il_uni27   = c(0.46794, 0.40506, 0.38816, 1.10120, 0.50612),
  wasp_il_uni28   = c(2.14993, 1.87193, 2.75341, 2.19627, 2.00446),
  wasp_il_uni29   = c(4.49541, 2.62825, 6.62107, 2.28792, 2.49672),
  wasp_il_uni30   = c(8.92964, 4.57483, 4.33559, 4.31133, 12.42008),
  wasp_il_twitter = c(0.16394, 0.30307, 0.18474, 0.26394, 0.14843),
  wasp_il_web     = c(0.32421, 0.24593, 0.23095, 0.23502, 0.32970),
  wasp_il_road    = c(1.29713, 1.24215, 1.12872, 1.17116, 1.24934),

  # --- HYDRA Replicated (repl_order_9/output_r_0.txt) ---
  hydra_ft_kron27  = c(0.63307, 0.87630, 0.72172, 0.94655, 0.50685),
  hydra_ft_kron28  = c(1.08076, 1.01018, 3.01532, 1.03037, 1.99352),
  hydra_ft_kron29  = c(6.80869, 2.22084, 2.19891, 3.84682, 2.52645),
  hydra_ft_kron30  = c(4.47922, 5.58756, 4.34161, 5.93868, 4.30129),
  hydra_ft_uni27   = c(3.18281, 2.36414, 2.27517, 2.65625, 2.25862),
  hydra_ft_uni28   = c(14.01363, 13.70135, 17.85600, 15.17646, 14.44651),
  hydra_ft_uni29   = c(5.87533, 5.84522, 52.02185, 5.30042, 5.71081),
  hydra_ft_uni30   = c(11.23389, 10.99212, 11.76247, 12.25048, 10.80230),
  hydra_ft_twitter = c(0.34200, 0.31578, 0.37608, 0.42594, 0.32666),
  hydra_ft_web     = c(0.91092, 0.98375, 0.89851, 0.88934, 0.96148),
  hydra_ft_road    = c(3.50882, 3.34856, 2.91563, 3.12241, 3.13601),

  # --- HYDRA Replicated+Interleaved (repl_order_9/output_ri_0.txt) ---
  hydra_il_kron27  = c(0.36689, 0.23514, 0.19265, 0.22459, 0.24049),
  hydra_il_kron28  = c(0.60145, 0.42525, 0.53115, 0.41542, 0.45691),
  hydra_il_kron29  = c(1.21707, 0.79401, 0.80776, 0.81125, 0.99240),
  hydra_il_kron30  = c(1.99856, 2.33646, 1.57689, 2.70618, 1.45598),
  hydra_il_uni27   = c(0.55093, 0.42021, 0.43687, 0.44238, 0.43321),
  hydra_il_uni28   = c(2.09086, 1.75376, 2.53927, 2.05027, 1.87486),
  hydra_il_uni29   = c(2.38270, 2.24051, 6.43616, 2.02222, 2.19242),
  hydra_il_uni30   = c(4.21606, 3.90635, 3.73062, 3.68280, 4.04010),
  hydra_il_twitter = c(0.18964, 0.21418, 0.20991, 0.30468, 0.16212),
  hydra_il_web     = c(0.32975, 0.30906, 0.28989, 0.29553, 0.30232),
  hydra_il_road    = c(3.44028, 3.38105, 2.91798, 3.11688, 3.19682)
)

# =============================================================================
# PAIRED PERMUTATION TEST (exact, one-sided: Linux slower → diff > 0)
# =============================================================================

perm_test <- function(baseline, treatment) {
  d <- baseline - treatment
  obs <- mean(d)
  n <- length(d)
  perm_stats <- numeric(2^n)
  for (i in 0:(2^n - 1)) {
    signs <- 2 * as.integer(intToBits(i)[1:n]) - 1
    perm_stats[i + 1] <- mean(signs * abs(d))
  }
  p <- mean(perm_stats >= obs)
  return(list(obs = obs, p = p))
}

# =============================================================================
# RUN ALL TESTS
# =============================================================================

graphs <- c("kron27", "kron28", "kron29", "kron30",
            "uni27", "uni28", "uni29", "uni30",
            "twitter", "web", "road")
policies <- c("ft", "il")
policy_labels <- c(ft = "First-Touch", il = "Interleaved")
systems <- c("mitosis", "wasp", "hydra")

results <- data.frame()

pdf("bfs.pdf", width = 10, height = 5)

for (graph in graphs) {
  for (pol in policies) {
    linux_key <- paste0("linux_", pol, "_", graph)
    for (sys in systems) {
      sys_key <- paste0(sys, "_", pol, "_", graph)
      res <- perm_test(data[[linux_key]], data[[sys_key]])
      results <- rbind(results, data.frame(
        Graph = graph,
        Policy = policy_labels[pol],
        Comparison = paste("Linux vs", tools::toTitleCase(sys)),
        MeanDiff = round(res$obs, 5),
        p_value = res$p,
        stringsAsFactors = FALSE
      ))
    }
  }
}

# Print results table
cat("\n====== PAIRED PERMUTATION TEST RESULTS (exact, one-sided) ======\n")
cat("BFS (Breadth-First Search)\n")
cat("128 threads | 5 trials | repl_order_9 for Hydra\n\n")
print(results, row.names = FALSE)

# Count significant results
cat("\n\nSignificant (p < 0.05):", sum(results$p_value < 0.05), "of", nrow(results), "\n")
cat("Non-significant (p >= 0.05):", sum(results$p_value >= 0.05), "of", nrow(results), "\n")

# =============================================================================
# PLOTS: One per graph per policy, with 3 facets (Mitosis, WASP, Hydra)
# =============================================================================

for (graph in graphs) {
  for (pol in policies) {
    linux_key <- paste0("linux_", pol, "_", graph)
    max_linux <- max(data[[linux_key]])
    df_list <- list()

    for (sys in systems) {
      sys_key <- paste0(sys, "_", pol, "_", graph)
      res <- perm_test(data[[linux_key]], data[[sys_key]])
      sys_label <- tools::toTitleCase(sys)
      pct <- round(res$obs / mean(data[[linux_key]]) * 100, 1)
      label <- paste0("Linux vs ", sys_label,
                      "\np = ", res$p,
                      " | ", pct, "% faster")
      df_list[[sys]] <- data.frame(
        Trial = rep(1:5, 2),
        Zeit = c(data[[linux_key]] / max_linux, data[[sys_key]] / max_linux),
        Bedingung = factor(rep(c("Linux", sys_label), each = 5),
                           levels = c("Linux", sys_label)),
        Vergleich = label
      )
    }

    df <- do.call(rbind, df_list)
    df$Vergleich <- factor(df$Vergleich, levels = unique(df$Vergleich))

    # Compute y-axis limits with padding for better spread
    y_min <- min(df$Zeit)
    y_max <- max(df$Zeit)
    y_pad <- (y_max - y_min) * 0.15

    p <- ggplot(df, aes(x = Bedingung, y = Zeit)) +
      geom_line(aes(group = Trial), color = "gray50", linewidth = 0.5) +
      geom_point(aes(color = Bedingung), size = 2) +
      scale_color_manual(values = c("Linux" = "#E74C3C",
                                    "Mitosis" = "#2ECC71",
                                    "Wasp" = "#3498DB",
                                    "Hydra" = "#9B59B6")) +
      coord_cartesian(ylim = c(y_min - y_pad, y_max + y_pad)) +
      facet_wrap(~ Vergleich, scales = "free_x") +
      labs(
        title = paste0("GAP Breadth-First Search (BFS) - ",
                       graph, " - ", policy_labels[pol]),
        subtitle = "128 threads | n = 5 | Normalized to max Linux trial | Paired permutation test | Average speedup",
        x = NULL,
        y = "Normalized Runtime (1.0 = max Linux)"
      ) +
      theme_minimal(base_size = 13) +
      theme(legend.position = "none",
            plot.title = element_text(face = "bold"),
            strip.text = element_text(face = "bold", size = 10))

    print(p)
  }
}

dev.off()
cat("Saved all plots to bfs.pdf\n")
