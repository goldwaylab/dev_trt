REPO_ROOT <- tryCatch(
  rprojroot::find_root(rprojroot::is_git_root),
  error = function(e) {
    if (exists("REPO_ROOT") && nzchar(REPO_ROOT)) return(REPO_ROOT)
    getwd()
  }
)

DATA_DIR          <- file.path(REPO_ROOT, "data")
DEMOGRAPHICS_FILE <- file.path(DATA_DIR, "demographics", "discovery.replication.sample.allocation.csv")

RISK_BEHAVIORAL_S1 <- file.path(DATA_DIR, "behavioral", "risk", "s1", "data.csv")
RISK_BEHAVIORAL_S2 <- file.path(DATA_DIR, "behavioral", "risk", "s2", "data.csv")
PIT_BEHAVIORAL_S1  <- file.path(DATA_DIR, "behavioral", "pit", "s1", "pgng.csv")
PIT_BEHAVIORAL_S2  <- file.path(DATA_DIR, "behavioral", "pit", "s2", "pgng.csv")
TWOSTEP_BEHAVIORAL_S1 <- file.path(DATA_DIR, "behavioral", "twostep", "s1", "MBMF_data_processed_2.csv")
TWOSTEP_BEHAVIORAL_S2 <- file.path(DATA_DIR, "behavioral", "twostep", "s2", "MBMF_data_processed_2.csv")

FIT_TAG <- "samp10k"

RISK_RELIABILITY_METRICS <- file.path(DATA_DIR, "parameter_estimates", "risk", "risk_samp10k_test_retest_reliability_metrics.csv")
PIT_RELIABILITY_METRICS  <- file.path(DATA_DIR, "parameter_estimates", "pit", "pit_samp10k_test_retest_reliability_metrics.csv")
PIT_PARAMETER_ESTIMATES  <- file.path(DATA_DIR, "parameter_estimates", "pit", "pit_pavlovian_bias_samp10k_summary_with_age.csv")

TWO_STEP_PARAMETER_ESTIMATES <- local({
  ts_dir <- file.path(DATA_DIR, "parameter_estimates", "twostep")
  preferred <- file.path(ts_dir, "two_step_fixed_lambda_samp10k_participant_estimates_20260620_144306.csv")
  if (file.exists(preferred)) {
    return(preferred)
  }
  candidates <- list.files(ts_dir, pattern = "^two_step_fixed_lambda_samp10k_participant_estimates_[0-9].*\\.csv$", full.names = TRUE)
  if (length(candidates) == 0) {
    stop("No samp10k TwoStep fixed-lambda participant parameter CSV found.")
  } else {
    candidates[which.max(file.info(candidates)$mtime)]
  }
})
TWO_STEP_RELIABILITY_METRICS <- file.path(DATA_DIR, "parameter_estimates", "twostep", "two_step_fixed_lambda_samp10k_test_retest_reliability_metrics.csv")

EXCLUSIONS_DIR           <- file.path(DATA_DIR, "exclusions")
PIT_GW_ACCURACY_CUTOFF   <- 0.55
PIT_GW_EXCLUSION_MIN_ACC <- PIT_GW_ACCURACY_CUTOFF
TWOSTEP_RT_EXCLUSIONS    <- file.path(EXCLUSIONS_DIR, "reject_rt_TS.csv")

FIGURES_DIR <- file.path(REPO_ROOT, "outputs", "figures")
dir.create(FIGURES_DIR, recursive = TRUE, showWarnings = FALSE)
