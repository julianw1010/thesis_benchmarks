###############################################################################
### CC_SV: Does speedup over Linux depend on working-set size (maxRSS)?   ###
###   Permutation test on Spearman correlation, per system × policy       ###
###############################################################################

# =============================================================================
# 1. MaxRSS for CC_SV (GB), per graph
# =============================================================================

maxrss <- c(
  kron27 = 17.74, kron28 = 35.56, kron29 = 71.28, kron30 = 142.84,
  uni27  = 18.00, uni28  = 36.00, uni29  = 72.00, uni30  = 143.98,
  twitter = 12.28, web = 15.51, road = 0.86
)

# =============================================================================
# 2. Runtime data (5 trials per configuration) — from cc_sv.R
# =============================================================================

rt <- list(
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
cat("  CC_SV: Spearman correlation between MaxRSS and Speedup vs Linux\n")
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

pdf("cc_sv_rss_speedup.pdf", width = 14, height = 10)
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
cat("\nSaved plot to cc_sv_rss_speedup.pdf\n")