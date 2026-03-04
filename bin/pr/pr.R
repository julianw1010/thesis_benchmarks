###############################################################################
###                              pr.R                                       ###
###############################################################################

library(ggplot2)

# =============================================================================
# RAW DATA: Trial Times (seconds) – PageRank Benchmark, 128 threads, n=5
# =============================================================================

data <- list(
  # --- LINUX First-Touch (output_0.txt) ---
  linux_ft_kron27  = c(17.50184, 17.66833, 17.78142, 17.79378, 17.81372),
  linux_ft_kron28  = c(35.50487, 35.60280, 35.48397, 35.61958, 35.54307),
  linux_ft_kron29  = c(76.43649, 80.61138, 79.29263, 80.30327, 79.61393),
  linux_ft_kron30  = c(182.32887, 182.33033, 181.89557, 182.98204, 181.64093),
  linux_ft_uni27   = c(20.76561, 20.96230, 20.87473, 20.85567, 20.76929),
  linux_ft_uni28   = c(41.15463, 40.77092, 40.74322, 40.73089, 40.90825),
  linux_ft_uni29   = c(69.37235, 73.12513, 72.40490, 73.15425, 72.51453),
  linux_ft_uni30   = c(140.25505, 140.18230, 137.85213, 139.09755, 138.44610),
  linux_ft_twitter = c(18.28245, 18.28677, 18.23434, 18.25142, 18.27576),
  linux_ft_web     = c(7.29792, 7.38545, 7.22025, 7.61308, 7.30975),
  linux_ft_road    = c(0.45120, 0.44574, 0.44647, 0.44471, 0.44397),

  # --- LINUX Interleaved (output_i_0.txt) ---
  linux_il_kron27  = c(15.86849, 15.88351, 15.90965, 15.96206, 15.91523),
  linux_il_kron28  = c(32.72621, 32.59287, 32.80884, 32.54387, 32.62864),
  linux_il_kron29  = c(61.24808, 61.52034, 61.27333, 61.90361, 61.35806),
  linux_il_kron30  = c(160.11105, 157.45955, 159.99338, 159.56424, 159.70311),
  linux_il_uni27   = c(19.99148, 19.94665, 20.25365, 19.95251, 19.93031),
  linux_il_uni28   = c(38.13529, 38.70524, 37.79141, 38.43674, 38.15051),
  linux_il_uni29   = c(53.68552, 53.93897, 54.01125, 54.07537, 54.19865),
  linux_il_uni30   = c(137.99416, 137.93692, 138.20821, 138.29149, 138.48080),
  linux_il_twitter = c(13.51514, 13.62466, 13.56617, 13.53053, 13.58229),
  linux_il_web     = c(2.16561, 2.15645, 2.16875, 2.15228, 2.15415),
  linux_il_road    = c(0.18927, 0.19558, 0.18789, 0.20356, 0.20121),

  # --- MITOSIS Replicated (output_r_0.txt) ---
  mitosis_ft_kron27  = c(17.59226, 17.64108, 17.68014, 17.82110, 17.86188),
  mitosis_ft_kron28  = c(35.69292, 35.52301, 35.69498, 35.56008, 35.75105),
  mitosis_ft_kron29  = c(57.05780, 57.20248, 57.20782, 57.35911, 57.54733),
  mitosis_ft_kron30  = c(87.68732, 88.04415, 87.91060, 87.55932, 87.52390),
  mitosis_ft_uni27   = c(20.28489, 20.26501, 20.61310, 20.51257, 20.40414),
  mitosis_ft_uni28   = c(42.58305, 40.16882, 41.11265, 40.21803, 41.05013),
  mitosis_ft_uni29   = c(57.04522, 63.59942, 63.01847, 63.74509, 62.97409),
  mitosis_ft_uni30   = c(69.56345, 69.63231, 69.46294, 69.62235, 69.29499),
  mitosis_ft_twitter = c(18.17493, 18.22023, 18.22918, 18.26631, 18.24213),
  mitosis_ft_web     = c(7.40571, 7.41005, 7.32313, 7.46405, 7.28156),
  mitosis_ft_road    = c(0.52669, 0.48772, 0.50664, 0.48991, 0.51190),

  # --- MITOSIS Replicated+Interleaved (output_ri_0.txt) ---
  mitosis_il_kron27  = c(16.53048, 16.57023, 16.56026, 16.60378, 16.67585),
  mitosis_il_kron28  = c(32.60312, 32.83451, 32.77466, 32.79131, 32.81679),
  mitosis_il_kron29  = c(52.56272, 52.59010, 52.54669, 52.64018, 52.48242),
  mitosis_il_kron30  = c(71.82140, 72.18235, 72.10291, 72.18531, 72.16052),
  mitosis_il_uni27   = c(20.58116, 20.31223, 20.17932, 20.28134, 20.35146),
  mitosis_il_uni28   = c(38.66212, 39.10049, 38.85919, 39.32762, 38.76125),
  mitosis_il_uni29   = c(47.77047, 47.82509, 47.81832, 47.88499, 47.89916),
  mitosis_il_uni30   = c(55.81372, 56.19742, 55.91811, 56.00898, 55.57183),
  mitosis_il_twitter = c(13.90770, 13.96014, 13.91190, 13.84580, 13.99819),
  mitosis_il_web     = c(2.16575, 2.16571, 2.03968, 2.05387, 2.01449),
  mitosis_il_road    = c(0.25885, 0.22711, 0.23657, 0.22970, 0.23005),

  # --- WASP First-Touch (output_0.txt) ---
  wasp_ft_kron27  = c(18.07104, 17.51271, 17.45798, 17.51343, 17.55405),
  wasp_ft_kron28  = c(35.95989, 34.74668, 34.89162, 34.78354, 34.93213),
  wasp_ft_kron29  = c(58.84495, 56.77895, 56.66808, 56.67550, 56.63817),
  wasp_ft_kron30  = c(97.80503, 92.62791, 104.40884, 101.37161, 102.99989),
  wasp_ft_uni27   = c(21.00698, 20.86360, 21.15490, 21.14027, 21.08561),
  wasp_ft_uni28   = c(41.12022, 40.11783, 40.04637, 40.11303, 40.11620),
  wasp_ft_uni29   = c(54.38060, 56.73807, 53.35356, 55.82243, 53.41249),
  wasp_ft_uni30   = c(82.97855, 87.24733, 87.84305, 87.01695, 77.75126),
  wasp_ft_twitter = c(18.74459, 18.24462, 18.30589, 18.23813, 18.25607),
  wasp_ft_web     = c(7.39309, 7.33741, 7.43112, 7.21200, 7.14323),
  wasp_ft_road    = c(0.52508, 0.46694, 0.44750, 0.51653, 0.44643),

  # --- WASP Interleaved (output_i_0.txt) ---
  wasp_il_kron27  = c(17.11104, 16.51384, 16.52535, 16.53173, 16.53408),
  wasp_il_kron28  = c(34.02310, 32.70830, 32.93885, 32.74451, 32.87504),
  wasp_il_kron29  = c(54.82723, 52.47405, 52.25664, 52.32270, 52.51317),
  wasp_il_kron30  = c(91.30996, 92.63530, 92.89418, 93.10458, 97.00286),
  wasp_il_uni27   = c(20.98059, 20.37204, 20.60746, 20.29999, 20.24772),
  wasp_il_uni28   = c(39.92989, 38.49050, 39.19684, 38.68085, 38.42034),
  wasp_il_uni29   = c(51.03295, 48.27616, 48.37604, 48.34596, 48.38431),
  wasp_il_uni30   = c(76.72029, 80.22544, 81.24527, 81.07926, 81.44129),
  wasp_il_twitter = c(14.25676, 13.96102, 13.92576, 13.96441, 13.99402),
  wasp_il_web     = c(2.00819, 1.99577, 1.98594, 1.99019, 1.97674),
  wasp_il_road    = c(0.18624, 0.18146, 0.26418, 0.17683, 0.17851),

  # --- HYDRA Replicated (repl_order_9/output_r_0.txt) ---
  hydra_ft_kron27  = c(17.40595, 17.40778, 17.34520, 17.32321, 17.36813),
  hydra_ft_kron28  = c(35.36108, 35.47974, 35.46905, 35.48515, 35.40583),
  hydra_ft_kron29  = c(56.28332, 58.07749, 58.25659, 58.12105, 58.02199),
  hydra_ft_kron30  = c(87.10500, 88.10317, 87.07468, 86.71468, 86.59526),
  hydra_ft_uni27   = c(20.35148, 20.49847, 20.11594, 20.12309, 20.17253),
  hydra_ft_uni28   = c(38.85135, 40.07364, 39.96242, 40.19975, 40.04917),
  hydra_ft_uni29   = c(49.57378, 52.96908, 52.97758, 52.96512, 52.84983),
  hydra_ft_uni30   = c(69.08961, 69.84396, 69.77432, 69.73851, 69.79545),
  hydra_ft_twitter = c(18.17420, 18.06874, 18.05074, 18.01871, 18.06625),
  hydra_ft_web     = c(7.20374, 7.18335, 7.39324, 7.12412, 7.17310),
  hydra_ft_road    = c(0.44656, 0.44709, 0.46766, 0.44695, 0.44525),

  # --- HYDRA Replicated+Interleaved (repl_order_9/output_ri_0.txt) ---
  hydra_il_kron27  = c(16.36189, 16.45879, 16.45850, 16.36436, 16.45580),
  hydra_il_kron28  = c(32.45968, 31.95391, 32.28849, 32.56121, 32.33601),
  hydra_il_kron29  = c(51.80895, 53.52176, 53.36410, 53.56231, 53.64906),
  hydra_il_kron30  = c(70.60941, 71.60929, 71.77183, 71.62185, 71.42000),
  hydra_il_uni27   = c(19.99896, 20.15998, 20.11829, 20.21614, 20.11619),
  hydra_il_uni28   = c(38.26990, 38.58344, 38.86460, 38.64748, 39.10358),
  hydra_il_uni29   = c(47.82523, 51.08869, 50.82141, 50.89568, 50.95564),
  hydra_il_uni30   = c(54.93353, 56.11282, 56.23019, 55.87103, 56.03795),
  hydra_il_twitter = c(13.64192, 13.67039, 13.78375, 13.78616, 13.72099),
  hydra_il_web     = c(2.17202, 1.99256, 1.96208, 1.94805, 1.94719),
  hydra_il_road    = c(0.18056, 0.17758, 0.17836, 0.18459, 0.18684)
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

pdf("pr.pdf", width = 10, height = 5)

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
cat("\n====== PAIRED PERMUTATION TEST RESULTS (exact, one-sided) ======\n\n")
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
        title = paste0("GAP PageRank (PR) - ",
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
cat("Saved all plots to pr.pdf\n")
