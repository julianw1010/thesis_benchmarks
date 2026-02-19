###############################################################################
###   BC: Does speedup over Linux depend on working-set size (maxRSS)?    ###
###   Permutation test on Spearman correlation, per system × policy       ###
###   ONE-SIDED test: H1: rho > 0 (larger RSS → more speedup)            ###
###############################################################################

# =============================================================================
# 1. MaxRSS for BC (GB), per graph
# =============================================================================

maxrss <- c(
  kron27 = 19.42, kron28 = 38.95, kron29 = 78.09, kron30 = 156.41,
  uni27  = 19.96, uni28  = 39.96, uni29  = 79.97, uni30  = 159.95,
  twitter = 13.03, web = 16.27, road = 1.21
)

# =============================================================================
# 2. Runtime data (5 trials per configuration)
# =============================================================================

rt <- list(
  linux_ft_kron27  = c(4.90674, 4.96771, 5.48193, 5.02660, 5.09110),
  linux_ft_kron28  = c(8.66935, 7.96993, 7.66010, 8.59287, 8.44211),
  linux_ft_kron29  = c(13.83380, 13.40707, 15.90102, 16.52888, 12.56563),
  linux_ft_kron30  = c(30.47549, 24.46888, 26.59006, 24.17824, 30.28428),
  linux_ft_uni27   = c(4.49935, 4.88154, 4.67789, 4.62772, 4.67098),
  linux_ft_uni28   = c(7.83971, 7.70742, 8.31134, 7.95331, 7.69698),
  linux_ft_uni29   = c(19.07057, 18.78238, 18.31517, 19.96941, 19.16277),
  linux_ft_uni30   = c(44.19197, 44.22043, 44.82875, 44.88824, 43.75288),
  linux_ft_twitter = c(2.79832, 2.83259, 2.89126, 2.94861, 2.68645),
  linux_ft_web     = c(0.56284, 0.56385, 0.54737, 0.54768, 0.55913),
  linux_ft_road    = c(0.90824, 0.82680, 0.72948, 0.75101, 0.84794),
  
  linux_il_kron27  = c(4.78605, 4.80686, 5.32972, 4.88197, 4.94169),
  linux_il_kron28  = c(8.78344, 8.16744, 7.59457, 8.71115, 8.53845),
  linux_il_kron29  = c(14.67579, 14.27705, 16.77364, 17.36504, 13.46484),
  linux_il_kron30  = c(32.14990, 26.36196, 28.50570, 26.00222, 31.92770),
  linux_il_uni27   = c(4.45827, 4.85439, 4.63438, 4.57764, 4.63659),
  linux_il_uni28   = c(8.07637, 7.91224, 8.57368, 8.15370, 7.96101),
  linux_il_uni29   = c(19.34791, 18.94564, 18.68820, 20.09955, 19.44714),
  linux_il_uni30   = c(45.51456, 45.52018, 45.91590, 45.97901, 45.23997),
  linux_il_twitter = c(2.40730, 2.49194, 2.51397, 2.60181, 2.31846),
  linux_il_web     = c(0.63231, 0.62291, 0.61419, 0.61734, 0.61973),
  linux_il_road    = c(0.93294, 0.90746, 0.76829, 0.82686, 0.91374),
  
  mitosis_ft_kron27  = c(5.08943, 5.09223, 5.66944, 5.19282, 5.21109),
  mitosis_ft_kron28  = c(8.03232, 7.82265, 7.48766, 7.91312, 8.10096),
  mitosis_ft_kron29  = c(12.17419, 12.10902, 13.56354, 14.09708, 11.64859),
  mitosis_ft_kron30  = c(24.66819, 20.49666, 21.83207, 20.19227, 24.48602),
  mitosis_ft_uni27   = c(4.45350, 4.84387, 4.62721, 4.57454, 4.62608),
  mitosis_ft_uni28   = c(7.11425, 6.90640, 7.52905, 7.12829, 6.98391),
  mitosis_ft_uni29   = c(16.47907, 16.10452, 15.85754, 17.09980, 16.47427),
  mitosis_ft_uni30   = c(37.64579, 37.63634, 37.86626, 37.90930, 37.41111),
  mitosis_ft_twitter = c(2.80177, 2.93838, 2.92116, 2.94509, 2.72999),
  mitosis_ft_web     = c(0.62412, 0.60591, 0.58794, 0.59651, 0.59699),
  mitosis_ft_road    = c(0.91552, 0.86029, 0.75084, 0.77058, 0.86449),
  
  mitosis_il_kron27  = c(4.82961, 4.86178, 5.42735, 4.93838, 4.96478),
  mitosis_il_kron28  = c(8.13021, 7.97274, 7.45024, 8.03725, 8.22198),
  mitosis_il_kron29  = c(12.84424, 12.62010, 14.36629, 14.84357, 12.32402),
  mitosis_il_kron30  = c(26.12686, 21.83224, 23.37164, 21.52263, 26.13876),
  mitosis_il_uni27   = c(4.41578, 4.83622, 4.58820, 4.54855, 4.61277),
  mitosis_il_uni28   = c(7.41676, 7.23546, 7.83681, 7.45211, 7.29741),
  mitosis_il_uni29   = c(17.22051, 16.84425, 16.65631, 17.86328, 17.29693),
  mitosis_il_uni30   = c(39.26459, 39.27833, 39.52680, 39.63546, 39.10956),
  mitosis_il_twitter = c(2.45264, 2.52897, 2.54264, 2.59104, 2.32402),
  mitosis_il_web     = c(0.68462, 0.64520, 0.64137, 0.64194, 0.65933),
  mitosis_il_road    = c(0.95611, 0.91802, 0.77916, 0.83655, 0.92218),
  
  wasp_ft_kron27  = c(4.92331, 5.00528, 5.49145, 5.04405, 5.07984),
  wasp_ft_kron28  = c(7.94314, 7.69423, 7.49966, 7.98564, 8.07372),
  wasp_ft_kron29  = c(12.52307, 12.04250, 13.60196, 14.16287, 11.76300),
  wasp_ft_kron30  = c(25.50050, 21.13473, 22.76175, 20.74872, 25.69785),
  wasp_ft_uni27   = c(4.42025, 4.84760, 4.62403, 4.58977, 4.62172),
  wasp_ft_uni28   = c(7.42548, 6.99967, 7.52242, 7.20247, 7.00609),
  wasp_ft_uni29   = c(16.67157, 16.10010, 15.88236, 17.11762, 16.51276),
  wasp_ft_uni30   = c(37.99265, 38.84381, 38.75248, 38.97097, 38.09107),
  wasp_ft_twitter = c(2.84589, 2.93132, 2.93581, 2.96456, 2.74040),
  wasp_ft_web     = c(0.56359, 0.55327, 0.56454, 0.54808, 0.55989),
  wasp_ft_road    = c(0.90751, 0.85162, 0.75002, 0.79521, 0.85946),
  
  wasp_il_kron27  = c(4.79413, 4.82933, 5.40100, 4.92988, 4.94032),
  wasp_il_kron28  = c(8.21073, 7.86941, 7.51824, 8.06240, 8.22909),
  wasp_il_kron29  = c(13.29821, 12.74501, 15.04758, 15.36072, 12.46427),
  wasp_il_kron30  = c(27.10790, 22.54183, 24.65710, 22.28141, 27.59926),
  wasp_il_uni27   = c(4.48185, 4.81685, 4.62983, 4.51850, 4.62588),
  wasp_il_uni28   = c(7.69394, 7.24862, 7.86016, 7.46305, 7.30513),
  wasp_il_uni29   = c(17.54968, 17.64655, 16.68436, 18.53099, 17.35638),
  wasp_il_uni30   = c(40.07167, 39.88642, 40.17865, 40.21686, 40.21491),
  wasp_il_twitter = c(2.46543, 2.51656, 2.54752, 2.62221, 2.34647),
  wasp_il_web     = c(0.64557, 0.62261, 0.61999, 0.61844, 0.63775),
  wasp_il_road    = c(0.99775, 0.93492, 0.82396, 0.84638, 0.96438),
  
  hydra_ft_kron27  = c(4.98719, 5.01230, 5.59173, 5.11344, 5.10233),
  hydra_ft_kron28  = c(7.89403, 7.67714, 7.47336, 7.98161, 8.16017),
  hydra_ft_kron29  = c(12.19525, 11.98156, 13.48334, 14.05485, 11.63432),
  hydra_ft_kron30  = c(24.22452, 20.13112, 21.42900, 19.80251, 24.16154),
  hydra_ft_uni27   = c(4.37346, 4.80972, 4.58331, 4.52122, 4.60576),
  hydra_ft_uni28   = c(7.06685, 6.88440, 7.50384, 7.10232, 6.96770),
  hydra_ft_uni29   = c(16.36981, 15.97858, 15.74845, 16.98174, 16.39432),
  hydra_ft_uni30   = c(37.46504, 37.46699, 37.70730, 37.71466, 37.21890),
  hydra_ft_twitter = c(2.79418, 2.90264, 2.92008, 2.96016, 2.70981),
  hydra_ft_web     = c(0.60778, 0.60674, 0.60390, 0.59455, 0.59883),
  hydra_ft_road    = c(1.12312, 1.06045, 0.95911, 1.00513, 1.05548),
  
  hydra_il_kron27  = c(4.76204, 4.83331, 5.35887, 4.89642, 4.91473),
  hydra_il_kron28  = c(8.06233, 7.97022, 7.51719, 8.11517, 8.18792),
  hydra_il_kron29  = c(12.77821, 12.68349, 14.20056, 14.69924, 12.25762),
  hydra_il_kron30  = c(26.00465, 21.58025, 23.07030, 21.30307, 25.90409),
  hydra_il_uni27   = c(4.35317, 4.77772, 4.56465, 4.50377, 4.55864),
  hydra_il_uni28   = c(7.40846, 7.26121, 7.84156, 7.45651, 7.31540),
  hydra_il_uni29   = c(17.23995, 16.84680, 16.63796, 17.87983, 17.27434),
  hydra_il_uni30   = c(39.34325, 39.32475, 39.53341, 39.52368, 39.09657),
  hydra_il_twitter = c(2.43087, 2.50876, 2.52796, 2.59600, 2.37917),
  hydra_il_web     = c(0.66161, 0.64531, 0.65673, 0.65076, 0.65633),
  hydra_il_road    = c(1.18956, 1.14501, 1.01715, 1.05209, 1.15011)
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
cat("  BC: Spearman correlation between MaxRSS and Speedup vs Linux\n")
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

pdf("bc_rss_speedup.pdf", width = 14, height = 10)
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
cat("\nSaved plot to bc_rss_speedup.pdf\n")
