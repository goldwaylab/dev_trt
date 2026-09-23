#!/usr/bin/env bash
# Tier A: reproduce manuscript outputs from processed data and cached Stan summaries.
set -euo pipefail
cd "$(dirname "$0")/.."

export MPLBACKEND="${MPLBACKEND:-Agg}"
export MPLCONFIGDIR="${MPLCONFIGDIR:-$PWD/.mplconfig}"
mkdir -p "$MPLCONFIGDIR" outputs/figures

echo "=== Reliability metrics ==="
FIT_TAG=samp10k Rscript analysis/reliability/export_tagged_trt_reliability.R

echo "=== Manuscript statistics verification ==="
Rscript analysis/manuscript/verify_manuscript_results.R

echo "=== Behavioral figures ==="
Rscript analysis/figures/save_risk_ab_from_model_free.R
Rscript analysis/figures/plot_pit_figure4_ab_revised.R
Rscript analysis/figures/plot_twostep_figure5_ab_revised.R

echo "=== Reliability figures ==="
Rscript analysis/figures/generate_canonical_trt_figures.R
python3 analysis/figures/plot_risk_reliability_dotplot.py
python3 analysis/figures/plot_pit_reliability_dotplot.py
python3 analysis/figures/plot_two_step_reliability_dotplot.py
python3 analysis/figures/plot_trt_reliability_spearman_icc_panels.py --fit-tag samp10k --tasks risk pit two_step_fixed_lambda

echo "=== Posterior predictive checks ==="
python3 analysis/figures/plot_risk_trt_ppc_session_structure.py --fit-tag samp10k
python3 analysis/figures/plot_pit_trt_ppc_reference_style.py
python3 analysis/figures/plot_two_step_ppc_session_structure.py --fit-tag samp10k --output-stem two_step_fixed_lambda_trt_ppc_session_structure

echo "=== Parameter recovery figures ==="
python3 analysis/figures/plot_risk_param_recovery_posterior.py --style poster --prefer-indep
python3 analysis/figures/plot_task_param_recovery_posterior.py --task pit --style poster
python3 analysis/figures/plot_task_param_recovery_posterior.py --task two_step_fixed_lambda --style poster

echo "Done. Verification report: analysis/manuscript/manuscript_verification_report.txt"
