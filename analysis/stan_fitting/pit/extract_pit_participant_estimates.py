#!/usr/bin/env python3
"""Extract pit_pavlovian_bias participant-level parameters with age from a cmdstanpy fit summary."""

from __future__ import annotations

import argparse
import os
import re

import pandas as pd


PARAM_PATTERNS = {
    "b1": "Reward Sensitivity",
    "b2": "Punishment Sensitivity",
    "b3": "Approach Bias",
    "b4": "Avoidance Bias",
    "a1": "Positive Learning Rate",
    "a2": "Negative Learning Rate",
}


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--repo-root", default=os.getcwd())
    p.add_argument("--summary", required=True)
    p.add_argument("--subjects", required=True)
    p.add_argument("--output", required=True)
    return p.parse_args()


def main() -> None:
    args = parse_args()
    s1 = pd.read_csv(os.path.join(args.repo_root, "data", "behavioral", "pit", "s1", "pgng.csv"))
    age_map = s1[["subject", "age"]].drop_duplicates()
    subj_map = pd.read_csv(args.subjects).sort_values("subject").reset_index(drop=True)
    subj_map["stan_idx"] = subj_map.index + 1

    stan_summary = pd.read_csv(args.summary, sep="\t")
    first_col = stan_summary.columns[0]

    rows = []
    for param_code, param_name in PARAM_PATTERNS.items():
        pat = re.compile(rf"^{re.escape(param_code)}\[(\d+),(\d+)\]$")
        for _, row in stan_summary.iterrows():
            key = str(row[first_col]).strip('"')
            m = pat.match(key)
            if not m:
                continue
            session_idx, stan_idx = map(int, m.groups())
            subj_row = subj_map.loc[subj_map["stan_idx"] == stan_idx]
            if subj_row.empty:
                continue
            subject_id = int(subj_row["subject"].iloc[0])
            age_row = age_map.loc[age_map["subject"] == subject_id]
            if age_row.empty:
                continue
            rows.append(
                {
                    "parameter": param_code,
                    "parameter_name": param_name,
                    "session": session_idx,
                    "subject_id": subject_id,
                    "age": float(age_row["age"].iloc[0]),
                    "param_value": float(row["Mean"]),
                }
            )

    out = pd.DataFrame(rows)
    out["age_group"] = pd.cut(
        out["age"], bins=[0, 15, 20, 30], labels=["10-15", "15-20", "20-25"], include_lowest=True
    )
    os.makedirs(os.path.dirname(args.output) or ".", exist_ok=True)
    out.to_csv(args.output, index=False)
    print(f"Wrote {args.output} ({len(out)} rows, {out['subject_id'].nunique()} subjects)")


if __name__ == "__main__":
    main()
