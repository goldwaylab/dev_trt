# Shared test-retest reliability summaries (Pearson + Spearman + age moderation).

suppressPackageStartupMessages({
  library(tidyverse)
})

#' One row per parameter: overall Pearson/Spearman with analytical Pearson CI.
compute_overall_trt_metrics <- function(wide, param_col = "parameter", label_col = "parameter_label") {
  wide %>%
    filter(!is.na(session_1), !is.na(session_2)) %>%
    group_by(.data[[param_col]], .data[[label_col]]) %>%
    group_modify(function(d, ...) {
      n <- nrow(d)
      if (n < 3) {
        return(tibble(
          n = n,
          pearson_r = NA_real_,
          pearson_ci_lo = NA_real_,
          pearson_ci_hi = NA_real_,
          spearman_rho = NA_real_,
          spearman_p = NA_real_
        ))
      }
      pct <- cor.test(d$session_1, d$session_2, method = "pearson")
      sct <- cor.test(d$session_1, d$session_2, method = "spearman", exact = FALSE)
      tibble(
        n = n,
        pearson_r = unname(pct$estimate),
        pearson_ci_lo = pct$conf.int[1],
        pearson_ci_hi = pct$conf.int[2],
        spearman_rho = unname(sct$estimate),
        spearman_p = sct$p.value
      )
    }) %>%
    ungroup()
}

compute_age_moderation <- function(wide, param_col = "parameter", label_col = "parameter_label") {
  wide %>%
    filter(!is.na(session_1), !is.na(session_2), !is.na(z_age)) %>%
    group_by(.data[[param_col]], .data[[label_col]]) %>%
    group_modify(function(d, ...) {
      m <- lm(session_2 ~ session_1 * z_age, data = d)
      sm <- summary(m)
      term <- "session_1:z_age"
      if (term %in% rownames(sm$coefficients)) {
        tibble(
          n = nrow(d),
          interaction_t = sm$coefficients[term, "t value"],
          interaction_p = sm$coefficients[term, "Pr(>|t|)"]
        )
      } else {
        tibble(n = nrow(d), interaction_t = NA_real_, interaction_p = NA_real_)
      }
    }) %>%
    ungroup()
}

compute_by_age_trt_metrics <- function(wide, param_col = "parameter", label_col = "parameter_label") {
  wide %>%
    filter(!is.na(session_1), !is.na(session_2), !is.na(age_group)) %>%
    group_by(.data[[param_col]], .data[[label_col]], age_group) %>%
    summarise(
      n = n(),
      pearson_r = if (n() >= 3) cor(session_1, session_2, method = "pearson", use = "complete.obs") else NA_real_,
      spearman_rho = if (n() >= 3) {
        ct <- cor.test(session_1, session_2, method = "spearman", exact = FALSE)
        unname(ct$estimate)
      } else NA_real_,
      .groups = "drop"
    )
}

#' Build long-format reliability export tables for one task/model.
build_trt_reliability_tables <- function(
    wide,
    task,
    model,
    param_col = "parameter",
    label_col = "parameter_label"
) {
  overall <- compute_overall_trt_metrics(wide, param_col, label_col) %>%
    mutate(
      task = task,
      model = model,
      metric_type = "overall",
      age_group = NA_character_,
      interaction_t = NA_real_,
      interaction_p = NA_real_
    )
  by_age <- compute_by_age_trt_metrics(wide, param_col, label_col) %>%
    mutate(
      task = task,
      model = model,
      metric_type = "by_age",
      pearson_ci_lo = NA_real_,
      pearson_ci_hi = NA_real_,
      spearman_p = NA_real_
    )
  age_mod <- compute_age_moderation(wide, param_col, label_col) %>%
    mutate(
      task = task,
      model = model,
      metric_type = "age_moderation",
      age_group = NA_character_,
      pearson_r = NA_real_,
      pearson_ci_lo = NA_real_,
      pearson_ci_hi = NA_real_,
      spearman_rho = NA_real_,
      spearman_p = NA_real_
    )

  bind_rows(overall, by_age, age_mod) %>%
    select(
      task, model, metric_type, parameter = all_of(param_col),
      parameter_label = all_of(label_col), age_group, n,
      pearson_r, pearson_ci_lo, pearson_ci_hi,
      spearman_rho, spearman_p,
      interaction_t, interaction_p
    )
}

write_trt_reliability_csv <- function(tbl, out_path) {
  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
  write_csv(tbl, out_path)
  invisible(out_path)
}

latest_file <- function(dir, pattern) {
  hits <- list.files(dir, pattern = pattern, full.names = TRUE)
  if (!length(hits)) stop("No files for pattern: ", pattern, " in ", dir)
  hits[which.max(file.info(hits)$mtime)]
}

parse_risk_session_wide <- function(summary_path, subjects_path, params, labels, demographics_path) {
  subj_order <- read_csv(subjects_path, show_col_types = FALSE)
  stan_summary <- read_tsv(summary_path, show_col_types = FALSE)
  col1 <- colnames(stan_summary)[1]
  age_data <- read_csv(demographics_path, show_col_types = FALSE)

  map_dfr(params, function(p) {
    stan_summary %>%
      filter(str_detect(.data[[col1]], paste0("^", p, "\\["))) %>%
      mutate(
        param = p,
        parameter_label = labels[[p]],
        session = as.numeric(str_extract(.data[[col1]], "(?<=\\[)\\d+")),
        subj_idx = as.numeric(str_extract(.data[[col1]], "(?<=,)\\d+(?=\\])"))
      ) %>%
      select(param, parameter_label, session, subj_idx, Mean) %>%
      pivot_wider(names_from = session, values_from = Mean, names_prefix = "session_") %>%
      mutate(subject = subj_order$subject[subj_idx])
  }) %>%
    rename(parameter = param) %>%
    left_join(age_data %>% select(Participant.ID, Age), by = c("subject" = "Participant.ID")) %>%
    filter(!is.na(Age)) %>%
    mutate(
      z_age = as.numeric(scale(Age)),
      age_group = cut(
        Age, breaks = c(10, 15, 20, 26),
        labels = c("10-15", "15-20", "20-25"), right = FALSE
      )
    )
}
