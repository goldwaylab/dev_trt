#!/usr/bin/env python3
"""TRT reliability dotplot for PIT Pavlovian-bias parameters."""

from __future__ import annotations

import os

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.stats import pearsonr


def age_group(age: float) -> str | None:
    if 10 <= age < 15:
        return "10-15 years old"
    if 15 <= age < 20:
        return "15-20 years old"
    if 20 <= age < 26:
        return "20-25 years old"
    return None


def main() -> None:
    repo_root = os.getcwd()
    pit_path = os.path.join(
        repo_root, "data", "parameter_estimates", "pit", "pit_pavlovian_bias_samp10k_summary_with_age.csv"
    )
    fig_dir = os.path.join(repo_root, "outputs", "figures")
    pit_dir = os.path.join(repo_root, "data", "parameter_estimates", "pit")
    os.makedirs(fig_dir, exist_ok=True)

    df = pd.read_csv(pit_path)
    df["age_group"] = df["age"].apply(age_group)
    df = df[df["age_group"].notna()].copy()

    label_map = {
        "b1": "Reward Sensitivity",
        "b2": "Punishment Sensitivity",
        "b3": "Approach Bias",
        "b4": "Avoidance Bias",
        "a1": "Positive Learning Rate",
        "a2": "Negative Learning Rate",
    }
    param_order = list(label_map.values())
    age_order = ["10-15 years old", "15-20 years old", "20-25 years old"]
    colors = {"10-15 years old": "#E41A1C", "15-20 years old": "#377EB8", "20-25 years old": "#4DAF4A"}
    jitter = {"10-15 years old": -0.12, "15-20 years old": 0.0, "20-25 years old": 0.12}

    rows = []
    for code, label in label_map.items():
        sub = df.loc[df["parameter"] == code]
        w = sub.pivot_table(index="subject_id", columns="session", values="param_value", aggfunc="first")
        w = w.rename(columns={1: "s1", 2: "s2"}).reset_index()
        w = w.merge(
            sub[["subject_id", "age_group"]].drop_duplicates(),
            on="subject_id",
            how="left",
        )
        for ag in age_order:
            a = w.loc[w["age_group"] == ag, ["s1", "s2"]].dropna()
            if len(a) < 3:
                continue
            r, p = pearsonr(a["s1"].to_numpy(float), a["s2"].to_numpy(float))
            rows.append({"parameter": label, "age_group": ag, "correlation": float(r), "p_value": float(p), "n": len(a)})

    out = pd.DataFrame(rows)
    out["parameter"] = pd.Categorical(out["parameter"], categories=param_order, ordered=True)

    fig, ax = plt.subplots(figsize=(12, 7))
    ax.axhline(0.7, linestyle=(0, (5, 5)), color="black", linewidth=2)
    x_map = {p: i for i, p in enumerate(param_order)}
    for ag in age_order:
        da = out[out["age_group"] == ag]
        xs = [x_map[p] + jitter[ag] for p in da["parameter"]]
        ax.scatter(xs, da["correlation"], s=120, alpha=0.92, color=colors[ag], label=ag, zorder=3)

    ax.set_xticks(range(len(param_order)))
    ax.set_xticklabels(param_order, rotation=35, ha="right", fontsize=13)
    ax.set_ylim(-0.05, 1.02)
    ax.set_ylabel("Pearson r (session 1 vs 2)", fontsize=16, fontweight="bold")
    ax.set_title("PIT Pavlovian bias - Test-Retest Reliability by Age", fontsize=16, fontweight="bold")
    ax.legend(title="Age group", frameon=False)
    ax.grid(axis="y", color="#ddd", alpha=0.8)
    fig.tight_layout()

    png = os.path.join(fig_dir, "pit_trt_reliability_dotplot.png")
    pdf = os.path.join(fig_dir, "pit_trt_reliability_dotplot.pdf")
    csv = os.path.join(pit_dir, "pit_trt_reliability_dotplot_values.csv")
    fig.savefig(png, dpi=300)
    fig.savefig(pdf)
    plt.close(fig)
    out.to_csv(csv, index=False)
    print(f"Saved: {png}\nSaved: {pdf}\nSaved: {csv}")


if __name__ == "__main__":
    main()
