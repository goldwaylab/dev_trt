library(tidyverse)

source("config.R")
source(file.path("analysis", "reliability", "trt_reliability_core.R"))

risk_dir <- file.path(DATA_DIR, "parameter_estimates", "risk")
risk_summary <- latest_file(risk_dir, "^risk_valence_asymmetry_samp10k_fit_summary_.*\\.tsv$")
risk_subjects <- latest_file(risk_dir, "^risk_valence_asymmetry_samp10k_fit_subjects_.*\\.csv$")

param_labels <- c(
  b1 = "Inverse Temperature",
  a1 = "Learning Rate (chosen, +PE)",
  a2 = "Learning Rate (chosen, -PE)",
  a3 = "Learning Rate (unchosen, +PE)",
  a4 = "Learning Rate (unchosen, -PE)",
  q0 = "Initial Q-value (q0)"
)

dat <- parse_risk_session_wide(risk_summary, risk_subjects, names(param_labels), param_labels, DEMOGRAPHICS_FILE)

cat("RISK valence-asymmetry TRT reliability\n")
cat("Summary:", basename(risk_summary), "\n")
cat("N subjects (age merge):", length(unique(dat$subject)), "\n\n")

cat("====== Overall Pearson r + 95% CI; Spearman rho ======\n")
for (p in names(param_labels)) {
  d <- dat %>% filter(parameter == p, !is.na(session_1), !is.na(session_2))
  if (nrow(d) < 3) next
  pct <- cor.test(d$session_1, d$session_2, method = "pearson")
  sct <- cor.test(d$session_1, d$session_2, method = "spearman", exact = FALSE)
  cat(sprintf(
    "%-32s  r = %.3f [%.3f, %.3f]  rho = %.3f  n = %d\n",
    param_labels[p], pct$estimate, pct$conf.int[1], pct$conf.int[2],
    sct$estimate, nrow(d)
  ))
}

cat("\n====== Age moderation (session_2 ~ session_1 * z_age) ======\n")
for (p in names(param_labels)) {
  d <- dat %>% filter(parameter == p, !is.na(z_age))
  m <- lm(session_2 ~ session_1 * z_age, data = d)
  sm <- summary(m)
  if ("session_1:z_age" %in% rownames(sm$coefficients)) {
    cat(sprintf(
      "%-32s  p = %.4f\n",
      param_labels[p],
      sm$coefficients["session_1:z_age", "Pr(>|t|)"]
    ))
  }
}

cat("\n====== By-age Pearson r ======\n")
for (p in names(param_labels)) {
  cat(sprintf("\n%s:\n", param_labels[p]))
  for (ag in c("10-15", "15-20", "20-25")) {
    d <- dat %>% filter(parameter == p, age_group == ag)
    if (nrow(d) >= 3) {
      cat(sprintf("  %s: r = %.3f (n = %d)\n", ag, cor(d$session_1, d$session_2), nrow(d)))
    }
  }
}
