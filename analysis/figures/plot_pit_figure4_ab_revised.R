#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(patchwork)
})
source("config.R")
source(file.path("analysis", "figures", "pit_bias_sig_helpers.R"))
source(file.path("analysis", "figures", "figure_ab_panel_theme.R"))

s1 <- read.csv(PIT_BEHAVIORAL_S1, stringsAsFactors = FALSE) %>% mutate(session = "session_1")
s2 <- read.csv(PIT_BEHAVIORAL_S2, stringsAsFactors = FALSE) %>% mutate(session = "session_2")

both <- intersect(unique(s1$subject), unique(s2$subject))
age_lookup <- s1 %>%
  transmute(subject, age_s1 = suppressWarnings(as.numeric(age))) %>%
  distinct(subject, .keep_all = TRUE)

d <- bind_rows(s1, s2) %>%
  filter(subject %in% both, subject != 999) %>%
  left_join(age_lookup, by = "subject") %>%
  mutate(
    trial = suppressWarnings(as.numeric(trial)),
    block = suppressWarnings(as.numeric(block)),
    choice_num = suppressWarnings(as.numeric(choice)),
    rt_num = suppressWarnings(as.numeric(rt)),
    age = coalesce(suppressWarnings(as.numeric(age)), age_s1),
    age_group = case_when(
      age < 13 ~ "Children",
      age >= 13 & age < 18 ~ "Adolescents",
      age >= 18 ~ "Adults",
      TRUE ~ NA_character_
    ),
    age_group = factor(age_group, levels = c("Children", "Adolescents", "Adults")),
    go_response = if_else(choice_num == 1, 1, 0, missing = 0),
    valence = as.character(valence),
    action = as.character(action),
    trialType = case_when(
      action == "go" & valence == "win" ~ "GW",
      action == "go" & valence == "lose" ~ "GAL",
      action == "no-go" & valence == "win" ~ "NGW",
      action == "no-go" & valence == "lose" ~ "NGAL",
      TRUE ~ NA_character_
    ),
    trialType = factor(trialType, levels = c("GW", "GAL", "NGW", "NGAL")),
    robot_id = as.character(robot),
    rune_id = as.character(rune),
    stim_id = paste(robot_id, rune_id, sep = "::"),
    session = factor(session, levels = c("session_1", "session_2"))
  ) %>%
  filter(
    trial >= 1,
    block %in% c(2, 3),
    !is.na(age_group),
    !is.na(valence),
    !is.na(action),
    !is.na(trialType)
  )

# Exposure index by participant x session x stimulus identity (robot+rune)
d <- d %>%
  group_by(subject, session, stim_id) %>%
  arrange(trial, .by_group = TRUE) %>%
  mutate(exposure = row_number()) %>%
  ungroup()

# --------------------------
# Panel A: exposure learning
# --------------------------
subj_exposure <- d %>%
  group_by(subject, age_group, session, trialType, exposure) %>%
  summarise(go_mean = mean(go_response, na.rm = TRUE), .groups = "drop")

sum_exposure <- subj_exposure %>%
  group_by(age_group, session, trialType, exposure) %>%
  summarise(
    mean_go = mean(go_mean, na.rm = TRUE),
    se_go = sd(go_mean, na.rm = TRUE) / sqrt(n()),
    n_subj = n(),
    .groups = "drop"
  ) %>%
  filter(n_subj >= 20)

trial_cols <- c(
  GW = "#3b6fb6",
  GAL = "#f08a5d",
  NGW = "#55c1a7",
  NGAL = "#b35aa3"
)

p_a <- ggplot(
  sum_exposure,
  aes(
    x = exposure,
    y = mean_go,
    color = trialType,
    fill = trialType,
    linetype = session,
    group = interaction(trialType, session)
  )
) +
  geom_ribbon(aes(ymin = mean_go - se_go, ymax = mean_go + se_go), alpha = 0.12, color = NA, show.legend = FALSE) +
  geom_line(linewidth = 1.05) +
  facet_wrap(~ age_group, nrow = 1, strip.position = "top") +
  scale_color_manual(values = trial_cols, name = "Trial Type") +
  scale_fill_manual(values = trial_cols, name = "Trial Type") +
  scale_linetype_manual(
    values = c(session_1 = "solid", session_2 = "dashed"),
    labels = c(session_1 = "Session 1 (solid)", session_2 = "Session 2 (dashed)"),
    name = "Session"
  ) +
  scale_x_continuous(breaks = c(1, 5, 10, 15)) +
  labs(
    x = "Exposure Number",
    y = "Go Response"
  ) +
  guides(
    linetype = guide_legend(order = 1, override.aes = list(linewidth = 1.6)),
    color = guide_legend(order = 2),
    fill = "none"
  )

# --------------------------
# Panel B: Pavlovian bias
# --------------------------
go_by_type <- d %>%
  mutate(go_response_rt = if_else(!is.na(rt_num) & rt_num > -1, 1, 0)) %>%
  group_by(subject, age_group, session, trialType) %>%
  summarise(go_rate = mean(go_response_rt, na.rm = TRUE), .groups = "drop")

bias_sub <- go_by_type %>%
  group_by(subject, age_group, session) %>%
  summarise(
    rew_inv = mean(go_rate[trialType %in% c("GW", "NGW")], na.rm = TRUE),
    pun_supp = mean(1 - go_rate[trialType %in% c("GAL", "NGAL")], na.rm = TRUE),
    pav_bias = mean(c(rew_inv, pun_supp), na.rm = TRUE),
    .groups = "drop"
  )

bias_sig <- session_paired_sig_annot(bias_sub)
message("Panel B paired session tests (Pavlovian bias):")
print(as.data.frame(bias_sig$tests))

p_b <- ggplot(bias_sub, aes(x = session, y = pav_bias, group = subject)) +
  geom_line(color = "grey35", alpha = 0.18, linewidth = 0.5, show.legend = FALSE) +
  geom_point(
    aes(shape = session),
    color = "grey35",
    alpha = 0.35,
    size = 1.8,
    position = position_jitter(width = 0.06, height = 0)
  ) +
  stat_summary(aes(group = 1), fun = mean, geom = "line", color = "black", linewidth = 1.3) +
  stat_summary(
    aes(group = 1),
    fun.data = mean_se,
    geom = "errorbar",
    width = 0.12,
    color = "black",
    linewidth = 0.6
  ) +
  stat_summary(
    aes(group = 1),
    fun = mean,
    geom = "point",
    shape = 22,
    size = 2.8,
    fill = "black",
    color = "black"
  ) +
  facet_wrap(~ age_group, nrow = 1, strip.position = "top") +
  scale_shape_manual(
    values = c(session_1 = 16, session_2 = 2),
    labels = c(session_1 = "Session 1", session_2 = "Session 2"),
    name = "Session"
  ) +
  scale_x_discrete(labels = c(session_1 = "1", session_2 = "2")) +
  labs(x = "Session", y = "Pavlovian Bias") +
  geom_hline(yintercept = 0.5, linetype = "dashed", linewidth = 0.6, color = "gray30")

p_b <- add_session_sig_brackets(p_b, bias_sig) +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.16)))

fig <- combine_ab_panels(p_a, p_b, widths = c(1.35, 1.0))

out_dir <- file.path("outputs", "figures")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
png_path <- file.path(out_dir, "pit_figure4_ab_revised.png")
pdf_path <- file.path(out_dir, "pit_figure4_ab_revised.pdf")

ggsave(png_path, fig, width = 13.8, height = 6.0, dpi = 320)
ggsave(pdf_path, fig, width = 13.8, height = 6.0)

message("Saved: ", png_path)
message("Saved: ", pdf_path)
