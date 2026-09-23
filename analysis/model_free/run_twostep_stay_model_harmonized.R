#!/usr/bin/env Rscript

Sys.setenv(VROOM_CONNECTION_SIZE = 1048576)
suppressPackageStartupMessages({
  library(tidyverse)
  library(afex)
  library(lme4)
  library(emmeans)
  library(broom)
})
source("config.R")

read_behav <- function(path, sess) {
  readr::read_csv(path, show_col_types = FALSE, col_types = cols(.default = col_character())) %>%
    mutate(session = sess)
}

compute_subject_mb_effect <- function(df) {
  df %>%
    group_by(participant_ID, age_group, age, session, previous_reward, previous_transition) %>%
    summarise(stay_mean = mean(stay, na.rm = TRUE), .groups = "drop") %>%
    tidyr::pivot_wider(
      names_from = c(previous_reward, previous_transition),
      values_from = stay_mean
    ) %>%
    mutate(
      mb_effect = (`Reward_common` - `Reward_rare`) - (`No Reward_common` - `No Reward_rare`)
    ) %>%
    filter(!is.na(mb_effect))
}

behav <- bind_rows(read_behav(TWOSTEP_BEHAVIORAL_S1, 1), read_behav(TWOSTEP_BEHAVIORAL_S2, 2)) %>%
  mutate(
    participant_ID = as.character(participant_ID),
    age = suppressWarnings(as.numeric(age)),
    trial = suppressWarnings(as.numeric(trial)),
    choice_1 = suppressWarnings(as.numeric(choice_1)),
    reward = suppressWarnings(as.numeric(reward)),
    transition = str_to_lower(as.character(transition)),
    session = suppressWarnings(as.numeric(session))
  ) %>%
  filter(
    practice_trial == "real",
    !is.na(participant_ID),
    !is.na(age),
    !is.na(choice_1),
    !is.na(reward),
    !is.na(transition)
  )

participants_with_both <- behav %>%
  distinct(participant_ID, session) %>%
  count(participant_ID) %>%
  filter(n == 2) %>%
  pull(participant_ID)

db <- behav %>%
  filter(participant_ID %in% participants_with_both) %>%
  arrange(participant_ID, session, trial) %>%
  group_by(participant_ID, session, age) %>%
  mutate(
    previous_reward = lag(reward),
    previous_transition = lag(transition),
    previous_choice = lag(choice_1)
  ) %>%
  ungroup() %>%
  mutate(
    stay = if_else(previous_choice == choice_1, 1, 0),
    age_z = as.numeric(scale(age)),
    age_group = case_when(
      age < 13 ~ "Children",
      age >= 13 & age < 18 ~ "Adolescents",
      age >= 18 ~ "Adults",
      TRUE ~ NA_character_
    ),
    age_group = factor(age_group, levels = c("Children", "Adolescents", "Adults")),
    previous_reward = factor(
      if_else(as.numeric(previous_reward) == 1, "Reward", "No Reward"),
      levels = c("No Reward", "Reward")
    ),
    previous_transition = factor(
      previous_transition,
      levels = c("common", "rare")
    ),
    session = factor(session, levels = c(1, 2), labels = c("Session 1", "Session 2"))
  ) %>%
  filter(
    !is.na(previous_reward),
    !is.na(previous_transition),
    !is.na(previous_choice),
    !is.na(age_group)
  )

model_rds <- "analysis/model_free/twostep_stay_model_harmonized.rds"
refit <- identical(Sys.getenv("TWOSTEP_STAY_REFIT", "0"), "1") || !file.exists(model_rds)

if (refit) {
  model <- mixed(
    stay ~ previous_reward * previous_transition * age_z * session + (previous_reward * previous_transition | participant_ID),
    family = "binomial",
    data = db,
    control = glmerControl(optimizer = "bobyqa"),
    method = "LRT"
  )
  saveRDS(model, model_rds)
} else {
  model <- readRDS(model_rds)
}

tab <- as.data.frame(nice(model))
out_csv <- "analysis/model_free/twostep_stay_model_nice_table.csv"
write.csv(tab, out_csv, row.names = FALSE)

anova_tab <- as.data.frame(anova(model, type = 3))
anova_csv <- "analysis/model_free/twostep_stay_model_anova_type3.csv"
write.csv(anova_tab, anova_csv, row.names = TRUE)

coef_tab <- as.data.frame(summary(model)$coefficients)
coef_tab$term <- rownames(coef_tab)
rownames(coef_tab) <- NULL
coef_csv <- "analysis/model_free/twostep_stay_model_coefficients.csv"
write.csv(coef_tab, coef_csv, row.names = FALSE)

interaction_row <- coef_tab %>%
  filter(grepl("previous_reward.*previous_transition.*age_z", term, perl = TRUE)) %>%
  filter(!grepl("session", term))
if (nrow(interaction_row) != 1) {
  stop("Could not uniquely identify age x MB interaction coefficient.")
}
interaction_term <- interaction_row$term[1]

interaction_beta <- unname(interaction_row$Estimate)
interaction_se <- unname(interaction_row$`Std. Error`)
interaction_z <- unname(interaction_row$`z value`)
interaction_p <- 2 * pnorm(-abs(interaction_z))
interaction_or <- exp(interaction_beta)

# Model-predicted reward x transition interaction across age.
ref_session <- levels(db$session)[1]
emm_age <- emmeans(
  model,
  ~ previous_reward * previous_transition | age_z,
  at = list(age_z = c(-1, 0, 1), session = ref_session),
  type = "link"
)
mb_by_age <- contrast(
  emm_age,
  method = list(mb_contrast = c(1, -1, -1, 1))
) %>%
  summary(infer = TRUE) %>%
  as.data.frame() %>%
  mutate(
    validation = "model_predicted_mb_contrast_by_age_z",
    session = ref_session
  )

age_trend <- emtrends(
  model,
  ~ previous_reward * previous_transition | session,
  var = "age_z",
  at = list(session = ref_session)
)
age_trend_tab <- contrast(
  age_trend,
  method = list(mb_contrast_trend = c(1, -1, -1, 1))
) %>%
  summary(infer = TRUE) %>%
  as.data.frame() %>%
  mutate(
    validation = "model_mb_contrast_slope_by_age_z",
    session = ref_session,
    trend_estimate = estimate
  )

subject_mb <- compute_subject_mb_effect(db) %>%
  group_by(participant_ID, age_group, age) %>%
  summarise(mb_effect = mean(mb_effect, na.rm = TRUE), .groups = "drop")

age_group_desc <- subject_mb %>%
  group_by(age_group) %>%
  summarise(
    n = n(),
    mean_mb = mean(mb_effect, na.rm = TRUE),
    se_mb = sd(mb_effect, na.rm = TRUE) / sqrt(n()),
  ) %>%
  mutate(validation = "subject_level_mb_by_age_group")

age_lm <- lm(mb_effect ~ age, data = subject_mb)
age_lm_tab <- broom::tidy(age_lm, conf.int = TRUE) %>%
  filter(term == "age") %>%
  mutate(validation = "subject_level_mb_vs_age_linear")

age_spearman <- cor.test(subject_mb$age, subject_mb$mb_effect, method = "spearman", exact = FALSE)
age_spearman_tab <- tibble(
  validation = "subject_level_mb_vs_age_spearman",
  estimate = unname(age_spearman$estimate),
  p_value = age_spearman$p.value,
  n = nrow(subject_mb)
)

age_group_ordinal <- lm(mb_effect ~ as.numeric(age_group), data = subject_mb)
age_group_ordinal_tab <- broom::tidy(age_group_ordinal, conf.int = TRUE) %>%
  filter(term == "as.numeric(age_group)") %>%
  mutate(validation = "subject_level_mb_vs_age_group_ordinal")

direction_summary <- bind_rows(
  tibble(
    validation = "glmm_interaction_term",
    term = interaction_term,
    estimate = interaction_beta,
    std_error = interaction_se,
    statistic = interaction_z,
    p_value = interaction_p,
    odds_ratio = interaction_or,
    direction = if_else(interaction_beta < 0, "strengthens_with_age", "weakens_with_age"),
    interpretation = paste0(
      "With contr.sum coding, the reward x transition x age_z interaction ",
      if_else(interaction_beta < 0, "strengthens", "weakens"),
      " (beta = ", sprintf("%.3f", interaction_beta),
      ", p = ", format.pval(interaction_p, digits = 3),
      "); see emtrends MB-contrast slope for interpretable direction."
    )
  ),
  age_trend_tab %>%
    transmute(
      validation,
      term = contrast,
      estimate = trend_estimate,
      std_error = SE,
      statistic = z.ratio,
      p_value = p.value,
      odds_ratio = exp(trend_estimate),
      direction = if_else(trend_estimate < 0, "strengthens_with_age", "weakens_with_age"),
      interpretation = paste0(
        "emtrends MB-contrast slope over age_z = ",
        sprintf("%.3f", trend_estimate),
        " (p = ",
        format.pval(p.value, digits = 3),
        "); more negative = stronger reward x transition interaction with age"
      )
    ),
  age_lm_tab %>%
    transmute(
      validation,
      term,
      estimate,
      std_error = std.error,
      statistic = statistic,
      p_value = p.value,
      odds_ratio = NA_real_,
      direction = if_else(estimate > 0, "increases_with_age", "decreases_with_age"),
      interpretation = paste0(
        "Subject-level MB contrast changes by ",
        sprintf("%.4f", estimate),
        " per year of age (p = ",
        format.pval(p.value, digits = 3),
        ")"
      )
    ),
  age_spearman_tab %>%
    transmute(
      validation,
      term = "age_vs_mb_spearman",
      estimate,
      std_error = NA_real_,
      statistic = NA_real_,
      p_value,
      odds_ratio = NA_real_,
      direction = if_else(estimate > 0, "increases_with_age", "decreases_with_age"),
      interpretation = paste0(
        "Spearman rho = ",
        sprintf("%.3f", estimate),
        " (p = ",
        format.pval(p_value, digits = 3),
        ", n = ",
        n,
        ")"
      )
    ),
  age_group_ordinal_tab %>%
    transmute(
      validation,
      term,
      estimate,
      std_error = std.error,
      statistic = statistic,
      p_value = p.value,
      odds_ratio = NA_real_,
      direction = if_else(estimate > 0, "increases_with_age", "decreases_with_age"),
      interpretation = paste0(
        "Ordinal age-group trend = ",
        sprintf("%.4f", estimate),
        " per step Children->Adolescents->Adults (p = ",
        format.pval(p.value, digits = 3),
        ")"
      )
    )
)

validation_csv <- "analysis/model_free/twostep_stay_model_direction_validation.csv"
validation_txt <- "analysis/model_free/twostep_stay_model_direction_validation.txt"

write.csv(
  bind_rows(
    direction_summary,
    age_group_desc %>% transmute(validation, term = as.character(age_group), estimate = mean_mb, std_error = se_mb, statistic = n, p_value = NA_real_, odds_ratio = NA_real_, direction = NA_character_, interpretation = NA_character_),
    mb_by_age %>% transmute(validation, term = paste0("age_z=", age_z), estimate = estimate, std_error = SE, statistic = z.ratio, p_value = p.value, odds_ratio = exp(estimate), direction = if_else(estimate > 0, "positive_mb_contrast", "negative_mb_contrast"), interpretation = paste0("predicted MB contrast at age_z=", age_z))
  ),
  validation_csv,
  row.names = FALSE
)

sink(validation_txt)
cat("TwoStep stay model: age x model-based pattern direction validation\n")
cat("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")
cat("N participants:", n_distinct(db$participant_ID), "\n")
cat("N trials:", nrow(db), "\n\n")
cat("=== GLMM interaction (reward x transition x age_z) ===\n")
print(interaction_row)
cat("\nDirection:", if_else(interaction_beta < 0, "STRENGTHENS with age (contr.sum interaction)", "WEAKENS with age (contr.sum interaction)"), "\n\n")
cat("=== emtrends: MB-contrast slope over age_z ===\n")
print(age_trend_tab)
cat("\n=== Predicted MB contrast at age_z = -1, 0, +1 ===\n")
print(mb_by_age)
cat("\n=== Subject-level MB contrast by age group ===\n")
print(age_group_desc)
cat("\n=== Subject-level age trend tests ===\n")
print(age_lm_tab)
print(age_spearman_tab)
print(age_group_ordinal_tab)
cat("\n=== Direction summary ===\n")
print(direction_summary %>% select(validation, direction, p_value, interpretation))
sink()

cat("Wrote:", out_csv, "\n")
cat("Wrote:", anova_csv, "\n")
cat("Wrote:", coef_csv, "\n")
cat("Wrote:", validation_csv, "\n")
cat("Wrote:", validation_txt, "\n")
print(tab)
cat("\nDirection validation summary:\n")
print(direction_summary %>% select(validation, direction, p_value, interpretation))
