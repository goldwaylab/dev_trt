# dev_trt — TRT Task Code and Manuscript Reproduction

This repository accompanies the manuscript:

> Goldway et al., *Assessing the test–retest reliability of a reinforcement-learning task battery across development*.

It is intended as a public reproducibility package for the published work. The
repository combines:

- **PsychoJS / Pavlovia** task code for RISK, PIT, and TwoStep.
- Processed data and analysis code needed to reproduce the manuscript's test-retest
  reliability analyses, behavioral model summaries, and manuscript figures.

Raw Pavlovia exports are not included. The data bundled here are processed and
de-identified files used by the reproduction workflow.

## Update log

**2026-09-22** — Brought the canonical models and reliability numbers up to date
with the current manuscript draft (this repo had not been updated since 2026-07-06):

- RISK and PIT now use their current 4-parameter models, `rstd_m9_sh.stan` and
  `pgng_m3_sh.stan` (previously the repo shipped an earlier, superseded model
  version for each task).
- TwoStep now uses a free-forgetting model (`two_step_free_forgetting_nc.stan`)
  that separates the learning rate from the unchosen-value forgetting rate; the
  old model tied them together (`lambda` fixed to 1, `phi = eta` implicitly),
  which is what caused a posterior-predictive-check failure the new model fixes.
  See `analysis/manuscript/TWOSTEP_OLD_NEW_COMPARISON_AND_FORGETTING_RATIONALE_20260921.md`.
- `analysis/manuscript/manuscript_targets.R` and the cached reliability CSVs in
  `data/parameter_estimates/{risk,pit,twostep}/` were regenerated against these
  models; `Rscript analysis/manuscript/verify_manuscript_results.R` passes
  67/67 checks against them as of this update.
- Known gap: the age-moderation checks (session-1-by-age interaction on
  reliability) are not yet wired into the automated verification script for all
  three tasks the way the point-estimate Spearman/ICC checks are — the reported
  age-moderation p-values in the manuscript have been checked by hand against
  the cached Stan summaries, but there's no automated regression test for them
  yet. By-age reliability breakdowns (`*_trt_reliability_*_by_age.csv`) also
  have not been regenerated for the current models.

## Task Code

| Folder | Task |
|---|---|
| [`tasks/pavlovia/source/risk/`](tasks/pavlovia/source/risk/) | RISK — valence asymmetry |
| [`tasks/pavlovia/source/pit/`](tasks/pavlovia/source/pit/) | PIT — Pavlovian bias |
| [`tasks/pavlovia/source/two-step/`](tasks/pavlovia/source/two-step/) | TWO-STEP — model-based / model-free |

## Manuscript Reproduction

The main reproduction entry point is:

```bash
bash analysis/run_manuscript_tier_a.sh
```

This regenerates manuscript result summaries and figures from processed behavior
files, cached Stan summaries, cached parameter-recovery outputs, and bundled model
tables. It writes figures to `outputs/figures/` and the numeric reproduction report to:

- `analysis/manuscript/manuscript_verification_report.txt`
- `analysis/manuscript/manuscript_verification_report.csv`

For a numeric-only check:

```bash
Rscript analysis/manuscript/verify_manuscript_results.R
```

## Reproduction Tiers

Tier A uses processed behavioral CSVs and cached canonical `samp10k` Stan
summaries/subject-level estimates. This tier is fast enough for a local machine and
does not require raw Pavlovia exports or CmdStan.

Tier B is optional full Stan refitting. The scripts live in `analysis/stan_fitting/`
and use the Stan models in `models/stan/`. They require CmdStan/CmdStanPy and can take
many hours depending on the computing environment. See `docs/optional_stan_refits.md`
for the lightweight refit entry points.

## Repository Layout

- `analysis/manuscript/`: manuscript targets and reproduction report script.
- `analysis/model_free/`: behavioral model scripts plus cached manuscript tables.
- `analysis/reliability/`: Spearman/ICC reliability export code.
- `analysis/figures/`: manuscript figure generation scripts.
- `analysis/recovery/`: cached parameter-recovery summaries used by figures.
- `analysis/stan_fitting/`: optional Tier B Stan refit scripts.
- `data/behavioral/`: processed task behavior files only.
- `data/parameter_estimates/`: canonical `samp10k` cached Stan summaries and reliability tables.
- `models/stan/`: canonical Stan model files.
- `tasks/pavlovia/source/`: task source snapshots, no participant exports.

## Environment

The local snapshot was checked with R 4.4.2 and Python 3.9.6. R dependencies are captured
in `renv.lock`; Python dependencies are listed in `requirements.txt`.
For headless machines, set:

```bash
export MPLBACKEND=Agg
export MPLCONFIGDIR="$PWD/.mplconfig"
```

The main Tier A script sets those Matplotlib variables automatically.
