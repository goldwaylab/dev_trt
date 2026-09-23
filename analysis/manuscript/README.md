# Manuscript Result Reproduction

Automated checks compare the bundled canonical outputs to the statistics reported in
the manuscript (*task behavior across sessions* + *test-retest reliability*).

## One-command Tier A reproduction

From the repository root:

```bash
bash analysis/run_manuscript_tier_a.sh
```

Reports are written to:

- `analysis/manuscript/manuscript_verification_report.csv`
- `analysis/manuscript/manuscript_verification_report.txt`

Exit code is **0** only if all checks pass.

For a numeric check only, run:

```bash
Rscript analysis/manuscript/verify_manuscript_results.R
```

## Canonical scripts by section

| Manuscript section | Script | Primary output |
|---|---|---|
| RISK behavior | `analysis/model_free/run_risk_full_model.R` | `risk_full_model_results.txt` |
| PIT Go logit | `analysis/model_free/run_pit_action_exposure_logit.R` | `pit_action_exposure_logit_type3.csv` |
| PIT Pavlovian bias F-test | `analysis/model_free/run_pit_pav_bias_session_model.R` | `pit_pav_bias_session_model_nice.csv` |
| TwoStep stay GLMM (processed harmonized effects) | `analysis/model_free/run_twostep_stay_model_harmonized.R` | `twostep_stay_model_anova_type3.csv` |
| TwoStep stay GLMM (cached LRT table) | bundled CSV | `twostep_stay_model_manuscript_nice.csv` |
| TRT reliability (all tasks) | `analysis/run_canonical_trt_outputs.sh` | `data/parameter_estimates/*/*_trt_reliability_*.csv` |

## Important notes

### TwoStep Stay Model

The clean Tier A repository excludes raw Pavlovia exports. The manuscript LRT table
for the TwoStep stay model is therefore included as a cached CSV
(`twostep_stay_model_manuscript_nice.csv`) and verified directly.

The session-effect values in the draft are generated from the processed behavioral
pipeline (`run_twostep_stay_model_harmonized.R`) with Type-III ANOVA
(`anova(model, type = 3)`). Those values differ from the cached LRT table, so the
verification script checks both sets of targets explicitly.

### PIT Pavlovian bias

The Tier A verification checks the cached PIT Pavlovian-bias model table included under
`analysis/model_free/`. The refit script now uses the processed PIT CSVs bundled in
`data/behavioral/pit/` with the same GW accuracy exclusion threshold (< 0.55, Session 1).

### Reliability

Spearman ρ and ICC are exported from the canonical `samp10k` fits by:

```bash
FIT_TAG=samp10k Rscript analysis/reliability/export_tagged_trt_reliability.R
```

The same `samp10k` reliability exports are verified by
`analysis/manuscript/verify_manuscript_results.R` and plotted by
`analysis/figures/plot_trt_reliability_spearman_icc_panels.py`.
Bootstrap Spearman CIs are in `*_samp10k_trt_reliability_spearman_overall.csv`.

Targets and tolerances live in `analysis/manuscript/manuscript_targets.R`.
