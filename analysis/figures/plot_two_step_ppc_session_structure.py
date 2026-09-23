#!/usr/bin/env python3
"""
Two-step fix-λ TRT PPC (Session 1/2 layout, risk-style aesthetics).

Panel A: canonical stay grid (session 1/2; pooled across age) with separate
         Observed and Model columns; identical bar width in both.
Panel B: per-participant observed vs model-predicted p(stay) by prior transition (common/rare).

Optional: --recovery-subject-file → supplementary scatter of MB-β from true vs
refitted parameters on re-simulated trials (independent recovery CSV).
"""

from __future__ import annotations

import argparse
import glob
import os
import warnings
from typing import Dict, Optional, Tuple

import matplotlib.pyplot as plt
from matplotlib.patches import Patch
import numpy as np
import pandas as pd
import seaborn as sns

try:
    import statsmodels.api as sm
except ImportError:
    sm = None

COMMON_PROB = 0.7
N_TRIALS_SIM = 200


def expit(x: float) -> float:
    return 1.0 / (1.0 + np.exp(-x))


def load_twostep_trials(repo_root: str) -> pd.DataFrame:
    parts = []
    for sess in (1, 2):
        path = os.path.join(repo_root, "data", "behavioral", "twostep", f"s{sess}", "MBMF_data_processed_2.csv")
        d = pd.read_csv(path)
        d["session"] = sess
        parts.append(d)
    d = pd.concat(parts, ignore_index=True)
    d = d[d["practice_trial"].astype(str).str.lower() == "real"].copy()
    d["participant_ID"] = pd.to_numeric(d["participant_ID"], errors="coerce")
    d["session"] = pd.to_numeric(d["session"], errors="coerce")
    d["trial"] = pd.to_numeric(d["trial"], errors="coerce")
    d["choice_1"] = pd.to_numeric(d["choice_1"], errors="coerce")
    d["reward"] = pd.to_numeric(d["reward"], errors="coerce")
    d = d.dropna(subset=["participant_ID", "session", "trial", "choice_1", "transition"])
    d = d.sort_values(["participant_ID", "session", "trial"]).reset_index(drop=True)

    d["c1"] = np.where(d["choice_1"] == 2, 1, 0)
    if "stay" in d.columns:
        d["stay"] = pd.to_numeric(d["stay"], errors="coerce")
    else:
        d["stay"] = np.nan
    d["prev_c1"] = d.groupby(["participant_ID", "session"])["c1"].shift(1)
    d["prev_reward"] = d.groupby(["participant_ID", "session"])["reward"].shift(1)
    d["prev_transition"] = d.groupby(["participant_ID", "session"])["transition"].shift(1)
    miss_stay = d["stay"].isna()
    d.loc[miss_stay, "stay"] = (d.loc[miss_stay, "c1"] == d.loc[miss_stay, "prev_c1"]).astype(float)
    d["prev_rew_bin"] = (d["prev_reward"] > 0).astype(float)
    d["prev_trans_common"] = d["prev_transition"].astype(str).str.lower().eq("common").astype(float)
    d = d.dropna(subset=["stay", "prev_rew_bin", "prev_trans_common", "prev_c1"]).copy()

    if "age" in d.columns:
        d["age"] = pd.to_numeric(d["age"], errors="coerce")
    if "age_group" not in d.columns and "age" in d.columns:
        d["age_group"] = np.select(
            [d["age"] < 13, d["age"] < 18],
            ["Children", "Adolescents"],
            default="Adults",
        )
    d["age_group"] = pd.Categorical(
        d["age_group"].astype(str),
        categories=["Children", "Adolescents", "Adults"],
        ordered=True,
    )

    both = d.groupby("participant_ID")["session"].nunique()
    keep = both[both == 2].index
    return d[d["participant_ID"].isin(keep)].copy()


def latest_fixed_lambda_params(repo_root: str, params_path: str | None = None, fit_tag: str | None = None) -> pd.DataFrame:
    if params_path:
        print(f"Using params: {os.path.basename(params_path)}")
        return pd.read_csv(params_path)
    ts_dir = os.path.join(repo_root, "data", "parameter_estimates", "twostep")
    if fit_tag is None:
        fit_tag = "samp10k"
    cand = sorted(glob.glob(os.path.join(ts_dir, f"two_step_fixed_lambda_{fit_tag}_participant_estimates_*.csv")))
    if not cand:
        summary = sorted(glob.glob(os.path.join(ts_dir, f"two_step_fixed_lambda_{fit_tag}_fit_summary_*.tsv")))
        if summary:
            raise FileNotFoundError(
                f"No two_step_fixed_lambda_{fit_tag}_participant_estimates_*.csv; run extract on "
                f"{os.path.basename(summary[-1])} first."
            )
        raise FileNotFoundError(f"No two_step_fixed_lambda_{fit_tag}_participant_estimates_*.csv")
    path = cand[-1]
    print(f"Using params: {os.path.basename(path)}")
    return pd.read_csv(path)


def load_glmm_footnote(glmm_table: str | None, repo_root: str) -> str:
    """One-line Panel A footnote from harmonized GLMM LRT table."""
    path = glmm_table or os.path.join(
        repo_root, "analysis", "model_free", "twostep_stay_model_nice_table.csv"
    )
    if not os.path.exists(path):
        return (
            "Inferential statistics for reward × transition on stay: logistic GLMM "
            "(see Supplementary Table)."
        )
    nice = pd.read_csv(path)

    def fmt(effect: str) -> str:
        row = nice.loc[nice["Effect"] == effect]
        if row.empty:
            return ""
        chi = float(str(row.iloc[0]["Chisq"]).strip().split()[0])
        p = str(row.iloc[0]["p.value"])
        return f"{effect.replace(':', ' × ')}: χ²(1) = {chi:.1f}, p {p}"

    rxt = fmt("previous_reward:previous_transition")
    rxt_age = fmt("previous_reward:previous_transition:age_z")
    parts = [p for p in (rxt, rxt_age) if p]
    stats = "; ".join(parts)
    return (
        f"Bars: observed group means ± SEM (left) vs fix-λ hybrid RL predictions (right). "
        f"Aggregate stay-pattern inference (logistic GLMM, Supp. Table): {stats}."
    )


def session_params(row: pd.Series, session: int) -> Dict[str, float]:
    sfx = "session1" if session == 1 else "session2"
    return {
        "alpha1": float(row[f"alpha1_{sfx}_mean"]),
        "beta1m": float(row[f"beta1m_{sfx}_mean"]),
        "beta1t": float(row[f"beta1t_{sfx}_mean"]),
        "beta2": float(row[f"beta2_{sfx}_mean"]),
        "betac": float(row[f"betac_{sfx}_mean"]),
    }


def forward_pass_observed(
    trials: pd.DataFrame, par: Dict[str, float], participant: int, session: int
) -> pd.DataFrame:
    """Trial-wise p(c1) and p(stay) on observed trial sequence."""
    g = trials[(trials["participant_ID"] == participant) & (trials["session"] == session)].sort_values("trial")
    qt1 = np.zeros(2)
    qt2 = np.zeros((2, 2))
    tcounts = np.zeros((2, 2), dtype=int)
    pc = 0.0
    rows = []
    for _, r in g.iterrows():
        net_common = (tcounts[0, 0] + tcounts[1, 1]) - (tcounts[0, 1] + tcounts[1, 0])
        is_common = net_common > 0
        qm = np.array([qt2[0].max(), qt2[1].max()]) if is_common else np.array([qt2[1].max(), qt2[0].max()])
        p_c1 = expit(par["beta1m"] * (qm[1] - qm[0]) + par["beta1t"] * (qt1[1] - qt1[0]) + par["betac"] * pc)
        prev_c1 = r["prev_c1"]
        if np.isfinite(prev_c1):
            p_stay = p_c1 if prev_c1 == 1 else (1.0 - p_c1)
        else:
            p_stay = np.nan
        rows.append(
            {
                "participant_ID": participant,
                "session": session,
                "trial": int(r["trial"]),
                "stay": float(r["stay"]),
                "p_stay": float(p_stay) if np.isfinite(p_stay) else np.nan,
                "prev_rew_bin": float(r["prev_rew_bin"]),
                "prev_trans_common": float(r["prev_trans_common"]),
                "prev_transition": r["prev_transition"],
            }
        )
        c1 = int(r["c1"])
        trans = str(r["transition"]).lower()
        rew = int(r["reward"] > 0)
        st = 0 if (c1 == 0 and trans == "common") or (c1 == 1 and trans == "rare") else 1
        c2 = 0
        if "choice_2" in g.columns:
            c2_val = pd.to_numeric(r.get("choice_2"), errors="coerce")
            if pd.notna(c2_val):
                c2 = 1 if c2_val == 2 else 0
        td2 = rew - qt2[st, c2]
        qt1[c1] = qt1[c1] * (1 - par["alpha1"]) + par["alpha1"] * qt2[st, c2] + 1.0 * par["alpha1"] * td2
        qt2[st, c2] = qt2[st, c2] * (1 - par["alpha1"]) + par["alpha1"] * rew
        qt1[1 - c1] *= 1 - par["alpha1"]
        qt2[st, 1 - c2] *= 1 - par["alpha1"]
        qt2[1 - st, 0] *= 1 - par["alpha1"]
        qt2[1 - st, 1] *= 1 - par["alpha1"]
        tcounts[c1, st] += 1
        pc = 2 * c1 - 1
    return pd.DataFrame(rows)


def mb_interaction_coef(
    df: pd.DataFrame, outcome_col: str = "stay", min_trials: int = 15, *, continuous: bool = False
) -> float:
    """Coefficient on reward × common-transition interaction (model-based index)."""
    if len(df) < min_trials:
        return np.nan
    y = df[outcome_col].astype(float)
    rew = df["prev_rew_bin"].astype(float)
    trans = df["prev_trans_common"].astype(float)
    Xdf = pd.DataFrame({"rew": rew, "trans": trans, "rew_trans": rew * trans})
    if continuous:
        try:
            beta, _, _, _ = np.linalg.lstsq(sm.add_constant(Xdf), y, rcond=None)
            return float(beta[3])
        except Exception:
            return np.nan
    if sm is None:
        return np.nan
    try:
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", category=Warning)
            res = sm.GLM(y, sm.add_constant(Xdf), family=sm.families.Binomial()).fit()
        return float(res.params["rew_trans"])
    except Exception:
        return np.nan


def per_subject_mb(trials: pd.DataFrame, pred: pd.DataFrame, params: pd.DataFrame) -> pd.DataFrame:
    rows = []
    for (pid, sess), g in trials.groupby(["participant_ID", "session"]):
        p = pred[(pred["participant_ID"] == pid) & (pred["session"] == sess)]
        m = g.merge(p[["trial", "p_stay"]], on="trial", how="inner")
        par_row = params.loc[params["participant_ID"] == pid]
        sfx = "session1" if sess == 1 else "session2"
        beta1m = float(par_row[f"beta1m_{sfx}_mean"].iloc[0]) if len(par_row) else np.nan
        rows.append(
            {
                "participant_ID": int(pid),
                "session": int(sess),
                "mb_obs": mb_interaction_coef(m, "stay", continuous=False),
                "beta1m_stan": beta1m,
            }
        )
    return pd.DataFrame(rows)


def simulate_trials(par: Dict[str, float], seed: int) -> pd.DataFrame:
    rng = np.random.default_rng(seed)
    qt1 = np.zeros(2)
    qt2 = np.zeros((2, 2))
    tcounts = np.zeros((2, 2), dtype=int)
    pc = 0.0
    rows = []
    for t in range(1, N_TRIALS_SIM + 1):
        net_common = (tcounts[0, 0] + tcounts[1, 1]) - (tcounts[0, 1] + tcounts[1, 0])
        is_common = net_common > 0
        qm = np.array([qt2[0].max(), qt2[1].max()]) if is_common else np.array([qt2[1].max(), qt2[0].max()])
        p_c1 = expit(par["beta1m"] * (qm[1] - qm[0]) + par["beta1t"] * (qt1[1] - qt1[0]) + par["betac"] * pc)
        prev_c1 = 0.0 if t == 1 else rows[-1]["c1"]
        prev_rew = 0.0 if t == 1 else rows[-1]["r"]
        prev_trans_common = 1.0 if t == 1 else (1.0 if rows[-1]["trans"] == "common" else 0.0)
        c1 = int(rng.random() < p_c1)
        if c1 == 0:
            s2 = 0 if rng.random() < COMMON_PROB else 1
        else:
            s2 = 1 if rng.random() < COMMON_PROB else 0
        c2 = int(rng.random() < expit(par["beta2"] * (qt2[s2, 1] - qt2[s2, 0])))
        r = int(rng.random() < 0.5)
        stay = float(c1 == prev_c1) if t > 1 else np.nan
        p_stay = p_c1 if prev_c1 == 1 else (1.0 - p_c1)
        rows.append(
            dict(
                trial=t,
                c1=c1,
                r=r,
                trans="common" if (c1 == 0 and s2 == 0) or (c1 == 1 and s2 == 1) else "rare",
                stay=stay,
                p_stay=p_stay,
                prev_rew_bin=prev_rew,
                prev_trans_common=prev_trans_common,
            )
        )
        td2 = r - qt2[s2, c2]
        qt1[c1] = qt1[c1] * (1 - par["alpha1"]) + par["alpha1"] * qt2[s2, c2] + par["alpha1"] * td2
        qt2[s2, c2] = qt2[s2, c2] * (1 - par["alpha1"]) + par["alpha1"] * r
        qt1[1 - c1] *= 1 - par["alpha1"]
        qt2[s2, 1 - c2] *= 1 - par["alpha1"]
        qt2[1 - s2, 0] *= 1 - par["alpha1"]
        qt2[1 - s2, 1] *= 1 - par["alpha1"]
        tcounts[c1, s2] += 1
        pc = 2 * c1 - 1
    out = pd.DataFrame(rows)
    out["stay_pred"] = (out["p_stay"] >= 0.5).astype(float)
    return out.dropna(subset=["stay"])


def recovery_mb_correlation(rec_path: str, out_dir: str) -> None:
    df = pd.read_csv(rec_path)
    rows = []
    for _, r in df.iterrows():
        par_true = {
            "alpha1": float(r["alpha1_sess_true"]),
            "beta1m": float(r["beta1m_sess_true"]),
            "beta1t": float(r["beta1t_sess_true"]),
            "beta2": float(r["beta2_sess_true"]),
            "betac": float(r["betac_sess_true"]),
        }
        par_est = {
            "alpha1": float(r["alpha1_sess_est"]),
            "beta1m": float(r["beta1m_sess_est"]),
            "beta1t": float(r["beta1t_sess_est"]),
            "beta2": float(r["beta2_sess_est"]),
            "betac": float(r["betac_sess_est"]),
        }
        sid = int(r["subject"])
        sim_t = simulate_trials(par_true, seed=10_000 + sid)
        sim_e = simulate_trials(par_est, seed=20_000 + sid)
        rows.append(
            {
                "subject": sid,
                "mb_true_sim": mb_interaction_coef(sim_t, "stay", continuous=False),
                "mb_est_sim": mb_interaction_coef(sim_e, "stay", continuous=False),
                "beta1m_true": par_true["beta1m"],
                "beta1m_est": par_est["beta1m"],
            }
        )
    out = pd.DataFrame(rows).dropna(subset=["mb_true_sim", "mb_est_sim"])
    r = out["mb_true_sim"].corr(out["mb_est_sim"], method="spearman")
    fig, ax = plt.subplots(figsize=(5.5, 5))
    ax.scatter(out["mb_true_sim"], out["mb_est_sim"], s=28, alpha=0.55, color="0.2")
    lim = [min(out["mb_true_sim"].min(), out["mb_est_sim"].min()) - 0.05, max(out["mb_true_sim"].max(), out["mb_est_sim"].max()) + 0.05]
    ax.plot(lim, lim, "k--", alpha=0.4)
    ax.set_xlabel("MB β (mixed model on true-sim trials)", fontweight="bold")
    ax.set_ylabel("MB β (mixed model on refit-sim trials)", fontweight="bold")
    ax.set_title(f"Recovery: empirical MB index (n={len(out)})\nSpearman ρ = {r:.2f}", fontweight="bold")
    sns.despine(ax=ax)
    path = os.path.join(out_dir, "two_step_fixed_lambda_recovery_mb_regression_scatter.png")
    fig.savefig(path, dpi=300, bbox_inches="tight")
    plt.close(fig)
    out.to_csv(os.path.join(out_dir, "two_step_fixed_lambda_recovery_mb_regression.csv"), index=False)
    print(f"Saved: {path}")


# Canonical figure-5 colors: common = blue, rare = red
TRANS_COLS = {1: "#2C7FB8", 0: "#D7191C"}
TRANS_LABELS = {1: "Common", 0: "Rare"}
REWARD_LABELS = {1: "Reward", 0: "No Reward"}

# Manuscript-readable typography (tune here)
FONT = {
    "panel_title": 17,
    "footnote": 10.5,
    "legend": 11.5,
    "legend_title": 11.5,
    "col_title": 13,
    "session_badge": 12,
    "axis_label": 12,
    "tick": 11,
    "stats": 12,
    "scatter_legend": 11,
}


def _stay_cell_stats(
    merged: pd.DataFrame, rew: int, trans: int, session: int, age_group: Optional[str] = None
) -> Dict[str, float]:
    sub = merged[
        (merged["session"] == session)
        & (merged["prev_rew_bin"] == rew)
        & (merged["prev_trans_common"] == trans)
    ]
    if age_group is not None:
        sub = sub[sub["age_group"].astype(str) == age_group]
    per_subj = sub.groupby("participant_ID", as_index=False).agg(stay=("stay", "mean"), p_stay=("p_stay", "mean"))
    return {
        "stay": float(per_subj["stay"].mean()) if len(per_subj) else np.nan,
        "p_stay": float(per_subj["p_stay"].mean()) if len(per_subj) else np.nan,
        "stay_sem": float(per_subj["stay"].sem()) if len(per_subj) > 1 else 0.0,
        "p_stay_sem": float(per_subj["p_stay"].sem()) if len(per_subj) > 1 else 0.0,
    }


def _draw_canonical_stay_panel(
    ax: plt.Axes,
    merged: pd.DataFrame,
    session: int,
    series: str,
    age_group: Optional[str] = None,
    *,
    show_ylabel: bool,
    show_xlabel: bool,
) -> None:
    """Canonical stay plot: outcome on x; common (blue) left, rare (red) right."""
    if series not in {"observed", "model"}:
        raise ValueError(f"series must be 'observed' or 'model', got {series!r}")

    reward_order = [1, 0]  # Reward, then No reward
    x_centers = np.arange(len(reward_order), dtype=float)
    trans_dodge = 0.22
    bar_w = 0.36

    val_key = "stay" if series == "observed" else "p_stay"
    sem_key = "stay_sem" if series == "observed" else "p_stay_sem"

    for xi, rew in enumerate(reward_order):
        for trans, side in ((1, -1), (0, 1)):
            stats = _stay_cell_stats(merged, rew, trans, session, age_group)
            tcolor = TRANS_COLS[trans]
            x_pos = x_centers[xi] + side * trans_dodge
            if series == "observed":
                ax.bar(
                    x_pos,
                    stats[val_key],
                    width=bar_w,
                    color=tcolor,
                    alpha=0.95,
                    edgecolor="black",
                    linewidth=0.6,
                    yerr=stats[sem_key],
                    capsize=2.0,
                    error_kw={"elinewidth": 0.8, "ecolor": "0.25"},
                    zorder=3,
                )
            else:
                ax.bar(
                    x_pos,
                    stats[val_key],
                    width=bar_w,
                    facecolor="white",
                    edgecolor=tcolor,
                    linewidth=1.4,
                    hatch="///",
                    yerr=stats[sem_key],
                    capsize=2.0,
                    error_kw={"elinewidth": 0.8, "ecolor": "0.35"},
                    zorder=3,
                )

    ax.axhline(0.5, color="k", alpha=0.08, zorder=0)
    ax.set_xticks(x_centers)
    ax.set_xticklabels([REWARD_LABELS[r] for r in reward_order], fontsize=FONT["tick"], color="#404040")
    if show_xlabel:
        ax.set_xlabel("Outcome of Previous Trial", fontsize=FONT["axis_label"], color="#606060", labelpad=4)
    else:
        ax.set_xlabel("")
    ax.set_ylim(0.5, 1.0)
    ax.set_yticks(np.linspace(0.5, 1.0, 6))
    ax.tick_params(axis="y", labelsize=FONT["tick"], colors="#606060")
    if show_ylabel:
        ax.set_ylabel("Proportion of First-Stage Stays", fontsize=FONT["axis_label"], color="#606060", fontweight="bold")
    else:
        ax.set_ylabel("")
        ax.set_yticklabels([])
    sns.despine(ax=ax, top=True, right=True)


def plot_trt_ppc(trials: pd.DataFrame, pred: pd.DataFrame, out_png: str, out_pdf: str) -> None:
    merged = trials.merge(pred, on=["participant_ID", "session", "trial"], suffixes=("", "_pred"))
    scatter_palette = {1.0: TRANS_COLS[1], 0.0: TRANS_COLS[0]}
    scatter_labels = {1.0: "Prior common", 0.0: "Prior rare"}

    sns.set_theme(style="ticks", context="notebook", font_scale=1.35, rc={"font.family": "Arial"})
    fig = plt.figure(figsize=(12.5, 10.5))
    gs = fig.add_gridspec(
        4,
        2,
        left=0.10,
        right=0.98,
        top=0.86,
        bottom=0.07,
        hspace=0.48,
        wspace=0.24,
        height_ratios=[1.0, 1.0, 0.06, 1.0],
    )

    fig.text(
        0.10,
        0.975,
        "A. Proportion of first-stage stays by prior reward × transition",
        fontsize=FONT["panel_title"],
        fontweight="bold",
        color="#505050",
    )
    panel_a_cols = [("observed", "Observed"), ("model", "Model")]
    ax_a_obs, ax_a_mod = None, None
    for ri, sess in enumerate([1, 2]):
        for ci, (series, col_title) in enumerate(panel_a_cols):
            ax = fig.add_subplot(gs[ri, ci])
            if ri == 0 and ci == 0:
                ax_a_obs = ax
            if ri == 0 and ci == 1:
                ax_a_mod = ax
            _draw_canonical_stay_panel(
                ax,
                merged,
                sess,
                series,
                age_group=None,
                show_ylabel=(ci == 0),
                show_xlabel=(ri == 1),
            )
            if ri == 0:
                ax.set_title(col_title, fontsize=FONT["col_title"], fontweight="bold", color="#404040", pad=6)
            if ci == 0:
                ax.text(
                    -0.20,
                    0.5,
                    f"Session {sess}",
                    transform=ax.transAxes,
                    rotation=90,
                    va="center",
                    ha="center",
                    fontsize=FONT["session_badge"],
                    fontweight="bold",
                    color="#505050",
                    bbox=dict(boxstyle="square,pad=0.35", facecolor="#F2F2F2", edgecolor="#B3B3B3", linewidth=0.6),
                )

    if ax_a_obs is not None and ax_a_mod is not None:
        pos_l = ax_a_obs.get_position()
        pos_r = ax_a_mod.get_position()
        x_mid = (pos_l.x1 + pos_r.x0) / 2
        y_legend = max(pos_l.y1, pos_r.y1) + 0.012
        fig.legend(
            handles=[
                Patch(facecolor=TRANS_COLS[1], edgecolor="black", linewidth=0.6, label="Common"),
                Patch(facecolor=TRANS_COLS[0], edgecolor="black", linewidth=0.6, label="Rare"),
            ],
            loc="lower center",
            bbox_to_anchor=(x_mid, y_legend),
            ncol=1,
            frameon=False,
            fontsize=FONT["legend"],
            title="Prior transition",
            title_fontsize=FONT["legend_title"],
            borderaxespad=0.0,
        )

    rmse = lambda x: np.sqrt(np.mean(np.square(x)))
    fig.text(
        0.10,
        0.34,
        "B. Observed & model-predicted stay (by participant)",
        fontsize=FONT["panel_title"],
        fontweight="bold",
        color="#505050",
    )
    for i, sess in enumerate([1, 2]):
        ax = fig.add_subplot(gs[3, i])
        dd = merged[merged["session"] == sess].copy()
        gb = dd.groupby(["participant_ID", "prev_trans_common"], as_index=False).agg(
            stay=("stay", "mean"), p_stay=("p_stay", "mean")
        )
        r = gb["stay"].corr(gb["p_stay"], method="spearman")
        e = rmse(gb["stay"] - gb["p_stay"])
        for pt, lab in scatter_labels.items():
            g = gb[np.isclose(gb["prev_trans_common"], pt)]
            ax.scatter(
                g["stay"],
                g["p_stay"],
                s=48,
                alpha=0.78,
                color=scatter_palette[pt],
                label=lab,
            )
        ax.plot([-0.02, 1.02], [-0.02, 1.02], color="k", alpha=0.35, zorder=-1)
        ax.annotate(
            f"RMSE = {e:0.3f}\n$\\rho$ = {r:0.3f}",
            (0, 0),
            (0.01, 0.98),
            "axes fraction",
            ha="left",
            va="top",
            color="#505050",
            fontsize=FONT["stats"],
        )
        ax.set(xlim=(-0.02, 1.02), ylim=(-0.02, 1.02), xticks=np.linspace(0, 1, 6), yticks=np.linspace(0, 1, 6))
        ax.set_xticklabels([f"{v:.1f}" for v in np.linspace(0, 1, 6)], fontsize=FONT["tick"], color="#606060")
        ax.tick_params(axis="y", labelsize=FONT["tick"], colors="#606060")
        if i == 0:
            ax.set_ylabel("Predicted p(Stay)", fontsize=FONT["axis_label"], color="#606060")
        else:
            ax.set_ylabel("")
            ax.set_yticklabels([])
        ax.set_xlabel("Observed p(Stay)", fontsize=FONT["axis_label"], color="#606060")
        ax.set_title(f"Session {sess}", loc="left", fontsize=FONT["col_title"], color="#606060")
        if i == 1:
            ax.legend(
                loc="center left",
                bbox_to_anchor=(1.02, 0.5),
                frameon=False,
                fontsize=FONT["scatter_legend"],
                title="Prior transition",
                title_fontsize=FONT["scatter_legend"],
            )
        sns.despine(ax=ax, top=True, right=True)

    fig.savefig(out_png, dpi=320, bbox_inches="tight")
    fig.savefig(out_pdf, bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    if sm is None:
        raise ImportError("statsmodels is required: pip install statsmodels")

    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=os.getcwd())
    ap.add_argument("--params-file", default=None, help="Participant params CSV (default: latest fixed_lambda)")
    ap.add_argument(
        "--fit-tag",
        default="samp10k",
        help="Tagged Stan fit for participant params CSV lookup. Default: samp10k.",
    )
    ap.add_argument(
        "--glmm-table",
        default=None,
        help="GLMM nice-table CSV for Panel A footnote (default: twostep_stay_model_nice_table.csv).",
    )
    ap.add_argument("--output-stem", default="two_step_fixed_lambda_trt_ppc_session_structure")
    ap.add_argument("--recovery-subject-file", default=None, help="Optional indep recovery subject-level CSV")
    args = ap.parse_args()
    repo_root = os.path.abspath(args.repo_root)
    out_dir = os.path.join(repo_root, "outputs", "figures")
    os.makedirs(out_dir, exist_ok=True)

    trials = load_twostep_trials(repo_root)
    params = latest_fixed_lambda_params(repo_root, args.params_file, fit_tag=args.fit_tag)
    pred_parts = []
    for _, row in params.iterrows():
        pid = int(row["participant_ID"])
        for sess in (1, 2):
            par = session_params(row, sess)
            pred_parts.append(forward_pass_observed(trials, par, pid, sess))
    pred = pd.concat(pred_parts, ignore_index=True)
    mb = per_subject_mb(trials, pred, params)

    out_png = os.path.join(out_dir, f"{args.output_stem}.png")
    out_pdf = os.path.join(out_dir, f"{args.output_stem}.pdf")
    plot_trt_ppc(trials, pred, out_png, out_pdf)
    mb.to_csv(os.path.join(out_dir, "two_step_fixed_lambda_trt_mb_regression_coefs.csv"), index=False)
    print(f"Saved: {out_png}")
    print(f"Saved: {out_pdf}")

    if args.recovery_subject_file:
        recovery_mb_correlation(args.recovery_subject_file, out_dir)


if __name__ == "__main__":
    main()
