#!/usr/bin/env python3
"""
Test-retest reliability figures (Raab & Hartley 2025 + SBDM poster aesthetics).

Layout per task:
  Row 1: Spearman rho — one panel, age groups color-coded (jittered x)
  Row 2: ICC — same layout, empirical common/difference variance per age bin

Style: large sans-serif fonts, light y-grid, thick L/B spines, age colours from TRT dotplots.
"""

from __future__ import annotations

import glob
import os
import re
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.stats import spearmanr

# ---------------------------------------------------------------------------
# Poster / SBDM-style theme (aligned with twostep TRT dotplot figures)
# ---------------------------------------------------------------------------
AGE_ORDER = ["10-15 years old", "15-20 years old", "20-25 years old"]
AGE_SHORT = {"10-15 years old": "10–15 y", "15-20 years old": "15–20 y", "20-25 years old": "20–25 y"}
AGE_COLORS = {
    "10-15 years old": "#E41A1C",
    "15-20 years old": "#377EB8",
    "20-25 years old": "#4DAF4A",
}
AGE_JITTER = {"10-15 years old": -0.14, "15-20 years old": 0.0, "20-25 years old": 0.14}
RHO_THRESH = 0.7
ICC_THRESH = 0.6
THRESH_BAND_COLOR = "#f5f5f5"


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


def latest(pattern: str) -> str:
    cands = glob.glob(pattern)
    if not cands:
        raise FileNotFoundError(f"No files for pattern: {pattern}")
    return max(cands, key=os.path.getmtime)


def age_group(age: float) -> str | None:
    if 10 <= age < 15:
        return "10-15 years old"
    if 15 <= age < 20:
        return "15-20 years old"
    if 20 <= age < 26:
        return "20-25 years old"
    return None


@dataclass
class TaskSpec:
    task_key: str
    task_label: str
    model_label: str
    summary_path: str
    subjects_path: Optional[str]
    params: List[str]
    labels: Dict[str, str]
    sigma_map: Dict[str, int]
    twostep: bool = False
    pit_age_csv: Optional[str] = None
    show_title: bool = True


def bootstrap_spearman_ci(
    x: np.ndarray, y: np.ndarray, n_boot: int = 5000, seed: int = 47404
) -> Tuple[float, float, float, float]:
    x = np.asarray(x, float)
    y = np.asarray(y, float)
    ok = np.isfinite(x) & np.isfinite(y)
    x, y = x[ok], y[ok]
    if len(x) < 3:
        return np.nan, np.nan, np.nan, np.nan
    rho, p = spearmanr(x, y)
    rng = np.random.default_rng(seed)
    boots = []
    n = len(x)
    for _ in range(n_boot):
        ix = rng.integers(0, n, n)
        r, _ = spearmanr(x[ix], y[ix])
        if np.isfinite(r):
            boots.append(r)
    if not boots:
        return float(rho), float(p), np.nan, np.nan
    lo, hi = np.percentile(boots, [2.5, 97.5])
    return float(rho), float(p), float(lo), float(hi)


def parse_sh_session_params(
    summary_path: str, subjects_path: str, param: str
) -> pd.DataFrame:
    sm = pd.read_csv(summary_path, sep="\t")
    subj = pd.read_csv(subjects_path)
    first = sm.columns[0]
    pat = re.compile(rf'^"?{re.escape(param)}\[(\d+),(\d+)\]"?$')
    rows = sm[sm[first].astype(str).str.match(pat)].copy()
    if rows.empty:
        return pd.DataFrame(columns=["subject", "session_1", "session_2"])
    idx = rows[first].astype(str).str.extract(pat)
    rows["session"] = idx[0].astype(int)
    rows["stan_idx"] = idx[1].astype(int)
    rows = rows.merge(subj, on="stan_idx", how="left")
    return (
        rows.pivot_table(index="subject", columns="session", values="Mean", aggfunc="first")
        .rename(columns={1: "session_1", 2: "session_2"})
        .reset_index()
    )


def load_demo(repo: str) -> pd.DataFrame:
    path = os.path.join(repo, "data", "demographics", "discovery.replication.sample.allocation.csv")
    d = pd.read_csv(path)
    d = d.rename(columns={"Participant.ID": "subject", "Age": "age"})
    d["age_group"] = d["age"].apply(age_group)
    return d[["subject", "age", "age_group"]]


def build_long_table(spec: TaskSpec, demo: pd.DataFrame) -> pd.DataFrame:
    rows = []
    if spec.twostep:
        fix = pd.read_csv(spec.subjects_path)
        fix = fix.rename(columns={"participant_ID": "subject"})
        fix = fix.merge(demo, on="subject", how="left")
        for p in spec.params:
            s1, s2 = f"{p}_session1_mean", f"{p}_session2_mean"
            for _, r in fix.iterrows():
                if pd.isna(r[s1]) or pd.isna(r[s2]) or pd.isna(r.get("age_group")):
                    continue
                rows.append(
                    dict(
                        subject=r["subject"],
                        age=r["age"],
                        age_group=r["age_group"],
                        parameter=p,
                        session_1=r[s1],
                        session_2=r[s2],
                    )
                )
        return pd.DataFrame(rows)

    if spec.pit_age_csv and os.path.exists(spec.pit_age_csv):
        pdf = pd.read_csv(spec.pit_age_csv)
        parts = []
        for p in spec.params:
            sub = pdf.loc[pdf["parameter"] == p, ["subject_id", "session", "param_value", "age"]]
            w = (
                sub.pivot_table(index="subject_id", columns="session", values="param_value", aggfunc="first")
                .rename(columns={1: "session_1", 2: "session_2"})
                .reset_index()
            )
            w["subject"] = w["subject_id"]
            w["parameter"] = p
            w["age"] = sub.groupby("subject_id")["age"].first().reindex(w["subject_id"]).values
            w["age_group"] = w["age"].apply(age_group)
            parts.append(w)
        return pd.concat(parts, ignore_index=True).dropna(subset=["session_1", "session_2", "age_group"])

    for p in spec.params:
        w = parse_sh_session_params(spec.summary_path, spec.subjects_path, p)
        w = w.merge(demo, on="subject", how="left")
        for _, r in w.iterrows():
            if pd.isna(r["session_1"]) or pd.isna(r["session_2"]) or pd.isna(r.get("age_group")):
                continue
            rows.append(
                dict(
                    subject=r["subject"],
                    age=r["age"],
                    age_group=r["age_group"],
                    parameter=p,
                    session_1=r["session_1"],
                    session_2=r["session_2"],
                )
            )
    return pd.DataFrame(rows)


def icc_from_sigma_row(summary: pd.DataFrame, row_idx: int) -> Tuple[float, float, float]:
    first = summary.columns[0]

    def _get(i: int, j: int, col: str) -> float:
        key = f"sigma[{i},{j}]"
        hit = summary[summary[first].astype(str).str.fullmatch(re.escape(key))]
        if hit.empty:
            raise KeyError(key)
        return float(hit[col].iloc[0])

    sb, sw = _get(row_idx, 1, "Mean"), _get(row_idx, 2, "Mean")
    icc = sb**2 / (sb**2 + sw**2)
    icc_lo = _get(row_idx, 1, "2.5%") ** 2 / (_get(row_idx, 1, "2.5%") ** 2 + _get(row_idx, 2, "97.5%") ** 2)
    icc_hi = _get(row_idx, 1, "97.5%") ** 2 / (_get(row_idx, 1, "97.5%") ** 2 + _get(row_idx, 2, "2.5%") ** 2)
    return icc, icc_lo, icc_hi


def icc_twostep(summary: pd.DataFrame, param: str) -> Tuple[float, float, float]:
    first = summary.columns[0]
    if param == "alpha1":
        c_pat, d_pat = r"sigma_alpha1_c\[(\d+)\]", r"sigma_alpha1_d\[(\d+)\]"
    else:
        br = {"beta1m": 1, "beta1t": 2, "beta2": 3, "betac": 4}[param]
        c_pat, d_pat = rf"sigma_beta_c\[{br},(\d+)\]", rf"sigma_beta_d\[{br},(\d+)\]"

    def mean_col(pat: str, col: str) -> float:
        return float(
            np.mean(
                [
                    float(row[col])
                    for _, row in summary.iterrows()
                    if re.fullmatch(pat, str(row[first]))
                ]
            )
        )

    sc, sd = mean_col(c_pat, "Mean"), mean_col(d_pat, "Mean")
    icc = sc**2 / (sc**2 + sd**2)
    icc_lo = mean_col(c_pat, "2.5%") ** 2 / (mean_col(c_pat, "2.5%") ** 2 + mean_col(d_pat, "97.5%") ** 2)
    icc_hi = mean_col(c_pat, "97.5%") ** 2 / (mean_col(c_pat, "97.5%") ** 2 + mean_col(d_pat, "2.5%") ** 2)
    return icc, icc_lo, icc_hi


def compute_spearman_overall(long: pd.DataFrame, spec: TaskSpec) -> pd.DataFrame:
    out = []
    for p in spec.params:
        d = long.loc[long["parameter"] == p]
        rho, pv, rlo, rhi = bootstrap_spearman_ci(d["session_1"].values, d["session_2"].values)
        out.append(
            dict(
                parameter=p,
                label=spec.labels[p],
                n=len(d),
                spearman_rho=rho,
                spearman_ci_lo=rlo,
                spearman_ci_hi=rhi,
                spearman_p=pv,
            )
        )
    return pd.DataFrame(out)


def compute_spearman_by_age(long: pd.DataFrame, spec: TaskSpec) -> pd.DataFrame:
    out = []
    for p in spec.params:
        for ag in AGE_ORDER:
            d = long.loc[(long["parameter"] == p) & (long["age_group"] == ag)]
            rho, pv, rlo, rhi = bootstrap_spearman_ci(d["session_1"].values, d["session_2"].values)
            out.append(
                dict(
                    parameter=p,
                    label=spec.labels[p],
                    age_group=ag,
                    spearman_rho=rho,
                    spearman_p=pv,
                    spearman_ci_lo=rlo,
                    spearman_ci_hi=rhi,
                    n=len(d),
                )
            )
    return pd.DataFrame(out)


def empirical_icc(s1: np.ndarray, s2: np.ndarray) -> float:
    """ICC = σ²_common / (σ²_common + σ²_difference) from session means."""
    s1 = np.asarray(s1, float)
    s2 = np.asarray(s2, float)
    ok = np.isfinite(s1) & np.isfinite(s2)
    s1, s2 = s1[ok], s2[ok]
    if len(s1) < 3:
        return np.nan
    avg = 0.5 * (s1 + s2)
    diff = s1 - s2
    var_common = np.var(avg, ddof=1)
    var_diff = np.var(diff, ddof=1)
    if var_common + var_diff <= 0:
        return np.nan
    return float(var_common / (var_common + var_diff))


def bootstrap_icc_ci(
    s1: np.ndarray, s2: np.ndarray, n_boot: int = 5000, seed: int = 47404
) -> Tuple[float, float, float]:
    s1 = np.asarray(s1, float)
    s2 = np.asarray(s2, float)
    ok = np.isfinite(s1) & np.isfinite(s2)
    s1, s2 = s1[ok], s2[ok]
    icc = empirical_icc(s1, s2)
    if len(s1) < 3:
        return icc, np.nan, np.nan
    rng = np.random.default_rng(seed)
    boots = []
    n = len(s1)
    for _ in range(n_boot):
        ix = rng.integers(0, n, n)
        b = empirical_icc(s1[ix], s2[ix])
        if np.isfinite(b):
            boots.append(b)
    if not boots:
        return icc, np.nan, np.nan
    lo, hi = np.percentile(boots, [2.5, 97.5])
    return float(icc), float(lo), float(hi)


def compute_icc_by_age(long: pd.DataFrame, spec: TaskSpec) -> pd.DataFrame:
    out = []
    for p in spec.params:
        for ag in AGE_ORDER:
            d = long.loc[(long["parameter"] == p) & (long["age_group"] == ag)]
            icc, ilo, ihi = bootstrap_icc_ci(d["session_1"].values, d["session_2"].values)
            out.append(
                dict(
                    parameter=p,
                    label=spec.labels[p],
                    age_group=ag,
                    icc=icc,
                    icc_ci_lo=ilo,
                    icc_ci_hi=ihi,
                    n=len(d),
                )
            )
    return pd.DataFrame(out)


def compute_icc_population(spec: TaskSpec) -> pd.DataFrame:
    summary = pd.read_csv(spec.summary_path, sep="\t")
    rows = []
    for p in spec.params:
        if spec.twostep:
            icc, ilo, ihi = icc_twostep(summary, p)
        else:
            icc, ilo, ihi = icc_from_sigma_row(summary, spec.sigma_map[p])
        rows.append(
            dict(
                parameter=p,
                label=spec.labels[p],
                icc=icc,
                icc_ci_lo=ilo,
                icc_ci_hi=ihi,
            )
        )
    return pd.DataFrame(rows)


def _finish_axis(ax: plt.Axes, ylabel: str, fontsize: int = 16) -> None:
    ax.set_ylabel(ylabel, fontsize=fontsize, fontweight="bold", labelpad=8)
    ax.set_ylim(-0.08, 1.06)
    ax.set_yticks(np.arange(0, 1.01, 0.2))
    ax.tick_params(axis="y", labelsize=13)
    ax.grid(axis="y", color="#d9d9d9", linewidth=1.0, alpha=0.85, zorder=0)
    ax.set_axisbelow(True)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_linewidth(2.5)
    ax.spines["bottom"].set_linewidth(2.5)


def _add_threshold_band(ax: plt.Axes, threshold: float, band_color: str) -> None:
    ax.axhspan(threshold, 1.0, color=band_color, zorder=0)
    ax.axhline(threshold, color="0.15", linestyle=(0, (6, 4)), linewidth=2.0, zorder=1)


def _plot_age_metric_panel(
    ax: plt.Axes,
    metric_df: pd.DataFrame,
    spec: TaskSpec,
    value_col: str,
    lo_col: str,
    hi_col: str,
    ylabel: str,
    *,
    threshold: float,
    band_color: str,
    show_xticklabels: bool,
) -> None:
    labels = [spec.labels[p] for p in spec.params]
    x_base = {p: i for i, p in enumerate(spec.params)}
    _add_threshold_band(ax, threshold, band_color)

    for ag in AGE_ORDER:
        color = AGE_COLORS[ag]
        sub = metric_df[metric_df["age_group"] == ag].set_index("parameter").reindex(spec.params)
        xs = np.array([x_base[p] + AGE_JITTER[ag] for p in spec.params], float)
        y = sub[value_col].to_numpy(float)
        ylo = sub[lo_col].to_numpy(float)
        yhi = sub[hi_col].to_numpy(float)
        yerr = np.vstack([np.clip(y - ylo, 0, None), np.clip(yhi - y, 0, None)])
        ax.errorbar(
            xs,
            y,
            yerr=yerr,
            fmt="o",
            color=color,
            ecolor=color,
            elinewidth=2,
            capsize=4,
            capthick=2,
            markersize=10,
            markeredgecolor="white",
            markeredgewidth=1.0,
            label=AGE_SHORT[ag],
            zorder=3,
        )

    _finish_axis(ax, ylabel, fontsize=16)
    ax.set_xticks(np.arange(len(labels)))
    if show_xticklabels:
        ax.set_xticklabels(labels, rotation=38, ha="right", fontsize=12)
        ax.tick_params(axis="x", pad=6)
    else:
        ax.set_xticklabels([])


def _add_panel_labels(ax_rho: plt.Axes, ax_icc: plt.Axes) -> None:
    """Place A/B tags outside the panel top-left (survives bbox_inches='tight')."""
    fig = ax_rho.figure
    for ax, label in ((ax_rho, "A"), (ax_icc, "B")):
        pos = ax.get_position()
        fig.text(
            pos.x0 - 0.012,
            pos.y1 + 0.006,
            label,
            fontsize=18,
            fontweight="bold",
            va="bottom",
            ha="right",
            transform=fig.transFigure,
        )


def plot_task_figure(
    spec: TaskSpec,
    spearman_age: pd.DataFrame,
    icc_age: pd.DataFrame,
    fig_dir: str,
    output_key: str | None = None,
) -> None:
    fig, (ax_rho, ax_icc) = plt.subplots(2, 1, figsize=(12, 8.5), sharex=True)
    fig.subplots_adjust(left=0.1, right=0.82, top=0.92, bottom=0.16, hspace=0.22)

    if spec.show_title:
        fig.suptitle(spec.task_label, fontsize=20, fontweight="bold", y=0.97)

    _plot_age_metric_panel(
        ax_rho,
        spearman_age,
        spec,
        "spearman_rho",
        "spearman_ci_lo",
        "spearman_ci_hi",
        "Spearman ρ",
        threshold=RHO_THRESH,
        band_color=THRESH_BAND_COLOR,
        show_xticklabels=False,
    )
    _plot_age_metric_panel(
        ax_icc,
        icc_age,
        spec,
        "icc",
        "icc_ci_lo",
        "icc_ci_hi",
        "ICC",
        threshold=ICC_THRESH,
        band_color=THRESH_BAND_COLOR,
        show_xticklabels=True,
    )

    leg = ax_icc.legend(
        title="Age group",
        loc="center left",
        bbox_to_anchor=(1.02, 0.5),
        frameon=False,
        fontsize=12,
        title_fontsize=13,
    )
    handles = getattr(leg, "legend_handles", None) or getattr(leg, "legendHandles", [])
    for h in handles:
        try:
            h.set_markersize(9)
        except Exception:
            pass

    _add_panel_labels(ax_rho, ax_icc)

    stem = f"{output_key or spec.task_key}_trt_reliability_spearman_icc_by_age"
    for ext in ("png", "pdf"):
        path = os.path.join(fig_dir, f"{stem}.{ext}")
        fig.savefig(path, dpi=300, bbox_inches="tight", facecolor="white")
        print(f"Saved: {path}")
    plt.close(fig)


def save_outputs(
    spec: TaskSpec,
    spearman_age: pd.DataFrame,
    spearman_overall: pd.DataFrame,
    icc_age: pd.DataFrame,
    icc_pop: pd.DataFrame,
    fig_dir: str,
    data_dir: str,
    output_key: str | None = None,
) -> None:
    key = output_key or spec.task_key
    spearman_overall.to_csv(
        os.path.join(data_dir, f"{key}_trt_reliability_spearman_overall.csv"),
        index=False,
    )
    spearman_age.to_csv(
        os.path.join(data_dir, f"{key}_trt_reliability_spearman_by_age.csv"),
        index=False,
    )
    icc_age.to_csv(
        os.path.join(data_dir, f"{key}_trt_reliability_icc_by_age.csv"),
        index=False,
    )
    icc_pop.to_csv(
        os.path.join(data_dir, f"{key}_trt_reliability_icc_population.csv"),
        index=False,
    )
    merged = spearman_age.merge(icc_age, on=["parameter", "label", "age_group"], how="left")
    merged.to_csv(
        os.path.join(data_dir, f"{key}_trt_reliability_spearman_icc.csv"),
        index=False,
    )


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--tasks",
        nargs="*",
        default=None,
        help="Task keys to plot (default: all canonical manuscript tasks). e.g. risk pit",
    )
    parser.add_argument(
        "--fit-tag",
        default="samp10k",
        help="Tagged Stan fit suffix. Default and manuscript canonical tag: samp10k.",
    )
    args = parser.parse_args()

    apply_poster_rc()
    repo = os.getcwd()
    risk_dir = os.path.join(repo, "data", "parameter_estimates", "risk")
    pit_dir = os.path.join(repo, "data", "parameter_estimates", "pit")
    ts_dir = os.path.join(repo, "data", "parameter_estimates", "twostep")
    fig_dir = os.path.join(repo, "outputs", "figures")
    os.makedirs(fig_dir, exist_ok=True)

    demo = load_demo(repo)
    fit_tag = args.fit_tag
    risk_summary_glob = os.path.join(risk_dir, f"risk_valence_asymmetry_{fit_tag}_fit_summary_*.tsv")
    risk_subjects_glob = os.path.join(risk_dir, f"risk_valence_asymmetry_{fit_tag}_fit_subjects_*.csv")
    pit_summary_glob = os.path.join(pit_dir, f"pit_pavlovian_bias_{fit_tag}_fit_summary_*.tsv")
    pit_subjects_glob = os.path.join(pit_dir, f"pit_pavlovian_bias_{fit_tag}_fit_subjects_*.csv")
    pit_age_csv = os.path.join(pit_dir, f"pit_pavlovian_bias_{fit_tag}_summary_with_age.csv")

    specs = [
        TaskSpec(
            task_key="risk",
            task_label="Valence asymmetry (RISK)",
            model_label="RISK valence asymmetry" + (f", {fit_tag}" if fit_tag else ""),
            summary_path=latest(risk_summary_glob),
            subjects_path=latest(risk_subjects_glob),
            params=["b1", "a1", "a2", "a3", "a4", "q0"],
            labels={
                "b1": "Inverse temp.",
                "a1": "LR chosen +PE",
                "a2": "LR chosen −PE",
                "a3": "LR unch. +PE",
                "a4": "LR unch. −PE",
                "q0": r"Initial $q_0$",
            },
            sigma_map={"b1": 1, "a1": 2, "a2": 3, "a3": 4, "a4": 5, "q0": 6},
            show_title=False,
        ),
        TaskSpec(
            task_key="pit",
            task_label="Pavlovian bias (PIT)",
            model_label="PIT Pavlovian bias" + (f", {fit_tag}" if fit_tag else ""),
            summary_path=latest(pit_summary_glob),
            subjects_path=(
                latest(pit_subjects_glob)
                if glob.glob(pit_subjects_glob)
                else None
            ),
            pit_age_csv=pit_age_csv if os.path.exists(pit_age_csv) else None,
            params=["b1", "b2", "b3", "b4", "a1", "a2"],
            labels={
                "b1": "Reward sens.",
                "b2": "Punish. sens.",
                "b3": "Approach bias",
                "b4": "Avoid. bias",
                "a1": "LR positive",
                "a2": "LR negative",
            },
            sigma_map={"b1": 1, "b2": 2, "b3": 3, "b4": 4, "a1": 5, "a2": 6},
            show_title=False,
        ),
        TaskSpec(
            task_key="two_step_fixed_lambda",
            task_label="Two-step (MB/MF)",
            model_label="λ fixed to 1",
            summary_path=latest(os.path.join(ts_dir, f"two_step_fixed_lambda_{fit_tag}_fit_summary_*.tsv")),
            subjects_path=latest(os.path.join(ts_dir, f"two_step_fixed_lambda_{fit_tag}_participant_estimates_*.csv")),
            params=["alpha1", "beta1m", "beta1t", "beta2", "betac"],
            labels={
                "alpha1": "Learning rate",
                "beta1m": "Model-based β",
                "beta1t": "Model-free β",
                "beta2": "Stage-2 temp.",
                "betac": "Stickiness",
            },
            sigma_map={},
            twostep=True,
            show_title=False,
        ),
    ]

    data_dirs = {
        "risk": risk_dir,
        "pit": pit_dir,
        "two_step_fixed_lambda": ts_dir,
    }
    if args.tasks:
        wanted = set(args.tasks)
        specs = [s for s in specs if s.task_key in wanted]
        if not specs:
            raise SystemExit(f"No matching tasks for: {args.tasks}")

    for spec in specs:
        print(f"\n=== {spec.task_key} ===")
        output_key = f"{spec.task_key}_{fit_tag}" if fit_tag else spec.task_key
        long = build_long_table(spec, demo)
        sp_age = compute_spearman_by_age(long, spec)
        sp_overall = compute_spearman_overall(long, spec)
        icc_age = compute_icc_by_age(long, spec)
        icc_pop = compute_icc_population(spec)
        data_dir = data_dirs[spec.task_key]
        save_outputs(spec, sp_age, sp_overall, icc_age, icc_pop, fig_dir, data_dir, output_key=output_key)
        plot_task_figure(spec, sp_age, icc_age, fig_dir, output_key=output_key)

        src = os.path.join(fig_dir, f"{output_key}_trt_reliability_spearman_icc_by_age.png")
        dst = os.path.join(fig_dir, f"{output_key}_trt_reliability_spearman_icc.png")
        if os.path.exists(src):
            import shutil

            shutil.copy2(src, dst)
            shutil.copy2(src.replace(".png", ".pdf"), dst.replace(".png", ".pdf"))
            print(f"Copied to: {dst}")


if __name__ == "__main__":
    main()
