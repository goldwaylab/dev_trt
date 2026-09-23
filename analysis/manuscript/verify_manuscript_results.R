#!/usr/bin/env Rscript
##
## Compare canonical analysis outputs to manuscript-reported statistics.
## Usage:
##   Rscript analysis/manuscript/verify_manuscript_results.R           # check cached/generated outputs
##   Rscript analysis/manuscript/verify_manuscript_results.R --run     # regenerate processed-data outputs first
##

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || is.na(x)[1]) y else x

args <- commandArgs(trailingOnly = TRUE)
do_run <- "--run" %in% args

source("config.R")
source(file.path("analysis", "manuscript", "manuscript_targets.R"))
source(file.path("analysis", "reliability", "trt_reliability_core.R"))

out_dir <- file.path(REPO_ROOT, "analysis", "manuscript")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
report_csv <- file.path(out_dir, "manuscript_verification_report.csv")
report_txt <- file.path(out_dir, "manuscript_verification_report.txt")

checks <- list()
add_check <- function(section, id, expected, observed, tol, pass, source_file, note = "") {
  checks[[length(checks) + 1]] <<- tibble(
    section = section,
    id = id,
    expected = expected,
    observed = observed,
    abs_diff = if (is.finite(observed) && is.finite(expected)) abs(observed - expected) else NA_real_,
    tolerance = tol,
    pass = pass,
    source = source_file,
    note = note
  )
}

near <- function(obs, exp, tol) {
  if (is.na(obs) || is.na(exp)) return(FALSE)
  abs(obs - exp) <= tol
}

parse_nice_chisq <- function(path, effect) {
  if (!file.exists(path)) return(NA_real_)
  tab <- read.csv(path, stringsAsFactors = FALSE)
  effect_col <- if ("Effect" %in% names(tab)) "Effect" else names(tab)[1]
  row <- tab %>% filter(.data[[effect_col]] == effect)
  if (nrow(row) == 0) return(NA_real_)
  val <- row$Chisq[1]
  if (is.character(val)) {
    val <- suppressWarnings(as.numeric(sub("\\s+\\*+.*$", "", val)))
  }
  as.numeric(val)
}

parse_nice_F <- function(path, effect) {
  if (!file.exists(path)) return(NA_real_)
  tab <- read.csv(path, stringsAsFactors = FALSE)
  effect_col <- if ("Effect" %in% names(tab)) "Effect" else names(tab)[1]
  row <- tab %>% filter(.data[[effect_col]] == effect)
  if (nrow(row) == 0) return(NA_real_)
  val <- row$F[1]
  if (is.character(val)) {
    val <- suppressWarnings(as.numeric(sub("\\s+\\*+.*$", "", val)))
  }
  as.numeric(val)
}

parse_type3_chisq <- function(path, effect) {
  if (!file.exists(path)) return(NA_real_)
  tab <- read.csv(path, stringsAsFactors = FALSE)
  rn <- tab[[1]]
  idx <- which(rn == effect)
  if (length(idx) == 0) return(NA_real_)
  as.numeric(tab$Chisq[idx[1]])
}

parse_wald_chisq <- function(path, effect) {
  if (!file.exists(path)) return(NA_real_)
  tab <- read.csv(path, stringsAsFactors = FALSE)
  row <- tab %>% filter(Effect == effect)
  if (nrow(row) == 0) return(NA_real_)
  as.numeric(row$Chisq[1])
}

parse_wald_p <- function(path, effect) {
  if (!file.exists(path)) return(NA_real_)
  tab <- read.csv(path, stringsAsFactors = FALSE)
  row <- tab %>% filter(Effect == effect)
  if (nrow(row) == 0) return(NA_real_)
  as.numeric(row$`Pr(>Chisq)`[1])
}

parse_nice_p <- function(path, effect) {
  if (!file.exists(path)) return(NA_real_)
  tab <- read.csv(path, stringsAsFactors = FALSE)
  effect_col <- if ("Effect" %in% names(tab)) "Effect" else names(tab)[1]
  row <- tab %>% filter(.data[[effect_col]] == effect)
  if (nrow(row) == 0) return(NA_real_)
  as.numeric(row$p.value[1])
}

if (do_run) {
  cat("=== Regenerating processed-data behavioral outputs ===\n")
  system2("Rscript", c(file.path("analysis", "model_free", "run_risk_full_model.R")))
  system2("Rscript", c(file.path("analysis", "model_free", "run_pit_action_exposure_logit.R")))
  system2("Rscript", c(file.path("analysis", "model_free", "run_pit_pav_bias_session_model.R")))
  system2("Rscript", c(file.path("analysis", "model_free", "run_twostep_stay_model_harmonized.R")))
  cat("=== Exporting reliability tables ===\n")
  Sys.setenv(FIT_TAG = "samp10k")
  system2("Rscript", c(file.path("analysis", "reliability", "export_tagged_trt_reliability.R")))
}

targets <- manuscript_targets()

# ---- RISK ----
risk_txt <- file.path("analysis", "model_free", "risk_full_model_results.txt")
if (file.exists(risk_txt)) {
  risk_lines <- readLines(risk_txt, warn = FALSE)
  grab_F <- function(effect_label) {
    esc <- gsub("([:()])", "\\\\\\1", effect_label, perl = TRUE)
    pat <- paste0("[[:space:]]*[0-9]+[[:space:]]+", esc, "[[:space:]]+[0-9]+,")
    line <- risk_lines[grep(pat, risk_lines, perl = TRUE)][1]
    if (is.na(line)) return(NA_real_)
    parts <- strsplit(trimws(line), "\\s+")[[1]]
    df_idx <- which(grepl(",", parts))[1]
    if (is.na(df_idx)) return(NA_real_)
    f_val <- if (grepl(",", parts[df_idx])) {
      suppressWarnings(as.numeric(parts[df_idx + 2]))
    } else {
      suppressWarnings(as.numeric(parts[df_idx + 1]))
    }
    f_val
  }
  effect_map <- c(
    "probability" = "risk_prob_F",
    "probability:z_exposure" = "risk_prob_exposure_F",
    "z_age:probability:z_exposure" = "risk_age_prob_exposure_F",
    "session" = "risk_session_F",
    "probability:session" = "risk_prob_session_F",
    "z_age:session" = "risk_age_session_F",
    "session:z_exposure" = "risk_session_exposure_F"
  )
  for (eff in names(effect_map)) {
    tgt <- targets$risk[[which(map_chr(targets$risk, "id") == effect_map[[eff]])]]
    obs <- grab_F(eff)
    add_check("risk", tgt$id, tgt$value, obs, tgt$tol, near(obs, tgt$value, tgt$tol), risk_txt)
  }
  mean_targets <- list(
    list(id = "risk_mean_p02_s1", pattern = "0\\.2\\s+session_1\\s+([0-9.]+)"),
    list(id = "risk_mean_p05_s1", pattern = "0\\.5\\s+session_1\\s+([0-9.]+)"),
    list(id = "risk_mean_p08_s1", pattern = "0\\.8\\s+session_1\\s+([0-9.]+)"),
    list(id = "risk_mean_p02_s2", pattern = "0\\.2\\s+session_2\\s+([0-9.]+)"),
    list(id = "risk_mean_p08_s2", pattern = "0\\.8\\s+session_2\\s+([0-9.]+)")
  )
  for (mt in mean_targets) {
    line <- risk_lines[grep(mt$pattern, risk_lines, perl = TRUE)][1]
    obs <- if (is.na(line)) NA_real_ else suppressWarnings(as.numeric(sub(".*session_[12]\\s+([0-9.]+).*", "\\1", line, perl = TRUE)))
    tgt <- targets$risk[[which(map_chr(targets$risk, "id") == mt$id)]]
    add_check("risk", tgt$id, tgt$value, obs, tgt$tol, near(obs, tgt$value, tgt$tol), risk_txt)
  }
}

# ---- PIT logit ----
pit_type3 <- file.path("analysis", "model_free", "pit_action_exposure_logit_type3.csv")
for (t in targets$pit_logit) {
  obs <- parse_wald_chisq(pit_type3, t$effect)
  add_check("pit_logit", t$id, t$value, obs, t$tol, near(obs, t$value, t$tol), pit_type3)
}

# ---- PIT bias ----
pit_bias_nice <- file.path("analysis", "model_free", "pit_pav_bias_session_model_nice.csv")
for (t in targets$pit_bias) {
  obs <- if (t$stat == "F") parse_nice_F(pit_bias_nice, t$effect) else parse_nice_p(pit_bias_nice, t$effect)
  add_check("pit_bias", t$id, t$value, obs, t$tol, near(obs, t$value, t$tol), pit_bias_nice)
}

# ---- TwoStep stay ----
ts_lrt <- file.path("analysis", "model_free", "twostep_stay_model_manuscript_nice.csv")
ts_anova <- file.path("analysis", "model_free", "twostep_stay_model_anova_type3.csv")
for (t in targets$twostep_stay) {
  src <- if (!is.null(t$note) && grepl("harmonized", t$note)) ts_anova else ts_lrt
  obs <- if (grepl("harmonized", t$note %||% "")) {
    parse_type3_chisq(src, t$effect)
  } else {
    parse_nice_chisq(src, t$effect)
  }
  add_check("twostep_stay", t$id, t$value, obs, t$tol, near(obs, t$value, t$tol), src, t$note %||% "")
}

# ---- Reliability ----
# Current canonical models as of 2026-09-22: rstd_m9_sh (RISK), pgng_m3_sh (PIT),
# two-step free-forgetting (replaces the old fixed-lambda model). See
# manuscript_targets.R for citations to the writeups behind these numbers.
risk_spear <- file.path(DATA_DIR, "parameter_estimates", "risk", "risk_valence_asymmetry_m9sh_samp10k_trt_reliability_spearman_overall.csv")
risk_icc <- file.path(DATA_DIR, "parameter_estimates", "risk", "risk_valence_asymmetry_m9sh_samp10k_trt_reliability_icc_population.csv")
pit_spear <- file.path(DATA_DIR, "parameter_estimates", "pit", "pit_pavlovian_bias_m3sh_samp10k_trt_reliability_spearman_overall.csv")
pit_icc <- file.path(DATA_DIR, "parameter_estimates", "pit", "pit_pavlovian_bias_m3sh_samp10k_trt_reliability_icc_population.csv")
ts_spear <- file.path(DATA_DIR, "parameter_estimates", "twostep", "two_step_free_forgetting_samp10k_trt_reliability_spearman_overall.csv")
ts_icc <- file.path(DATA_DIR, "parameter_estimates", "twostep", "two_step_free_forgetting_samp10k_trt_reliability_icc_population.csv")

read_param_stat <- function(path, param, col) {
  if (!file.exists(path)) return(NA_real_)
  tab <- read.csv(path, stringsAsFactors = FALSE)
  row <- tab %>% filter(parameter == param)
  if (nrow(row) == 0) return(NA_real_)
  as.numeric(row[[col]][1])
}

for (t in targets$reliability_risk) {
  col <- if (t$stat == "spearman_rho") "spearman_rho" else "icc"
  src <- if (t$stat == "spearman_rho") risk_spear else risk_icc
  obs <- read_param_stat(src, t$param, col)
  add_check("reliability_risk", t$id, t$value, obs, t$tol, near(obs, t$value, t$tol), src)
}

for (t in targets$reliability_pit) {
  if (t$stat == "age_mod_p") {
    wide <- read_csv(PIT_PARAMETER_ESTIMATES, show_col_types = FALSE) %>%
      filter(parameter == t$param, !is.na(param_value)) %>%
      pivot_wider(names_from = session, values_from = param_value, names_prefix = "session_") %>%
      filter(!is.na(session_1), !is.na(session_2)) %>%
      mutate(z_age = as.numeric(scale(age)))
    m <- lm(session_2 ~ session_1 * z_age, data = wide)
    obs <- summary(m)$coefficients["session_1:z_age", "Pr(>|t|)"]
    add_check("reliability_pit", t$id, t$value, obs, t$tol, near(obs, t$value, t$tol), PIT_PARAMETER_ESTIMATES)
  } else {
    col <- if (t$stat == "spearman_rho") "spearman_rho" else "icc"
    src <- if (t$stat == "spearman_rho") pit_spear else pit_icc
    obs <- read_param_stat(src, t$param, col)
    add_check("reliability_pit", t$id, t$value, obs, t$tol, near(obs, t$value, t$tol), src)
  }
}

for (t in targets$reliability_twostep) {
  col <- if (t$stat == "spearman_rho") "spearman_rho" else "icc"
  src <- if (t$stat == "spearman_rho") ts_spear else ts_icc
  obs <- read_param_stat(src, t$param, col)
  add_check("reliability_twostep", t$id, t$value, obs, t$tol, near(obs, t$value, t$tol), src)
}

report <- bind_rows(checks)
write.csv(report, report_csv, row.names = FALSE)

n_pass <- sum(report$pass, na.rm = TRUE)
n_fail <- sum(!report$pass, na.rm = TRUE)
n_na <- sum(is.na(report$pass))

sink(report_txt)
cat("Manuscript verification report –", format(Sys.time(), "%Y-%m-%d %H:%M"), "\n")
cat("PASS:", n_pass, " FAIL:", n_fail, " NA/missing:", n_na, "\n\n")
if (n_fail > 0) {
  cat("=== FAILURES ===\n")
  print(report %>% filter(!pass) %>% select(section, id, expected, observed, abs_diff, tolerance, source, note))
  cat("\n")
}
if (n_na > 0) {
  cat("=== MISSING OBSERVATIONS ===\n")
  print(report %>% filter(is.na(pass) | is.na(observed)) %>% select(section, id, source))
  cat("\n")
}
cat("=== ALL CHECKS ===\n")
print(report)
sink()

cat("Wrote:", report_csv, "\n")
cat("Wrote:", report_txt, "\n")
cat("Summary: PASS", n_pass, "FAIL", n_fail, "NA", n_na, "\n")
if (n_fail > 0) quit(status = 1)
