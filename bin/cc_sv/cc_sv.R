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
  # --- LINUX First-Touch ---
  linux_ft_kron27  = c(5.25484, 5.26032, 5.28091, 5.26657, 5.27103),
  linux_ft_kron28  = c(9.66535, 9.68412, 9.62954, 9.68620, 9.70048),
  linux_ft_kron29  = c(21.36107, 21.37305, 21.41995, 21.46194, 21.34614),
  linux_ft_kron30  = c(51.07288, 51.12533, 51.93556, 50.69916, 50.74301),
  linux_ft_uni27   = c(6.28895, 6.68920, 6.67710, 6.74859, 6.71957),
  linux_ft_uni28   = c(12.19214, 12.33447, 12.42295, 12.54301, 12.56131),
  linux_ft_uni29   = c(24.08220, 24.11816, 24.21038, 24.20223, 24.24678),
  linux_ft_uni30   = c(48.84104, 49.08338, 49.17349, 48.82028, 48.99220),
  linux_ft_twitter = c(3.50382, 3.48879, 3.51651, 3.51070, 3.51832),
  linux_ft_web     = c(0.70499, 0.70360, 0.70398, 0.70382, 0.70357),
  linux_ft_road    = c(0.06002, 0.06056, 0.06124, 0.05944, 0.06057),
  
  # --- LINUX Interleaved ---
  linux_il_kron27  = c(4.93441, 4.92587, 4.92297, 4.92864, 4.91815),
  linux_il_kron28  = c(9.23494, 9.28035, 9.24255, 9.28068, 9.29464),
  linux_il_kron29  = c(19.47225, 19.49401, 19.52732, 19.48812, 19.48009),
  linux_il_kron30  = c(51.73405, 51.86121, 51.89680, 51.77142, 51.95272),
  linux_il_uni27   = c(5.28040, 5.19274, 5.18627, 5.22500, 5.25201),
  linux_il_uni28   = c(10.05837, 10.00358, 10.08839, 10.06971, 10.10126),
  linux_il_uni29   = c(20.96328, 21.01192, 21.07239, 20.89253, 20.93381),
  linux_il_uni30   = c(45.38459, 45.73710, 45.50109, 45.69392, 45.76469),
  linux_il_twitter = c(3.59982, 3.57544, 3.58353, 3.54719, 3.55030),
  linux_il_web     = c(0.38643, 0.39050, 0.39284, 0.38911, 0.38891),
  linux_il_road    = c(0.05414, 0.05483, 0.05340, 0.05492, 0.05413),
  
  # --- MITOSIS Replicated ---
  mitosis_ft_kron27  = c(5.32927, 5.32670, 5.33916, 5.35210, 5.33593),
  mitosis_ft_kron28  = c(9.65998, 9.62766, 9.60069, 9.62837, 9.64665),
  mitosis_ft_kron29  = c(19.22859, 19.20115, 19.14699, 19.15355, 19.15803),
  mitosis_ft_kron30  = c(38.35697, 38.44493, 38.36576, 38.50652, 38.83380),
  mitosis_ft_uni27   = c(6.33470, 6.53826, 6.55095, 6.56969, 6.58279),
  mitosis_ft_uni28   = c(12.28736, 12.29017, 12.28888, 12.35406, 12.32418),
  mitosis_ft_uni29   = c(24.01963, 23.99558, 23.99474, 24.00844, 24.06025),
  mitosis_ft_uni30   = c(44.21888, 44.00983, 43.99888, 43.87973, 43.98086),
  mitosis_ft_twitter = c(3.51010, 3.54679, 3.53780, 3.53888, 3.50956),
  mitosis_ft_web     = c(0.70518, 0.70532, 0.70498, 0.70649, 0.70744),
  mitosis_ft_road    = c(0.06135, 0.06211, 0.06202, 0.06173, 0.06293),
  
  # --- MITOSIS Replicated+Interleaved ---
  mitosis_il_kron27  = c(4.96331, 4.96929, 4.93380, 4.93207, 4.93797),
  mitosis_il_kron28  = c(9.11478, 9.12970, 9.13596, 9.13547, 9.09965),
  mitosis_il_kron29  = c(18.66971, 18.62110, 18.66530, 18.63940, 18.69707),
  mitosis_il_kron30  = c(39.32392, 39.33262, 39.37635, 39.32107, 39.31315),
  mitosis_il_uni27   = c(5.13578, 5.11402, 5.12234, 5.13151, 5.18294),
  mitosis_il_uni28   = c(9.83580, 9.84009, 9.84658, 9.86791, 9.84942),
  mitosis_il_uni29   = c(19.85316, 20.02597, 20.11907, 20.10913, 20.12806),
  mitosis_il_uni30   = c(39.36505, 39.32781, 39.32152, 39.32529, 39.37414),
  mitosis_il_twitter = c(3.60069, 3.59348, 3.56167, 3.56556, 3.57514),
  mitosis_il_web     = c(0.38792, 0.38802, 0.38783, 0.39038, 0.38837),
  mitosis_il_road    = c(0.05322, 0.05442, 0.05393, 0.05354, 0.05635),
  
  # --- WASP First-Touch ---
  wasp_ft_kron27  = c(5.24487, 5.29025, 5.28476, 5.28375, 5.28700),
  wasp_ft_kron28  = c(9.67273, 9.65359, 9.65075, 9.62588, 9.67058),
  wasp_ft_kron29  = c(19.19147, 19.21619, 19.15130, 19.20645, 19.18890),
  wasp_ft_kron30  = c(40.30071, 39.49725, 39.46534, 39.69362, 39.38787),
  wasp_ft_uni27   = c(6.20150, 6.27181, 6.31631, 6.38845, 6.46691),
  wasp_ft_uni28   = c(12.37133, 12.64887, 12.49645, 12.51744, 12.54634),
  wasp_ft_uni29   = c(24.20154, 24.30787, 24.45964, 24.47068, 24.36437),
  wasp_ft_uni30   = c(44.43909, 43.14892, 43.39943, 43.16789, 43.23215),
  wasp_ft_twitter = c(3.49794, 3.51806, 3.49035, 3.50746, 3.49254),
  wasp_ft_web     = c(0.70263, 0.70113, 0.70170, 0.70125, 0.70825),
  wasp_ft_road    = c(0.05976, 0.06149, 0.06060, 0.06031, 0.06200),
  
  # --- WASP Interleaved ---
  wasp_il_kron27  = c(4.95242, 4.93969, 4.92518, 4.98378, 4.92604),
  wasp_il_kron28  = c(9.15927, 9.16503, 9.17403, 9.19621, 9.15616),
  wasp_il_kron29  = c(18.61356, 18.28532, 18.35296, 18.30987, 18.28173),
  wasp_il_kron30  = c(40.40808, 39.41689, 39.24146, 39.41304, 39.56242),
  wasp_il_uni27   = c(5.38389, 5.26754, 5.44832, 5.46658, 5.48619),
  wasp_il_uni28   = c(10.03319, 9.87219, 9.89053, 9.92695, 9.93253),
  wasp_il_uni29   = c(20.35081, 19.70221, 19.86567, 19.72701, 19.65318),
  wasp_il_uni30   = c(39.49509, 38.52351, 39.00984, 38.55478, 38.86414),
  wasp_il_twitter = c(3.58606, 3.57410, 3.55183, 3.56409, 3.56470),
  wasp_il_web     = c(0.39082, 0.38840, 0.38954, 0.38795, 0.40130),
  wasp_il_road    = c(0.05333, 0.05519, 0.05402, 0.05419, 0.05507),
  
  # --- HYDRA Replicated (repl_order_9) ---
  hydra_ft_kron27  = c(4.50426, 4.47571, 4.50305, 4.51011, 4.50043),
  hydra_ft_kron28  = c(9.63287, 9.65094, 9.64767, 9.60098, 9.61790),
  hydra_ft_kron29  = c(19.11479, 19.22337, 19.08240, 19.09946, 19.11066),
  hydra_ft_kron30  = c(38.50780, 38.47436, 38.52977, 38.57468, 38.50830),
  hydra_ft_uni27   = c(6.31090, 6.25959, 6.40793, 6.48870, 6.57451),
  hydra_ft_uni28   = c(12.42254, 12.38289, 12.43202, 12.50828, 12.54017),
  hydra_ft_uni29   = c(24.17071, 24.14613, 24.09560, 24.15431, 24.19881),
  hydra_ft_uni30   = c(43.67589, 44.14764, 43.60100, 44.07743, 44.06376),
  hydra_ft_twitter = c(3.43534, 3.45646, 3.44897, 3.45290, 3.47831),
  hydra_ft_web     = c(0.70135, 0.70419, 0.70359, 0.70181, 0.70403),
  hydra_ft_road    = c(0.06194, 0.06338, 0.06473, 0.06224, 0.06316),
  
  # --- HYDRA Replicated+Interleaved (repl_order_9) ---
  hydra_il_kron27  = c(4.22922, 4.16219, 4.17206, 4.16953, 4.16445),
  hydra_il_kron28  = c(9.13263, 9.14077, 9.15380, 9.14465, 9.15070),
  hydra_il_kron29  = c(18.23685, 18.24263, 18.27915, 18.23570, 18.25752),
  hydra_il_kron30  = c(39.15965, 39.30615, 39.35078, 39.24755, 39.17100),
  hydra_il_uni27   = c(5.45858, 5.37068, 5.26221, 5.20225, 5.23410),
  hydra_il_uni28   = c(10.05013, 10.03508, 10.02906, 10.09155, 10.21619),
  hydra_il_uni29   = c(19.38677, 19.36953, 19.34873, 19.35816, 19.35200),
  hydra_il_uni30   = c(38.82365, 38.38094, 38.48954, 38.42631, 38.41695),
  hydra_il_twitter = c(3.54399, 3.49015, 3.51798, 3.49149, 3.51643),
  hydra_il_web     = c(0.38741, 0.38673, 0.38698, 0.38745, 0.38694),
  hydra_il_road    = c(0.05334, 0.05560, 0.05378, 0.05494, 0.05435)
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
