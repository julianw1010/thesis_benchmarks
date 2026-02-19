###############################################################################
### PR_SPMV: Does speedup over Linux depend on working-set size (maxRSS)? ###
###   Permutation test on Spearman correlation, per system × policy       ###
###   ONE-SIDED test: H1: rho > 0 (larger RSS → more speedup)            ###
###############################################################################

# =============================================================================
# 1. MaxRSS for PR_SPMV (GB), per graph
# =============================================================================

maxrss <- c(
  kron27 = 17.74, kron28 = 35.56, kron29 = 71.28, kron30 = 142.84,
  uni27  = 18.00, uni28  = 36.00, uni29  = 72.00, uni30  = 143.98,
  twitter = 12.32, web = 15.51, road = 0.95
)

# =============================================================================
# 2. Runtime data (5 trials per configuration) — from pr_spmv.R
# =============================================================================

rt <- list(
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
cat("  PR_SPMV: Spearman correlation between MaxRSS and Speedup vs Linux\n")
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

pdf("pr_spmv_rss_speedup.pdf", width = 14, height = 10)
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
cat("\nSaved plot to pr_spmv_rss_speedup.pdf\n")
