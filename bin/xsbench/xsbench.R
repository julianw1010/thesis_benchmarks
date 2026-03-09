###############################################################################
###                           xsbench.R                                     ###
###############################################################################

library(ggplot2)

# =============================================================================
# RAW DATA: Simulation Runtime (seconds) – XSBench v18, 128 threads, n=5
# Working Set: ~200 GB (Est. Memory Usage: 200,965 MB)
# 25M particle histories, 400K gridpoints/nuclide, 142M unionized grid points
# =============================================================================

data <- list(
  # --- LINUX First-Touch (linux/output_0..4.txt) ---
  linux_ft  = c(561.340, 562.174, 584.192, 576.587, 571.139),

  # --- LINUX Interleaved (linux/output_i_0..4.txt) ---
  linux_il  = c(131.963, 131.581, 132.308, 130.073, 133.531),

  # --- WASP First-Touch (wasp/output_0..4.txt) ---
  wasp_ft   = c(499.690, 462.761, 465.340, 458.543, 492.394),

  # --- WASP Interleaved (wasp/output_i_0..4.txt) ---
  wasp_il   = c(86.673, 86.347, 87.224, 87.983, 88.731),

  # --- MITOSIS Replicated (mitosis/output_r_0..4.txt) ---
  mitosis_ft  = c(473.566, 485.805, 489.841, 475.259, 483.255),

  # --- MITOSIS Replicated+Interleaved (mitosis/output_ri_0..4.txt) ---
  mitosis_il  = c(79.428, 79.331, 79.245, 78.929, 79.492),

  # --- HYDRA Replicated (hydra/repl_order_9/output_r_0..4.txt) ---
  hydra_ft  = c(403.798, 397.409, 408.364, 401.961, 410.385),

  # --- HYDRA Replicated+Interleaved (hydra/repl_order_9/output_ri_0..4.txt) ---
  hydra_il  = c(79.788, 80.560, 80.059, 79.500, 80.298)
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

pdf("xsbench.pdf", width = 10, height = 5)

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
cat("====== XSBench v18 | 128 threads | ~200 GB working set | n=5  ======\n\n")
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
      title = paste0("XSBench v18 - ", policy_labels[pol]),
      subtitle = "128 threads | n = 5 | ~200 GB working set | Normalized to max Linux trial | Paired permutation test",
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
cat("Saved all plots to xsbench.pdf\n")
