#!/usr/bin/env python3
from __future__ import annotations

"""
Fit the canonical manuscript RISK TRT model with cmdstanpy.

Default cohort is TRT (both-session participants only). Use --full-sample for all subjects
present in concatenated S1+S2 behavioral CSVs (single-session subjects retained).

Output prefix:
  TRT, pooled sessions:   risk_valence_asymmetry_fit_*
  Tagged TRT fit:         risk_valence_asymmetry_samp10k_fit_*

Usage:
  python analysis/stan_fitting/risk/run_risk_stan_fit.py [--repo-root PATH]
  python analysis/stan_fitting/risk/run_risk_stan_fit.py --output-cohort-tag samp10k --iter-sampling 10000
"""

import argparse
import json
import os
from datetime import datetime

import pandas as pd
from cmdstanpy import CmdStanModel


def output_prefix(model: str, session: int | None, full_sample: bool, cohort_tag: str | None = None) -> str:
    """
    TRT cohort (default): risk_valence_asymmetry_fit, risk_valence_asymmetry_s1_fit.
    With cohort_tag=\"samp10k\": risk_valence_asymmetry_samp10k_fit.
    """
    parts = [model]
    if session is not None:
        parts.append(f"s{session}")
    if cohort_tag:
        t = cohort_tag.strip().replace(" ", "_").replace("/", "_")
        if t:
            parts.append(t)
    if full_sample:
        parts.append("full")
    parts.append("fit")
    return "_".join(parts)


def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--model",
        default="risk_valence_asymmetry",
        choices=["risk_valence_asymmetry"],
        help="Canonical manuscript model shipped in this repository.",
    )
    ap.add_argument("--repo-root", default=os.getcwd())
    ap.add_argument("--chains", type=int, default=4)
    ap.add_argument("--iter-warmup", type=int, default=2000)
    ap.add_argument("--iter-sampling", type=int, default=2000)
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--session", type=int, choices=[1, 2], default=None)
    ap.add_argument("--full-sample", action="store_true", help="Do not restrict to TRT (both-session) participants.")
    ap.add_argument("--s1-data", default=None, help="Optional path to session-1 CSV.")
    ap.add_argument("--s2-data", default=None, help="Optional path to session-2 CSV.")
    ap.add_argument(
        "--output-cohort-tag",
        default=None,
        help="Optional short label inserted into output filenames (e.g. discovery) so different "
        "behavioral cohorts do not overwrite one another.",
    )
    return ap.parse_args()


def load_data(repo_root, session=None, full_sample=False, s1_data=None, s2_data=None):
    default_s1 = os.path.join(repo_root, "data", "behavioral", "risk", "s1", "data.csv")
    default_s2 = os.path.join(repo_root, "data", "behavioral", "risk", "s2", "data.csv")
    s1_path = s1_data or default_s1
    s2_path = s2_data or default_s2

    # Avoid mixing cohorts: TP0 session-1-only fits should not pull default TRT session-2.
    single_session_cohort = (
        session == 1 and s1_data is not None and s2_data is None and s1_path != default_s1
    ) or (session == 2 and s2_data is not None and s1_data is None and s2_path != default_s2)

    if single_session_cohort:
        if session == 1:
            s1 = pd.read_csv(s1_path)
            s1["session"] = 1
            data = s1
        else:
            s2 = pd.read_csv(s2_path)
            s2["session"] = 2
            data = s2
    else:
        s1 = pd.read_csv(s1_path)
        s2 = pd.read_csv(s2_path)
        s1["session"] = 1
        s2["session"] = 2
        data = pd.concat([s1, s2], ignore_index=True)
    if full_sample:
        keep_subjects = sorted(data["subject"].unique().tolist())
    else:
        both = data.groupby("subject")["session"].nunique()
        keep_subjects = sorted(both[both == 2].index.tolist())
        data = data[data["subject"].isin(keep_subjects)].copy()
    if session is not None:
        data = data[data["session"] == session].copy()
        keep_subjects = sorted(data["subject"].unique().tolist())
    if len(keep_subjects) < 2:
        raise RuntimeError("Not enough participants found for RISK.")
    subj_to_idx = {sid: i + 1 for i, sid in enumerate(keep_subjects)}
    data["J"] = data["subject"].map(subj_to_idx).astype(int)
    data["K"] = data["bandit"].astype(int)
    data["Y"] = data["choice"].astype(int)
    # Legacy/OG pipeline uses points-based reward coding.
    # Using outcome>0 would wrongly code sure-option outcome=5 as reward=1.
    if "points" in data.columns:
        data["R"] = (data["points"].astype(float) > 0).astype(int)
    else:
        data["R"] = (data["outcome"].astype(float) > 0).astype(int)
    data = data.sort_values(["subject", "session", "block", "trial"]).reset_index(drop=True)

    # Previous choice within subject x session x bandit history (required by m4/m5)
    data["X"] = (
        data.groupby(["subject", "session", "bandit"])["Y"]
        .shift(1)
        .map({1: 1, 0: -1})
        .fillna(0)
        .astype(int)
    )
    return data, keep_subjects


def main():
    args = parse_args()
    repo_root = os.path.abspath(args.repo_root)
    out_dir = os.path.join(repo_root, "data", "parameter_estimates", "risk")
    os.makedirs(out_dir, exist_ok=True)

    stan_file = os.path.join(repo_root, "models", "stan", "risk", f"{args.model}.stan")
    if not os.path.exists(stan_file):
        raise FileNotFoundError(stan_file)

    data, keep_subjects = load_data(
        repo_root,
        session=args.session,
        full_sample=args.full_sample,
        s1_data=args.s1_data,
        s2_data=args.s2_data,
    )
    dd = {
        "N": int(len(data)),
        "J": data["J"].tolist(),
        "K": data["K"].tolist(),
        "Y": data["Y"].tolist(),
        "R": data["R"].tolist(),
    }
    dd["M"] = data["session"].astype(int).tolist()

    print(f"=== RISK {args.model} fit ===")
    print(f"Participants: {len(keep_subjects)}")
    print(f"Session: {'both (pooled)' if args.session is None else args.session}")
    print(f"Cohort: {'full sample' if args.full_sample else 'TRT only'}")
    print(f"Trials: {dd['N']}")

    model = CmdStanModel(stan_file=stan_file)
    fit = model.sample(
        data=dd,
        chains=args.chains,
        iter_warmup=args.iter_warmup,
        iter_sampling=args.iter_sampling,
        seed=args.seed,
        show_progress=True,
    )

    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    prefix = output_prefix(args.model, args.session, args.full_sample, cohort_tag=args.output_cohort_tag)
    summary_path = os.path.join(out_dir, f"{prefix}_summary_{ts}.tsv")
    draws_path = os.path.join(out_dir, f"{prefix}_draws_{ts}.tsv.gz")
    subjects_path = os.path.join(out_dir, f"{prefix}_subjects_{ts}.csv")
    meta_path = os.path.join(out_dir, f"{prefix}_metadata_{ts}.json")

    beh_s1 = os.path.abspath(args.s1_data) if args.s1_data else os.path.join(
        repo_root, "data", "behavioral", "risk", "s1", "data.csv"
    )
    beh_s2 = os.path.abspath(args.s2_data) if args.s2_data else os.path.join(
        repo_root, "data", "behavioral", "risk", "s2", "data.csv"
    )
    if args.session == 1 and args.s1_data is not None and args.s2_data is None:
        beh_s2 = None
    elif args.session == 2 and args.s2_data is not None and args.s1_data is None:
        beh_s1 = None

    fit.summary(percentiles=(2.5, 50, 97.5), sig_figs=4).to_csv(summary_path, sep="\t")
    fit.draws_pd().to_csv(draws_path, sep="\t", index=False, compression="gzip")
    pd.DataFrame({"subject": keep_subjects, "stan_idx": range(1, len(keep_subjects) + 1)}).to_csv(subjects_path, index=False)
    with open(meta_path, "w") as f:
        json.dump(
            {
                "model": args.model,
                "stan_file": os.path.basename(stan_file),
                "n_participants": len(keep_subjects),
                "session": args.session,
                "full_sample": args.full_sample,
                "behavior_s1_csv": beh_s1,
                "behavior_s2_csv": beh_s2,
                "n_trials": dd["N"],
                "chains": args.chains,
                "iter_warmup": args.iter_warmup,
                "iter_sampling": args.iter_sampling,
                "seed": args.seed,
                "output_cohort_tag": args.output_cohort_tag,
                "summary_path": os.path.basename(summary_path),
                "draws_path": os.path.basename(draws_path),
                "subjects_path": os.path.basename(subjects_path),
            },
            f,
            indent=2,
        )

    print(f"Saved summary: {summary_path}")
    print(f"Saved draws:   {draws_path}")
    print(f"Saved subjects:{subjects_path}")
    print(f"Saved meta:    {meta_path}")
    print(fit.diagnose())


if __name__ == "__main__":
    main()
