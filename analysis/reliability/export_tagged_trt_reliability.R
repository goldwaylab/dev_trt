#!/usr/bin/env Rscript
# Export test-retest reliability metrics for a tagged Stan fit (e.g. samp10k).
#
# Usage:
#   FIT_TAG=samp10k Rscript analysis/reliability/export_tagged_trt_reliability.R
#   FIT_TAG=samp10k TASKS=risk,pit Rscript analysis/reliability/export_tagged_trt_reliability.R

source(file.path("config.R"))
source(file.path("analysis", "reliability", "trt_reliability_core.R"))

fit_tag <- Sys.getenv("FIT_TAG", "samp10k")
tasks <- strsplit(Sys.getenv("TASKS", "risk,pit,twostep"), ",", fixed = TRUE)[[1]]
tasks <- trimws(tasks)

risk_dir <- file.path(DATA_DIR, "parameter_estimates", "risk")
pit_dir <- file.path(DATA_DIR, "parameter_estimates", "pit")
ts_dir <- file.path(DATA_DIR, "parameter_estimates", "twostep")

tagged_latest <- function(dir, stem, kind = c("summary", "subjects")) {
  kind <- match.arg(kind)
  pat <- if (kind == "summary") {
    paste0("^", stem, "_", fit_tag, "_fit_summary_.*\\.tsv$")
  } else {
    paste0("^", stem, "_", fit_tag, "_fit_subjects_.*\\.csv$")
  }
  latest_file(dir, pat)
}

if ("risk" %in% tasks) {
  risk_summary <- tagged_latest(risk_dir, "risk_valence_asymmetry", "summary")
  risk_subjects <- tagged_latest(risk_dir, "risk_valence_asymmetry", "subjects")
  risk_labels <- c(
    b1 = "Inverse Temperature",
    a1 = "Learning Rate (chosen, +PE)",
    a2 = "Learning Rate (chosen, -PE)",
    a3 = "Learning Rate (unchosen, +PE)",
    a4 = "Learning Rate (unchosen, -PE)",
    q0 = "Initial Q-value (q0)"
  )
  risk_wide <- parse_risk_session_wide(risk_summary, risk_subjects, names(risk_labels), risk_labels, DEMOGRAPHICS_FILE)
  risk_out <- file.path(risk_dir, paste0("risk_", fit_tag, "_test_retest_reliability_metrics.csv"))
  write_trt_reliability_csv(
    build_trt_reliability_tables(risk_wide, "RISK", paste0("risk_valence_asymmetry_", fit_tag)),
    risk_out
  )
  cat("Wrote", risk_out, "\n")
  cat("  summary:", basename(risk_summary), "\n")
}

if ("pit" %in% tasks) {
  pit_summary_tsv <- tagged_latest(pit_dir, "pit_pavlovian_bias", "summary")
  pit_subjects <- tagged_latest(pit_dir, "pit_pavlovian_bias", "subjects")
  pit_with_age <- file.path(pit_dir, paste0("pit_pavlovian_bias_", fit_tag, "_summary_with_age.csv"))

  if (!file.exists(pit_with_age)) {
    system2(
      "python3",
      c(
        file.path("analysis", "stan_fitting", "pit", "extract_pit_participant_estimates.py"),
        "--repo-root", REPO_ROOT,
        "--summary", pit_summary_tsv,
        "--subjects", pit_subjects,
        "--output", pit_with_age
      ),
      stdout = "", stderr = ""
    )
    cat("Wrote", pit_with_age, "\n")
  }

  pit_labels <- c(
    b1 = "Reward Sensitivity",
    b2 = "Punishment Sensitivity",
    b3 = "Approach Bias",
    b4 = "Avoidance Bias",
    a1 = "Positive Learning Rate",
    a2 = "Negative Learning Rate"
  )
  pit_wide <- read_csv(pit_with_age, show_col_types = FALSE) %>%
    filter(!is.na(param_value), parameter %in% names(pit_labels)) %>%
    mutate(parameter_label = pit_labels[parameter]) %>%
    select(parameter, parameter_label, session, subject_id, age, param_value) %>%
    pivot_wider(names_from = session, values_from = param_value, names_prefix = "session_") %>%
    filter(!is.na(session_1), !is.na(session_2)) %>%
    mutate(
      z_age = as.numeric(scale(age)),
      age_group = cut(age, breaks = c(10, 15, 20, 26),
                      labels = c("10-15", "15-20", "20-25"), right = FALSE)
    )

  pit_out <- file.path(pit_dir, paste0("pit_", fit_tag, "_test_retest_reliability_metrics.csv"))
  write_trt_reliability_csv(
    build_trt_reliability_tables(pit_wide, "PIT", paste0("pit_pavlovian_bias_", fit_tag)),
    pit_out
  )
  cat("Wrote", pit_out, "\n")
}

if ("twostep" %in% tasks) {
  fixed_lambda_path <- file.path(ts_dir, paste0("two_step_fixed_lambda_", fit_tag, "_participant_estimates_20260620_144306.csv"))
  if (!file.exists(fixed_lambda_path)) {
    candidates <- list.files(ts_dir, pattern = paste0("^two_step_fixed_lambda_", fit_tag, "_participant_estimates_.*\\.csv$"), full.names = TRUE)
    if (length(candidates) == 0) stop("No tagged TwoStep params for tag: ", fit_tag)
    fixed_lambda_path <- candidates[which.max(file.info(candidates)$mtime)]
  }

  fixed_lambda_labels <- c(
    alpha1 = "Learning Rate",
    beta1m = "Model-Based Beta",
    beta1t = "Model-Free Beta",
    beta2 = "Stage-2 Temperature",
    betac = "Stickiness"
  )
  fixed_lambda_wide <- read_csv(fixed_lambda_path, show_col_types = FALSE) %>%
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

  fixed_lambda_long <- purrr::map_dfr(names(fixed_lambda_labels), function(p) {
    s1 <- paste0(p, "_session1_mean")
    s2 <- paste0(p, "_session2_mean")
    fixed_lambda_wide %>%
      transmute(
        parameter = p,
        parameter_label = fixed_lambda_labels[[p]],
        session_1 = .data[[s1]],
        session_2 = .data[[s2]],
        participant_ID,
        Age,
        z_age,
        age_group
      ) %>%
      filter(!is.na(session_1), !is.na(session_2))
  })

  fixed_lambda_out <- file.path(ts_dir, paste0("two_step_fixed_lambda_", fit_tag, "_test_retest_reliability_metrics.csv"))
  write_trt_reliability_csv(
    build_trt_reliability_tables(fixed_lambda_long, "TwoStep", paste0("two_step_fixed_lambda_", fit_tag)),
    fixed_lambda_out
  )
  cat("Wrote", fixed_lambda_out, "\n")
}
