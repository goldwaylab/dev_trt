#!/usr/bin/env python3
"""
Fit PIT pit_pavlovian_bias Stan model with cmdstanpy.

Outputs (data/parameter_estimates/pit/):
  - pit_pavlovian_bias[_<tag>_]fit_summary_<timestamp>.tsv
  - pit_pavlovian_bias[_<tag>_]fit_draws_<timestamp>.tsv.gz
  - pit_pavlovian_bias[_<tag>_]fit_subjects_<timestamp>.csv
  - pit_pavlovian_bias[_<tag>_]fit_metadata_<timestamp>.json
"""

from __future__ import annotations

import argparse
import json
import os
from datetime import datetime

import numpy as np
import pandas as pd
from cmdstanpy import CmdStanModel


def output_stem(tag: str | None) -> str:
    if tag:
        return f"pit_pavlovian_bias_{tag}_fit"
    return "pit_pavlovian_bias_fit"


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Fit TRT pit_pavlovian_bias with cmdstanpy.")
    p.add_argument("--repo-root", default=os.getcwd())
    p.add_argument("--chains", type=int, default=4)
    p.add_argument("--iter-warmup", type=int, default=5000)
    p.add_argument("--iter-sampling", type=int, default=1250)
    p.add_argument("--seed", type=int, default=0)
    p.add_argument(
        "--output-tag",
        default=None,
        help="Optional label in output filenames (e.g. samp10k) so runs do not overwrite.",
    )
    return p.parse_args()


def main() -> None:
    args = parse_args()
    repo_root = args.repo_root
    stan_file = os.path.join(repo_root, "models", "stan", "pit", "pit_pavlovian_bias.stan")
    s1_path = os.path.join(repo_root, "data", "behavioral", "pit", "s1", "pgng.csv")
    s2_path = os.path.join(repo_root, "data", "behavioral", "pit", "s2", "pgng.csv")
    out_dir = os.path.join(repo_root, "data", "parameter_estimates", "pit")
    os.makedirs(out_dir, exist_ok=True)

    for path in (stan_file, s1_path, s2_path):
        if not os.path.exists(path):
            raise FileNotFoundError(path)

    s1 = pd.read_csv(s1_path)
    s2 = pd.read_csv(s2_path)
    s1["session"] = 1
    s2["session"] = 2
    data = pd.concat([s1, s2], ignore_index=True)

    both = data.groupby("subject")["session"].nunique()
    keep_subjects = sorted(both[both == 2].index.tolist())
    data = data[data["subject"].isin(keep_subjects)].copy()
    if len(keep_subjects) < 2:
        raise RuntimeError("Not enough TRT PIT participants found.")

    subj_to_idx = {sid: i + 1 for i, sid in enumerate(keep_subjects)}
    data["J"] = data["subject"].map(subj_to_idx).astype(int)
    data["K"] = data["stimulus"].astype(int)
    data["M"] = data["session"].astype(int)
    data["Y"] = data["choice"].astype(int)
    data["V"] = data["valence"].replace({"win": 1, "lose": 0}).astype(int)
    data["R"] = np.where(data["V"] == 1, data["outcome"] > 5, data["outcome"] > -5).astype(int)

    stan_data = {
        "N": int(len(data)),
        "J": data["J"].tolist(),
        "K": data["K"].tolist(),
        "M": data["M"].tolist(),
        "Y": data["Y"].tolist(),
        "R": data["R"].tolist(),
        "V": data["V"].tolist(),
    }

    print("=== PIT pit_pavlovian_bias fit (cmdstanpy) ===")
    print(f"Participants: {len(keep_subjects)}")
    print(f"Trials: {stan_data['N']}")
    print(
        f"Chains: {args.chains}  Warmup: {args.iter_warmup}  "
        f"Sampling: {args.iter_sampling}  tag: {args.output_tag or '(none)'}"
    )

    model = CmdStanModel(stan_file=stan_file)
    fit = model.sample(
        data=stan_data,
        chains=args.chains,
        iter_warmup=args.iter_warmup,
        iter_sampling=args.iter_sampling,
        parallel_chains=args.chains,
        seed=args.seed,
        show_progress=True,
    )

    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    stem = output_stem(args.output_tag)
    summary = fit.summary(percentiles=(2.5, 50, 97.5), sig_figs=4)
    summary_path = os.path.join(out_dir, f"{stem}_summary_{ts}.tsv")
    summary.to_csv(summary_path, sep="\t")

    draws = fit.draws_pd()
    draws_path = os.path.join(out_dir, f"{stem}_draws_{ts}.tsv.gz")
    draws.to_csv(draws_path, sep="\t", index=False, compression="gzip")

    subj_path = os.path.join(out_dir, f"{stem}_subjects_{ts}.csv")
    pd.DataFrame({"subject": keep_subjects, "stan_idx": range(1, len(keep_subjects) + 1)}).to_csv(
        subj_path, index=False
    )

    meta = {
        "timestamp": ts,
        "output_tag": args.output_tag,
        "stan_model": os.path.basename(stan_file),
        "n_participants": len(keep_subjects),
        "n_trials": stan_data["N"],
        "n_chains": args.chains,
        "iter_warmup": args.iter_warmup,
        "iter_sampling": args.iter_sampling,
        "summary_path": os.path.basename(summary_path),
        "draws_path": os.path.basename(draws_path),
        "subjects_path": os.path.basename(subj_path),
    }
    meta_path = os.path.join(out_dir, f"{stem}_metadata_{ts}.json")
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2)

    print(f"Saved summary: {summary_path}")
    print(f"Saved draws:   {draws_path}")
    print(f"Saved subjects:{subj_path}")
    print(f"Saved meta:    {meta_path}")
    print("\n=== CmdStan diagnostics ===")
    print(fit.diagnose())
    print("=== DONE ===")


if __name__ == "__main__":
    main()
