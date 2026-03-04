###############################################################################
###                              cc_sv.R                                    ###
###############################################################################

library(ggplot2)

# =============================================================================
# RAW DATA: Trial Times (seconds) – CC_SV (Shiloach-Vishkin) Benchmark
# 128 threads, n=5, repl_order_9 for Hydra
# Source: rawdata.txt
# =============================================================================

data <- list(
  # --- LINUX First-Touch (output_0.txt) ---
  linux_ft_kron27  = c(15.82237, 15.74627, 15.77084, 15.75321, 15.77406),
  linux_ft_kron28  = c(30.76351, 31.00142, 31.50737, 31.57743, 31.76542),
  linux_ft_kron29  = c(59.60355, 60.13915, 59.69884, 60.50329, 59.64982),
  linux_ft_kron30  = c(138.03302, 138.78981, 139.87363, 138.07829, 142.38553),
  linux_ft_uni27   = c(23.90084, 23.95485, 24.21317, 24.36135, 24.60640),
  linux_ft_uni28   = c(50.41987, 49.97601, 50.28857, 50.66371, 50.73966),
  linux_ft_uni29   = c(86.47493, 84.57016, 86.83659, 86.34633, 85.90183),
  linux_ft_uni30   = c(162.49857, 160.31126, 161.38108, 160.26792, 160.18392),
  linux_ft_twitter = c(7.64011, 7.58761, 7.60232, 7.63649, 7.61882),
  linux_ft_web     = c(2.08579, 2.08628, 2.08546, 2.08345, 2.08412),
  linux_ft_road    = c(0.15227, 0.14963, 0.14926, 0.15008, 0.14913),

  # --- LINUX Interleaved (output_i_0.txt) ---
  linux_il_kron27  = c(13.26495, 13.12443, 13.25567, 13.22947, 13.25169),
  linux_il_kron28  = c(29.09330, 29.02147, 28.45833, 29.07986, 29.37919),
  linux_il_kron29  = c(52.01867, 52.85969, 52.26381, 52.19511, 52.08245),
  linux_il_kron30  = c(119.19694, 118.47321, 121.35548, 123.20097, 119.81340),
  linux_il_uni27   = c(17.71041, 17.81047, 17.99010, 17.84845, 17.71825),
  linux_il_uni28   = c(34.54230, 33.97858, 34.33435, 34.23571, 34.41306),
  linux_il_uni29   = c(58.44643, 58.82285, 57.10278, 58.38704, 59.23436),
  linux_il_uni30   = c(130.79212, 131.03184, 132.60268, 131.11023, 135.29647),
  linux_il_twitter = c(6.85175, 6.83856, 6.84620, 6.83247, 6.85741),
  linux_il_web     = c(0.49992, 0.50293, 0.50705, 0.49205, 0.50270),
  linux_il_road    = c(0.06997, 0.06859, 0.07081, 0.06808, 0.07096),

  # --- MITOSIS Replicated (output_r_0.txt) ---
  mitosis_ft_kron27  = c(15.82248, 15.82003, 15.86174, 15.83107, 15.87820),
  mitosis_ft_kron28  = c(31.80908, 32.57123, 32.92361, 33.12206, 33.08460),
  mitosis_ft_kron29  = c(47.54026, 48.34475, 48.18720, 48.32842, 48.93790),
  mitosis_ft_kron30  = c(72.50576, 72.66663, 73.10794, 73.30307, 72.67251),
  mitosis_ft_uni27   = c(23.86082, 24.62011, 24.67830, 24.70131, 24.63313),
  mitosis_ft_uni28   = c(51.39587, 49.32200, 50.88074, 51.00614, 51.09387),
  mitosis_ft_uni29   = c(86.04805, 88.35629, 86.76075, 87.24415, 87.58937),
  mitosis_ft_uni30   = c(135.10018, 134.12412, 134.50373, 134.40096, 135.72945),
  mitosis_ft_twitter = c(7.71510, 7.70536, 7.69963, 7.71883, 7.70263),
  mitosis_ft_web     = c(1.96562, 1.95541, 1.95664, 1.95760, 1.95682),
  mitosis_ft_road    = c(0.18279, 0.17320, 0.17290, 0.17317, 0.17331),

  # --- MITOSIS Replicated+Interleaved (output_ri_0.txt) ---
  mitosis_il_kron27  = c(10.10791, 10.05352, 13.28644, 10.11158, 13.28428),
  mitosis_il_kron28  = c(27.44621, 27.70119, 27.57970, 27.83353, 27.42825),
  mitosis_il_kron29  = c(38.05381, 37.80822, 38.77499, 38.29548, 37.85821),
  mitosis_il_kron30  = c(60.14705, 59.81429, 59.44928, 59.47187, 59.58860),
  mitosis_il_uni27   = c(17.79767, 17.97693, 18.36646, 17.72877, 17.94841),
  mitosis_il_uni28   = c(32.49222, 33.06187, 32.34751, 32.12652, 32.50118),
  mitosis_il_uni29   = c(51.57928, 50.64013, 51.00612, 51.03968, 51.13943),
  mitosis_il_uni30   = c(81.10184, 82.08945, 80.86335, 81.47511, 81.93958),
  mitosis_il_twitter = c(6.87349, 6.85699, 6.86113, 6.83875, 6.86669),
  mitosis_il_web     = c(0.57551, 0.55340, 0.55465, 0.55483, 0.55320),
  mitosis_il_road    = c(0.10484, 0.09781, 0.09801, 0.09890, 0.09903),

  # --- WASP First-Touch (output_0.txt) ---
  wasp_ft_kron27  = c(16.45367, 15.91955, 15.94408, 16.05114, 16.04750),
  wasp_ft_kron28  = c(32.90274, 31.91921, 31.70537, 31.87172, 31.96148),
  wasp_ft_kron29  = c(51.68377, 48.65234, 48.78206, 48.89719, 49.06535),
  wasp_ft_kron30  = c(85.85679, 79.02075, 79.45234, 78.98932, 80.53426),
  wasp_ft_uni27   = c(24.81200, 23.98647, 24.00501, 24.06165, 24.11997),
  wasp_ft_uni28   = c(51.02127, 51.12236, 50.00937, 50.87713, 49.49765),
  wasp_ft_uni29   = c(87.00005, 82.53282, 82.54819, 82.52241, 81.83444),
  wasp_ft_uni30   = c(151.09661, 145.62330, 146.64352, 146.23047, 147.32005),
  wasp_ft_twitter = c(8.08003, 7.72234, 7.67685, 7.68289, 7.66847),
  wasp_ft_web     = c(2.10637, 2.10727, 2.10768, 2.13619, 2.10675),
  wasp_ft_road    = c(0.15262, 0.15075, 0.26044, 0.14945, 0.15115),

  # --- WASP Interleaved (output_i_0.txt) ---
  wasp_il_kron27  = c(14.06947, 13.49581, 13.59390, 10.32304, 13.58549),
  wasp_il_kron28  = c(29.04677, 27.46403, 27.48463, 27.40795, 27.58761),
  wasp_il_kron29  = c(41.17179, 38.10782, 38.13588, 39.00235, 39.07991),
  wasp_il_kron30  = c(78.89364, 73.44086, 75.47918, 72.02325, 73.98376),
  wasp_il_uni27   = c(18.78479, 18.27037, 17.89462, 17.80564, 18.19421),
  wasp_il_uni28   = c(35.49741, 35.49223, 33.44544, 33.59739, 33.62246),
  wasp_il_uni29   = c(53.04753, 50.74918, 50.63806, 52.92509, 51.27224),
  wasp_il_uni30   = c(92.60895, 88.23511, 86.85883, 85.25440, 88.02771),
  wasp_il_twitter = c(7.37861, 6.87614, 6.89340, 6.89079, 6.88052),
  wasp_il_web     = c(0.49555, 0.53508, 0.49266, 0.53555, 0.49524),
  wasp_il_road    = c(0.07105, 0.06795, 0.06962, 0.06784, 0.07189),

  # --- HYDRA Replicated (repl_order_9/output_r_0.txt) ---
  hydra_ft_kron27  = c(15.73937, 15.70004, 15.67866, 15.70116, 15.66784),
  hydra_ft_kron28  = c(30.58956, 30.77481, 30.72643, 31.01992, 30.66413),
  hydra_ft_kron29  = c(47.32597, 47.16604, 47.29171, 47.32823, 47.46555),
  hydra_ft_kron30  = c(73.00444, 72.37389, 72.53390, 72.78187, 72.52093),
  hydra_ft_uni27   = c(23.91479, 23.92985, 23.98321, 23.96095, 23.92689),
  hydra_ft_uni28   = c(51.29873, 49.90361, 51.03126, 50.89476, 50.16885),
  hydra_ft_uni29   = c(85.65175, 83.97699, 82.20406, 82.26766, 82.10985),
  hydra_ft_uni30   = c(140.20121, 136.92401, 141.28304, 138.75370, 140.70807),
  hydra_ft_twitter = c(7.61949, 7.62692, 7.57542, 7.60439, 7.59550),
  hydra_ft_web     = c(1.97470, 1.97044, 1.97413, 1.97176, 1.97237),
  hydra_ft_road    = c(0.15270, 0.15252, 0.15164, 0.15006, 0.15033),

  # --- HYDRA Replicated+Interleaved (repl_order_9/output_ri_0.txt) ---
  hydra_il_kron27  = c(13.29621, 13.43769, 13.20479, 13.31850, 13.29409),
  hydra_il_kron28  = c(27.60120, 27.40706, 27.57485, 27.53205, 27.51925),
  hydra_il_kron29  = c(38.20641, 38.22552, 38.25501, 38.58558, 38.11974),
  hydra_il_kron30  = c(59.41846, 58.90716, 59.39390, 59.48500, 59.60694),
  hydra_il_uni27   = c(17.40348, 17.41853, 17.58632, 17.44507, 17.37098),
  hydra_il_uni28   = c(35.74188, 32.47790, 32.18320, 32.34862, 32.62752),
  hydra_il_uni29   = c(51.15984, 50.66014, 52.38790, 51.73044, 50.54718),
  hydra_il_uni30   = c(80.78966, 83.37300, 83.30703, 81.41621, 88.94883),
  hydra_il_twitter = c(6.77358, 6.76970, 6.76284, 6.75308, 6.74841),
  hydra_il_web     = c(0.52921, 0.50446, 0.50618, 0.50795, 0.50526),
  hydra_il_road    = c(0.07268, 0.06824, 0.07119, 0.07066, 0.07141)
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

pdf("cc_sv.pdf", width = 10, height = 5)

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
cat("CC_SV (Shiloach-Vishkin) Connected Components\n")
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
        title = paste0("GAP Shiloach-Vishkin Connected Components (CC_SV) - ",
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
cat("Saved all plots to cc_sv.pdf\n")
