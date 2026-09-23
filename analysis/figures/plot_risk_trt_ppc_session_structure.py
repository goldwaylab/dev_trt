#!/usr/bin/env python3
"""
Risk TRT PPC figure (Session 1/2): learning curves + observed vs predicted scatter.

Model: risk_valence_asymmetry (canonical manuscript RISK model).
"""

from __future__ import annotations

import argparse
import glob
import os
import re

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns


def inv_logit(x: float) -> float:
    return 1.0 / (1.0 + np.exp(-x))


def load_behavior(repo_root: str) -> pd.DataFrame:
    s1 = pd.read_csv(os.path.join(repo_root, "data", "behavioral", "risk", "s1", "data.csv"))
    s2 = pd.read_csv(os.path.join(repo_root, "data", "behavioral", "risk", "s2", "data.csv"))
    s1["session"] = 1
    s2["session"] = 2
    d = pd.concat([s1, s2], ignore_index=True)
    d = d.rename(columns={d.columns[0]: "row_id"})
    for c in ["subject", "session", "choice", "bandit", "probability", "exposure", "block", "trial"]:
        d[c] = pd.to_numeric(d[c], errors="coerce")
    d["reward_bin"] = (pd.to_numeric(d["points"], errors="coerce") > 0).astype(int)
    d = d.dropna(subset=["subject", "session", "choice", "bandit", "probability", "exposure"])
    d = d.sort_values(["subject", "session", "block", "trial"]).reset_index(drop=True)
    both = d.groupby("subject")["session"].nunique()
    keep = sorted(both[both == 2].index.tolist())
    return d[d["subject"].isin(keep)].copy()


def latest_risk_fit_files(repo_root: str, fit_tag: str | None = None) -> tuple[str, str]:
    risk_dir = os.path.join(repo_root, "data", "parameter_estimates", "risk")
    if fit_tag is None:
        fit_tag = "samp10k"
    summ_glob = os.path.join(risk_dir, f"risk_valence_asymmetry_{fit_tag}_fit_summary_*.tsv")
    subs_glob = os.path.join(risk_dir, f"risk_valence_asymmetry_{fit_tag}_fit_subjects_*.csv")
    summ_matches = glob.glob(summ_glob)
    subs_matches = glob.glob(subs_glob)
    if not summ_matches or not subs_matches:
        raise FileNotFoundError(f"No risk_valence_asymmetry fit files matching {summ_glob}")
    summ = max(summ_matches, key=os.path.getmtime)
    subs = max(subs_matches, key=os.path.getmtime)
    return summ, subs


def load_risk_parameters(repo_root: str, fit_tag: str | None = None) -> pd.DataFrame:
    summ_path, subs_path = latest_risk_fit_files(repo_root, fit_tag)
    summ = pd.read_csv(summ_path, sep="\t", index_col=0)
    subs = pd.read_csv(subs_path)
    params = ["b1", "a1", "a2", "a3", "a4", "q0"]
    rows = []
    first = summ.index.name or summ.reset_index().columns[0]
    means = summ["Mean"] if "Mean" in summ.columns else summ.iloc[:, 0]
    for idx, val in means.items():
        m = re.match(r"^(b1|a1|a2|a3|a4|q0)\[(\d+),(\d+)\]$", str(idx).strip('"'))
        if not m:
            continue
        p, sess, sidx = m.group(1), int(m.group(2)), int(m.group(3))
        if 1 <= sidx <= len(subs):
            rows.append(
                {"subject": int(subs.iloc[sidx - 1]["subject"]), "session": sess, "param": p, "value": float(val)}
            )
    out = (
        pd.DataFrame(rows)
        .pivot_table(index=["subject", "session"], columns="param", values="value", aggfunc="first")
        .reset_index()
    )
    print(f"Using RISK summary: {os.path.basename(summ_path)}")
    return out


def predict_risk(df: pd.DataFrame, pars: pd.DataFrame) -> pd.DataFrame:
    d = df.merge(pars, on=["subject", "session"], how="inner").copy()
    out = []
    for (subj, sess), g in d.groupby(["subject", "session"], sort=False):
        g = g.sort_values(["block", "trial"])
        bandits = sorted(pd.unique(g["bandit"]))
        bmap = {b: i for i, b in enumerate(bandits)}
        q0 = float(g["q0"].iloc[0])
        Q = np.full(len(bandits), q0, dtype=float)
        b1 = float(g["b1"].iloc[0])
        a1, a2, a3, a4 = float(g["a1"].iloc[0]), float(g["a2"].iloc[0]), float(g["a3"].iloc[0]), float(g["a4"].iloc[0])
        for _, r in g.iterrows():
            k = bmap[r["bandit"]]
            p = inv_logit(b1 * (Q[k] - 0.5))
            rew = int(r["reward_bin"])
            y = int(r["choice"])
            out.append(
                dict(
                    subject=int(subj),
                    session=int(sess),
                    exposure=int(r["exposure"]),
                    probability=float(r["probability"]),
                    choice=float(y),
                    Y_hat=float(p),
                )
            )
            delta = rew - Q[k]
            if delta > 0:
                eta = a1 if y == 1 else a3
            elif delta < 0:
                eta = a2 if y == 1 else a4
            else:
                eta = 0.0
            Q[k] += eta * delta
    return pd.DataFrame(out)


def plot_ppc(ppc: pd.DataFrame, out_png: str, out_pdf: str) -> None:
    sessions = [1, 2]
    labels = ["Session 1", "Session 2"]
    probs = [0.2, 0.5, 0.8]
    prob_palette = {0.2: "#66c2a5", 0.5: "#fc8d62", 0.8: "#8da0cb"}

    sns.set_theme(style="ticks", context="notebook", font_scale=1.2, rc={"font.family": "Arial"})
    fig = plt.figure(figsize=(7.2, 7.0))
    gs = fig.add_gridspec(2, 2, left=0.09, right=0.98, top=0.84, bottom=0.08, hspace=0.78, wspace=0.22)

    for i, sess in enumerate(sessions):
        ax = plt.subplot(gs[0, i])
        dd = ppc[ppc["session"] == sess].copy()
        dd_sub = dd.groupby(["subject", "probability", "exposure"], as_index=False).agg(
            choice=("choice", "mean"), Y_hat=("Y_hat", "mean")
        )
        dd_grp = dd_sub.groupby(["probability", "exposure"], as_index=False).agg(
            choice=("choice", "mean"), Y_hat=("Y_hat", "mean"), n_subj=("subject", "nunique")
        )
        dd_grp = dd_grp[dd_grp["n_subj"] >= 20].copy()
        for p in probs:
            dpp = dd_grp[np.isclose(dd_grp["probability"], p)].sort_values("exposure")
            ax.plot(dpp["exposure"], dpp["choice"], color=prob_palette[p], linewidth=3)
            ax.plot(dpp["exposure"], dpp["Y_hat"], color="0.1", linewidth=2, linestyle=(0, (1, 1)))
        ax.axhline(0.5, color="k", alpha=0.08, zorder=-1)
        ax.set(xlim=(0.7, 15.3), xticks=[1, 3, 5, 7, 9, 11, 13, 15])
        ax.set_xticklabels([1, 3, 5, 7, 9, 11, 13, 15], fontsize=9, color="#606060")
        ax.set_xlabel("Exposure", fontsize=9, color="#606060", labelpad=1)
        if i == 0:
            ax.set_ylabel("p(Risky)", fontsize=11, color="#606060")
        else:
            ax.set_ylabel("")
            ax.set_yticklabels([])
        ax.set_title(labels[i], loc="left", fontsize=11, color="#606060")
        if i == 0:
            for p in probs:
                ax.plot([], [], color=prob_palette[p], lw=4, label=f"{p:.1f}")
            ax.plot([], [], color="0.1", linestyle=(0, (1, 1)), lw=2.2, label="MODEL")
            ax.legend(
                loc="upper left",
                bbox_to_anchor=(0, 1.33),
                ncol=4,
                frameon=False,
                fontsize=9,
                borderpad=0,
                borderaxespad=0,
                handletextpad=0.45,
                title="p(Reward)",
                title_fontsize=9,
            )
            ax.annotate(
                "A. Observed & model-predicted learning curves",
                (0, 0),
                (-0.13, 1.43),
                "axes fraction",
                ha="left",
                va="bottom",
                color="#505050",
                fontsize=14,
            )
        sns.despine(ax=ax, top=True, right=True)

    rmse = lambda x: np.sqrt(np.mean(np.square(x)))
    for i, sess in enumerate(sessions):
        ax = plt.subplot(gs[1, i])
        dd = ppc[ppc["session"] == sess].copy()
        gb = dd.groupby(["subject", "probability"], as_index=False).agg(
            choice=("choice", "mean"), Y_hat=("Y_hat", "mean")
        )
        r = gb[["choice", "Y_hat"]].corr(method="spearman").iloc[0, 1]
        e = rmse(gb["choice"] - gb["Y_hat"])
        sns.scatterplot(
            x="choice",
            y="Y_hat",
            hue="probability",
            hue_order=probs,
            data=gb,
            palette=prob_palette,
            legend=False,
            ax=ax,
            s=40,
            alpha=0.78,
        )
        ax.plot([-1, 2], [-1, 2], color="k", alpha=0.35, zorder=-1)
        ax.annotate(
            f"RMSE = {e:0.3f}\n$\\rho$ = {r:0.3f}",
            (0, 0),
            (0.01, 0.98),
            "axes fraction",
            ha="left",
            va="top",
            color="#505050",
            fontsize=10,
        )
        ax.set(xlim=(-0.02, 1.02), ylim=(-0.02, 1.02), xticks=np.linspace(0, 1, 6), yticks=np.linspace(0, 1, 6))
        ax.set_xticklabels([f"{v:.1f}" for v in np.linspace(0, 1, 6)], fontsize=9, color="#606060")
        if i == 0:
            ax.set_ylabel("Predicted", fontsize=11, color="#606060")
            ax.annotate(
                "B. Observed & model-predicted choice behavior",
                (0, 0),
                (-0.13, 1.20),
                "axes fraction",
                ha="left",
                va="bottom",
                color="#505050",
                fontsize=14,
            )
        else:
            ax.set_ylabel("")
            ax.set_yticklabels([])
        ax.set_xlabel("Observed", fontsize=9, color="#606060")
        ax.set_title(labels[i], loc="left", fontsize=11, color="#606060")
        sns.despine(ax=ax, top=True, right=True)

    fig.savefig(out_png, dpi=320, bbox_inches="tight")
    fig.savefig(out_pdf, bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", choices=("risk_valence_asymmetry",), default="risk_valence_asymmetry")
    ap.add_argument(
        "--fit-tag",
        default="samp10k",
        help="Tagged Stan fit suffix. Default: samp10k.",
    )
    ap.add_argument("--repo-root", default=os.getcwd())
    args = ap.parse_args()
    repo_root = os.path.abspath(args.repo_root)
    out_dir = os.path.join(repo_root, "outputs", "figures")
    os.makedirs(out_dir, exist_ok=True)
    out_png = os.path.join(out_dir, "risk_trt_ppc_session_structure.png")
    out_pdf = os.path.join(out_dir, "risk_trt_ppc_session_structure.pdf")

    d = load_behavior(repo_root)
    pars = load_risk_parameters(repo_root, fit_tag=args.fit_tag)
    ppc = predict_risk(d, pars)

    plot_ppc(ppc, out_png, out_pdf)
    print(f"Saved: {out_png}")
    print(f"Saved: {out_pdf}")


if __name__ == "__main__":
    main()
