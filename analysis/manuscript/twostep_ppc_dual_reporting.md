# TwoStep PPC — dual reporting (RL model + GLMM)

## Rationale

The canonical fix-λ hybrid RL model (`two_step_fixed_lambda.stan`) captures **trial-level stay probabilities** and **subject-level parameters** well (Panel B: Spearman ρ ≥ 0.91), but **modestly underpredicts** the group-level **reward × transition interaction** on stay (~50% of the observed contrast). Longer MCMC (s10k) and sum/diff reparameterization did not change this pattern.

**Dual reporting:** use the RL model for mechanisms, test–retest reliability, and individual-differences analyses; use the **logistic GLMM** (`run_twostep_stay_model_harmonized.R`) for **aggregate stay-pattern inference** (reward × transition and extensions).

---

## Figure caption (recommended)

**Figure X. Two-step task: stay behavior and hybrid RL posterior predictive checks (test–retest cohort).**

**(A)** Proportion of first-stage stays as a function of prior-trial reward (Reward vs No Reward) and transition (Common vs Rare), shown separately for Session 1 and Session 2. **Observed** bars (filled) show group means ± SEM across participants; **Model** bars (hatched) show predictions from the canonical fix-λ hybrid RL model fitted with subject- and session-specific parameters (`two_step_fixed_lambda.stan`). Inferential statistics for the reward × transition interaction and higher-order terms were evaluated with a complementary **logistic GLMM** on trial-level stay (see Supplementary Table X): reward × transition, χ²(1) = 81.8, *p* < .001; reward × transition × age, χ²(1) = 6.0, *p* = .014.

**(B)** Participant-level observed versus model-predicted mean *p*(stay), split by prior transition (common vs rare), with root-mean-square error (RMSE) and Spearman ρ for each session. The dashed line indicates perfect correspondence.

---

## Results text (short paragraph)

Posterior predictive checks indicated that the fix-λ hybrid RL model captured participant-level stay tendencies (Session 1: ρ = 0.92; Session 2: ρ = 0.91) and overall stay rates across conditions, but slightly underestimated the magnitude of the group-level reward × transition interaction on stay. We therefore report inferential statistics for this aggregate stay pattern from a complementary logistic mixed model (`stay ~ previous_reward × previous_transition × age_z × session + random slopes`; Supplementary Table X). The reward × transition interaction was strongly significant (χ²(1) = 81.8, *p* < .001), with a significant three-way interaction with age (χ²(1) = 6.0, *p* = .014). Individual-difference analyses, test–retest reliability, and computational parameters are based on the hybrid RL model throughout.

---

## Supplementary table

Exported CSV: `data/parameter_estimates/twostep/twostep_stay_glmm_dual_report_table.csv`

Source scripts:
- GLMM fit: `analysis/model_free/run_twostep_stay_model_harmonized.R`
- PPC figure: `analysis/figures/plot_two_step_ppc_session_structure.py`

Regenerate:
```bash
Rscript analysis/model_free/run_twostep_stay_model_harmonized.R   # if TWOSTEP_STAY_REFIT=1
python3 analysis/figures/export_twostep_stay_glmm_dual_report.py
python3 analysis/figures/plot_two_step_ppc_session_structure.py --fit-tag samp10k
```
