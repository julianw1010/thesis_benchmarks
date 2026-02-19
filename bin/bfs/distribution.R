###############################################################################
###  BFS: Does speedup over Linux depend on working-set size (maxRSS)?    ###
###  Permutation test on Spearman correlation, per system × policy        ###
###  ONE-SIDED test: H1: rho > 0 (larger RSS → more speedup)             ###
###############################################################################

# =============================================================================
# 1. MaxRSS for BFS (GB), per graph
# =============================================================================

maxrss <- c(
  kron27 = 17.74, kron28 = 35.56, kron29 = 71.28, kron30 = 142.84,
  uni27  = 18.00, uni28  = 36.00, uni29  = 72.00, uni30  = 143.98,
  twitter = 12.28, web = 15.51, road = 0.95
)

# =============================================================================
# 2. Runtime data (5 trials per configuration) — from bfs.R
# =============================================================================

rt <- list(
  # --- LINUX First-Touch ---
  linux_ft_kron27  = c(0.39534, 0.29521, 0.24107, 0.28652, 0.25213),
  linux_ft_kron28  = c(0.43326, 0.38893, 0.58089, 0.35885, 0.47656),
  linux_ft_kron29  = c(0.98460, 0.77534, 0.60090, 0.75869, 1.08126),
  linux_ft_kron30  = c(1.24678, 2.66584, 1.51447, 2.96633, 1.20656),
  linux_ft_uni27   = c(0.79836, 0.60190, 0.60209, 0.70992, 0.59170),
  linux_ft_uni28   = c(2.24256, 1.85336, 2.32016, 2.02002, 2.05999),
  linux_ft_uni29   = c(2.81867, 2.96304, 5.97070, 2.55078, 2.80120),
  linux_ft_uni30   = c(4.99616, 5.11766, 4.72721, 4.79570, 5.16856),
  linux_ft_twitter = c(0.19449, 0.16970, 0.19503, 0.24759, 0.18189),
  linux_ft_web     = c(0.31523, 0.31139, 0.28996, 0.29125, 0.31093),
  linux_ft_road    = c(0.68861, 0.64204, 0.52577, 0.57417, 0.64966),
  
  # --- LINUX Interleaved ---
  linux_il_kron27  = c(0.34702, 0.18948, 0.16800, 0.20039, 0.21128),
  linux_il_kron28  = c(0.34756, 0.32015, 0.34142, 0.29481, 0.32253),
  linux_il_kron29  = c(0.59040, 0.58410, 0.51100, 0.56126, 0.79681),
  linux_il_kron30  = c(0.99960, 1.84978, 1.08629, 2.13583, 0.93249),
  linux_il_uni27   = c(0.35050, 0.29219, 0.29479, 0.29942, 0.29321),
  linux_il_uni28   = c(0.88142, 0.77727, 1.03920, 0.86755, 0.80848),
  linux_il_uni29   = c(1.41583, 1.50662, 2.19409, 1.26200, 1.40013),
  linux_il_uni30   = c(2.42604, 2.46590, 2.31227, 2.28579, 2.56193),
  linux_il_twitter = c(0.15514, 0.15950, 0.19205, 0.25068, 0.13496),
  linux_il_web     = c(0.20378, 0.19050, 0.18285, 0.18586, 0.19646),
  linux_il_road    = c(0.79331, 0.74093, 0.62783, 0.66626, 0.75095),
  
  # --- MITOSIS Replicated ---
  mitosis_ft_kron27  = c(0.41867, 0.30193, 0.23858, 0.29534, 0.26052),
  mitosis_ft_kron28  = c(0.42969, 0.40048, 0.59270, 0.36506, 0.48361),
  mitosis_ft_kron29  = c(0.97510, 0.81908, 0.63746, 0.80791, 1.08561),
  mitosis_ft_kron30  = c(1.31398, 2.49550, 1.52288, 2.76670, 1.23986),
  mitosis_ft_uni27   = c(0.73725, 0.52245, 0.57123, 0.56808, 0.55668),
  mitosis_ft_uni28   = c(2.09228, 1.81765, 2.40155, 2.05249, 1.88179),
  mitosis_ft_uni29   = c(2.88626, 2.98424, 6.24052, 2.59952, 2.81901),
  mitosis_ft_uni30   = c(5.04417, 5.03641, 4.84113, 4.69046, 5.18991),
  mitosis_ft_twitter = c(0.18883, 0.16984, 0.20095, 0.25039, 0.17003),
  mitosis_ft_web     = c(0.30973, 0.31561, 0.29135, 0.29331, 0.31523),
  mitosis_ft_road    = c(0.71911, 0.68368, 0.55110, 0.59389, 0.68273),
  
  # --- MITOSIS Replicated+Interleaved ---
  mitosis_il_kron27  = c(0.36246, 0.19492, 0.17367, 0.19305, 0.21576),
  mitosis_il_kron28  = c(0.36615, 0.33031, 0.34888, 0.29681, 0.33247),
  mitosis_il_kron29  = c(0.60279, 0.57770, 0.51555, 0.55895, 0.78646),
  mitosis_il_kron30  = c(1.00448, 1.70623, 1.07883, 2.07666, 0.93086),
  mitosis_il_uni27   = c(0.37252, 0.29413, 0.29990, 0.30024, 0.29718),
  mitosis_il_uni28   = c(0.86911, 0.77785, 1.03476, 0.87649, 0.81693),
  mitosis_il_uni29   = c(1.37111, 1.43228, 2.19855, 1.24383, 1.36865),
  mitosis_il_uni30   = c(2.41568, 2.41973, 2.31396, 2.28841, 2.49981),
  mitosis_il_twitter = c(0.15373, 0.15993, 0.20405, 0.23922, 0.13618),
  mitosis_il_web     = c(0.19963, 0.19053, 0.18181, 0.20014, 0.19608),
  mitosis_il_road    = c(0.85709, 0.82027, 0.68255, 0.74305, 0.81967),
  
  # --- WASP First-Touch ---
  wasp_ft_kron27  = c(0.40090, 0.29891, 0.24234, 0.28541, 0.25106),
  wasp_ft_kron28  = c(0.42491, 0.38490, 0.56933, 0.35930, 0.64266),
  wasp_ft_kron29  = c(0.98939, 1.12203, 0.64602, 0.81763, 1.12446),
  wasp_ft_kron30  = c(1.32731, 3.07184, 1.60448, 2.92576, 1.28872),
  wasp_ft_uni27   = c(0.66087, 0.48427, 0.59814, 0.58436, 0.52640),
  wasp_ft_uni28   = c(2.28764, 2.08114, 2.47150, 2.28651, 1.95981),
  wasp_ft_uni29   = c(2.82046, 2.92439, 6.18168, 2.57943, 2.78541),
  wasp_ft_uni30   = c(5.24666, 5.19646, 4.81023, 4.88284, 5.36276),
  wasp_ft_twitter = c(0.16135, 0.16481, 0.22011, 0.28995, 0.15958),
  wasp_ft_web     = c(0.30484, 0.31054, 0.30349, 0.28998, 0.31321),
  wasp_ft_road    = c(0.70433, 0.67665, 0.55567, 0.57323, 0.67890),
  
  # --- WASP Interleaved ---
  wasp_il_kron27  = c(0.33780, 0.18859, 0.16845, 0.18779, 0.21226),
  wasp_il_kron28  = c(0.36193, 0.32298, 0.34405, 0.29115, 0.32547),
  wasp_il_kron29  = c(0.61027, 0.57574, 0.82591, 0.55361, 0.77391),
  wasp_il_kron30  = c(1.00537, 2.28614, 1.09304, 2.03069, 0.94333),
  wasp_il_uni27   = c(0.35574, 0.29864, 0.29540, 0.30179, 0.35613),
  wasp_il_uni28   = c(0.88866, 0.95789, 1.04035, 0.87169, 0.81889),
  wasp_il_uni29   = c(1.42305, 1.51290, 2.20200, 1.29238, 1.42866),
  wasp_il_uni30   = c(3.13147, 2.41080, 2.30456, 2.28989, 2.49246),
  wasp_il_twitter = c(0.15932, 0.15896, 0.19770, 0.24953, 0.13550),
  wasp_il_web     = c(0.20368, 0.18863, 0.18351, 0.19027, 0.19005),
  wasp_il_road    = c(0.82392, 0.76485, 0.63280, 0.69207, 0.77911),
  
  # --- HYDRA Replicated (repl_order_9) ---
  hydra_ft_kron27  = c(0.39941, 0.29800, 0.24541, 0.29931, 0.26472),
  hydra_ft_kron28  = c(0.45786, 0.41634, 0.59446, 0.37978, 0.50311),
  hydra_ft_kron29  = c(1.08413, 0.83063, 0.68114, 0.83419, 1.13264),
  hydra_ft_kron30  = c(1.44842, 2.58800, 1.58603, 2.89163, 1.28970),
  hydra_ft_uni27   = c(0.81929, 0.65879, 0.67303, 0.76665, 0.65905),
  hydra_ft_uni28   = c(2.00960, 1.84905, 2.41788, 2.10091, 1.90960),
  hydra_ft_uni29   = c(2.93373, 3.02496, 6.25218, 2.67045, 2.97470),
  hydra_ft_uni30   = c(5.31154, 5.26837, 5.03181, 4.92181, 5.49664),
  hydra_ft_twitter = c(0.17027, 0.17673, 0.20505, 0.28116, 0.16631),
  hydra_ft_web     = c(0.30612, 0.33415, 0.29623, 0.29523, 0.31563),
  hydra_ft_road    = c(1.08329, 1.04928, 0.90961, 0.97021, 1.03769),
  
  # --- HYDRA Replicated+Interleaved (repl_order_9) ---
  hydra_il_kron27  = c(0.35079, 0.20624, 0.17250, 0.19449, 0.22235),
  hydra_il_kron28  = c(0.38683, 0.33695, 0.35768, 0.30188, 0.33931),
  hydra_il_kron29  = c(0.64828, 0.59462, 0.53788, 0.55256, 0.78890),
  hydra_il_kron30  = c(1.17613, 1.73788, 1.12181, 2.07758, 0.97412),
  hydra_il_uni27   = c(0.35819, 0.30027, 0.30293, 0.31082, 0.31426),
  hydra_il_uni28   = c(0.89305, 0.80852, 1.04394, 0.89700, 0.82442),
  hydra_il_uni29   = c(1.56209, 1.60389, 2.21582, 1.40118, 1.52736),
  hydra_il_uni30   = c(2.74216, 2.68902, 2.53779, 2.52880, 2.77665),
  hydra_il_twitter = c(0.15072, 0.16138, 0.20270, 0.24180, 0.13618),
  hydra_il_web     = c(0.21073, 0.19901, 0.19221, 0.19087, 0.19650),
  hydra_il_road    = c(1.14437, 1.13205, 0.97137, 1.01711, 1.10390)
)

# =============================================================================
# 3. Permutation test on Spearman rho
#    H0: rho <= 0 (no positive association)
#    H1: rho > 0  (larger RSS → more speedup)
#    One-sided test (greater)
# =============================================================================

perm_cor_test <- function(x, y, n_perm = 100000) {
  n <- length(x)
  obs_rho <- cor(x, y, method = "spearman")
  count <- 0
  for (i in seq_len(n_perm)) {
    perm_rho <- cor(sample(x), y, method = "spearman")
    if (perm_rho >= obs_rho) count <- count + 1
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
cat("  BFS: Spearman correlation between MaxRSS and Speedup vs Linux\n")
cat("  Permutation test (ONE-SIDED, H1: rho > 0, 100k permutations)\n")
cat("  11 graphs, mean speedup per graph\n")
cat("======================================================================\n\n")

# Print with formatted p-value column
print_results <- results[, c("System", "Policy", "Rho", "p_display", "Sig")]
colnames(print_results)[4] <- "p_value"
print(print_results, row.names = FALSE)

cat("\nInterpretation:\n")
cat("  H1: rho > 0 → larger working sets see MORE speedup over Linux\n")
cat("  Small p → reject H0 in favour of positive association\n")
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
cat("  The Spearman rho and one-sided permutation p-value above test this formally.\n")

# =============================================================================
# 6. Scatter plots (base R): Speedup vs MaxRSS, per system × policy
# =============================================================================

pdf("bfs_rss_speedup.pdf", width = 14, height = 10)
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
    # Annotate with rho and p (one-sided)
    legend("topleft",
           legend = paste0("rho = ", rho_val, ",  p = ", p_str, " ", sig_val,
                           " (one-sided)"),
           bty = "n", cex = 0.9)
    # Label points
    text(sub$MaxRSS, sub$Speedup, labels = sub$Graph,
         pos = 3, cex = 0.65, col = "gray30")
  }
}

dev.off()
cat("\nSaved plot to bfs_rss_speedup.pdf\n")
