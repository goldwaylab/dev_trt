#!/usr/bin/env bash
# Canonical TRT stats + reliability figures for the manuscript models.
set -euo pipefail
cd "$(dirname "$0")/.."

export MPLBACKEND="${MPLBACKEND:-Agg}"
export MPLCONFIGDIR="${MPLCONFIGDIR:-$PWD/.mplconfig}"
mkdir -p "$MPLCONFIGDIR" outputs/figures

echo "=== Export reliability metrics (CSV) ==="
FIT_TAG=samp10k Rscript analysis/reliability/export_tagged_trt_reliability.R

echo "=== Console verification ==="
Rscript analysis/reliability/verify_risk_reliability.R
Rscript analysis/reliability/verify_pit_reliability.R
Rscript analysis/reliability/verify_two_step_reliability.R

echo "=== Scatter figure panels ==="
Rscript analysis/figures/generate_canonical_trt_figures.R

echo "=== By-age dotplots ==="
python3 analysis/figures/plot_risk_reliability_dotplot.py
python3 analysis/figures/plot_pit_reliability_dotplot.py
python3 analysis/figures/plot_two_step_reliability_dotplot.py

echo "=== Paper-style panels: Spearman (top) + ICC (bottom) ==="
python3 analysis/figures/plot_trt_reliability_spearman_icc_panels.py --fit-tag samp10k --tasks risk pit two_step_fixed_lambda

echo "Done. Main figures are in outputs/figures/."
