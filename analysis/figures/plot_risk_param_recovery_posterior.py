#!/usr/bin/env python3
"""
Plot posterior-based parameter recovery scatter grids for the RISK task.
"""

from __future__ import annotations

import argparse
import glob
import os
import sys
from typing import List, Tuple

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from param_recovery_poster_common import infer_output_suffix, plot_poster_grid  # noqa: E402


PARAMS = {
    "risk_valence_asymmetry": [
        ("b1", "Inverse temperature\n(b1)"),
        ("a1", "Risky + PE > 0\n(a1)"),
        ("a2", "Risky + PE < 0\n(a2)"),
        ("a3", "Safe + PE > 0\n(a3)"),
        ("a4", "Safe + PE < 0\n(a4)"),
        ("q0", "Initial risky expectation\n(q0)"),
    ]
}


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="risk_valence_asymmetry", choices=sorted(PARAMS.keys()))
    ap.add_argument("--repo-root", default=os.getcwd())
    ap.add_argument("--subject-file", default=None)
    ap.add_argument(
        "--output-suffix",
        default=None,
        help="Optional tag in output filenames (e.g. joint_pooled_trt, indep_pooled_trt).",
    )
    ap.add_argument(
        "--style",
        choices=("default", "poster"),
        default="default",
        help="poster: SBDM/TRT figure aesthetics (large type, clean spines).",
    )
    ap.add_argument(
        "--prefer-indep",
        action="store_true",
        help="When auto-picking subject CSV, prefer *indep* over latest file.",
    )
    return ap.parse_args()


def recovery_subtitle(df: pd.DataFrame) -> str:
    if "true_param_sampling" in df.columns:
        mode = str(df["true_param_sampling"].dropna().iloc[0]).lower()
        if mode == "independent":
            return "True parameters sampled independently from TRT posterior"
    return "True parameters sampled from joint TRT posterior"


def latest_subject_file(rec_dir: str, model: str, prefer_indep: bool = False) -> str:
    cands = sorted(
        glob.glob(os.path.join(rec_dir, f"{model}_param_recovery*subject_level_*.csv")),
        key=os.path.getmtime,
    )
    if not cands:
        raise FileNotFoundError(f"No subject-level recovery file found for {model}")
    if prefer_indep:
        indep = [p for p in cands if "_indep_" in os.path.basename(p)]
        if indep:
            return indep[-1]
    return cands[-1]


def main() -> None:
    args = parse_args()
    repo_root = os.path.abspath(args.repo_root)
    rec_dir = os.path.join(repo_root, "analysis", "recovery")
    fig_dir = os.path.join(repo_root, "outputs", "figures")
    os.makedirs(fig_dir, exist_ok=True)

    subject_path = args.subject_file or latest_subject_file(
        rec_dir, args.model, prefer_indep=args.prefer_indep or args.style == "poster"
    )
    df = pd.read_csv(subject_path)
    mapping = PARAMS[args.model]

    suffix = args.output_suffix or infer_output_suffix(subject_path)

    if args.style == "poster":
        out_stem = f"param_recovery_{args.model}_posterior_scatter_poster"
        if suffix and suffix != "posterior":
            out_stem = f"{out_stem}_{suffix}"
        plot_poster_grid(df, mapping, fig_dir, out_stem)
        print(f"Read:  {subject_path}")
        return

    n = len(mapping)
    ncol = 3
    nrow = int(np.ceil(n / ncol))
    fig, axes = plt.subplots(nrow, ncol, figsize=(5.4 * ncol, 4.8 * nrow), constrained_layout=True)
    axes = np.array(axes).reshape(-1)
    color = "#1b9e77"
    sns.set_style("whitegrid")

    for i, (p, label) in enumerate(mapping):
        ax = axes[i]
        xcol = f"{p}_true"
        ycol = f"{p}_est"
        d = df[[xcol, ycol]].dropna()
        if len(d) < 3:
            ax.axis("off")
            continue
        r = np.corrcoef(d[xcol], d[ycol])[0, 1]
        lim_lo = float(min(d[xcol].min(), d[ycol].min()))
        lim_hi = float(max(d[xcol].max(), d[ycol].max()))
        ax.plot([lim_lo, lim_hi], [lim_lo, lim_hi], linestyle="--", linewidth=1.0, color="gray")
        sns.scatterplot(data=d, x=xcol, y=ycol, s=10, alpha=0.55, color="black", ax=ax, edgecolor=None)
        sns.regplot(data=d, x=xcol, y=ycol, scatter=False, ci=95, color=color, line_kws={"linewidth": 1.7}, ax=ax)
        ax.set_title(label, fontsize=12)
        ax.set_xlabel("True (posterior draw)", fontsize=10)
        ax.set_ylabel("Recovered (refit mean)", fontsize=10)
        ax.text(0.02, 1.02, f"r = {r:.2f}", transform=ax.transAxes, ha="left", va="bottom", fontsize=9)
        ax.tick_params(labelsize=9)

    for j in range(n, len(axes)):
        axes[j].axis("off")

    sub_note = recovery_subtitle(df)
    fig.suptitle(
        f"Risk task ({args.model}): posterior-based parameter recovery",
        fontsize=18,
        weight="bold",
    )
    fig.text(
        0.5,
        0.965,
        sub_note + "; dashed line = identity",
        ha="center",
        fontsize=10,
    )

    out_stem = f"param_recovery_{args.model}_posterior_scatter_grid"
    if suffix and suffix != "posterior":
        out_stem = f"{out_stem}_{suffix}"
    out_png = os.path.join(fig_dir, f"{out_stem}.png")
    out_pdf = os.path.join(fig_dir, f"{out_stem}.pdf")
    fig.savefig(out_png, dpi=300, bbox_inches="tight")
    fig.savefig(out_pdf, bbox_inches="tight")
    plt.close(fig)
    print(f"Read:  {subject_path}")
    print(f"Saved: {out_png}")
    print(f"Saved: {out_pdf}")


if __name__ == "__main__":
    main()
