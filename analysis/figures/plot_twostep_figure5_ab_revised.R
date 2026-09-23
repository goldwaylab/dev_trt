#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(patchwork)
  library(lme4)
})
source("config.R")
source(file.path("analysis", "figures", "figure_ab_panel_theme.R"))

read_ts <- function(path, sess) {
  readr::read_csv(path, show_col_types = FALSE, col_types = cols(.default = col_character())) %>%
    mutate(session = as.character(sess))
}

s1 <- read_ts(TWOSTEP_BEHAVIORAL_S1, 1)
s2 <- read_ts(TWOSTEP_BEHAVIORAL_S2, 2)

d <- bind_rows(s1, s2) %>%
  mutate(
    participant_ID = as.character(participant_ID),
    age = suppressWarnings(as.numeric(age)),
    trial = suppressWarnings(as.numeric(trial)),
    choice_1 = suppressWarnings(as.numeric(choice_1)),
    reward = suppressWarnings(as.numeric(reward)),
    transition = as.character(transition),
    session = factor(session, levels = c("1", "2"), labels = c("Session 1", "Session 2")),
    age_group = cut(
      age,
      breaks = c(10, 15, 20, 26),
      labels = c("10-15", "15-20", "20-25"),
      right = FALSE
    )
  ) %>%
  filter(
    practice_trial == "real",
    !is.na(participant_ID),
    !is.na(age),
    age >= 10,
    age < 26,
    !is.na(age_group),
    !is.na(choice_1),
    !is.na(reward),
    !is.na(transition)
  )

# Keep only participants with both sessions
keep <- d %>%
  distinct(participant_ID, session) %>%
  count(participant_ID) %>%
  filter(n == 2) %>%
  pull(participant_ID)

d <- d %>% filter(participant_ID %in% keep)

# Recompute previous-trial variables and stay
stay_df <- d %>%
  arrange(participant_ID, session, trial) %>%
  group_by(participant_ID, session, age_group) %>%
  mutate(
    previous_reward = lag(reward),
    previous_transition = lag(transition),
    previous_choice = lag(choice_1),
    stay = if_else(previous_choice == choice_1, 1, 0)
  ) %>%
  ungroup() %>%
  filter(!is.na(previous_reward), !is.na(previous_transition), !is.na(stay)) %>%
  mutate(
    previous_reward = factor(if_else(previous_reward == 1, "Reward", "No Reward"), levels = c("Reward", "No Reward")),
    previous_transition = factor(str_to_lower(previous_transition), levels = c("common", "rare"))
  )

# --------------------
# Panel A
# --------------------
panel_a_sum <- stay_df %>%
  group_by(previous_reward, previous_transition, participant_ID, age_group, session) %>%
  summarise(mean_stay = mean(stay, na.rm = TRUE), .groups = "drop") %>%
  group_by(previous_reward, previous_transition, age_group, session) %>%
  summarise(
    stay_prop = mean(mean_stay),
    se_stay = sd(mean_stay, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

trans_cols <- c(common = "#2C7FB8", rare = "#D7191C")

p_a <- ggplot(panel_a_sum, aes(x = previous_reward, y = stay_prop, fill = previous_transition)) +
  geom_col(position = position_dodge(width = 0.9), color = "black", width = 0.78, alpha = 0.95) +
  geom_errorbar(
    aes(ymin = stay_prop - se_stay, ymax = stay_prop + se_stay),
    position = position_dodge(width = 0.9),
    width = 0.15
  ) +
  facet_grid(rows = vars(session), cols = vars(age_group), switch = "y") +
  scale_fill_manual(values = trans_cols, name = "Previous Trial Transition") +
  scale_y_continuous(breaks = seq(0.5, 1.0, by = 0.1)) +
  coord_cartesian(ylim = c(0.5, 1.0)) +
  geom_segment(
    data = panel_a_sum %>% dplyr::distinct(age_group, session) %>% dplyr::filter(session == "Session 1"),
    x = 0.55,
    xend = 2.45,
    y = -Inf,
    yend = -Inf,
    color = "gray45",
    linewidth = 0.35,
    inherit.aes = FALSE
  ) +
  labs(
    x = "Outcome of Previous Trial",
    y = "Proportion of First-Stage Stays"
  ) +
  figure_ab_panel_theme(legend.position = "bottom") +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5))

# --------------------
# Panel B
# --------------------
# Subject-level model-based effect as reward x transition interaction contrast
mb_sub <- stay_df %>%
  group_by(participant_ID, age_group, session, previous_reward, previous_transition) %>%
  summarise(stay_mean = mean(stay, na.rm = TRUE), .groups = "drop") %>%
  tidyr::pivot_wider(
    names_from = c(previous_reward, previous_transition),
    values_from = stay_mean
  ) %>%
  mutate(
    mb_effect = (`Reward_common` - `Reward_rare`) - (`No Reward_common` - `No Reward_rare`)
  ) %>%
  filter(!is.na(mb_effect))

# Session encoded by shape/fill (not color) to avoid conflict with Panel A
p_b <- ggplot(mb_sub, aes(x = session, y = mb_effect, group = participant_ID)) +
  geom_line(color = "grey35", alpha = 0.18, linewidth = 0.5) +
  geom_point(
    aes(shape = session),
    color = "grey35",
    alpha = 0.35,
    size = 1.8,
    position = position_jitter(width = 0.06, height = 0)
  ) +
  stat_summary(
    aes(group = 1),
    fun = mean,
    geom = "line",
    color = "black",
    linewidth = 1.3
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
  scale_shape_manual(values = c("Session 1" = 16, "Session 2" = 2), name = "Session") +
  scale_x_discrete(labels = c("Session 1" = "1", "Session 2" = "2")) +
  labs(
    x = "Session",
    y = "Model-Based Effect\n(reward × transition contrast)"
  ) +
  figure_ab_panel_theme(legend.position = "bottom")

# --------------------
# Panel B (model-derived: fixef + ranef)
# --------------------
compute_model_mb_effect <- function(df_session) {
  df_session <- df_session %>%
    mutate(
      previous_reward = factor(previous_reward, levels = c("Reward", "No Reward")),
      previous_transition = factor(previous_transition, levels = c("common", "rare")),
      participant_ID = factor(participant_ID)
    )

  fit <- glmer(
    stay ~ previous_reward * previous_transition + (previous_reward * previous_transition | participant_ID),
    data = df_session,
    family = binomial(link = "logit"),
    control = glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 2e5))
  )

  # Participant-specific coefficients (fixed + random) on log-odds scale.
  subj_coef <- coef(fit)$participant_ID %>%
    tibble::rownames_to_column("participant_ID")

  cond <- tidyr::expand_grid(
    previous_reward = factor(c("Reward", "No Reward"), levels = c("Reward", "No Reward")),
    previous_transition = factor(c("common", "rare"), levels = c("common", "rare"))
  ) %>%
    mutate(cond_label = paste(previous_reward, previous_transition, sep = "_"))

  X <- model.matrix(~ previous_reward * previous_transition, data = cond)
  needed_cols <- colnames(X)

  subj_eta <- subj_coef %>%
    select(all_of(c("participant_ID", needed_cols))) %>%
    rowwise() %>%
    mutate(
      eta_vec = list(as.numeric(X %*% c_across(all_of(needed_cols)))),
      cond_label = list(cond$cond_label)
    ) %>%
    ungroup() %>%
    select(participant_ID, eta_vec, cond_label) %>%
    tidyr::unnest(c(eta_vec, cond_label))

  subj_wide <- subj_eta %>%
    pivot_wider(names_from = cond_label, values_from = eta_vec)

  subj_wide %>%
    mutate(
      mb_effect_model = (`Reward_common` - `Reward_rare`) - (`No Reward_common` - `No Reward_rare`)
    ) %>%
    select(participant_ID, mb_effect_model)
}

mb_model <- stay_df %>%
  mutate(session_chr = as.character(session)) %>%
  group_split(session_chr) %>%
  purrr::map_dfr(function(df_s) {
    s <- unique(df_s$session_chr)
    out <- compute_model_mb_effect(df_s)
    out$session <- factor(s, levels = c("Session 1", "Session 2"))
    out
  }) %>%
  left_join(
    stay_df %>% distinct(participant_ID, age_group),
    by = "participant_ID"
  ) %>%
  filter(!is.na(mb_effect_model))

p_b_model <- ggplot(mb_model, aes(x = session, y = mb_effect_model, group = participant_ID)) +
  geom_line(color = "grey35", alpha = 0.18, linewidth = 0.5) +
  geom_point(
    aes(shape = session),
    color = "grey35",
    alpha = 0.35,
    size = 1.8,
    position = position_jitter(width = 0.06, height = 0)
  ) +
  stat_summary(
    aes(group = 1),
    fun = mean,
    geom = "line",
    color = "black",
    linewidth = 1.3
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
  scale_shape_manual(values = c("Session 1" = 16, "Session 2" = 2), name = "Session") +
  scale_x_discrete(labels = c("Session 1" = "1", "Session 2" = "2")) +
  labs(
    x = "Session",
    y = "Model-Based Effect"
  ) +
  figure_ab_panel_theme(legend.position = "bottom")

# Panel B (scatter): session 1 vs session 2 — clearer test–retest read than spaghetti
age_cols <- c(
  "10-15" = "#E41A1C",
  "15-20" = "#377EB8",
  "20-25" = "#4DAF4A"
)

mb_wide <- mb_model %>%
  select(participant_ID, age_group, session, mb_effect_model) %>%
  pivot_wider(names_from = session, values_from = mb_effect_model) %>%
  filter(is.finite(`Session 1`), is.finite(`Session 2`))

mb_cor <- mb_wide %>%
  group_by(age_group) %>%
  summarise(
    n = n(),
    rho = suppressWarnings(cor(`Session 1`, `Session 2`, method = "spearman", use = "complete.obs")),
  ) %>%
  ungroup()

mb_cor_all <- tibble(
  age_group = "All",
  n = nrow(mb_wide),
  rho = suppressWarnings(cor(mb_wide$`Session 1`, mb_wide$`Session 2`, method = "spearman", use = "complete.obs"))
)

message("\n=== Panel B scatter: Spearman rho (S1 vs S2 model-based effect) ===")
print(bind_rows(mb_cor, mb_cor_all))

lim <- range(c(mb_wide$`Session 1`, mb_wide$`Session 2`), na.rm = TRUE)
pad <- diff(lim) * 0.06
lims <- c(lim[1] - pad, lim[2] + pad)

p_b_scatter <- ggplot(mb_wide, aes(x = `Session 1`, y = `Session 2`, color = age_group, fill = age_group)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray45", linewidth = 0.55) +
  geom_point(size = 2.6, alpha = 0.82) +
  geom_smooth(method = "lm", se = TRUE, aes(group = age_group), linewidth = 0.9, alpha = 0.22) +
  scale_color_manual(values = age_cols, name = "Age group (years)") +
  scale_fill_manual(values = age_cols, guide = "none") +
  scale_x_continuous(limits = lims) +
  scale_y_continuous(limits = lims) +
  coord_fixed(ratio = 1) +
  labs(
    x = "Session 1 model-based effect",
    y = "Session 2 model-based effect"
  ) +
  figure_ab_panel_theme(legend.position = "bottom")

fig <- combine_ab_panels(p_a, p_b_scatter)
fig_spaghetti <- combine_ab_panels(p_a, p_b_model)

out_dir <- file.path("outputs", "figures")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
png_path <- file.path(out_dir, "twostep_figure5_ab_revised.png")
pdf_path <- file.path(out_dir, "twostep_figure5_ab_revised.pdf")

ggsave(png_path, fig, width = 14.5, height = 6.4, dpi = 320)
ggsave(pdf_path, fig, width = 14.5, height = 6.4)

spaghetti_png <- file.path(out_dir, "twostep_figure5_ab_spaghetti_b.png")
spaghetti_pdf <- file.path(out_dir, "twostep_figure5_ab_spaghetti_b.pdf")
ggsave(spaghetti_png, fig_spaghetti, width = 14.5, height = 6.4, dpi = 320)
ggsave(spaghetti_pdf, fig_spaghetti, width = 14.5, height = 6.4)

scatter_only_png <- file.path(out_dir, "twostep_figure5b_mb_effect_scatter.png")
scatter_only_pdf <- file.path(out_dir, "twostep_figure5b_mb_effect_scatter.pdf")
ggsave(scatter_only_png, p_b_scatter, width = 6.2, height = 5.8, dpi = 320)
ggsave(scatter_only_pdf, p_b_scatter, width = 6.2, height = 5.8)

compare_fig <- (p_b + p_b_model +
  plot_layout(ncol = 1, heights = c(1, 1)) +
  plot_annotation(tag_levels = "A", theme = theme(plot.tag = element_text(size = 16, face = "bold")))) &
  figure_ab_panel_theme(legend.position = "bottom")
compare_png_path <- file.path(out_dir, "twostep_figure5b_compare_raw_vs_model.png")
compare_pdf_path <- file.path(out_dir, "twostep_figure5b_compare_raw_vs_model.pdf")

ggsave(compare_png_path, compare_fig, width = 9.5, height = 10.5, dpi = 320)
ggsave(compare_pdf_path, compare_fig, width = 9.5, height = 10.5)

message("Saved: ", png_path)
message("Saved: ", pdf_path)
message("Saved: ", spaghetti_png)
message("Saved: ", scatter_only_png)
message("Saved: ", compare_png_path)
message("Saved: ", compare_pdf_path)
