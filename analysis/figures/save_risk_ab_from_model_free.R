#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(patchwork)
})

source("config.R")

load_and_process_data <- function(data_path, session_name) {
  read.csv(data_path, header = TRUE) %>%
    mutate(
      participantId = as.character(subject),
      rt = as.numeric(rt),
      key_press = as.character(key_press),
      choice = as.numeric(choice),
      session = session_name
    )
}

define_age_group <- function(df) {
  df %>%
    mutate(
      age_group = case_when(
        age < 13 ~ "Children",
        age >= 13 & age < 18 ~ "Adolescents",
        age >= 18 ~ "Adults"
      ),
      age_group = factor(age_group, levels = c("Children", "Adolescents", "Adults"))
    )
}

risk_data_s1 <- load_and_process_data(RISK_BEHAVIORAL_S1, "session_1")
risk_data_s2 <- load_and_process_data(RISK_BEHAVIORAL_S2, "session_2")
risk_data <- bind_rows(risk_data_s1, risk_data_s2)

common_subjects <- intersect(risk_data_s1$participantId, risk_data_s2$participantId)
risk_data <- risk_data %>%
  filter(participantId %in% common_subjects) %>%
  mutate(
    age = as.numeric(age),
    block = as.numeric(block),
    exposure = as.numeric(exposure),
    probability = as.numeric(probability),
    choice = as.numeric(choice)
  ) %>%
  define_age_group() %>%
  filter(age < 30, block > 0, !is.na(choice), choice %in% c(0, 1))

prob_levels <- c(0.2, 0.5, 0.8)
prob_cols <- c("0.2" = "#66c2a5", "0.5" = "#fc8d62", "0.8" = "#8da0cb")

# Panel A: exposure curves by probability and session
subj_exposure <- risk_data %>%
  group_by(participantId, age_group, session, probability, exposure) %>%
  summarize(prop_risky = mean(choice, na.rm = TRUE), .groups = "drop")

panel_a <- subj_exposure %>%
  group_by(age_group, session, probability, exposure) %>%
  summarize(
    mean_prop = mean(prop_risky, na.rm = TRUE),
    se_prop = sd(prop_risky, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  ) %>%
  mutate(
    probability_f = factor(probability, levels = prob_levels),
    session = factor(session, levels = c("session_1", "session_2"))
  ) %>%
  ggplot(aes(x = exposure, y = mean_prop, color = probability_f, group = interaction(probability_f, session))) +
  geom_ribbon(
    aes(ymin = mean_prop - se_prop, ymax = mean_prop + se_prop, fill = probability_f),
    alpha = 0.16, color = NA
  ) +
  geom_line(aes(linetype = session), linewidth = 1.0) +
  geom_point(aes(shape = session), size = 1.8, alpha = 0.9) +
  facet_wrap(~ age_group, nrow = 1) +
  scale_color_manual(values = prob_cols, name = "Probability") +
  scale_fill_manual(values = prob_cols, name = "Probability") +
  guides(fill = "none") +
  scale_y_continuous(limits = c(0.1, 0.9)) +
  labs(
    x = "Exposure",
    y = "Proportion Risky Choice",
    linetype = "Session",
    shape = "Session",
    caption = "Smoothed ribbons represent ±1 SE"
  ) +
  theme_classic(base_size = 20) +
  theme(
    legend.position = "right",
    strip.text = element_text(face = "bold", size = 16, margin = margin(2, 2, 2, 2)),
    axis.title = element_text(face = "bold", size = 24),
    axis.text = element_text(size = 18),
    legend.title = element_text(size = 20, face = "bold"),
    legend.text = element_text(size = 18),
    plot.caption = element_text(size = 14)
  ) +
  geom_hline(yintercept = c(0.2, 0.5, 0.8), linetype = "dashed", color = "black", linewidth = 0.35)

# Panel B: session summary points + means by probability
subj_session <- risk_data %>%
  group_by(participantId, age_group, session, probability) %>%
  summarize(prop_risky = mean(choice, na.rm = TRUE), .groups = "drop") %>%
  mutate(
    probability_f = factor(probability, levels = prob_levels),
    session = factor(session, levels = c("session_1", "session_2"))
  )

panel_b <- ggplot(subj_session, aes(x = session, y = prop_risky, color = probability_f)) +
  geom_point(
    position = position_jitter(width = 0.08, height = 0),
    alpha = 0.35, size = 1.2, show.legend = FALSE
  ) +
  stat_summary(
    fun = mean,
    geom = "line",
    aes(group = probability_f),
    linewidth = 1.1,
    show.legend = FALSE
  ) +
  stat_summary(
    fun = mean,
    geom = "point",
    size = 2.0,
    show.legend = FALSE
  ) +
  facet_wrap(~ age_group, nrow = 1) +
  scale_color_manual(values = prob_cols, name = "Probability") +
  scale_y_continuous(limits = c(0.1, 1.05)) +
  scale_x_discrete(labels = c("session_1" = "1", "session_2" = "2")) +
  labs(
    x = "Session",
    y = "Proportion Risky Choice"
  ) +
  theme_classic(base_size = 20) +
  theme(
    legend.position = "right",
    strip.text = element_text(face = "bold", size = 16, margin = margin(2, 2, 2, 2)),
    axis.title = element_text(face = "bold", size = 24),
    axis.text = element_text(size = 18),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 18),
    legend.title = element_text(size = 20, face = "bold"),
    legend.text = element_text(size = 18)
  )

fig_ab <- panel_a + panel_b +
  plot_layout(widths = c(1.1, 1.25), guides = "collect") +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(size = 28, face = "bold"))

out_dir <- file.path("outputs", "figures")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
png_path <- file.path(out_dir, "risk_exposure_session_by_age_AB.png")
pdf_path <- file.path(out_dir, "risk_exposure_session_by_age_AB.pdf")

ggsave(png_path, fig_ab, width = 18, height = 6.8, dpi = 300, limitsize = FALSE)
ggsave(pdf_path, fig_ab, width = 18, height = 6.8, limitsize = FALSE)

message("Saved: ", png_path)
message("Saved: ", pdf_path)
