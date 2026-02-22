###############################################################################
###                              pr.R                                       ###
###############################################################################

library(ggplot2)

# =============================================================================
# RAW DATA: Trial Times (seconds) – PageRank Benchmark, 128 threads, n=5
# =============================================================================

data <- list(
  # --- LINUX (First-Touch) ---
  linux_ft_kron27  = c(5.81940, 5.80369, 5.85122, 5.83647, 5.81667),
  linux_ft_kron28  = c(10.02791, 10.05239, 10.03720, 10.05618, 10.05463),
  linux_ft_kron29  = c(22.49483, 22.69184, 22.56925, 22.51509, 22.50064),
  linux_ft_kron30  = c(56.41439, 56.54028, 56.56200, 56.65709, 56.54722),
  linux_ft_uni27   = c(5.94102, 6.00006, 5.94203, 5.97740, 5.93471),
  linux_ft_uni28   = c(8.94579, 8.95631, 8.95536, 8.94460, 8.94416),
  linux_ft_uni29   = c(18.78821, 18.80024, 18.77792, 18.79414, 18.77132),
  linux_ft_uni30   = c(50.20408, 50.14499, 50.13726, 50.14120, 50.13426),
  linux_ft_twitter = c(9.74113, 9.68228, 9.72513, 9.70831, 9.76318),
  linux_ft_web     = c(2.50682, 2.47198, 2.43666, 2.51944, 2.54909),
  linux_ft_road    = c(0.22212, 0.21732, 0.22207, 0.21586, 0.23084),
  
  # --- LINUX (Interleaved) ---
  linux_il_kron27  = c(4.61049, 4.60908, 4.61041, 4.62647, 4.61994),
  linux_il_kron28  = c(9.26118, 9.12502, 9.12672, 9.15445, 9.12854),
  linux_il_kron29  = c(21.05044, 21.03381, 21.04851, 21.06628, 21.07370),
  linux_il_kron30  = c(56.06263, 56.06463, 56.43218, 56.07901, 56.04406),
  linux_il_uni27   = c(4.78200, 4.77849, 4.77924, 4.78355, 4.77928),
  linux_il_uni28   = c(8.40958, 8.40788, 8.40951, 8.41205, 8.41256),
  linux_il_uni29   = c(18.87302, 18.84751, 18.87742, 18.88076, 18.82595),
  linux_il_uni30   = c(48.02948, 47.97263, 47.95190, 47.92377, 48.00480),
  linux_il_twitter = c(6.97496, 6.96769, 6.99059, 6.98964, 6.98328),
  linux_il_web     = c(1.78840, 1.77738, 1.76997, 1.76784, 1.77008),
  linux_il_road    = c(0.17869, 0.16390, 0.16077, 0.15351, 0.15819),
  
  # --- MITOSIS (Repl+FT) ---
  mitosis_ft_kron27  = c(5.88884, 5.87035, 5.87077, 5.86901, 5.90300),
  mitosis_ft_kron28  = c(9.78134, 9.81800, 9.78443, 9.74966, 9.74965),
  mitosis_ft_kron29  = c(20.39994, 20.39051, 20.36856, 20.37781, 20.38875),
  mitosis_ft_kron30  = c(42.83477, 42.85464, 42.83340, 42.84029, 42.86263),
  mitosis_ft_uni27   = c(6.08937, 6.12922, 6.12192, 6.10186, 6.11029),
  mitosis_ft_uni28   = c(8.74914, 8.75847, 8.75498, 8.75770, 8.74740),
  mitosis_ft_uni29   = c(17.98045, 17.98915, 17.98947, 18.00180, 17.99220),
  mitosis_ft_uni30   = c(36.89089, 36.88765, 36.88806, 36.88647, 36.88443),
  mitosis_ft_twitter = c(9.73624, 9.68201, 9.67055, 9.71635, 9.73604),
  mitosis_ft_web     = c(2.45810, 2.48249, 2.36674, 2.48940, 2.53574),
  mitosis_ft_road    = c(0.24383, 0.22379, 0.22248, 0.22292, 0.22154),
  
  # --- MITOSIS (Repl+Interleaved) ---
  mitosis_il_kron27  = c(4.68587, 4.63619, 4.63142, 4.64394, 4.65050),
  mitosis_il_kron28  = c(8.98572, 8.99027, 8.98283, 9.01316, 8.99605),
  mitosis_il_kron29  = c(19.83383, 19.84658, 19.81893, 19.82533, 19.83105),
  mitosis_il_kron30  = c(41.94053, 42.02887, 41.99813, 42.05659, 42.01537),
  mitosis_il_uni27   = c(4.82944, 4.83425, 4.83098, 4.83024, 4.84139),
  mitosis_il_uni28   = c(8.23923, 8.23490, 8.23538, 8.24141, 8.23531),
  mitosis_il_uni29   = c(17.58155, 17.58906, 17.58849, 17.58724, 17.58639),
  mitosis_il_uni30   = c(36.58095, 36.56740, 36.57683, 36.57209, 36.58108),
  mitosis_il_twitter = c(6.99806, 7.00550, 6.99529, 6.99307, 7.01459),
  mitosis_il_web     = c(1.76406, 1.74975, 1.76108, 1.74662, 1.75538),
  mitosis_il_road    = c(0.16232, 0.16682, 0.17789, 0.15877, 0.16005),
  
  # --- WASP (First-Touch) ---
  wasp_ft_kron27  = c(5.99698, 5.86328, 5.85430, 5.87151, 5.88518),
  wasp_ft_kron28  = c(9.75513, 9.81955, 9.77893, 9.82185, 9.77883),
  wasp_ft_kron29  = c(20.40303, 20.28352, 20.26422, 20.28780, 20.27356),
  wasp_ft_kron30  = c(43.36698, 42.69459, 42.73170, 42.59989, 42.59830),
  wasp_ft_uni27   = c(6.01295, 6.01908, 6.01458, 5.98716, 5.99503),
  wasp_ft_uni28   = c(8.88172, 8.75208, 8.75022, 8.74736, 8.75566),
  wasp_ft_uni29   = c(18.03726, 17.89813, 17.88199, 17.90144, 17.89019),
  wasp_ft_uni30   = c(37.54246, 36.91591, 36.77312, 36.87888, 36.78278),
  wasp_ft_twitter = c(9.61260, 9.69863, 9.64813, 9.57625, 9.62993),
  wasp_ft_web     = c(2.51516, 2.43064, 2.64366, 2.57100, 2.49326),
  wasp_ft_road    = c(0.21329, 0.21727, 0.23427, 0.22420, 0.22115),
  
  # --- WASP (Interleaved) ---
  wasp_il_kron27  = c(4.64805, 4.64934, 4.65861, 4.63676, 4.63649),
  wasp_il_kron28  = c(9.06294, 8.99706, 8.99700, 9.00138, 9.11130),
  wasp_il_kron29  = c(20.00846, 19.76834, 19.77036, 19.74547, 19.76483),
  wasp_il_kron30  = c(42.95297, 42.14454, 42.18938, 42.13620, 42.13537),
  wasp_il_uni27   = c(4.87782, 4.83166, 4.82453, 4.82636, 4.82150),
  wasp_il_uni28   = c(8.32578, 8.23423, 8.24230, 8.23539, 8.23662),
  wasp_il_uni29   = c(17.77808, 17.54155, 17.55528, 17.53518, 17.54944),
  wasp_il_uni30   = c(37.58754, 36.65457, 36.64124, 36.64961, 36.68150),
  wasp_il_twitter = c(7.04457, 6.99673, 6.98895, 7.00302, 6.98061),
  wasp_il_web     = c(1.76863, 1.77763, 1.74911, 1.74578, 1.76233),
  wasp_il_road    = c(0.17911, 0.15462, 0.15949, 0.15993, 0.15579),
  
  # --- HYDRA (Repl+FT) ---
  hydra_ft_kron27  = c(5.75950, 5.77678, 5.76272, 5.74279, 5.75410),
  hydra_ft_kron28  = c(9.77730, 9.78762, 9.72512, 9.76516, 9.76591),
  hydra_ft_kron29  = c(20.29240, 20.12589, 20.14706, 20.13703, 20.16842),
  hydra_ft_kron30  = c(42.76642, 42.84020, 42.70403, 42.68348, 42.67279),
  hydra_ft_uni27   = c(6.37702, 6.40262, 6.41280, 6.41219, 6.40434),
  hydra_ft_uni28   = c(8.75203, 8.81333, 8.81695, 8.81906, 8.80903),
  hydra_ft_uni29   = c(17.93811, 17.81393, 17.81011, 17.79953, 17.79537),
  hydra_ft_uni30   = c(36.87449, 36.88908, 36.88064, 36.88476, 36.88299),
  hydra_ft_twitter = c(9.74386, 9.66591, 9.67042, 9.69633, 9.70334),
  hydra_ft_web     = c(2.50462, 2.56178, 2.42522, 2.57260, 2.54041),
  hydra_ft_road    = c(0.21761, 0.23898, 0.21598, 0.20632, 0.21644),
  
  # --- HYDRA (Repl+Interleaved) ---
  hydra_il_kron27  = c(4.63884, 4.62678, 4.62386, 4.62579, 4.62065),
  hydra_il_kron28  = c(8.98077, 9.04624, 9.00646, 9.01379, 9.01050),
  hydra_il_kron29  = c(19.84247, 19.68267, 19.73583, 19.68947, 19.71409),
  hydra_il_kron30  = c(42.01088, 41.82124, 41.88539, 41.85321, 41.89108),
  hydra_il_uni27   = c(4.83038, 4.81693, 4.81546, 4.81657, 4.81765),
  hydra_il_uni28   = c(8.22616, 8.24956, 8.24573, 8.24414, 8.24413),
  hydra_il_uni29   = c(17.59354, 17.52511, 17.52912, 17.52803, 17.52011),
  hydra_il_uni30   = c(36.58287, 36.52494, 36.52239, 36.53230, 36.54095),
  hydra_il_twitter = c(7.00259, 6.98156, 6.99565, 6.99925, 6.98124),
  hydra_il_web     = c(1.76102, 1.75394, 1.73181, 1.73950, 1.76810),
  hydra_il_road    = c(0.16161, 0.15973, 0.16510, 0.16528, 0.15883)
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
