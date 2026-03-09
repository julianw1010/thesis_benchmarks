###############################################################################
###                           btree.R                                       ###
###############################################################################

library(ggplot2)

# =============================================================================
# RAW DATA: Lookup Runtime (seconds) – BTree bench_btree_mt, 128 threads, n=5
# Working Set: ~269 GB (Allocator total: 268,579 MB)
# 3B elements, 1.31B lookups, tree height 9
# Metric: "got ... sum in X seconds"
# =============================================================================

data <- list(
  # --- LINUX First-Touch (linux/output_0..4.txt) ---
  linux_ft  = c(202, 200, 203, 210, 199),

  # --- LINUX Interleaved (linux/output_i_0..4.txt) ---
  linux_il  = c(97, 97, 97, 98, 96),

  # --- WASP First-Touch (wasp/output_0..4.txt) ---
  wasp_ft   = c(167, 153, 181, 147, 141),

  # --- WASP Interleaved (wasp/output_i_0..4.txt) ---
  wasp_il   = c(80, 81, 81, 80, 80),

  # --- MITOSIS Replicated (mitosis/output_r_0..4.txt) ---
  mitosis_ft  = c(161, 130, 131, 144, 84),

  # --- MITOSIS Replicated+Interleaved (mitosis/output_ri_0..4.txt) ---
  mitosis_il  = c(79, 77, 77, 78, 78),

  # --- HYDRA Replicated (hydra/repl_order_9/output_r_0..4.txt) ---
  hydra_ft  = c(83, 126, 85, 84, 143),

  # --- HYDRA Replicated+Interleaved (hydra/repl_order_9/output_ri_0..4.txt) ---
  hydra_il  = c(79, 78, 78, 77, 78)
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

policies <- c("ft", "il")
policy_labels <- c(ft = "First-Touch", il = "Interleaved")
systems <- c("mitosis", "wasp", "hydra")

results <- data.frame()

pdf("btree.pdf", width = 10, height = 5)

for (pol in policies) {
  linux_key <- paste0("linux_", pol)
  for (sys in systems) {
    sys_key <- paste0(sys, "_", pol)
    res <- perm_test(data[[linux_key]], data[[sys_key]])
    results <- rbind(results, data.frame(
      Policy = policy_labels[pol],
      Comparison = paste("Linux vs", tools::toTitleCase(sys)),
      Linux_Mean = round(mean(data[[linux_key]]), 3),
      Sys_Mean = round(mean(data[[sys_key]]), 3),
      MeanDiff = round(res$obs, 3),
      PctFaster = round(res$obs / mean(data[[linux_key]]) * 100, 1),
      p_value = res$p,
      stringsAsFactors = FALSE
    ))
  }
}

# Print results table
cat("\n====== PAIRED PERMUTATION TEST RESULTS (exact, one-sided) ======\n")
cat("====== BTree | 128 threads | ~269 GB working set | n=5        ======\n\n")
print(results, row.names = FALSE)

# Count significant results
cat("\n\nSignificant (p < 0.05):", sum(results$p_value < 0.05), "of", nrow(results), "\n")
cat("Non-significant (p >= 0.05):", sum(results$p_value >= 0.05), "of", nrow(results), "\n")

# =============================================================================
# PLOTS: One per policy, with 3 facets (Mitosis, WASP, Hydra)
# =============================================================================

for (pol in policies) {
  linux_key <- paste0("linux_", pol)
  max_linux <- max(data[[linux_key]])
  df_list <- list()

  for (sys in systems) {
    sys_key <- paste0(sys, "_", pol)
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

  # Compute y-axis limits with padding
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
      title = paste0("BTree Lookup - ", policy_labels[pol]),
      subtitle = "128 threads | n = 5 | ~269 GB working set | Normalized to max Linux trial | Paired permutation test",
      x = NULL,
      y = "Normalized Runtime (1.0 = max Linux)"
    ) +
    theme_minimal(base_size = 13) +
    theme(legend.position = "none",
          plot.title = element_text(face = "bold"),
          strip.text = element_text(face = "bold", size = 10))

  print(p)
}

dev.off()
cat("Saved all plots to btree.pdf\n")
