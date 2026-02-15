###############################################################################
###   CC: Does speedup over Linux depend on working-set size (maxRSS)?    ###
###   Permutation test on Spearman correlation, per system × policy       ###
###############################################################################

# =============================================================================
# 1. MaxRSS for CC (GB), per graph
# =============================================================================

maxrss <- c(
  kron27 = 17.74, kron28 = 35.56, kron29 = 71.28, kron30 = 142.84,
  uni27  = 18.00, uni28  = 36.00, uni29  = 72.00, uni30  = 143.98,
  twitter = 12.28, web = 15.51, road = 0.86
)

# =============================================================================
# 2. Runtime data (5 trials per configuration) — from cc.R
# =============================================================================

rt <- list(
  # --- LINUX First-Touch ---
  linux_ft_kron27  = c(0.33432, 0.33719, 0.33736, 0.33210, 0.33170),
  linux_ft_kron28  = c(0.60428, 0.61037, 0.60743, 0.60363, 0.61118),
  linux_ft_kron29  = c(1.21015, 1.20480, 1.19634, 1.16316, 1.18709),
  linux_ft_kron30  = c(2.09808, 2.21373, 2.17341, 2.28224, 2.20104),
  linux_ft_uni27   = c(1.18827, 1.16887, 1.15323, 1.15058, 1.17195),
  linux_ft_uni28   = c(2.45903, 2.49955, 2.56540, 2.55408, 2.52200),
  linux_ft_uni29   = c(5.47980, 5.45273, 5.55925, 5.50595, 5.45401),
  linux_ft_uni30   = c(12.10859, 12.12118, 12.08304, 12.19501, 12.17252),
  linux_ft_twitter = c(0.18231, 0.17170, 0.17307, 0.17776, 0.17210),
  linux_ft_web     = c(0.12921, 0.11152, 0.14532, 0.11367, 0.13373),
  linux_ft_road    = c(0.03938, 0.04308, 0.04179, 0.04394, 0.04215),
  
  # --- LINUX Interleaved ---
  linux_il_kron27  = c(0.25568, 0.26908, 0.25490, 0.25550, 0.25602),
  linux_il_kron28  = c(0.46972, 0.47812, 0.47114, 0.47250, 0.49086),
  linux_il_kron29  = c(0.92636, 0.91469, 0.93650, 0.92920, 0.90505),
  linux_il_kron30  = c(1.87866, 1.88115, 1.90174, 1.90381, 1.91024),
  linux_il_uni27   = c(0.76189, 0.73479, 0.74908, 0.74255, 0.73844),
  linux_il_uni28   = c(1.74240, 1.75118, 1.75498, 1.74074, 1.75582),
  linux_il_uni29   = c(4.10651, 4.04614, 4.06896, 4.08327, 4.06141),
  linux_il_uni30   = c(9.35257, 9.35723, 9.36331, 9.35796, 9.46177),
  linux_il_twitter = c(0.13059, 0.13006, 0.13119, 0.12852, 0.12938),
  linux_il_web     = c(0.07028, 0.06937, 0.06963, 0.06934, 0.06867),
  linux_il_road    = c(0.02967, 0.03030, 0.03044, 0.04164, 0.03055),
  
  # --- MITOSIS Replicated ---
  mitosis_ft_kron27  = c(0.34886, 0.34696, 0.34402, 0.34417, 0.34352),
  mitosis_ft_kron28  = c(0.63570, 0.62427, 0.63464, 0.62502, 0.62136),
  mitosis_ft_kron29  = c(1.24479, 1.24005, 1.22290, 1.23012, 1.25852),
  mitosis_ft_kron30  = c(2.12465, 2.22176, 2.14811, 2.14393, 2.16096),
  mitosis_ft_uni27   = c(1.25579, 1.21579, 1.28107, 1.23458, 1.25247),
  mitosis_ft_uni28   = c(2.54689, 2.49474, 2.47363, 2.51197, 2.49002),
  mitosis_ft_uni29   = c(6.02214, 5.81009, 5.98436, 5.90102, 5.89157),
  mitosis_ft_uni30   = c(13.26237, 13.32196, 13.18052, 13.27089, 13.21549),
  mitosis_ft_twitter = c(0.18049, 0.17791, 0.18010, 0.17678, 0.17723),
  mitosis_ft_web     = c(0.12836, 0.11718, 0.11773, 0.12013, 0.11819),
  mitosis_ft_road    = c(0.04078, 0.04251, 0.04212, 0.04227, 0.04184),
  
  # --- MITOSIS Replicated+Interleaved ---
  mitosis_il_kron27  = c(0.25968, 0.25756, 0.25533, 0.25687, 0.25584),
  mitosis_il_kron28  = c(0.47911, 0.46570, 0.46784, 0.47068, 0.46172),
  mitosis_il_kron29  = c(0.91337, 0.92042, 0.93662, 0.91907, 0.91425),
  mitosis_il_kron30  = c(1.77704, 1.83280, 1.77881, 1.74097, 1.74171),
  mitosis_il_uni27   = c(0.74402, 0.74084, 0.74025, 0.73736, 0.74931),
  mitosis_il_uni28   = c(1.73375, 1.74838, 1.73782, 1.74728, 1.74103),
  mitosis_il_uni29   = c(4.02504, 4.04885, 4.05882, 4.07201, 4.03096),
  mitosis_il_uni30   = c(9.31540, 9.35624, 9.29052, 9.26697, 9.34132),
  mitosis_il_twitter = c(0.13144, 0.13206, 0.13004, 0.12971, 0.12970),
  mitosis_il_web     = c(0.06971, 0.06858, 0.06930, 0.06887, 0.06879),
  mitosis_il_road    = c(0.03096, 0.03015, 0.03020, 0.03045, 0.03063),
  
  # --- WASP First-Touch ---
  wasp_ft_kron27  = c(0.33527, 0.34038, 0.34087, 0.34007, 0.43727),
  wasp_ft_kron28  = c(0.60347, 0.62062, 0.63099, 0.63286, 0.62883),
  wasp_ft_kron29  = c(1.19862, 1.40999, 1.26841, 1.23482, 1.23059),
  wasp_ft_kron30  = c(2.37828, 2.16981, 2.23374, 2.20839, 2.11691),
  wasp_ft_uni27   = c(1.11689, 1.11587, 1.12409, 1.12318, 1.11606),
  wasp_ft_uni28   = c(2.55775, 2.52966, 2.53246, 2.52459, 2.47480),
  wasp_ft_uni29   = c(5.46369, 5.69698, 5.72876, 5.72185, 5.70470),
  wasp_ft_uni30   = c(13.00939, 12.94447, 12.68042, 12.82998, 12.62236),
  wasp_ft_twitter = c(0.18163, 0.17186, 0.17432, 0.17254, 0.17664),
  wasp_ft_web     = c(0.12749, 0.11511, 0.11400, 0.11412, 0.11218),
  wasp_ft_road    = c(0.05861, 0.04301, 0.04140, 0.04249, 0.04187),
  
  # --- WASP Interleaved ---
  wasp_il_kron27  = c(0.25634, 0.26579, 0.25337, 0.25540, 0.30581),
  wasp_il_kron28  = c(0.48778, 0.48226, 0.48061, 0.46740, 0.46592),
  wasp_il_kron29  = c(0.92352, 0.94378, 0.94426, 0.92688, 0.93075),
  wasp_il_kron30  = c(2.34424, 1.83257, 1.76604, 1.79748, 1.82377),
  wasp_il_uni27   = c(0.73522, 0.73883, 0.74124, 0.73380, 0.74116),
  wasp_il_uni28   = c(1.87841, 1.74229, 1.73700, 1.75124, 1.75105),
  wasp_il_uni29   = c(4.11585, 4.03830, 4.03221, 4.06124, 4.05638),
  wasp_il_uni30   = c(9.29679, 9.28747, 9.32106, 9.32014, 9.37765),
  wasp_il_twitter = c(0.12882, 0.13339, 0.12998, 0.13955, 0.12865),
  wasp_il_web     = c(0.07056, 0.07019, 0.06941, 0.06937, 0.07045),
  wasp_il_road    = c(0.02987, 0.03020, 0.03050, 0.03047, 0.03095),
  
  # --- HYDRA Replicated (repl_order_9) ---
  hydra_ft_kron27  = c(0.36914, 0.34359, 0.34791, 0.34817, 0.36161),
  hydra_ft_kron28  = c(0.67069, 0.65018, 0.65746, 0.65463, 0.65877),
  hydra_ft_kron29  = c(1.21586, 1.24727, 1.23666, 1.22624, 1.25073),
  hydra_ft_kron30  = c(2.18219, 2.18830, 2.17792, 2.19172, 2.07314),
  hydra_ft_uni27   = c(1.18717, 1.21247, 1.20780, 1.20146, 1.21323),
  hydra_ft_uni28   = c(2.49349, 2.49622, 2.50323, 2.50483, 2.50630),
  hydra_ft_uni29   = c(5.71528, 5.79724, 5.88380, 5.78073, 5.76615),
  hydra_ft_uni30   = c(13.02523, 13.16519, 13.24926, 13.48782, 13.07836),
  hydra_ft_twitter = c(0.18016, 0.17822, 0.17699, 0.17940, 0.17606),
  hydra_ft_web     = c(0.11971, 0.11806, 0.13615, 0.11644, 0.13770),
  hydra_ft_road    = c(0.03986, 0.04351, 0.04288, 0.04293, 0.04314),
  
  # --- HYDRA Replicated+Interleaved (repl_order_9) ---
  hydra_il_kron27  = c(0.24175, 0.23935, 0.26174, 0.25478, 0.25545),
  hydra_il_kron28  = c(0.46746, 0.47608, 0.46362, 0.48639, 0.47549),
  hydra_il_kron29  = c(0.93557, 0.95258, 0.90745, 0.92060, 0.90686),
  hydra_il_kron30  = c(1.75343, 1.84890, 1.77762, 1.86501, 1.79378),
  hydra_il_uni27   = c(0.74274, 0.73695, 0.73650, 0.74413, 0.73997),
  hydra_il_uni28   = c(1.75516, 1.77303, 1.74849, 1.74639, 1.73972),
  hydra_il_uni29   = c(4.04427, 4.04295, 4.05114, 4.02582, 4.05104),
  hydra_il_uni30   = c(9.39343, 9.34908, 9.33556, 9.32547, 9.36958),
  hydra_il_twitter = c(0.13787, 0.13057, 0.13137, 0.13000, 0.12967),
  hydra_il_web     = c(0.06916, 0.06829, 0.06829, 0.06842, 0.06892),
  hydra_il_road    = c(0.03005, 0.03039, 0.04955, 0.03045, 0.03059)
)

# =============================================================================
# 3. Permutation test on Spearman rho
#    H0: no monotonic association between maxRSS and speedup
#    Two-sided test
# =============================================================================

perm_cor_test <- function(x, y, n_perm = 100000) {
  n <- length(x)
  obs_rho <- cor(x, y, method = "spearman")
  count <- 0
  for (i in seq_len(n_perm)) {
    perm_rho <- cor(sample(x), y, method = "spearman")
    if (abs(perm_rho) >= abs(obs_rho)) count <- count + 1
  }
  list(rho = obs_rho, p = (count + 1) / (n_perm + 1), n = n)
}

# Helper: format p-value with full precision (scientific notation for small values)
fmt_p <- function(p) {
  ifelse(p < 1e-4, sprintf("%.4e", p), sprintf("%.6f", p))
}

# =============================================================================
# 4. Compute per-graph mean speedup, then test correlation with maxRSS
# =============================================================================

graphs   <- c("kron27","kron28","kron29","kron30",
              "uni27","uni28","uni29","uni30",
              "twitter","web","road")
policies <- c("ft", "il")
pol_lab  <- c(ft = "First-Touch", il = "Interleaved")
systems  <- c("mitosis", "wasp", "hydra")
sys_lab  <- c(mitosis = "Mitosis", wasp = "WASP", hydra = "Hydra")

set.seed(42)
results <- data.frame()
plot_data <- data.frame()

for (sys in systems) {
  for (pol in policies) {
    speedups <- numeric(length(graphs))
    rss_vals <- numeric(length(graphs))
    
    for (i in seq_along(graphs)) {
      g <- graphs[i]
      lk <- paste0("linux_", pol, "_", g)
      sk <- paste0(sys, "_", pol, "_", g)
      # Mean speedup = mean(linux) / mean(system)
      speedups[i] <- mean(rt[[lk]]) / mean(rt[[sk]])
      rss_vals[i] <- maxrss[g]
    }
    
    # Permutation test
    res <- perm_cor_test(rss_vals, speedups)
    
    results <- rbind(results, data.frame(
      System  = sys_lab[sys],
      Policy  = pol_lab[pol],
      Rho     = round(res$rho, 4),
      p_value = res$p,
      p_display = fmt_p(res$p),
      Sig     = ifelse(res$p < 0.001, "***",
                       ifelse(res$p < 0.01,  "**",
                              ifelse(res$p < 0.05,  "*", ""))),
      stringsAsFactors = FALSE
    ))
    
    # Collect for plotting
    for (i in seq_along(graphs)) {
      plot_data <- rbind(plot_data, data.frame(
        System  = sys_lab[sys],
        Policy  = pol_lab[pol],
        Graph   = graphs[i],
        MaxRSS  = rss_vals[i],
        Speedup = speedups[i],
        stringsAsFactors = FALSE
      ))
    }
  }
}

# =============================================================================
# 5. Print results
# =============================================================================

cat("\n")
cat("======================================================================\n")
cat("  CC: Spearman correlation between MaxRSS and Speedup vs Linux\n")
cat("  Permutation test (two-sided, 100k permutations)\n")
cat("  11 graphs, mean speedup per graph\n")
cat("======================================================================\n\n")

# Print with formatted p-value column
print_results <- results[, c("System", "Policy", "Rho", "p_display", "Sig")]
colnames(print_results)[4] <- "p_value"
print(print_results, row.names = FALSE)

cat("\nInterpretation:\n")
cat("  rho > 0 → larger working sets see MORE speedup over Linux\n")
cat("  rho < 0 → larger working sets see LESS speedup over Linux\n")
cat("  * p < 0.05  ** p < 0.01  *** p < 0.001\n")

# =============================================================================
# 5b. Detailed per-graph speedup tables for each system × policy
# =============================================================================

cat("\n")
cat("======================================================================\n")
cat("  Per-graph speedup vs MaxRSS (sorted by MaxRSS ascending)\n")
cat("======================================================================\n")

for (sys in systems) {
  for (pol in policies) {
    label <- paste(sys_lab[sys], "-", pol_lab[pol])
    cat("\n---", label, "---\n")
    cat(sprintf("  %-10s %8s %10s %12s\n",
                "Graph", "RSS(GB)", "Speedup", "% Improv."))
    
    speedups <- numeric(length(graphs))
    rss_vals <- numeric(length(graphs))
    for (i in seq_along(graphs)) {
      g <- graphs[i]
      lk <- paste0("linux_", pol, "_", g)
      sk <- paste0(sys, "_", pol, "_", g)
      speedups[i] <- mean(rt[[lk]]) / mean(rt[[sk]])
      rss_vals[i] <- maxrss[g]
    }
    
    ord <- order(rss_vals)
    for (i in ord) {
      pct <- (speedups[i] - 1) * 100
      cat(sprintf("  %-10s %8.2f %10.4f %+11.2f%%\n",
                  graphs[i], rss_vals[i], speedups[i], pct))
    }
    
    # Summarise: small vs large
    small_idx <- which(rss_vals < 20)
    large_idx <- which(rss_vals >= 40)
    cat(sprintf("  >> Small graphs (RSS < 20 GB, n=%d): mean speedup = %.4f\n",
                length(small_idx), mean(speedups[small_idx])))
    cat(sprintf("  >> Large graphs (RSS >= 40 GB, n=%d): mean speedup = %.4f\n",
                length(large_idx), mean(speedups[large_idx])))
  }
}

# =============================================================================
# 5c. Overall summary across all systems
# =============================================================================

cat("\n")
cat("======================================================================\n")
cat("  Summary: Average speedup by MaxRSS group across all systems\n")
cat("======================================================================\n\n")

for (pol in policies) {
  cat(sprintf("--- %s ---\n", pol_lab[pol]))
  cat(sprintf("  %-10s %12s %12s %12s\n",
              "RSS Group", "Mitosis", "WASP", "Hydra"))
  
  for (grp_label in c("Small (<20GB)", "Medium (20-80GB)", "Large (>80GB)")) {
    vals <- character(3)
    for (si in seq_along(systems)) {
      sys <- systems[si]
      speedups <- numeric(length(graphs))
      rss_vals <- numeric(length(graphs))
      for (i in seq_along(graphs)) {
        g <- graphs[i]
        lk <- paste0("linux_", pol, "_", g)
        sk <- paste0(sys, "_", pol, "_", g)
        speedups[i] <- mean(rt[[lk]]) / mean(rt[[sk]])
        rss_vals[i] <- maxrss[g]
      }
      if (grp_label == "Small (<20GB)")       idx <- which(rss_vals < 20)
      else if (grp_label == "Medium (20-80GB)") idx <- which(rss_vals >= 20 & rss_vals <= 80)
      else                                      idx <- which(rss_vals > 80)
      vals[si] <- sprintf("%.4f", mean(speedups[idx]))
    }
    cat(sprintf("  %-17s %9s %12s %12s\n", grp_label, vals[1], vals[2], vals[3]))
  }
  cat("\n")
}

cat("Interpretation guide:\n")
cat("  If speedup increases monotonically with RSS group (small < medium < large),\n")
cat("  this supports the hypothesis that the tiered-memory systems benefit more\n")
cat("  when the working set is larger (exceeding fast-tier capacity).\n")
cat("  The Spearman rho and permutation p-value above test this formally.\n")

# =============================================================================
# 6. Scatter plots (base R): Speedup vs MaxRSS, per system × policy
# =============================================================================

pdf("cc_rss_speedup.pdf", width = 14, height = 10)
par(mfrow = c(2, 3), mar = c(4.5, 4.5, 3, 1))

graph_cols <- rainbow(length(graphs))
names(graph_cols) <- graphs

for (sys in systems) {
  for (pol in policies) {
    label <- paste(sys_lab[sys], "-", pol_lab[pol])
    
    # Extract subset
    idx <- plot_data$System == sys_lab[sys] & plot_data$Policy == pol_lab[pol]
    sub <- plot_data[idx, ]
    
    # Annotation from results
    ridx <- results$System == sys_lab[sys] & results$Policy == pol_lab[pol]
    rho_val <- results$Rho[ridx]
    p_str   <- results$p_display[ridx]
    sig_val <- results$Sig[ridx]
    
    plot(sub$MaxRSS, sub$Speedup,
         log = "x", pch = 19,
         col = graph_cols[sub$Graph], cex = 1.5,
         xlab = "MaxRSS (GB, log scale)",
         ylab = "Speedup (Linux / System)",
         main = label)
    abline(h = 1, lty = 2, col = "gray50")
    # Linear fit on log(RSS) for trend line
    fit <- lm(Speedup ~ log2(MaxRSS), data = sub)
    xseq <- seq(min(sub$MaxRSS), max(sub$MaxRSS), length.out = 100)
    lines(xseq, predict(fit, newdata = data.frame(MaxRSS = xseq)),
          lty = 3, col = "black")
    # Annotate with rho and p
    legend("topleft",
           legend = paste0("rho = ", rho_val, ",  p = ", p_str, " ", sig_val),
           bty = "n", cex = 0.9)
    # Label points
    text(sub$MaxRSS, sub$Speedup, labels = sub$Graph,
         pos = 3, cex = 0.65, col = "gray30")
  }
}

dev.off()
cat("\nSaved plot to cc_rss_speedup.pdf\n")