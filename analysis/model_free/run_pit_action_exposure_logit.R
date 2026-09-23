#!/usr/bin/env Rscript
##
## PIT trial-level logistic mixed model:
##   go_response ~ valence * action * z_exposure * z_age * session
## with random intercepts for participant and stimulus identity.
##

suppressPackageStartupMessages({
  library(tidyverse)
  library(lme4)
  library(car)
  library(emmeans)
  library(rprojroot)
})

REPO_ROOT <- rprojroot::find_root(rprojroot::is_git_root)
source(file.path(REPO_ROOT, "config.R"))

out_dir <- file.path(REPO_ROOT, "analysis", "model_free")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_txt <- file.path(out_dir, "pit_action_exposure_logit_results.txt")
out_anova <- file.path(out_dir, "pit_action_exposure_logit_type3.csv")
out_emm <- file.path(out_dir, "pit_action_exposure_logit_exposure_slopes.csv")

sink(out_txt, split = TRUE)
cat("=============================================================\n")
cat(" PIT trial-level logistic model (action as outcome)\n")
cat(" Outcome: go_response (1=Go, 0=No-Go)\n")
cat(" Fixed: valence * action * z_exposure * z_age * session\n")
cat(" Random: (1 + z_exposure | participantId) + (1 | stim_id)\n")
cat("=============================================================\n\n")

# -----------------------------
# Load / harmonize processed trial data
# -----------------------------
pit_s1 <- PIT_BEHAVIORAL_S1
pit_s2 <- PIT_BEHAVIORAL_S2
stopifnot(file.exists(pit_s1), file.exists(pit_s2))

s1 <- read.csv(pit_s1, stringsAsFactors = FALSE) %>% mutate(session = "session_1")
s2 <- read.csv(pit_s2, stringsAsFactors = FALSE) %>% mutate(session = "session_2")
both <- intersect(unique(s1$subject), unique(s2$subject))

age_lookup <- s1 %>%
  transmute(subject, age_s1 = suppressWarnings(as.numeric(age))) %>%
  distinct(subject, .keep_all = TRUE)

d <- bind_rows(s1, s2) %>%
  filter(subject %in% both, subject != 999) %>%
  left_join(age_lookup, by = "subject") %>%
  mutate(
    participantId = as.character(subject),
    trial = suppressWarnings(as.numeric(trial)),
    block = suppressWarnings(as.numeric(block)),
    choice_num = suppressWarnings(as.numeric(choice)),
    age = coalesce(suppressWarnings(as.numeric(age)), age_s1),
    valence = as.character(valence),
    action = as.character(action),
    session = factor(session, levels = c("session_1", "session_2")),
    go_response = if_else(choice_num == 1, 1L, 0L, missing = 0L),
    robot_id = as.character(robot),
    rune_id = as.character(rune),
    stim_id = paste(robot_id, rune_id, sep = "::")
  ) %>%
  filter(
    trial >= 1,
    block %in% c(2, 3),
    !is.na(go_response),
    !is.na(valence),
    !is.na(action),
    !is.na(age),
    !is.na(stim_id)
  ) %>%
  group_by(participantId, session, stim_id) %>%
  arrange(trial, .by_group = TRUE) %>%
  mutate(exposure = row_number()) %>%
  ungroup() %>%
  mutate(
    z_age = as.numeric(scale(age)),
    z_exposure = as.numeric(scale(exposure)),
    valence = factor(valence, levels = c("lose", "win")),
    action = factor(action, levels = c("no-go", "go")),
    participantId = factor(participantId),
    stim_id = factor(stim_id)
  )

cat(sprintf("Rows: %d\nParticipants: %d\nStim IDs: %d\n\n",
            nrow(d), n_distinct(d$participantId), n_distinct(d$stim_id)))

contrasts(d$valence) <- contr.sum(2)
contrasts(d$action) <- contr.sum(2)
contrasts(d$session) <- contr.sum(2)

# -----------------------------
# Fit logistic mixed model
# -----------------------------
ctrl <- glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 2e6))
form_full <- go_response ~ valence * action * z_exposure * z_age * session +
  (1 + z_exposure | participantId) + (1 | stim_id)

cat("Fitting full model...\n")
fit <- glmer(form_full, data = d, family = binomial(link = "logit"), control = ctrl)

cat("\nModel fit summary:\n")
print(summary(fit))

cat("\nType III Wald chi-square tests:\n")
anv <- car::Anova(fit, type = 3)
print(anv)

anv_tbl <- as.data.frame(anv) %>%
  tibble::rownames_to_column("Effect")
write.csv(anv_tbl, out_anova, row.names = FALSE)

# Exposure slope by valence x action x session at mean age
cat("\nExposure simple slopes by valence x action x session (z_age=0):\n")
exp_slopes <- emtrends(fit, ~ valence * action * session, var = "z_exposure", at = list(z_age = 0))
print(summary(exp_slopes))
write.csv(as.data.frame(summary(exp_slopes)), out_emm, row.names = FALSE)

cat("\nSaved:\n")
cat(" - ", out_txt, "\n", sep = "")
cat(" - ", out_anova, "\n", sep = "")
cat(" - ", out_emm, "\n", sep = "")
sink()

cat("Done.\n")
