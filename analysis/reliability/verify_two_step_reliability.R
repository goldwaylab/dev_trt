library(tidyverse)

source("config.R")
source(file.path("analysis", "reliability", "trt_reliability_core.R"))

ts_dir <- file.path(DATA_DIR, "parameter_estimates", "twostep")
fixed_lambda_path <- latest_file(ts_dir, "^two_step_fixed_lambda_samp10k_participant_estimates_.*\\.csv$")

param_labels <- c(
  alpha1 = "Learning Rate",
  beta1m = "Model-Based Beta",
  beta1t = "Model-Free Beta",
  beta2 = "Stage-2 Temperature",
  betac = "Stickiness"
)

df <- read_csv(fixed_lambda_path, show_col_types = FALSE) %>%
  left_join(
    read_csv(DEMOGRAPHICS_FILE, show_col_types = FALSE) %>%
      select(participant_ID = Participant.ID, Age),
    by = "participant_ID"
  ) %>%
  filter(!is.na(Age)) %>%
  mutate(
    z_age = as.numeric(scale(Age)),
    age_group = cut(Age, breaks = c(10, 15, 20, 26),
                    labels = c("10-15", "15-20", "20-25"), right = FALSE)
  )

cat("TwoStep fixed-lambda TRT reliability\n")
cat("Params file:", basename(fixed_lambda_path), "\n")
cat("N participants:", nrow(df), "\n\n")

cat("====== Overall Pearson r + 95% CI; Spearman rho ======\n")
for (p in names(param_labels)) {
  s1 <- paste0(p, "_session1_mean")
  s2 <- paste0(p, "_session2_mean")
  d <- df %>% filter(!is.na(.data[[s1]]), !is.na(.data[[s2]]))
  if (nrow(d) < 3) next
  pct <- cor.test(d[[s1]], d[[s2]], method = "pearson")
  sct <- cor.test(d[[s1]], d[[s2]], method = "spearman", exact = FALSE)
  cat(sprintf(
    "%-24s  r = %.3f [%.3f, %.3f]  rho = %.3f  n = %d\n",
    param_labels[p], pct$estimate, pct$conf.int[1], pct$conf.int[2],
    sct$estimate, nrow(d)
  ))
}

cat("\nMetrics CSV:", file.path(ts_dir, "two_step_fixed_lambda_samp10k_test_retest_reliability_metrics.csv"), "\n")
cat("Run FIT_TAG=samp10k Rscript analysis/reliability/export_tagged_trt_reliability.R to refresh the CSV.\n")
