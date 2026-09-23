#!/usr/bin/env python3
"""Print manuscript-ready TRT reliability stats for tagged fits."""

from __future__ import annotations

import argparse
import os

import pandas as pd


RISK_PARAM_ORDER = ["b1", "q0", "a1", "a2", "a3", "a4"]
RISK_NAMES = {
    "b1": "β",
    "q0": "Q0",
    "a1": "η⁺(chosen)",
    "a2": "η⁻(chosen)",
    "a3": "η⁺(unchosen)",
    "a4": "η⁻(unchosen)",
}

PIT_PARAM_ORDER = ["a1", "a2", "b1", "b2", "b3", "b4"]
PIT_NAMES = {
    "b1": "β_reward",
    "b2": "β_punishment",
    "b3": "τ_reward",
    "b4": "τ_punishment",
    "a1": "η⁺",
    "a2": "η⁻",
}


def fmt_rho(row: pd.Series) -> str:
    return f"ρ = {row['spearman_rho']:.2f}, 95% CI [{row['spearman_ci_lo']:.2f}, {row['spearman_ci_hi']:.2f}]"


def fmt_icc(row: pd.Series) -> str:
    hi = row["icc_ci_hi"]
    hi_s = f">{hi:.2f}" if hi > 0.99 else f"{hi:.2f}"
    return f"ICC = {row['icc']:.2f} (95% CI [{row['icc_ci_lo']:.2f}, {hi_s}])"


def print_task(task: str, fit_tag: str, param_order: list[str], names: dict[str, str]) -> None:
    base = os.path.join("data", "parameter_estimates", "risk" if task == "risk" else "pit")
    key = f"{'risk' if task == 'risk' else 'pit'}_{fit_tag}"
    rho = pd.read_csv(os.path.join(base, f"{key}_trt_reliability_spearman_overall.csv"))
    icc = pd.read_csv(os.path.join(base, f"{key}_trt_reliability_icc_population.csv"))
    metrics = pd.read_csv(
        os.path.join(base, f"{'risk' if task == 'risk' else 'pit'}_{fit_tag}_test_retest_reliability_metrics.csv")
    )
    age_mod = metrics.loc[metrics["metric_type"] == "age_moderation"]

    print(f"\n=== {task.upper()} ({fit_tag}) ===\n")
    print("Spearman (overall):")
    for p in param_order:
        r = rho.loc[rho["parameter"] == p].iloc[0]
        print(f"  {names[p]:16s} {fmt_rho(r)}")

    print("\nICC (population, hierarchical σ):")
    for p in param_order:
        r = icc.loc[icc["parameter"] == p].iloc[0]
        print(f"  {names[p]:16s} {fmt_icc(r)}")

    print("\nAge moderation (session_1 × z_age), p:")
    for p in param_order:
        row = age_mod.loc[age_mod["parameter"] == p]
        if row.empty:
            continue
        print(f"  {names[p]:16s} p = {row['interaction_p'].iloc[0]:.3f}")

    if task == "pit":
        by_age = pd.read_csv(os.path.join(base, f"{key}_trt_reliability_spearman_by_age.csv"))
        b4 = by_age.loc[by_age["parameter"] == "b4"]
        print("\nPIT b4 (avoidance) by age — Spearman ρ:")
        for _, row in b4.iterrows():
            print(f"  {row['age_group']:18s} ρ = {row['spearman_rho']:.2f}")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--fit-tag", default="samp10k")
    args = p.parse_args()
    print_task("risk", args.fit_tag, RISK_PARAM_ORDER, RISK_NAMES)
    print_task("pit", args.fit_tag, PIT_PARAM_ORDER, PIT_NAMES)


if __name__ == "__main__":
    main()
