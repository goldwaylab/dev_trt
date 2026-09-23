#!/usr/bin/env python3
"""
Two-step fixed-lambda TRT reliability dot plot by age group.

Replicates the style of the existing TRT reliability summary plot,
but uses fixed-lambda posterior participant estimates.
"""

from __future__ import annotations

import glob
import os
from typing import Dict, List

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.stats import pearsonr


def latest(pattern: str) -> str:
    cands = sorted(glob.glob(pattern), key=os.path.getmtime)
    if not cands:
        raise FileNotFoundError(f"No files matching pattern: {pattern}")
    return cands[-1]


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
    ts_dir = os.path.join(repo_root, "data", "parameter_estimates", "twostep")
    fig_dir = os.path.join(repo_root, "outputs", "figures")
    os.makedirs(fig_dir, exist_ok=True)

    params_path = latest(os.path.join(ts_dir, "two_step_fixed_lambda_samp10k_participant_estimates_*.csv"))
    demo_path = os.path.join(repo_root, "data", "demographics", "discovery.replication.sample.allocation.csv")
    if not os.path.exists(demo_path):
        raise FileNotFoundError(demo_path)

    df = pd.read_csv(params_path)
    demo = pd.read_csv(demo_path).rename(columns={"Participant.ID": "participant_ID", "Age": "age"})
    data = df.merge(demo, on="participant_ID", how="left")
    data["age_group"] = data["age"].apply(age_group)
    data = data[data["age_group"].notna()].copy()

    param_map: Dict[str, str] = {
        "beta1t": "Model Free Beta",
        "beta1m": "Model Based Beta",
        "beta2": "Stage2 Temperature",
        "alpha1": "Learning Rate",
        "betac": "Stickiness",
    }
    param_order: List[str] = [
        "Model Free Beta",
        "Model Based Beta",
        "Stage2 Temperature",
        "Learning Rate",
        "Stickiness",
    ]
    age_order = ["10-15 years old", "15-20 years old", "20-25 years old"]
    colors = {
        "10-15 years old": "#E41A1C",  # red
        "15-20 years old": "#377EB8",  # blue
        "20-25 years old": "#4DAF4A",  # green
    }

    rows = []
    for base, label in param_map.items():
        s1 = f"{base}_session1_mean"
        s2 = f"{base}_session2_mean"
        if s1 not in data.columns or s2 not in data.columns:
            continue
        for ag in age_order:
            d = data.loc[data["age_group"] == ag, [s1, s2]].dropna()
            if len(d) < 3:
                continue
            r, p = pearsonr(d[s1].to_numpy(float), d[s2].to_numpy(float))
            rows.append(
                {
                    "parameter": label,
                    "age_group": ag,
                    "correlation": float(r),
                    "p_value": float(p),
                }
            )

    out = pd.DataFrame(rows)
    out["parameter"] = pd.Categorical(out["parameter"], categories=param_order, ordered=True)
    out["age_group"] = pd.Categorical(out["age_group"], categories=age_order, ordered=True)
    out = out.sort_values(["parameter", "age_group"]).reset_index(drop=True)

    fig, ax = plt.subplots(figsize=(12, 7.5))
    ax.axhline(0.7, linestyle=(0, (5, 5)), color="black", linewidth=2)

    x_map = {p: i for i, p in enumerate(param_order)}
    jitter = {"10-15 years old": -0.08, "15-20 years old": 0.0, "20-25 years old": 0.08}

    for ag in age_order:
        d = out[out["age_group"] == ag]
        xs = [x_map[p] + jitter[ag] for p in d["parameter"]]
        ys = d["correlation"].to_numpy(float)
        ax.scatter(xs, ys, s=120, alpha=0.92, color=colors[ag], label=ag, zorder=3)

    ax.set_xticks(range(len(param_order)))
    ax.set_xticklabels(param_order, rotation=40, ha="right", fontsize=22)
    ax.set_ylim(-0.02, 1.03)
    ax.set_yticks(np.arange(0, 1.01, 0.2))
    ax.set_yticklabels([f"{v:.1f}" for v in np.arange(0, 1.01, 0.2)], fontsize=22)
    ax.set_ylabel("Correlation", fontsize=28, fontweight="bold")
    ax.set_title(
        "Test-Retest Reliability of Model Parameters\n(Model-based / model-free task)",
        fontsize=20,
        fontweight="bold",
        pad=16,
    )
    ax.grid(axis="y", color="#d9d9d9", linewidth=1, alpha=0.8)
    ax.set_axisbelow(True)
    for s in ["top", "right"]:
        ax.spines[s].set_visible(False)
    for s in ["left", "bottom"]:
        ax.spines[s].set_linewidth(2.5)

    leg = ax.legend(
        title="Age Group",
        title_fontsize=28,
        fontsize=22,
        loc="center left",
        bbox_to_anchor=(1.02, 0.5),
        frameon=False,
        handlelength=0.8,
        handletextpad=0.6,
    )
    handles = getattr(leg, "legend_handles", None)
    if handles is None:
        handles = getattr(leg, "legendHandles", [])
    for h in handles:
        try:
            h.set_sizes([100])
        except Exception:
            pass

    png_path = os.path.join(fig_dir, "two_step_fixed_lambda_trt_reliability_dotplot.png")
    pdf_path = os.path.join(fig_dir, "two_step_fixed_lambda_trt_reliability_dotplot.pdf")
    csv_path = os.path.join(ts_dir, "two_step_fixed_lambda_trt_reliability_dotplot_values.csv")
    fig.savefig(png_path, dpi=300, bbox_inches="tight")
    fig.savefig(pdf_path, bbox_inches="tight")
    plt.close(fig)
    out.to_csv(csv_path, index=False)

    print(f"Using params: {os.path.basename(params_path)}")
    print(f"Saved: {png_path}")
    print(f"Saved: {pdf_path}")
    print(f"Saved: {csv_path}")


if __name__ == "__main__":
    main()
