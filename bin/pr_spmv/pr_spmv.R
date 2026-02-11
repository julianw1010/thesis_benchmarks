


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
  # --- LINUX First-Touch ---
  linux_ft_kron27  = c(5.60689, 5.78571, 5.81468, 5.81268, 5.70899),
  linux_ft_kron28  = c(12.00335, 12.02797, 12.02118, 12.07782, 12.01830),
  linux_ft_kron29  = c(30.82341, 30.78010, 30.72806, 30.75000, 31.00027),
  linux_ft_kron30  = c(80.65777, 80.26017, 80.12596, 80.02661, 80.11251),
  linux_ft_uni27   = c(6.12160, 6.13390, 6.12099, 6.11091, 6.05486),
  linux_ft_uni28   = c(11.82064, 11.83728, 11.83113, 11.81247, 11.82084),
  linux_ft_uni29   = c(28.52539, 28.51833, 28.48190, 28.48557, 28.45805),
  linux_ft_uni30   = c(71.96063, 71.97437, 71.93255, 71.95810, 71.91793),
  linux_ft_twitter = c(4.97456, 4.95015, 4.99015, 4.92900, 4.92827),
  linux_ft_web     = c(2.42009, 2.40084, 2.40088, 2.44765, 2.40095),
  linux_ft_road    = c(0.16269, 0.15891, 0.15537, 0.17054, 0.15079),
  
  # --- LINUX Interleaved ---
  linux_il_kron27  = c(5.51888, 5.51711, 5.52002, 5.51091, 5.51065),
  linux_il_kron28  = c(11.91265, 11.88666, 11.90524, 11.90750, 11.89980),
  linux_il_kron29  = c(31.87374, 31.69995, 31.74806, 32.11746, 31.72002),
  linux_il_kron30  = c(76.13552, 76.17279, 76.54586, 76.16650, 76.16241),
  linux_il_uni27   = c(5.86524, 5.85108, 5.83931, 5.85822, 5.85546),
  linux_il_uni28   = c(11.81841, 11.81925, 11.81216, 11.80873, 11.81934),
  linux_il_uni29   = c(26.92574, 26.92700, 26.95309, 26.98423, 26.98245),
  linux_il_uni30   = c(71.82716, 71.82346, 71.82341, 71.79665, 71.92331),
  linux_il_twitter = c(4.65366, 4.67529, 4.60192, 4.71304, 4.65536),
  linux_il_web     = c(1.52335, 1.52597, 1.52236, 1.53895, 1.52249),
  linux_il_road    = c(0.16916, 0.16413, 0.15742, 0.15640, 0.15765),
  
  # --- MITOSIS Replicated ---
  mitosis_ft_kron27  = c(5.81398, 5.68789, 5.81626, 5.81711, 5.80863),
  mitosis_ft_kron28  = c(11.98649, 11.95624, 11.89802, 11.97262, 11.95867),
  mitosis_ft_kron29  = c(27.53284, 27.50132, 27.53214, 27.50369, 27.52192),
  mitosis_ft_kron30  = c(59.44022, 59.40710, 59.36535, 59.75903, 59.40309),
  mitosis_ft_uni27   = c(6.12154, 6.13060, 6.10742, 6.07150, 6.13219),
  mitosis_ft_uni28   = c(11.80627, 11.80254, 11.82123, 11.81172, 11.81128),
  mitosis_ft_uni29   = c(26.17962, 26.18585, 26.18422, 26.18145, 26.19539),
  mitosis_ft_uni30   = c(54.99734, 55.00058, 54.99837, 55.00940, 54.99479),
  mitosis_ft_twitter = c(5.02839, 5.06497, 4.71827, 5.11537, 5.01923),
  mitosis_ft_web     = c(2.41304, 2.40009, 2.48159, 2.47481, 2.42221),
  mitosis_ft_road    = c(0.19288, 0.16107, 0.15812, 0.16109, 0.15713),
  
  # --- MITOSIS Replicated+Interleaved ---
  mitosis_il_kron27  = c(5.52413, 5.51292, 5.53421, 5.50039, 5.51415),
  mitosis_il_kron28  = c(11.78106, 11.77991, 11.78503, 11.80380, 11.80268),
  mitosis_il_kron29  = c(27.12448, 27.16264, 27.13283, 27.14744, 27.14153),
  mitosis_il_kron30  = c(58.23553, 58.16370, 58.31293, 58.28844, 58.17426),
  mitosis_il_uni27   = c(5.88081, 5.90496, 5.89437, 5.88464, 5.89438),
  mitosis_il_uni28   = c(11.67146, 11.66270, 11.65296, 11.65517, 11.66035),
  mitosis_il_uni29   = c(25.85110, 25.85924, 25.85000, 25.84797, 25.85031),
  mitosis_il_uni30   = c(54.37594, 54.36054, 54.36599, 54.37121, 54.38199),
  mitosis_il_twitter = c(4.68412, 4.62787, 4.57398, 4.57202, 4.49785),
  mitosis_il_web     = c(1.51157, 1.52274, 1.51141, 1.52291, 1.51341),
  mitosis_il_road    = c(0.16513, 0.16168, 0.15689, 0.15482, 0.16831),
  
  # --- WASP First-Touch ---
  wasp_ft_kron27  = c(5.82713, 5.78179, 5.75176, 5.72431, 5.59051),
  wasp_ft_kron28  = c(11.97564, 11.90606, 11.91744, 11.95674, 11.94507),
  wasp_ft_kron29  = c(27.52359, 27.30616, 27.49892, 27.36940, 27.32729),
  wasp_ft_kron30  = c(59.89252, 59.04356, 59.17673, 59.02133, 59.14508),
  wasp_ft_uni27   = c(6.03473, 6.05302, 6.03953, 6.06835, 6.06464),
  wasp_ft_uni28   = c(11.76820, 11.75971, 11.75464, 11.76930, 11.79352),
  wasp_ft_uni29   = c(26.03695, 25.99559, 25.99863, 25.99930, 26.03974),
  wasp_ft_uni30   = c(55.52143, 54.79505, 54.75044, 54.81669, 54.76377),
  wasp_ft_twitter = c(4.95477, 4.96732, 5.04555, 4.81333, 5.01345),
  wasp_ft_web     = c(2.39412, 2.36668, 2.45227, 2.40624, 2.46916),
  wasp_ft_road    = c(0.16689, 0.18125, 0.15231, 0.15215, 0.15709),
  
  # --- WASP Interleaved ---
  wasp_il_kron27  = c(5.54621, 5.51392, 5.49088, 5.47785, 5.54791),
  wasp_il_kron28  = c(11.92376, 11.83193, 11.83116, 11.80771, 11.80715),
  wasp_il_kron29  = c(27.17016, 26.94076, 26.97902, 27.01372, 26.94939),
  wasp_il_kron30  = c(59.29268, 58.52254, 58.43044, 58.61811, 58.43216),
  wasp_il_uni27   = c(5.87198, 5.90998, 5.88703, 5.87663, 5.85593),
  wasp_il_uni28   = c(11.70964, 11.66071, 11.66739, 11.66551, 11.67061),
  wasp_il_uni29   = c(26.01704, 25.76561, 25.77027, 25.77617, 25.76203),
  wasp_il_uni30   = c(55.29072, 54.50910, 54.45751, 54.46230, 54.50668),
  wasp_il_twitter = c(4.64678, 4.59980, 4.34964, 4.56071, 4.65672),
  wasp_il_web     = c(1.51467, 1.52646, 1.52390, 1.54641, 1.50624),
  wasp_il_road    = c(0.20343, 0.18234, 0.15501, 0.16026, 0.15866),
  
  # --- HYDRA Replicated (repl_order_9) ---
  hydra_ft_kron27  = c(5.76124, 5.83223, 5.81959, 5.77086, 5.79748),
  hydra_ft_kron28  = c(11.97809, 11.88585, 11.89830, 11.90961, 11.89232),
  hydra_ft_kron29  = c(27.48782, 27.13043, 27.16357, 27.15631, 27.21258),
  hydra_ft_kron30  = c(59.45102, 59.22243, 59.28094, 59.23622, 59.35713),
  hydra_ft_uni27   = c(6.14914, 6.10252, 6.10504, 6.13405, 6.07960),
  hydra_ft_uni28   = c(11.75540, 11.73895, 11.74194, 11.73961, 11.73610),
  hydra_ft_uni29   = c(26.16183, 25.96191, 25.96865, 25.96134, 25.97278),
  hydra_ft_uni30   = c(54.95750, 54.99185, 54.94955, 54.94748, 54.91970),
  hydra_ft_twitter = c(5.02551, 5.01287, 4.67179, 5.00870, 5.04639),
  hydra_ft_web     = c(2.41967, 2.52560, 2.42986, 2.38019, 2.41342),
  hydra_ft_road    = c(0.16968, 0.16046, 0.15935, 0.15778, 0.15514),
  
  # --- HYDRA Replicated+Interleaved (repl_order_9) ---
  hydra_il_kron27  = c(5.52840, 5.45595, 5.49503, 5.45839, 5.51161),
  hydra_il_kron28  = c(11.82315, 11.79197, 11.81470, 11.80651, 11.83356),
  hydra_il_kron29  = c(27.04466, 26.78330, 27.05287, 26.82670, 26.83521),
  hydra_il_kron30  = c(58.24676, 57.85056, 57.96408, 57.93560, 58.11791),
  hydra_il_uni27   = c(5.85523, 5.85387, 5.82550, 5.86321, 5.85585),
  hydra_il_uni28   = c(11.64904, 11.66142, 11.65592, 11.64159, 11.66950),
  hydra_il_uni29   = c(25.83544, 25.64483, 25.66933, 25.65425, 25.64415),
  hydra_il_uni30   = c(54.38842, 54.27532, 54.28479, 54.30344, 54.28573),
  hydra_il_twitter = c(4.70613, 4.54640, 4.65367, 4.67439, 4.56736),
  hydra_il_web     = c(1.53449, 1.50501, 1.51261, 1.49819, 1.51398),
  hydra_il_road    = c(0.15715, 0.15638, 0.14913, 0.15167, 0.17372)
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
    
    p <- ggplot(df, aes(x = Bedingung, y = Zeit)) +
      geom_line(aes(group = Trial), color = "gray50", linewidth = 0.5) +
      geom_point(aes(color = Bedingung), size = 2) +
      scale_color_manual(values = c("Linux" = "#E74C3C",
                                    "Mitosis" = "#2ECC71",
                                    "Wasp" = "#3498DB",
                                    "Hydra" = "#9B59B6")) +
      coord_cartesian(ylim = c(0, NA)) +
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