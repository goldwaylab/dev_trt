#!/usr/bin/env python3
"""Posterior parameter-recovery scatter grids for PIT and Two-Step."""

from __future__ import annotations

import argparse
import os
import sys

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from param_recovery_poster_common import (  # noqa: E402
    infer_output_suffix,
    latest_subject_file,
    plot_poster_grid,
)

PIT_PANELS = [
    ("b1", "Reward sensitivity\n(b1)"),
    ("b2", "Punishment sensitivity\n(b2)"),
    ("b3", "Approach bias\n(b3)"),
    ("b4", "Avoidance bias\n(b4)"),
    ("a1", "Positive learning rate\n(a1)"),
    ("a2", "Negative learning rate\n(a2)"),
]

TWO_STEP_FIXED_LAMBDA_PANELS = [
    ("alpha1_sess", "Learning rate\n(alpha1)"),
    ("beta1m_sess", "Model-based β\n(beta1m)"),
    ("beta1t_sess", "Model-free β\n(beta1t)"),
    ("beta2_sess", "Stage-2 temperature\n(beta2)"),
    ("betac_sess", "Stickiness\n(betac)"),
]

TWOSTEP_PANELS = TWO_STEP_FIXED_LAMBDA_PANELS + [
    ("lambda_sess", "Eligibility trace\n(lambda)"),
]

TASK_CONFIG = {
    "pit": {
        "csv_prefix": "pit_param_recovery",
        "panels": PIT_PANELS,
        "out_label": "pit",
    },
    "two_step_fixed_lambda": {
        "csv_prefix": "two_step_fixed_lambda_param_recovery",
        "panels": TWO_STEP_FIXED_LAMBDA_PANELS,
        "out_label": "two_step_fixed_lambda",
    },
    "twostep": {
        "csv_prefix": "twostep_param_recovery",
        "panels": TWOSTEP_PANELS,
        "out_label": "twostep",
    },
}


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser()
    ap.add_argument("--task", required=True, choices=sorted(TASK_CONFIG.keys()))
    ap.add_argument("--subject-file", default=None)
    ap.add_argument("--repo-root", default=os.getcwd())
    ap.add_argument("--output-suffix", default=None)
    ap.add_argument("--style", choices=("default", "poster"), default="poster")
    ap.add_argument("--prefer-indep", action="store_true", default=True)
    return ap.parse_args()


def recovery_subtitle(df: pd.DataFrame) -> str:
    if "true_param_sampling" in df.columns:
        mode = str(df["true_param_sampling"].dropna().iloc[0]).lower()
        if mode == "independent":
            return "True parameters sampled independently from TRT posterior"
    return "True parameters sampled from joint TRT posterior"


def plot_default_grid(
    df: pd.DataFrame,
    panels: list,
    fig_dir: str,
    task_title: str,
    stem: str,
) -> None:
    ncol = 3
    nrow = int(np.ceil(len(panels) / ncol))
    fig, axes = plt.subplots(nrow, ncol, figsize=(5.4 * ncol, 4.8 * nrow), constrained_layout=True)
    axes = np.array(axes).reshape(-1)
    color = "#d95f02" if "pit" in stem else "#7570b3"
    sns.set_style("whitegrid")

    for i, (p, label) in enumerate(panels):
        ax = axes[i]
        xcol, ycol = f"{p}_true", f"{p}_est"
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

    for j in range(len(panels), len(axes)):
        axes[j].axis("off")

    fig.suptitle(f"{task_title}: posterior-based parameter recovery", fontsize=18, weight="bold")
    fig.text(0.5, 0.965, recovery_subtitle(df) + "; dashed line = identity", ha="center", fontsize=10)

    for ext in ("png", "pdf"):
        path = os.path.join(fig_dir, f"{stem}.{ext}")
        fig.savefig(path, dpi=300, bbox_inches="tight")
        print(f"Saved: {path}")
    plt.close(fig)


def main() -> None:
    args = parse_args()
    repo = os.path.abspath(args.repo_root)
    rec_dir = os.path.join(repo, "analysis", "recovery")
    fig_dir = os.path.join(repo, "outputs", "figures")
    os.makedirs(fig_dir, exist_ok=True)

    cfg = TASK_CONFIG[args.task]
    subject_path = args.subject_file or latest_subject_file(
        rec_dir, cfg["csv_prefix"], prefer_indep=args.prefer_indep
    )
    df = pd.read_csv(subject_path)
    panels = cfg["panels"]

    suffix = args.output_suffix or infer_output_suffix(subject_path)
    if args.style == "poster":
        stem = f"param_recovery_{cfg['out_label']}_posterior_scatter_poster"
        if suffix and suffix != "posterior":
            stem = f"{stem}_{suffix}"
        plot_poster_grid(df, panels, fig_dir, stem)
    else:
        titles = {
            "pit": "PIT Pavlovian bias",
            "two_step_fixed_lambda": "Two-step (λ fixed to 1)",
            "twostep": "Two-step",
        }
        stem = f"param_recovery_{args.task}_posterior_scatter_grid"
        if suffix and suffix != "posterior":
            stem = f"{stem}_{suffix}"
        plot_default_grid(df, panels, fig_dir, titles[args.task], stem)

    print(f"Read: {subject_path}")


if __name__ == "__main__":
    main()
