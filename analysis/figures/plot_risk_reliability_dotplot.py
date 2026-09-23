#!/usr/bin/env python3
"""TRT reliability dotplot for RISK valence-asymmetry parameters."""

from __future__ import annotations

import glob
import os
import re

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.stats import pearsonr


def latest(pattern: str) -> str:
    cands = sorted(glob.glob(pattern), key=os.path.getmtime)
    if not cands:
        raise FileNotFoundError(pattern)
    return cands[-1]


def age_group(age: float) -> str | None:
    if 10 <= age < 15:
        return "10-15 years old"
    if 15 <= age < 20:
        return "15-20 years old"
    if 20 <= age < 26:
        return "20-25 years old"
    return None


def parse_param(summary_path: str, subjects_path: str, param: str) -> pd.DataFrame:
    sm = pd.read_csv(summary_path, sep="\t")
    subj = pd.read_csv(subjects_path)
    first = sm.columns[0]
    pat = re.compile(rf'^"?{re.escape(param)}\[(\d+),(\d+)\]"?$')
    rows = sm[sm[first].astype(str).str.match(pat)].copy()
    idx = rows[first].astype(str).str.extract(pat)
    rows["session"] = idx[0].astype(int)
    rows["stan_idx"] = idx[1].astype(int)
    rows = rows.merge(subj, on="stan_idx", how="left")
    return rows[["subject", "session", "Mean"]].rename(columns={"Mean": "value"})


def main() -> None:
    repo_root = os.getcwd()
    risk_dir = os.path.join(repo_root, "data", "parameter_estimates", "risk")
    fig_dir = os.path.join(repo_root, "outputs", "figures")
    os.makedirs(fig_dir, exist_ok=True)

    demo = pd.read_csv(
        os.path.join(repo_root, "data", "demographics", "discovery.replication.sample.allocation.csv")
    ).rename(columns={"Participant.ID": "subject", "Age": "age"})
    demo["age_group"] = demo["age"].apply(age_group)
    demo = demo[demo["age_group"].notna()][["subject", "age_group"]]

    params = ["b1", "a1", "a2", "a3", "a4", "q0"]
    pretty = {
        "b1": "Inverse temp",
        "a1": "Chosen +PE",
        "a2": "Chosen -PE",
        "a3": "Unchosen +PE",
        "a4": "Unchosen -PE",
        "q0": "Initial q0",
    }
    age_order = ["10-15 years old", "15-20 years old", "20-25 years old"]
    colors = {"10-15 years old": "#E41A1C", "15-20 years old": "#377EB8", "20-25 years old": "#4DAF4A"}
    jitter = {"10-15 years old": -0.12, "15-20 years old": 0.0, "20-25 years old": 0.12}

    sm_path = latest(os.path.join(risk_dir, "risk_valence_asymmetry_samp10k_fit_summary_*.tsv"))
    subj_path = latest(os.path.join(risk_dir, "risk_valence_asymmetry_samp10k_fit_subjects_*.csv"))

    rows = []
    for p in params:
        d = parse_param(sm_path, subj_path, p)
        w = d.pivot_table(index="subject", columns="session", values="value", aggfunc="first").reset_index()
        w = w.rename(columns={1: "session_1", 2: "session_2"}).merge(demo, on="subject", how="inner")
        for ag in age_order:
            a = w[w["age_group"] == ag]
            if len(a) < 3:
                continue
            r, pv = pearsonr(a["session_1"].to_numpy(float), a["session_2"].to_numpy(float))
            rows.append(
                {
                    "parameter": pretty[p],
                    "age_group": ag,
                    "correlation": float(r),
                    "p_value": float(pv),
                    "n": len(a),
                }
            )

    out = pd.DataFrame(rows)
    param_order = [pretty[p] for p in params]
    out["parameter"] = pd.Categorical(out["parameter"], categories=param_order, ordered=True)

    fig, ax = plt.subplots(figsize=(12, 7))
    ax.axhline(0.7, linestyle=(0, (5, 5)), color="black", linewidth=2)
    x_map = {p: i for i, p in enumerate(param_order)}
    for ag in age_order:
        da = out[out["age_group"] == ag]
        xs = [x_map[p] + jitter[ag] for p in da["parameter"]]
        ax.scatter(xs, da["correlation"], s=120, alpha=0.92, color=colors[ag], label=ag, zorder=3)

    ax.set_xticks(range(len(param_order)))
    ax.set_xticklabels(param_order, rotation=35, ha="right", fontsize=14)
    ax.set_ylim(-0.05, 1.02)
    ax.set_ylabel("Pearson r (session 1 vs 2)", fontsize=16, fontweight="bold")
    ax.set_title("RISK valence asymmetry - Test-Retest Reliability by Age", fontsize=16, fontweight="bold")
    ax.legend(title="Age group", frameon=False)
    ax.grid(axis="y", color="#ddd", alpha=0.8)
    fig.tight_layout()

    png = os.path.join(fig_dir, "risk_trt_reliability_dotplot.png")
    pdf = os.path.join(fig_dir, "risk_trt_reliability_dotplot.pdf")
    csv = os.path.join(risk_dir, "risk_trt_reliability_dotplot_values.csv")
    fig.savefig(png, dpi=300)
    fig.savefig(pdf)
    plt.close(fig)
    out.to_csv(csv, index=False)
    print(f"Saved: {png}\nSaved: {pdf}\nSaved: {csv}")


if __name__ == "__main__":
    main()
