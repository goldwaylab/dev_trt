#!/usr/bin/env Rscript
# Scatter panels + triggers dotplots for canonical TRT models:
#   RISK risk_valence_asymmetry, PIT pit_pavlovian_bias, TwoStep fixed-lambda.

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(patchwork)
})

source("config.R")
source(file.path("analysis", "reliability", "trt_reliability_core.R"))

plot_trt_scatter_grid <- function(wide, param_ids, param_labels, title, ncol = 2) {
  plots <- lapply(param_ids, function(pid) {
    d <- wide %>%
      filter(parameter == pid, !is.na(session_1), !is.na(session_2), !is.na(age_group))
    r <- if (nrow(d) >= 2) cor(d$session_1, d$session_2, method = "pearson") else NA_real_
    ggplot(d, aes(x = session_1, y = session_2, color = age_group)) +
      geom_point(size = 2, alpha = 0.85) +
      scale_color_brewer(palette = "Set1") +
      geom_smooth(method = "lm", se = TRUE, aes(group = age_group), linewidth = 0.9) +
      labs(
        title = param_labels[[pid]],
        x = "Session 1",
        y = "Session 2",
        color = "Age group"
      ) +
      theme_minimal(base_size = 12) +
      theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
      annotate(
        "text",
        x = mean(range(d$session_1, na.rm = TRUE)),
        y = max(d$session_2, na.rm = TRUE),
        label = if (is.na(r)) "Pearson: NA" else sprintf("Pearson: %.2f", r),
        hjust = 0.5,
        vjust = 1.2,
        size = 3.5
      )
  })
  combined <- wrap_plots(plots, ncol = ncol, guides = "collect") &
    theme(legend.position = "bottom")
  list(plot = combined, title = title)
}

save_trt_scatter <- function(obj, stem) {
  png <- file.path(FIGURES_DIR, paste0(stem, ".png"))
  pdf <- file.path(FIGURES_DIR, paste0(stem, ".pdf"))
  ggsave(png, obj$plot, width = 10, height = ifelse(grepl("RISK", obj$title), 12, 8), dpi = 300, bg = "white")
  ggsave(pdf, obj$plot, width = 10, height = ifelse(grepl("RISK", obj$title), 12, 8), bg = "white")
  cat("Saved", png, "\n")
}

# ---- RISK valence asymmetry ----
risk_dir <- file.path(DATA_DIR, "parameter_estimates", "risk")
risk_labels <- c(
  b1 = "Inverse Temperature",
  a1 = "LR chosen (+PE)",
  a2 = "LR chosen (-PE)",
  a3 = "LR unchosen (+PE)",
  a4 = "LR unchosen (-PE)",
  q0 = "Initial Q (q0)"
)
risk_wide <- parse_risk_session_wide(
  latest_file(risk_dir, "^risk_valence_asymmetry_samp10k_fit_summary_.*\\.tsv$"),
  latest_file(risk_dir, "^risk_valence_asymmetry_samp10k_fit_subjects_.*\\.csv$"),
  names(risk_labels),
  risk_labels,
  DEMOGRAPHICS_FILE
)
risk_plot <- plot_trt_scatter_grid(risk_wide, names(risk_labels), risk_labels, "RISK valence asymmetry", ncol = 3)
save_trt_scatter(risk_plot, "risk_trt_scatter")

# ---- PIT Pavlovian bias ----
pit_labels <- c(
  b1 = "Reward Sensitivity",
  b2 = "Punishment Sensitivity",
  b3 = "Approach Bias",
  b4 = "Avoidance Bias",
  a1 = "Positive Learning Rate",
  a2 = "Negative Learning Rate"
)
pit_wide <- read_csv(PIT_PARAMETER_ESTIMATES, show_col_types = FALSE) %>%
  filter(parameter %in% names(pit_labels), !is.na(param_value)) %>%
  mutate(parameter_label = pit_labels[parameter]) %>%
  pivot_wider(names_from = session, values_from = param_value, names_prefix = "session_") %>%
  left_join(
    read_csv(DEMOGRAPHICS_FILE, show_col_types = FALSE) %>%
      transmute(subject_id = Participant.ID, Age),
    by = "subject_id"
  ) %>%
  mutate(
    age_group = cut(Age, breaks = c(10, 15, 20, 26),
                    labels = c("10-15", "15-20", "20-25"), right = FALSE)
  )
pit_plot <- plot_trt_scatter_grid(pit_wide, names(pit_labels), pit_labels, "PIT Pavlovian bias")
save_trt_scatter(pit_plot, "pit_trt_scatter")
ggsave(file.path(FIGURES_DIR, "PIT_TRT.png"), pit_plot$plot, width = 8, height = 8, dpi = 300, bg = "white")
cat("Saved", file.path(FIGURES_DIR, "PIT_TRT.png"), "\n")

# ---- TwoStep fixed lambda ----
ts_dir <- file.path(DATA_DIR, "parameter_estimates", "twostep")
fixed_lambda <- read_csv(latest_file(ts_dir, "^two_step_fixed_lambda_samp10k_participant_estimates_.*\\.csv$"), show_col_types = FALSE) %>%
  left_join(
    read_csv(DEMOGRAPHICS_FILE, show_col_types = FALSE) %>%
      transmute(participant_ID = Participant.ID, Age),
    by = "participant_ID"
  ) %>%
  mutate(
    age_group = cut(Age, breaks = c(10, 15, 20, 26),
                    labels = c("10-15", "15-20", "20-25"), right = FALSE)
  )
fixed_lambda_labels <- c(
  alpha1 = "Learning Rate",
  beta1m = "Model-Based Beta",
  beta1t = "Model-Free Beta",
  beta2 = "Stage-2 Temperature",
  betac = "Stickiness"
)
fixed_lambda_wide <- map_dfr(names(fixed_lambda_labels), function(p) {
  fixed_lambda %>%
    transmute(
      parameter = p,
      parameter_label = fixed_lambda_labels[[p]],
      session_1 = .data[[paste0(p, "_session1_mean")]],
      session_2 = .data[[paste0(p, "_session2_mean")]],
      age_group
    )
})
save_trt_scatter(
  plot_trt_scatter_grid(fixed_lambda_wide, names(fixed_lambda_labels), fixed_lambda_labels, "TwoStep fixed-lambda"),
  "two_step_fixed_lambda_trt_scatter"
)

cat("\nRun Python dotplot scripts from repo root:\n")
cat("  python3 analysis/figures/plot_risk_reliability_dotplot.py\n")
cat("  python3 analysis/figures/plot_pit_reliability_dotplot.py\n")
cat("  python3 analysis/figures/plot_two_step_reliability_dotplot.py\n")
