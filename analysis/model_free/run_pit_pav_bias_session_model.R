#!/usr/bin/env Rscript
##
## Pavlovian bias (RewInv + PunSupp) ~ z_age * session + (1 | participantId)
## Uses de-identified processed PIT trial CSVs included in this repository.
##

suppressPackageStartupMessages({
  library(tidyverse)
  library(afex)
})

source("config.R")

out_dir <- file.path(REPO_ROOT, "analysis", "model_free")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_txt <- file.path(out_dir, "pit_pav_bias_session_model_results.txt")
out_nice <- file.path(out_dir, "pit_pav_bias_session_model_nice.csv")

load_pit_processed <- function(path, session_number) {
  read.csv(path, header = TRUE, stringsAsFactors = FALSE) %>%
    mutate(
      participantId = as.factor(subject),
      session = as.factor(session_number),
      trial = suppressWarnings(as.numeric(trial)),
      choice = suppressWarnings(as.numeric(choice)),
      accuracy = suppressWarnings(as.numeric(accuracy)),
      age = suppressWarnings(as.numeric(age))
    )
}

sink(out_txt, split = TRUE)
cat("=============================================================\n")
cat(" PIT Pavlovian bias mixed model (processed CSV pipeline)\n")
cat(" PavBias = mean(RewInv, PunSupp); GW accuracy exclusion <", PIT_GW_EXCLUSION_MIN_ACC, "\n")
cat(" Model: PavBias ~ z_age * session + (1 | participantId)\n")
cat("=============================================================\n\n")

pit_data_s1 <- load_pit_processed(PIT_BEHAVIORAL_S1, 1)
pit_data_s2 <- load_pit_processed(PIT_BEHAVIORAL_S2, 2)
participants_with_session_2 <- unique(pit_data_s2$participantId)

pit2analyse <- bind_rows(pit_data_s1, pit_data_s2) %>%
  filter(participantId %in% participants_with_session_2) %>%
  filter(!is.na(participantId), !is.na(action), subject != 999) %>%
  mutate(
    participantId = as.factor(participantId),
    session = as.factor(session),
    z_age = as.numeric(scale(age)),
    trialType = case_when(
      action == "go" & valence == "win" ~ "GW",
      action == "go" & valence == "lose" ~ "GAL",
      action == "no-go" & valence == "win" ~ "NGW",
      action == "no-go" & valence == "lose" ~ "NGAL",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(trial > 0, !is.na(trialType), !is.na(age))

excluded_subjects <- pit2analyse %>%
  filter(trialType == "GW", session == "1") %>%
  group_by(participantId) %>%
  summarise(meanAcc = mean(accuracy, na.rm = TRUE), .groups = "drop") %>%
  filter(meanAcc < PIT_GW_EXCLUSION_MIN_ACC) %>%
  pull(participantId)

pit2analyse <- pit2analyse %>% filter(!(participantId %in% excluded_subjects))

pit2analyse <- pit2analyse %>%
  mutate(go_num = as.numeric(choice == 1), nogo_num = as.numeric(choice == 0))

pav_bias_per_sub <- pit2analyse %>%
  group_by(participantId, session, z_age, age) %>%
  summarise(
    n_go = sum(go_num == 1, na.rm = TRUE),
    n_nogo = sum(nogo_num == 1, na.rm = TRUE),
    go_win = sum(go_num == 1 & trialType %in% c("GW", "NGW"), na.rm = TRUE),
    nogo_avoid = sum(nogo_num == 1 & trialType %in% c("GAL", "NGAL"), na.rm = TRUE),
    RewInv = ifelse(n_go == 0, NA_real_, go_win / n_go),
    PunSupp = ifelse(n_nogo == 0, NA_real_, nogo_avoid / n_nogo),
    PavBias = mean(c(RewInv, PunSupp), na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(!is.na(PavBias))

both_sessions <- pav_bias_per_sub %>%
  count(participantId) %>%
  filter(n == 2) %>%
  pull(participantId)

pav_bias_per_sub <- pav_bias_per_sub %>% filter(participantId %in% both_sessions)

cat("Participants (both sessions, post-exclusion):", length(both_sessions), "\n")
cat("GW accuracy exclusions:", length(excluded_subjects), "\n\n")

model <- mixed(
  PavBias ~ z_age * session + (1 | participantId),
  data = pav_bias_per_sub,
  control = lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 1e6)),
  method = "S"
)

nice_tab <- as.data.frame(nice(model))
write.csv(nice_tab, out_nice, row.names = FALSE)

print(nice_tab)
sink()

cat("Wrote:", out_txt, "\n")
cat("Wrote:", out_nice, "\n")
