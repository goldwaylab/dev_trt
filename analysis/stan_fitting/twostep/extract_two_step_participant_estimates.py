#!/usr/bin/env python3
"""
Extract participant-level posterior means from TRT fixed-lambda TwoStep cmdstanpy fit.

Uses latest tagged two_step_fixed_lambda_<tag>_fit_summary_*.tsv and
two_step_fixed_lambda_<tag>_fit_subjects_*.csv from data/parameter_estimates/twostep/
(same layout as run_two_step_stan_fit.py). Defaults to the canonical samp10k tag.

Writes: two_step_fixed_lambda_<tag>_participant_estimates_<timestamp>.csv
Columns mirror trt_participant_params_mle_subset_*.csv but without lambda_*.

Usage:
  python3 extract_two_step_participant_estimates.py [REPO_ROOT]
"""

from __future__ import annotations

import glob
import os
import sys
from datetime import datetime

import pandas as pd

REPO_ROOT = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
OUT_DIR = os.path.join(REPO_ROOT, "data", "parameter_estimates", "twostep")


def latest(pattern: str) -> str | None:
    c = sorted(glob.glob(os.path.join(OUT_DIR, pattern)), key=os.path.getmtime)
    return c[-1] if c else None


fit_tag = os.environ.get("FIT_TAG", "samp10k")
summary_path = latest(f"two_step_fixed_lambda_{fit_tag}_fit_summary_*.tsv")
id_map_path = latest(f"two_step_fixed_lambda_{fit_tag}_fit_subjects_*.csv")
out_prefix = f"two_step_fixed_lambda_{fit_tag}_participant_estimates"

if summary_path is None or id_map_path is None:
    sys.exit(
        f"Missing two_step_fixed_lambda outputs in {OUT_DIR}.\n"
        f"Copy two_step_fixed_lambda_{fit_tag}_fit_summary_*.tsv and "
        f"two_step_fixed_lambda_{fit_tag}_fit_subjects_*.csv from your refit outputs, or run:\n"
        f"  FIT_TAG={fit_tag} python3 analysis/stan_fitting/twostep/run_two_step_stan_fit.py"
    )

print(f"Using summary: {os.path.basename(summary_path)}")
print(f"Using ID map:  {os.path.basename(id_map_path)}")

summary = pd.read_csv(summary_path, sep="\t", index_col=0)
id_map = pd.read_csv(id_map_path)
n_subjects = len(id_map)

PARAMS_SESS = ["alpha1_sess", "beta1m_sess", "beta1t_sess", "beta2_sess", "betac_sess"]
PARAMS_SHORT = ["alpha1", "beta1m", "beta1t", "beta2", "betac"]
PARAMS_COMMON = ["alpha1_common", "beta1m_common", "beta1t_common", "beta2_common", "betac_common"]

result = pd.DataFrame({"participant_ID": id_map["participant_id"]})

for stan_name, short in zip(PARAMS_SESS, PARAMS_SHORT):
    for sess in [1, 2]:
        means, sds = [], []
        for s in range(1, n_subjects + 1):
            key = f"{stan_name}[{s},{sess}]"
            if key not in summary.index:
                sys.exit(f"Parameter {key} not found in summary.")
            means.append(summary.loc[key, "Mean"])
            sds.append(summary.loc[key, "StdDev"])
        result[f"{short}_session{sess}_mean"] = means
        result[f"{short}_session{sess}_sd"] = sds
    print(f"  Extracted {stan_name}")

for stan_name, short in zip(PARAMS_COMMON, PARAMS_SHORT):
    means, sds = [], []
    for s in range(1, n_subjects + 1):
        key = f"{stan_name}[{s}]"
        if key not in summary.index:
            print(f"  Warning: {key} missing; skip common {short}")
            break
        means.append(summary.loc[key, "Mean"])
        sds.append(summary.loc[key, "StdDev"])
    else:
        result[f"{short}_common_mean"] = means
        result[f"{short}_common_sd"] = sds
        print(f"  Extracted {stan_name}")

ts = datetime.now().strftime("%Y%m%d_%H%M%S")
out_path = os.path.join(OUT_DIR, f"{out_prefix}_{ts}.csv")
result.to_csv(out_path, index=False)
print(f"\nSaved: {out_path} ({len(result)} participants)")
