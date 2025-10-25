# eps <- 1e-9  # tolerance for "zero"
#
# pd <- Morphometrics %>%
#   transmute(D = Calf_Age_Days,
#             P = Alaska_Difference_Positives_Only) %>%
#   filter(!is.na(D), !is.na(P)) %>%
#   arrange(D) %>%
#   group_by(D) %>%                      # collapse duplicate lengths, if any
#   summarise(P = median(P), .groups = "drop")
#
# if (!any(pd$P > eps)) {
#   # no positive excess anywhere
#   D_stop <- min(pd$D, na.rm = TRUE)
#   ExcessThermo_Area_Wm <- 0
#   pd_cut <- pd[0,]
# } else {
#   last_pos <- max(which(pd$P > eps))           # last positive value
#   cut_idx  <- min(last_pos + 1, nrow(pd))      # include first zero after it
#   pd_cut   <- pd[1:cut_idx, , drop = FALSE]
#   # trapezoidal integration
#   ExcessThermo_Area_Wm <- sum(diff(pd_cut$D) * (head(pd_cut$P, -1) + tail(pd_cut$P, -1)) / 2)
#   D_stop <- pd$D[cut_idx]
# }
#
# # ---- Bootstrap uncertainty around the trapezoid AUC ----
# set.seed(42)
# B   <- 2000        # number of bootstrap replicates
# eps <- 1e-9
#
# base_df <- Morphometrics %>%
#   transmute(D = Calf_Age_Days, P = Alaska_Difference_Positives_Only) %>%
#   filter(!is.na(D), !is.na(P))
# n <- nrow(base_df)
#
# # grid for drawing a band (use your cut curve domain)
# D_grid <- pd_cut$D
# if (length(D_grid) < 2) D_grid <- seq(min(base_df$D), max(base_df$D), length.out = 200)
#
# boot_one <- function() {
#   d <- base_df[sample.int(n, replace = TRUE), , drop = FALSE] %>%
#     arrange(D) %>%
#     group_by(D) %>% summarise(P = median(P), .groups = "drop")
#
#   if (!any(d$P > eps) || nrow(d) < 2) {
#     return(list(AUC = 0, Pg = rep(0, length(D_grid))))
#   }
#
#   last_pos <- max(which(d$P > eps))
#   cut_idx  <- min(last_pos + 1, nrow(d))
#   d_cut    <- d[1:cut_idx, , drop = FALSE]
#
#   AUC <- sum(diff(d_cut$D) * (head(d_cut$P, -1) + tail(d_cut$P, -1)) / 2)
#
#   # interpolate onto common grid; force beyond cut to 0
#   Pg  <- approx(d_cut$D, d_cut$P, xout = D_grid, rule = 2, yright = 0)$y
#   Pg[is.na(Pg)] <- 0
#   list(AUC = AUC, Pg = Pg)
# }
#
# boot_res <- replicate(B, boot_one(), simplify = FALSE)
# AUCs     <- vapply(boot_res, `[[`, numeric(1), "AUC")
# Pg_mat   <- do.call(cbind, lapply(boot_res, `[[`, "Pg"))
#
# # 95% CI on AUC (units: W·day)
# AUC_CI <- quantile(AUCs, c(0.025, 0.5, 0.975), na.rm = TRUE)
# AUC_Wday <- ExcessThermo_Area_Wm      # your original trapezoid (now W·day)
#
# # Convert AUC to energy (optional): Joules & MJ
# AUC_J  <- AUC_Wday * 86400
# AUC_MJ <- AUC_J / 1e6
# AUC_CI_MJ <- AUC_CI * 86400 / 1e6
#
# cat(sprintf(
#   "AUC (birth → day %.0f): %.0f W·day  [95%% CI: %.0f, %.0f]\nEnergy ≈ %.1f MJ  [95%% CI: %.1f, %.1f]\n",
#   max(pd_cut$D), AUC_Wday, AUC_CI[1], AUC_CI[3], AUC_MJ, AUC_CI_MJ[1], AUC_CI_MJ[3]
# ))
#
# # Band (2.5–97.5th percentile) around the piecewise-linear curve you integrate
# band_df <- tibble(
#   D  = D_grid,
#   lo = apply(Pg_mat, 1, quantile, probs = 0.025, na.rm = TRUE),
#   hi = apply(Pg_mat, 1, quantile, probs = 0.975, na.rm = TRUE)
# )
#
# pAlaskaDiffBMRvsBL <- ggplot(Morphometrics, aes(x = Calf_Age_Days)) +
#   # 95% bootstrap band around the trapezoid curve
#   geom_ribbon(data = band_df, aes(x = D, ymin = lo, ymax = hi),
#               inherit.aes = FALSE, alpha = 0.12) +
#   # shaded area actually integrated (deterministic trapezoid)
#   geom_ribbon(data = pd_cut, aes(x = D, ymin = 0, ymax = P),
#               inherit.aes = FALSE, alpha = 0.25, fill = "purple") +
#   geom_point(aes(y = Alaska_Difference_Positives_Only), size = 0.8) +
#   annotate("text", x = max(pd_cut$D), y = 380, hjust = 1, vjust = 1.1,
#            label = sprintf("AUC = %.0f W·day\n(95%% CI %.0f–%.0f)", AUC_Wday, AUC_CI[1], AUC_CI[3])) +
#   scale_x_continuous(expand = c(0, 0)) +
#   scale_y_continuous(limits = c(0, 400),
#                      breaks = seq(0, 400, by = 50),
#                      labels = seq(0, 400, by = 50),
#                      expand = c(0, 0)) +
#   labs(x = "Calf Age (days)",
#        y = "Alaska Heat Loss Above Kleiber BMR (W)") +
#   theme_classic(base_size = 8) +
#   theme(axis.text = element_text(size = 40),
#         axis.title.x = element_text(size = 60, margin = margin(t = 30)),
#         axis.title.y = element_text(size = 30, margin = margin(r = 10)),
#         axis.line = element_line(color = "black", size = 1),
#         legend.position = "none",
#        panel.grid.minor = element_blank())
