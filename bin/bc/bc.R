###############################################################################
###                              bc.R                                       ###
###############################################################################

library(ggplot2)

# =============================================================================
# RAW DATA: Trial Times (seconds) – BC (Betweenness Centrality) Benchmark
# 128 threads, n=5, repl_order_9 for Hydra
# Source: rawdata.txt
# =============================================================================

data <- list(
  # --- LINUX First-Touch (output_0.txt) ---
  linux_ft_kron27  = c(5.97398, 6.19747, 7.71791, 6.41826, 6.33879),
  linux_ft_kron28  = c(15.39043, 14.00199, 12.33121, 15.37601, 14.81761),
  linux_ft_kron29  = c(28.69552, 26.96302, 36.16430, 36.77485, 25.47991),
  linux_ft_kron30  = c(75.78223, 57.50289, 61.76406, 58.04299, 73.84547),
  linux_ft_uni27   = c(9.33695, 10.04217, 9.72351, 9.59068, 9.72131),
  linux_ft_uni28   = c(18.60065, 18.64050, 18.96078, 18.45909, 18.02135),
  linux_ft_uni29   = c(38.50926, 38.74015, 37.41126, 40.04094, 38.95602),
  linux_ft_uni30   = c(102.93214, 103.44322, 106.14459, 107.03464, 99.74429),
  linux_ft_twitter = c(2.81514, 3.14794, 3.07555, 3.12386, 2.82047),
  linux_ft_web     = c(1.25705, 1.22842, 1.23353, 1.23629, 1.22941),
  linux_ft_road    = c(1.45858, 1.23309, 1.36677, 1.33303, 1.44894),

  # --- LINUX Interleaved (output_i_0.txt) ---
  linux_il_kron27  = c(5.42857, 5.65634, 6.94807, 5.87732, 5.81836),
  linux_il_kron28  = c(13.65492, 12.64482, 11.08725, 13.67278, 13.28625),
  linux_il_kron29  = c(25.29042, 23.75009, 30.91167, 32.94052, 22.27681),
  linux_il_kron30  = c(65.54067, 51.88531, 54.72624, 52.38488, 64.54406),
  linux_il_uni27   = c(8.27282, 8.94724, 8.61123, 8.55053, 8.65330),
  linux_il_uni28   = c(15.42425, 15.39263, 15.96067, 15.57214, 15.43452),
  linux_il_uni29   = c(32.78244, 32.12601, 31.88654, 34.53057, 33.00740),
  linux_il_uni30   = c(90.73078, 91.55763, 94.21127, 94.54576, 89.99843),
  linux_il_twitter = c(2.48123, 2.69611, 2.65272, 2.73418, 2.34319),
  linux_il_web     = c(0.77987, 0.77082, 0.78550, 0.78488, 0.80396),
  linux_il_road    = c(1.44109, 1.42463, 0.90443, 1.36422, 1.43745),

  # --- MITOSIS Replicated (output_r_0.txt) ---
  mitosis_ft_kron27  = c(6.30702, 6.58363, 8.02416, 6.81061, 6.53632),
  mitosis_ft_kron28  = c(13.22758, 12.95056, 12.86997, 13.31625, 14.05633),
  mitosis_ft_kron29  = c(23.00271, 22.00657, 24.24270, 26.25786, 21.95062),
  mitosis_ft_kron30  = c(43.10726, 37.36598, 38.33031, 36.94006, 42.46407),
  mitosis_ft_uni27   = c(9.00668, 9.73980, 9.44871, 9.30484, 9.35781),
  mitosis_ft_uni28   = c(15.30903, 15.61190, 15.44956, 15.36733, 15.27531),
  mitosis_ft_uni29   = c(26.01827, 25.23133, 24.82572, 26.57673, 25.70218),
  mitosis_ft_uni30   = c(56.77064, 56.37995, 57.23975, 57.12768, 56.09052),
  mitosis_ft_twitter = c(3.05696, 3.32363, 3.32872, 3.42082, 3.12476),
  mitosis_ft_web     = c(1.51795, 1.49641, 1.48601, 1.49388, 1.49952),
  mitosis_ft_road    = c(1.83417, 1.61751, 1.62602, 1.65726, 1.78024),

  # --- MITOSIS Replicated+Interleaved (output_ri_0.txt) ---
  mitosis_il_kron27  = c(5.76329, 6.01598, 7.41737, 6.31548, 6.11498),
  mitosis_il_kron28  = c(12.45800, 11.92220, 11.32032, 12.28701, 12.73956),
  mitosis_il_kron29  = c(20.81120, 19.91400, 22.86557, 24.05624, 19.42116),
  mitosis_il_kron30  = c(41.77075, 35.47286, 37.28573, 35.26547, 41.50046),
  mitosis_il_uni27   = c(8.43156, 9.02244, 8.85049, 8.84367, 8.84622),
  mitosis_il_uni28   = c(14.56260, 14.79135, 14.84699, 14.64140, 14.56968),
  mitosis_il_uni29   = c(25.53688, 24.88835, 24.96902, 26.52521, 25.70485),
  mitosis_il_uni30   = c(58.10526, 57.72748, 58.11207, 58.22551, 57.14827),
  mitosis_il_twitter = c(2.87921, 3.04631, 2.86889, 3.13701, 2.81052),
  mitosis_il_web     = c(1.21160, 1.19789, 1.20606, 1.20081, 1.20694),
  mitosis_il_road    = c(2.48950, 2.42705, 2.28646, 2.31718, 2.42447),

  # --- WASP First-Touch (output_0.txt) ---
  wasp_ft_kron27  = c(6.84122, 6.61148, 7.95626, 6.71976, 6.48107),
  wasp_ft_kron28  = c(14.53364, 12.88642, 12.73356, 13.14261, 13.76762),
  wasp_ft_kron29  = c(25.26019, 25.94429, 29.79842, 32.91304, 25.39128),
  wasp_ft_kron30  = c(55.44244, 46.75821, 49.45851, 44.76015, 54.40444),
  wasp_ft_uni27   = c(9.48976, 9.52264, 9.26390, 9.18456, 9.29308),
  wasp_ft_uni28   = c(17.20591, 16.49255, 16.20861, 16.26265, 16.18860),
  wasp_ft_uni29   = c(28.91074, 30.39823, 30.61857, 33.38870, 31.64461),
  wasp_ft_uni30   = c(75.34704, 73.86203, 75.53602, 77.31266, 75.21711),
  wasp_ft_twitter = c(3.52843, 3.59088, 3.55771, 3.57796, 3.22749),
  wasp_ft_web     = c(1.31015, 1.32491, 1.31871, 1.28723, 1.28518),
  wasp_ft_road    = c(1.14376, 1.50902, 1.63719, 1.89096, 1.66241),

  # --- WASP Interleaved (output_i_0.txt) ---
  wasp_il_kron27  = c(6.36565, 6.26727, 7.42948, 6.23724, 6.08471),
  wasp_il_kron28  = c(13.56862, 14.82177, 14.59285, 15.36450, 15.81045),
  wasp_il_kron29  = c(27.43572, 22.38110, 27.64775, 28.88214, 23.98360),
  wasp_il_kron30  = c(56.29775, 49.68720, 50.51668, 48.65640, 56.59834),
  wasp_il_uni27   = c(9.20334, 9.16624, 8.90715, 8.75603, 9.08060),
  wasp_il_uni28   = c(16.18400, 18.51958, 18.87678, 18.33175, 18.47883),
  wasp_il_uni29   = c(31.08879, 31.30716, 29.65798, 32.73301, 32.78561),
  wasp_il_uni30   = c(75.23489, 74.82605, 75.77245, 76.93656, 73.42864),
  wasp_il_twitter = c(3.06191, 3.10202, 3.00832, 3.17469, 2.71517),
  wasp_il_web     = c(0.77966, 0.81330, 0.92544, 0.79262, 0.80159),
  wasp_il_road    = c(2.31353, 1.60145, 1.92211, 2.75771, 1.78659),

  # --- HYDRA Replicated (repl_order_9/output_r_0.txt) ---
  hydra_ft_kron27  = c(5.87231, 6.09889, 7.54342, 6.33698, 6.09020),
  hydra_ft_kron28  = c(12.13902, 11.59670, 11.16713, 12.03359, 12.62774),
  hydra_ft_kron29  = c(20.28675, 19.37202, 21.92449, 23.43511, 18.84367),
  hydra_ft_kron30  = c(39.51911, 34.36084, 35.58128, 34.15626, 39.04138),
  hydra_ft_uni27   = c(8.61968, 9.10363, 8.91461, 8.70585, 8.88335),
  hydra_ft_uni28   = c(14.00527, 14.16608, 14.11542, 14.00164, 14.01387),
  hydra_ft_uni29   = c(24.38293, 23.50275, 23.17408, 24.78045, 23.97238),
  hydra_ft_uni30   = c(54.31332, 53.22320, 54.31038, 54.21996, 53.28230),
  hydra_ft_twitter = c(2.86705, 3.13574, 3.09034, 3.28130, 2.81021),
  hydra_ft_web     = c(1.39341, 1.37109, 1.36103, 1.36768, 1.37823),
  hydra_ft_road    = c(3.22315, 3.10306, 3.15017, 2.60236, 3.16643),

  # --- HYDRA Replicated+Interleaved (repl_order_9/output_ri_0.txt) ---
  hydra_il_kron27  = c(5.32994, 5.63893, 6.91421, 5.85450, 5.70777),
  hydra_il_kron28  = c(11.49860, 11.13379, 10.55073, 11.48186, 12.03346),
  hydra_il_kron29  = c(19.35749, 18.26225, 21.38597, 22.45881, 18.13079),
  hydra_il_kron30  = c(38.53673, 32.54719, 34.47276, 32.29009, 38.38823),
  hydra_il_uni27   = c(8.04595, 8.58944, 8.39899, 8.37371, 8.45913),
  hydra_il_uni28   = c(13.83212, 13.77870, 14.15652, 13.99813, 13.90814),
  hydra_il_uni29   = c(24.44995, 23.80429, 23.67477, 25.21147, 24.38472),
  hydra_il_uni30   = c(54.68760, 54.33177, 55.22005, 55.57761, 54.59884),
  hydra_il_twitter = c(2.55011, 2.70554, 2.66283, 2.82129, 2.37357),
  hydra_il_web     = c(0.99271, 0.97582, 0.96847, 0.98728, 0.99080),
  hydra_il_road    = c(3.53091, 3.52996, 3.05566, 3.45653, 3.42196)
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

pdf("bc.pdf", width = 10, height = 5)

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
cat("BC (Betweenness Centrality)\n")
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
        title = paste0("GAP Betweenness Centrality (BC) - ",
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
cat("Saved all plots to bc.pdf\n")
