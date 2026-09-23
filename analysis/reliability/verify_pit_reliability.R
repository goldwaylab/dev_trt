library(tidyverse)

source("config.R")

pit_data <- read_csv(PIT_PARAMETER_ESTIMATES, show_col_types = FALSE) %>%
  filter(!is.na(param_value))

cat("Unique parameters:", paste(unique(pit_data$parameter), collapse = ", "), "\n")
cat("Unique sessions:", paste(sort(unique(pit_data$session)), collapse = ", "), "\n")
cat("N unique subjects:", length(unique(pit_data$subject_id)), "\n\n")

param_labels <- c(
  "b1" = "Reward Sensitivity",
  "b2" = "Punishment Sensitivity",
  "b3" = "Approach Bias",
  "b4" = "Avoidance Bias",
  "a1" = "Positive Learning Rate",
  "a2" = "Negative Learning Rate"
)

pit_wide <- pit_data %>%
  select(parameter, session, subject_id, age, param_value) %>%
  pivot_wider(names_from = session, values_from = param_value, names_prefix = "session_") %>%
  filter(!is.na(session_1), !is.na(session_2)) %>%
  mutate(
    z_age = as.numeric(scale(age)),
    age_group = cut(age, breaks = c(10, 15, 20, 26),
                    labels = c("10-15", "15-20", "20-25"),
                    right = FALSE)
  )

cat("N subjects with both sessions:", length(unique(pit_wide$subject_id)), "\n\n")

cat("====== STEP 1: Overall Pearson r + analytical 95% CIs ======\n")
for (p in names(param_labels)) {
  d <- pit_wide %>% filter(parameter == p)
  if (nrow(d) < 3) { cat(sprintf("%-25s  insufficient data\n", param_labels[p])); next }
  ct <- cor.test(d$session_1, d$session_2, method = "pearson")
  cat(sprintf("%-25s  r = %.3f  [%.3f, %.3f]  n = %d\n",
              param_labels[p], ct$estimate, ct$conf.int[1], ct$conf.int[2], nrow(d)))
}

cat("\nManuscript values:\n")
cat("  Positive Learning Rate:  r = 0.948 [0.929, 0.962]\n")
cat("  Negative Learning Rate:  r = 0.945 [0.926, 0.960]\n")
cat("  Reward Sensitivity:      r = 0.840 [0.786, 0.881]\n")
cat("  Punishment Sensitivity:  r = 0.737 [0.655, 0.801]\n")
cat("  Approach Bias:           r = 0.735 [0.653, 0.800]\n")
cat("  Avoidance Bias:          r = 0.703 [0.613, 0.774]\n\n")

cat("====== STEP 2: Age moderation (session_2 ~ session_1 * z_age) ======\n")
for (p in names(param_labels)) {
  d <- pit_wide %>% filter(parameter == p, !is.na(z_age))
  if (nrow(d) < 5) { cat(sprintf("%-25s  insufficient data\n", param_labels[p])); next }
  m <- lm(session_2 ~ session_1 * z_age, data = d)
  sm <- summary(m)
  int_term <- "session_1:z_age"
  if (int_term %in% rownames(sm$coefficients)) {
    t_val <- sm$coefficients[int_term, "t value"]
    p_val <- sm$coefficients[int_term, "Pr(>|t|)"]
    cat(sprintf("%-25s  t = %6.3f, p = %.4f  n = %d  %s\n",
                param_labels[p], t_val, p_val, nrow(d),
                ifelse(p_val < 0.05, " *", "")))
  }
}

cat("\nManuscript: 'All parameters exhibited stable reliability across age' (no sig interactions)\n\n")

cat("====== STEP 3: By-age group correlations (5-year bins) ======\n")
for (p in names(param_labels)) {
  cat(sprintf("\n%s:\n", param_labels[p]))
  for (ag in c("10-15", "15-20", "20-25")) {
    d <- pit_wide %>% filter(parameter == p, age_group == ag)
    if (nrow(d) >= 3) {
      r <- cor(d$session_1, d$session_2, use = "complete.obs")
      cat(sprintf("  %s: r = %.3f  (n = %d)\n", ag, r, nrow(d)))
    } else {
      cat(sprintf("  %s: insufficient data (n = %d)\n", ag, nrow(d)))
    }
  }
}
