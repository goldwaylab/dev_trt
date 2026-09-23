"""Shared poster-style parameter-recovery scatter grids."""

from __future__ import annotations

import glob
import os
from typing import List, Tuple

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy import stats


def apply_poster_rc() -> None:
    mpl.rcParams.update(
        {
            "font.family": "sans-serif",
            "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans"],
            "axes.labelweight": "bold",
            "axes.titleweight": "bold",
            "axes.linewidth": 2.0,
            "xtick.major.width": 1.5,
            "ytick.major.width": 1.5,
            "figure.facecolor": "white",
            "axes.facecolor": "white",
        }
    )


def _finish_poster_axis(ax: plt.Axes) -> None:
    ax.grid(axis="both", color="#d9d9d9", linewidth=1.0, alpha=0.85, zorder=0)
    ax.set_axisbelow(True)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_linewidth(2.5)
    ax.spines["bottom"].set_linewidth(2.5)
    ax.tick_params(labelsize=11)


def latest_subject_file(rec_dir: str, file_prefix: str, prefer_indep: bool = False) -> str:
    patterns = [
        os.path.join(rec_dir, f"{file_prefix}*posterior_subject_level_*.csv"),
        os.path.join(rec_dir, f"{file_prefix}*subject_level_posterior_*.csv"),
        os.path.join(rec_dir, f"{file_prefix}*subject_level_*.csv"),
    ]
    cands = sorted({p for pattern in patterns for p in glob.glob(pattern)}, key=os.path.getmtime)
    if not cands:
        raise FileNotFoundError(f"No subject-level recovery file for patterns: {patterns}")
    if prefer_indep:
        indep = [p for p in cands if "_indep_" in os.path.basename(p)]
        if indep:
            return indep[-1]
    return cands[-1]


def infer_output_suffix(subject_path: str) -> str:
    base = os.path.basename(subject_path)
    if "param_recovery_" not in base:
        return ""
    mid = base.split("param_recovery_", 1)[1]
    return mid.split("_subject_level", 1)[0]


def _regression_ci_band(
    ax: plt.Axes,
    x: np.ndarray,
    y: np.ndarray,
    color: str,
    n_grid: int = 100,
    alpha: float = 0.25,
) -> None:
    slope, intercept, _, _, _ = stats.linregress(x, y)
    xg = np.linspace(float(x.min()), float(x.max()), n_grid)
    yhat = intercept + slope * xg
    n = len(x)
    if n > 2:
        resid = y - (intercept + slope * x)
        se = np.sqrt(np.sum(resid**2) / (n - 2))
        xbar = float(x.mean())
        sxx = np.sum((x - xbar) ** 2)
        if sxx > 0:
            se_fit = se * np.sqrt(1 / n + (xg - xbar) ** 2 / sxx)
            t = stats.t.ppf(0.975, n - 2)
            ax.fill_between(xg, yhat - t * se_fit, yhat + t * se_fit, color=color, alpha=alpha, zorder=2)
    ax.plot(xg, yhat, color=color, linewidth=2.2, zorder=3)


def plot_poster_grid(
    df: pd.DataFrame,
    mapping: List[Tuple[str, str]],
    fig_dir: str,
    out_stem: str,
    *,
    ncol: int = 3,
    reg_color: str = "#1b9e77",
) -> None:
    """Scatter grid: true (posterior draw) vs recovered (refit mean)."""
    apply_poster_rc()
    nrow = int(np.ceil(len(mapping) / ncol))
    fig, axes = plt.subplots(nrow, ncol, figsize=(4.7 * ncol, 4.25 * nrow))
    axes = np.atleast_1d(axes).reshape(-1)

    for i, (p, label) in enumerate(mapping):
        ax = axes[i]
        xcol, ycol = f"{p}_true", f"{p}_est"
        if xcol not in df.columns or ycol not in df.columns:
            ax.axis("off")
            continue
        d = df[[xcol, ycol]].dropna()
        if len(d) < 3:
            ax.axis("off")
            continue
        x = d[xcol].to_numpy(float)
        y = d[ycol].to_numpy(float)
        r = float(np.corrcoef(x, y)[0, 1])
        lim_lo = float(min(x.min(), y.min()))
        lim_hi = float(max(x.max(), y.max()))
        pad = 0.04 * (lim_hi - lim_lo) if lim_hi > lim_lo else 0.05
        lim_lo -= pad
        lim_hi += pad

        ax.plot([lim_lo, lim_hi], [lim_lo, lim_hi], linestyle="--", linewidth=1.2, color="0.45", zorder=1)
        ax.scatter(x, y, s=22, alpha=0.5, color="0.15", edgecolors="none", zorder=4)
        _regression_ci_band(ax, x, y, reg_color)

        ax.set_xlim(lim_lo, lim_hi)
        ax.set_ylim(lim_lo, lim_hi)
        ax.set_aspect("equal", adjustable="box")
        ax.set_title(label, fontsize=13, fontweight="bold", pad=8)
        ax.set_xlabel("True (posterior draw)", fontsize=11, fontweight="bold")
        ax.set_ylabel("Recovered (refit mean)", fontsize=11, fontweight="bold")
        ax.text(0.04, 0.96, f"r = {r:.2f}", transform=ax.transAxes, ha="left", va="top", fontsize=12, fontweight="bold")
        _finish_poster_axis(ax)

    for j in range(len(mapping), len(axes)):
        axes[j].axis("off")

    fig.subplots_adjust(left=0.07, right=0.98, top=0.96, bottom=0.08, wspace=0.28, hspace=0.38)
    for ext in ("png", "pdf"):
        path = os.path.join(fig_dir, f"{out_stem}.{ext}")
        fig.savefig(path, dpi=300, bbox_inches="tight", facecolor="white")
        print(f"Saved: {path}")
    plt.close(fig)
