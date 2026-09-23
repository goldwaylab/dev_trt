#!/usr/bin/env python3
"""
TRT TwoStep Stan fit — fixed-lambda model (cmdstanpy).

Fits:
  two_step_fixed_lambda.stan

Outputs (data/parameter_estimates/twostep/):
  - two_step_fixed_lambda[_<tag>_]fit_summary_<timestamp>.tsv
  - two_step_fixed_lambda[_<tag>_]fit_draws_<timestamp>.tsv.gz
  - two_step_fixed_lambda[_<tag>_]fit_subjects_<timestamp>.csv
  - two_step_fixed_lambda[_<tag>_]fit_metadata_<timestamp>.json
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
        return f"two_step_fixed_lambda_{tag}_fit"
    return "two_step_fixed_lambda_fit"


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Fit TRT TwoStep fixed-lambda model with cmdstanpy.")
    p.add_argument("--repo-root", default=os.getcwd())
    p.add_argument("--chains", type=int, default=4)
    p.add_argument("--iter-warmup", type=int, default=5000)
    p.add_argument("--iter-sampling", type=int, default=5000)
    p.add_argument("--adapt-delta", type=float, default=0.90)
    p.add_argument("--max-treedepth", type=int, default=12)
    p.add_argument("--seed", type=int, default=42)
    p.add_argument(
        "--output-tag",
        default=None,
        help="Optional label in output filenames (e.g. samp10k) so runs do not overwrite.",
    )
    return p.parse_args()


def process_session(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)
    df = df.rename(columns={"participant_ID": "participant_id"})
    df["c1"] = (df["choice_1"] == 2).astype(int)
    df["c2"] = (df["choice_2"] == 2).astype(int)
    df["transition_bin"] = df["transition"].str.strip().str.lower().eq("common").astype(int)
    df["r"] = df["reward"].astype(int)
    df = df.dropna(subset=["c1", "c2", "transition_bin", "r"])
    return df[["participant_id", "c1", "c2", "transition_bin", "r"]].copy()


def main() -> None:
    args = parse_args()
    repo_root = args.repo_root
    stan_file = os.path.join(
        repo_root, "models", "stan", "twostep", "two_step_fixed_lambda.stan"
    )
    s1_path = os.path.join(repo_root, "data", "behavioral", "twostep", "s1", "MBMF_data_processed_2.csv")
    s2_path = os.path.join(repo_root, "data", "behavioral", "twostep", "s2", "MBMF_data_processed_2.csv")
    out_dir = os.path.join(repo_root, "data", "parameter_estimates", "twostep")
    os.makedirs(out_dir, exist_ok=True)

    for path in (stan_file, s1_path, s2_path):
        if not os.path.exists(path):
            raise FileNotFoundError(path)

    s1 = process_session(s1_path)
    s2 = process_session(s2_path)

    trt_ids = sorted(set(s1["participant_id"]) & set(s2["participant_id"]))
    if len(trt_ids) < 2:
        raise RuntimeError(f"Only {len(trt_ids)} TRT participants found")
    id_map = {pid: idx + 1 for idx, pid in enumerate(trt_ids)}

    def make_long(df: pd.DataFrame, sess: int) -> pd.DataFrame:
        df = df[df["participant_id"].isin(trt_ids)].copy()
        df["participant_idx"] = df["participant_id"].map(id_map)
        df["session"] = sess
        df["st"] = np.where(
            (df["c1"] == 0) & (df["transition_bin"] == 1) | (df["c1"] == 1) & (df["transition_bin"] == 0),
            1,
            2,
        )
        return df[["participant_idx", "session", "c1", "c2", "st", "r"]]

    combined = pd.concat([make_long(s1, 1), make_long(s2, 2)], ignore_index=True)
    combined = combined.sort_values(["participant_idx", "session"]).reset_index(drop=True)

    stan_data = {
        "N": len(combined),
        "NS": len(trt_ids),
        "M": 2,
        "subj": combined["participant_idx"].tolist(),
        "session": combined["session"].tolist(),
        "c1": combined["c1"].tolist(),
        "c2": combined["c2"].tolist(),
        "st": combined["st"].tolist(),
        "r": combined["r"].tolist(),
    }

    print("=== TRT 2-STEP FIXLAMBDA FIT (cmdstanpy) ===")
    print(f"Participants: {stan_data['NS']}")
    print(f"Trials: {stan_data['N']}")
    print(
        f"Chains: {args.chains}  Warmup: {args.iter_warmup}  "
        f"Sampling: {args.iter_sampling}  tag: {args.output_tag or '(none)'}"
    )
    print(f"adapt_delta: {args.adapt_delta}  max_treedepth: {args.max_treedepth}\n")

    model = CmdStanModel(stan_file=stan_file)
    fit = model.sample(
        data=stan_data,
        chains=args.chains,
        iter_warmup=args.iter_warmup,
        iter_sampling=args.iter_sampling,
        adapt_delta=args.adapt_delta,
        max_treedepth=args.max_treedepth,
        seed=args.seed,
        show_progress=True,
    )

    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    stem = output_stem(args.output_tag)
    summary = fit.summary(percentiles=(2.5, 50, 97.5), sig_figs=4)
    summary_path = os.path.join(out_dir, f"{stem}_summary_{ts}.tsv")
    summary.to_csv(summary_path, sep="\t")
    print(f"Saved summary: {summary_path}")

    draws = fit.draws_pd()
    draws_path = os.path.join(out_dir, f"{stem}_draws_{ts}.tsv.gz")
    draws.to_csv(draws_path, sep="\t", index=False, compression="gzip")
    print(f"Saved draws: {draws_path}")

    id_map_path = os.path.join(out_dir, f"{stem}_subjects_{ts}.csv")
    pd.DataFrame({"participant_id": trt_ids, "stan_idx": range(1, len(trt_ids) + 1)}).to_csv(
        id_map_path, index=False
    )
    print(f"Saved ID map: {id_map_path}")

    meta = {
        "model": os.path.basename(stan_file),
        "output_tag": args.output_tag,
        "n_participants": stan_data["NS"],
        "n_trials": stan_data["N"],
        "n_chains": args.chains,
        "iter_warmup": args.iter_warmup,
        "iter_sampling": args.iter_sampling,
        "adapt_delta": args.adapt_delta,
        "max_treedepth": args.max_treedepth,
        "timestamp": ts,
        "summary_path": os.path.basename(summary_path),
        "draws_path": os.path.basename(draws_path),
    }
    meta_path = os.path.join(out_dir, f"{stem}_metadata_{ts}.json")
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2)
    print(f"Saved metadata: {meta_path}")

    print("\n=== CmdStan diagnostics ===")
    print(fit.diagnose())
    print("=== DONE ===")


if __name__ == "__main__":
    main()
