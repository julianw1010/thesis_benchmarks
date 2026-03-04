###############################################################################
###                              pr_spmv.R                                  ###
###############################################################################

library(ggplot2)

# =============================================================================
# RAW DATA: Trial Times (seconds) – PageRank Sparse Matrix-Vector Multiplication
# Benchmark, 128 threads, n=5, repl_order_9 for hydra
# Source: rawdata.txt
# =============================================================================

data <- list(
  # --- LINUX First-Touch (output_0.txt) ---
  linux_ft_kron27  = c(24.40905, 24.45211, 24.49389, 24.51141, 24.47348),
  linux_ft_kron28  = c(49.59469, 50.66923, 50.58726, 51.11835, 50.85292),
  linux_ft_kron29  = c(107.94006, 112.32421, 112.14550, 112.18870, 113.72085),
  linux_ft_kron30  = c(247.29671, 247.65984, 247.56797, 248.94957, 246.12277),
  linux_ft_uni27   = c(29.70460, 29.85451, 29.75848, 29.84755, 29.81181),
  linux_ft_uni28   = c(61.12317, 62.53612, 65.70226, 66.68128, 66.48124),
  linux_ft_uni29   = c(95.65103, 99.13185, 100.14952, 100.38359, 100.73326),
  linux_ft_uni30   = c(217.81924, 212.33977, 219.10686, 217.57142, 220.39131),
  linux_ft_twitter = c(17.73960, 17.77104, 17.86128, 17.76698, 17.87729),
  linux_ft_web     = c(7.91589, 7.56842, 7.67178, 7.63543, 7.51173),
  linux_ft_road    = c(0.40395, 0.40288, 0.39943, 0.39863, 0.39644),

  # --- LINUX Interleaved (output_i_0.txt) ---
  linux_il_kron27  = c(23.00560, 23.05655, 22.88260, 23.01640, 22.98572),
  linux_il_kron28  = c(45.83565, 45.88817, 46.08192, 46.18237, 46.32601),
  linux_il_kron29  = c(96.40878, 96.75201, 96.71965, 96.79237, 99.28503),
  linux_il_kron30  = c(232.53018, 233.89442, 238.58192, 233.79309, 237.72306),
  linux_il_uni27   = c(30.25579, 30.16539, 30.52063, 30.15922, 30.26446),
  linux_il_uni28   = c(57.08633, 56.49607, 57.33037, 57.16682, 57.28270),
  linux_il_uni29   = c(84.99326, 84.01448, 84.75155, 84.77136, 83.96337),
  linux_il_uni30   = c(181.95546, 187.50632, 187.65769, 185.27693, 179.63452),
  linux_il_twitter = c(13.80895, 13.79509, 13.81345, 13.78792, 13.74024),
  linux_il_web     = c(2.09172, 2.09662, 2.08133, 2.05187, 2.07532),
  linux_il_road    = c(0.25762, 0.25487, 0.24539, 0.24984, 0.24715),

  # --- MITOSIS Replicated (output_r_0.txt) ---
  mitosis_ft_kron27  = c(24.73945, 24.74124, 24.80751, 24.76587, 24.73658),
  mitosis_ft_kron28  = c(49.66122, 49.08310, 49.89265, 49.96023, 50.11387),
  mitosis_ft_kron29  = c(79.55886, 80.04777, 80.14224, 80.24017, 79.99027),
  mitosis_ft_kron30  = c(121.86807, 122.16012, 121.64956, 122.13306, 122.19745),
  mitosis_ft_uni27   = c(31.25259, 31.16102, 31.92864, 33.26899, 34.17872),
  mitosis_ft_uni28   = c(63.35973, 73.10772, 70.15739, 70.95691, 70.28892),
  mitosis_ft_uni29   = c(95.17719, 99.79761, 99.21635, 99.42382, 99.64301),
  mitosis_ft_uni30   = c(102.95441, 102.98648, 102.99059, 103.06588, 103.02919),
  mitosis_ft_twitter = c(17.86841, 17.77910, 17.79293, 17.89152, 17.76631),
  mitosis_ft_web     = c(7.64845, 7.74462, 7.71294, 7.62777, 7.72259),
  mitosis_ft_road    = c(0.46752, 0.44930, 0.45253, 0.44848, 0.44919),

  # --- MITOSIS Replicated+Interleaved (output_ri_0.txt) ---
  mitosis_il_kron27  = c(23.13102, 23.08065, 23.16126, 23.17801, 23.17456),
  mitosis_il_kron28  = c(45.80965, 45.89591, 45.96707, 45.94678, 45.76572),
  mitosis_il_kron29  = c(73.18571, 72.96678, 73.24265, 73.32692, 73.32051),
  mitosis_il_kron30  = c(99.99702, 99.54938, 100.02769, 99.78223, 99.72663),
  mitosis_il_uni27   = c(30.71890, 30.63771, 30.76594, 30.75624, 30.77110),
  mitosis_il_uni28   = c(58.51101, 57.89106, 58.30825, 58.57128, 58.30013),
  mitosis_il_uni29   = c(71.24849, 71.21652, 71.20664, 71.33057, 71.35308),
  mitosis_il_uni30   = c(83.08423, 82.86147, 82.48690, 82.83984, 82.53480),
  mitosis_il_twitter = c(13.73964, 13.87631, 13.82604, 13.82858, 13.90650),
  mitosis_il_web     = c(2.37607, 2.13834, 2.18354, 2.13892, 2.13870),
  mitosis_il_road    = c(0.31119, 0.29083, 0.29457, 0.29669, 0.29541),

  # --- WASP First-Touch (output_0.txt) ---
  wasp_ft_kron27  = c(25.14331, 24.53052, 24.54744, 24.53376, 24.55160),
  wasp_ft_kron28  = c(49.87453, 50.51914, 50.41288, 50.44401, 50.38268),
  wasp_ft_kron29  = c(81.87596, 81.99493, 82.56569, 82.50999, 81.91379),
  wasp_ft_kron30  = c(137.05292, 144.34725, 139.94909, 142.24951, 131.13559),
  wasp_ft_uni27   = c(30.57382, 30.12347, 30.12817, 30.19260, 30.09174),
  wasp_ft_uni28   = c(63.96576, 60.75423, 60.35381, 60.23367, 60.23799),
  wasp_ft_uni29   = c(85.10223, 84.60119, 86.62890, 86.69898, 87.01801),
  wasp_ft_uni30   = c(122.07551, 126.50892, 125.09240, 126.60082, 116.17814),
  wasp_ft_twitter = c(18.27336, 17.92756, 17.85946, 17.92059, 17.92595),
  wasp_ft_web     = c(7.91529, 7.82568, 7.98028, 7.82324, 7.94502),
  wasp_ft_road    = c(0.52330, 0.39651, 0.39212, 0.50531, 0.39659),

  # --- WASP Interleaved (output_i_0.txt) ---
  wasp_il_kron27  = c(23.53276, 23.16488, 23.05498, 23.16224, 23.18191),
  wasp_il_kron28  = c(47.24095, 45.92613, 45.93154, 45.71130, 45.72416),
  wasp_il_kron29  = c(75.24239, 73.04822, 72.91191, 72.91394, 73.09776),
  wasp_il_kron30  = c(123.57370, 126.80633, 128.35268, 127.58862, 130.19137),
  wasp_il_uni27   = c(30.97595, 30.67438, 30.55555, 30.70004, 30.55890),
  wasp_il_uni28   = c(58.58901, 57.87223, 57.60271, 58.20802, 57.86386),
  wasp_il_uni29   = c(74.47610, 71.90540, 72.17992, 72.22545, 72.17489),
  wasp_il_uni30   = c(112.06580, 116.69017, 116.00645, 116.27844, 117.02809),
  wasp_il_twitter = c(14.42489, 13.94331, 14.01172, 14.00597, 14.07864),
  wasp_il_web     = c(2.14472, 2.07968, 2.12181, 2.12485, 2.15038),
  wasp_il_road    = c(0.24003, 0.36363, 0.24303, 0.25132, 0.24860),

  # --- HYDRA Replicated (repl_order_9/output_r_0.txt) ---
  hydra_ft_kron27  = c(24.28470, 24.28336, 24.30008, 24.34368, 24.37484),
  hydra_ft_kron28  = c(49.46486, 51.91998, 51.51328, 51.64875, 51.43571),
  hydra_ft_kron29  = c(79.18941, 81.29496, 80.85403, 81.36300, 81.37749),
  hydra_ft_kron30  = c(120.09237, 121.56792, 120.91231, 121.10148, 121.11745),
  hydra_ft_uni27   = c(30.27191, 30.85972, 31.27462, 31.24780, 31.07926),
  hydra_ft_uni28   = c(58.76440, 60.31478, 60.27234, 60.23376, 60.26130),
  hydra_ft_uni29   = c(75.74527, 81.64872, 81.64265, 81.63269, 81.55123),
  hydra_ft_uni30   = c(102.18241, 103.50483, 103.31401, 103.35772, 103.31077),
  hydra_ft_twitter = c(17.64722, 17.65583, 17.66577, 17.61228, 17.69125),
  hydra_ft_web     = c(7.68574, 7.79773, 7.50807, 7.53679, 7.58558),
  hydra_ft_road    = c(0.40606, 0.39967, 0.40678, 0.41031, 0.40052),

  # --- HYDRA Replicated+Interleaved (repl_order_9/output_ri_0.txt) ---
  hydra_il_kron27  = c(22.98592, 22.83784, 22.90866, 22.94798, 22.97525),
  hydra_il_kron28  = c(45.73251, 44.56667, 44.92874, 45.50392, 45.42529),
  hydra_il_kron29  = c(72.64505, 75.24815, 75.02141, 75.71345, 75.16624),
  hydra_il_kron30  = c(99.10227, 100.84919, 100.56260, 100.17314, 100.34992),
  hydra_il_uni27   = c(30.25500, 30.52555, 30.56523, 30.49754, 30.46493),
  hydra_il_uni28   = c(57.91420, 57.91762, 58.31303, 57.99278, 58.25342),
  hydra_il_uni29   = c(71.56068, 76.39425, 76.02311, 76.01775, 76.35835),
  hydra_il_uni30   = c(81.55573, 83.79708, 83.02195, 83.49200, 83.40431),
  hydra_il_twitter = c(13.44125, 13.70835, 13.63505, 13.64827, 13.66717),
  hydra_il_web     = c(2.29110, 2.09863, 2.05216, 2.06415, 2.06817),
  hydra_il_road    = c(0.23232, 0.24323, 0.24361, 0.24895, 0.24531)
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

pdf("pr_spmv.pdf", width = 10, height = 5)

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
cat("PageRank Sparse Matrix-Vector Multiplication\n")
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
        title = paste0("GAP PageRank SpMV (PR_SPMV) - ",
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
cat("Saved all plots to pr_spmv.pdf\n")
