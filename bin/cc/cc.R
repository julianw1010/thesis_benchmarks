###############################################################################
###                              cc.R                                       ###
###############################################################################

library(ggplot2)

# =============================================================================
# RAW DATA: Trial Times (seconds) – Connected Components (bench_cc_mt)
# 128 threads, n=5, repl_order_9 for Hydra
# Source: rawdata.txt
# =============================================================================

data <- list(
  # --- LINUX First-Touch (output_0.txt) ---
  linux_ft_kron27  = c(0.65344, 0.67036, 0.65830, 0.66483, 0.66963),
  linux_ft_kron28  = c(1.31737, 1.30014, 1.29013, 1.30306, 1.33092),
  linux_ft_kron29  = c(2.71880, 2.72892, 2.74484, 2.69228, 2.71441),
  linux_ft_kron30  = c(5.56958, 5.44284, 5.55520, 5.45603, 5.57672),
  linux_ft_uni27   = c(2.91474, 3.53563, 3.44081, 3.41229, 3.48710),
  linux_ft_uni28   = c(8.20476, 8.48896, 8.36320, 8.41363, 8.19125),
  linux_ft_uni29   = c(21.60264, 21.85805, 21.16792, 21.19485, 21.27137),
  linux_ft_uni30   = c(52.61764, 51.77408, 51.33788, 51.28715, 51.15687),
  linux_ft_twitter = c(0.34301, 0.34072, 0.33807, 0.34075, 0.33926),
  linux_ft_web     = c(0.38057, 0.39122, 0.37943, 0.37656, 0.39007),
  linux_ft_road    = c(0.07428, 0.06963, 0.07240, 0.06997, 0.07143),

  # --- LINUX Interleaved (output_i_0.txt) ---
  linux_il_kron27  = c(0.26996, 0.26913, 0.27255, 0.25297, 0.27005),
  linux_il_kron28  = c(0.51428, 0.51029, 0.50789, 0.51501, 0.50974),
  linux_il_kron29  = c(1.06747, 1.07209, 1.09199, 1.06703, 1.06233),
  linux_il_kron30  = c(2.30592, 2.34706, 2.27783, 2.27191, 2.30826),
  linux_il_uni27   = c(0.85657, 0.84866, 0.83773, 0.84148, 0.84964),
  linux_il_uni28   = c(2.12258, 2.13713, 2.12200, 2.14575, 2.12886),
  linux_il_uni29   = c(5.22135, 5.28535, 5.22777, 5.22462, 5.24643),
  linux_il_uni30   = c(12.45592, 12.46883, 12.40855, 12.40998, 12.41384),
  linux_il_twitter = c(0.13010, 0.12481, 0.12706, 0.12536, 0.12658),
  linux_il_web     = c(0.09380, 0.09482, 0.09400, 0.09282, 0.09354),
  linux_il_road    = c(0.03715, 0.03095, 0.03070, 0.03280, 0.02976),

  # --- MITOSIS Replicated (output_r_0.txt) ---
  mitosis_ft_kron27  = c(0.71522, 0.74848, 0.75109, 0.72917, 0.75300),
  mitosis_ft_kron28  = c(1.45320, 1.47040, 1.49209, 1.46282, 1.51209),
  mitosis_ft_kron29  = c(3.05517, 2.99345, 3.01444, 3.03898, 3.01080),
  mitosis_ft_kron30  = c(5.98744, 6.13239, 6.06506, 6.04102, 6.10619),
  mitosis_ft_uni27   = c(3.21338, 3.36912, 3.32722, 3.32642, 3.43297),
  mitosis_ft_uni28   = c(8.69971, 9.02610, 8.80542, 8.73364, 8.69427),
  mitosis_ft_uni29   = c(22.80782, 23.05819, 23.15438, 23.23957, 23.58924),
  mitosis_ft_uni30   = c(57.38102, 60.02908, 59.59669, 59.66739, 59.20830),
  mitosis_ft_twitter = c(0.37160, 0.36333, 0.36573, 0.36409, 0.36616),
  mitosis_ft_web     = c(0.40997, 0.40300, 0.41493, 0.41576, 0.40667),
  mitosis_ft_road    = c(0.09781, 0.08977, 0.09076, 0.09335, 0.09161),

  # --- MITOSIS Replicated+Interleaved (output_ri_0.txt) ---
  mitosis_il_kron27  = c(0.36544, 0.38217, 0.37187, 0.36896, 0.38021),
  mitosis_il_kron28  = c(0.71412, 0.69947, 0.69179, 0.70930, 0.67960),
  mitosis_il_kron29  = c(1.21729, 1.22195, 1.21950, 1.22098, 1.21101),
  mitosis_il_kron30  = c(2.64233, 2.66103, 2.58591, 2.60024, 2.57108),
  mitosis_il_uni27   = c(0.94142, 0.96438, 0.95266, 0.93686, 0.95181),
  mitosis_il_uni28   = c(2.32194, 2.27849, 2.30733, 2.25720, 2.29267),
  mitosis_il_uni29   = c(5.48766, 5.33445, 5.36208, 5.42251, 5.35038),
  mitosis_il_uni30   = c(12.61277, 12.67338, 12.61206, 12.57715, 12.67491),
  mitosis_il_twitter = c(0.18189, 0.16002, 0.16104, 0.16139, 0.16126),
  mitosis_il_web     = c(0.14175, 0.14493, 0.14800, 0.14633, 0.14280),
  mitosis_il_road    = c(0.06627, 0.05008, 0.06780, 0.05070, 0.06856),

  # --- WASP First-Touch (output_0.txt) ---
  wasp_ft_kron27  = c(0.65552, 0.67713, 0.64675, 1.30905, 0.73801),
  wasp_ft_kron28  = c(1.30713, 2.62054, 1.49314, 1.52684, 1.50894),
  wasp_ft_kron29  = c(2.62188, 5.42154, 2.95203, 2.97920, 2.94148),
  wasp_ft_kron30  = c(10.64879, 5.94905, 5.95739, 12.94164, 12.61108),
  wasp_ft_uni27   = c(3.84874, 3.42273, 3.24975, 3.38987, 3.33825),
  wasp_ft_uni28   = c(9.91075, 8.90999, 8.76334, 8.88093, 8.78020),
  wasp_ft_uni29   = c(25.95394, 23.30147, 22.53701, 23.10840, 23.52064),
  wasp_ft_uni30   = c(60.43355, 56.15627, 56.25901, 57.17734, 56.34955),
  wasp_ft_twitter = c(0.38475, 0.36574, 0.34021, 0.33906, 0.38090),
  wasp_ft_web     = c(0.39112, 0.38833, 0.40532, 0.38614, 0.37374),
  wasp_ft_road    = c(0.07114, 0.06974, 0.06864, 0.06968, 0.06868),

  # --- WASP Interleaved (output_i_0.txt) ---
  wasp_il_kron27  = c(0.30007, 0.26541, 0.26670, 0.31278, 0.92112),
  wasp_il_kron28  = c(0.51847, 0.54319, 0.51291, 1.83248, 0.72472),
  wasp_il_kron29  = c(1.04509, 3.65201, 1.24181, 1.23871, 1.41531),
  wasp_il_kron30  = c(7.50636, 4.06875, 7.52530, 2.61641, 10.21237),
  wasp_il_uni27   = c(0.86923, 0.86081, 1.49655, 0.96218, 0.96221),
  wasp_il_uni28   = c(3.42348, 2.25014, 2.27317, 2.23328, 2.25211),
  wasp_il_uni29   = c(7.79381, 5.36546, 5.36112, 5.37847, 5.41807),
  wasp_il_uni30   = c(17.43031, 12.86958, 12.78217, 12.73413, 12.80344),
  wasp_il_twitter = c(0.12896, 0.12630, 0.12811, 0.12722, 0.12592),
  wasp_il_web     = c(0.09301, 0.09426, 0.09338, 0.09432, 0.09264),
  wasp_il_road    = c(0.03479, 0.03004, 0.02906, 0.03254, 0.02937),

  # --- HYDRA Replicated (repl_order_9/output_r_0.txt) ---
  hydra_ft_kron27  = c(0.64873, 0.65560, 0.65571, 0.64538, 0.65171),
  hydra_ft_kron28  = c(1.35312, 1.36395, 1.34076, 1.33001, 1.31507),
  hydra_ft_kron29  = c(2.78758, 2.74739, 2.73131, 2.69848, 2.73103),
  hydra_ft_kron30  = c(5.56464, 5.55427, 5.53651, 5.61112, 5.47493),
  hydra_ft_uni27   = c(3.19415, 3.53321, 3.68661, 3.76178, 3.66486),
  hydra_ft_uni28   = c(9.27716, 9.19802, 8.92699, 8.60718, 8.23657),
  hydra_ft_uni29   = c(23.21893, 23.25123, 23.33190, 23.57098, 23.13746),
  hydra_ft_uni30   = c(59.40881, 58.60953, 60.31778, 57.94528, 60.64329),
  hydra_ft_twitter = c(0.34088, 0.33539, 0.33418, 0.33616, 0.33512),
  hydra_ft_web     = c(0.37359, 0.38232, 0.38018, 0.36768, 0.37524),
  hydra_ft_road    = c(0.06920, 0.06859, 0.06811, 0.06828, 0.06905),

  # --- HYDRA Replicated+Interleaved (repl_order_9/output_ri_0.txt) ---
  hydra_il_kron27  = c(0.26023, 0.26428, 0.26014, 0.26806, 0.27137),
  hydra_il_kron28  = c(0.52620, 0.51147, 0.52038, 0.51414, 0.52004),
  hydra_il_kron29  = c(1.03372, 1.00748, 1.04085, 1.00365, 1.01792),
  hydra_il_kron30  = c(2.11062, 2.23806, 2.08331, 2.09526, 2.12196),
  hydra_il_uni27   = c(0.84347, 0.86374, 0.84380, 0.84264, 0.84035),
  hydra_il_uni28   = c(2.14791, 2.15539, 2.13945, 2.11507, 2.12117),
  hydra_il_uni29   = c(5.14230, 5.12691, 5.12436, 5.15831, 5.14275),
  hydra_il_uni30   = c(12.23165, 12.20048, 12.29435, 12.18596, 12.23598),
  hydra_il_twitter = c(0.13290, 0.12867, 0.12805, 0.12720, 0.12758),
  hydra_il_web     = c(0.09896, 0.09894, 0.09889, 0.09534, 0.09801),
  hydra_il_road    = c(0.03511, 0.02955, 0.03010, 0.03271, 0.02985)
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

pdf("cc_mt.pdf", width = 10, height = 5)

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
cat("Connected Components (bench_cc_mt)\n")
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
        title = paste0("GAP Connected Components (CC) - ",
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
cat("Saved all plots to cc_mt.pdf\n")
