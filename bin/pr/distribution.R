###############################################################################
###   PR: Does speedup over Linux depend on working-set size (maxRSS)?    ###
###   Permutation test on Spearman correlation, per system × policy       ###
###   ONE-SIDED test: H1: rho > 0 (larger RSS → more speedup)            ###
###############################################################################

# =============================================================================
# 1. MaxRSS for PR (GB), per graph
# =============================================================================

maxrss <- c(
  kron27 = 17.74, kron28 = 35.56, kron29 = 71.28, kron30 = 142.84,
  uni27  = 18.00, uni28  = 36.00, uni29  = 72.00, uni30  = 143.98,
  twitter = 12.32, web = 15.51, road = 0.95
)

# =============================================================================
# 2. Runtime data (5 trials per configuration) — from pr.R
# =============================================================================

rt <- list(
  # --- LINUX First-Touch ---
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
  
  # --- LINUX Interleaved ---
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
  
  # --- MITOSIS Replicated ---
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
  
  # --- MITOSIS Replicated+Interleaved ---
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
  
  # --- WASP First-Touch ---
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
  
  # --- WASP Interleaved ---
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
  
  # --- HYDRA Replicated (repl_order_9) ---
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
  
  # --- HYDRA Replicated+Interleaved (repl_order_9) ---
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
cat("  PR: Spearman correlation between MaxRSS and Speedup vs Linux\n")
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

pdf("pr_rss_speedup.pdf", width = 14, height = 10)
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
cat("\nSaved plot to pr_rss_speedup.pdf\n")
