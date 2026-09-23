# Optional Tier B Stan Refits

Tier A does not require CmdStan. Use this note only if you want to rerun the canonical
Stan models from the processed behavioral files.

Canonical models (updated 2026-09-22 — see `analysis/manuscript/manuscript_targets.R`
for the verified reliability numbers these produce):

- RISK: `models/stan/risk/rstd_m9_sh.stan` (4 parameters: beta, confirmatory and
  disconfirmatory learning rate, initial Q-value)
- PIT: `models/stan/pit/pgng_m3_sh.stan` (4 parameters: beta, go bias in gain/loss
  context, learning rate)
- TwoStep: `models/stan/twostep/two_step_free_forgetting_nc.stan` (6 parameters:
  learning rate, unchosen-value forgetting rate, model-based beta, model-free
  beta, stickiness, stage-2 temperature). This replaces
  `two_step_fixed_lambda_nc.stan` (kept here for reference/comparison — see
  `analysis/manuscript/TWOSTEP_OLD_NEW_COMPARISON_AND_FORGETTING_RATIONALE_20260921.md`
  for why forgetting was separated from the learning rate).

Laptop examples:

```bash
python3 analysis/stan_fitting/risk/run_risk_stan_fit.py --output-cohort-tag local --iter-warmup 1000 --iter-sampling 1000
python3 analysis/stan_fitting/pit/run_pit_stan_fit.py --output-tag local --iter-warmup 1000 --iter-sampling 1000
python3 analysis/stan_fitting/twostep/run_two_step_stan_fit.py --output-tag local --iter-warmup 1000 --iter-sampling 1000
```

For full-length refits, adapt these scripts to your own compute environment and scheduler.
