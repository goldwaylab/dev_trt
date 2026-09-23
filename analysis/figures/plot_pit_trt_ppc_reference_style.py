
#!/usr/bin/env python3
"""
PIT TRT PPC figure in reference (RobotFactory) style.
"""

from __future__ import annotations

import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


def inv_logit(x):
    return 1.0 / (1.0 + np.exp(-x))


def load_pit_behavior(repo_root: str) -> pd.DataFrame:
    s1 = pd.read_csv(os.path.join(repo_root, "data", "behavioral", "pit", "s1", "pgng.csv"))
    s2 = pd.read_csv(os.path.join(repo_root, "data", "behavioral", "pit", "s2", "pgng.csv"))
    s1["session"] = 1
    s2["session"] = 2
    d = pd.concat([s1, s2], ignore_index=True)
    d = d.rename(columns={d.columns[0]: "row_id"})
    d["subject"] = pd.to_numeric(d["subject"], errors="coerce")
    d["session"] = pd.to_numeric(d["session"], errors="coerce")
    d["choice"] = pd.to_numeric(d["choice"], errors="coerce")
    d["outcome_num"] = pd.to_numeric(d["outcome"], errors="coerce")
    d = d.dropna(subset=["subject", "session", "choice", "stimulus", "valence", "robot", "exposure", "outcome_num"])
    d["val_bin"] = d["valence"].astype(str).str.lower().eq("win").astype(int)
    d["r_bin"] = np.where(d["val_bin"] == 1, (d["outcome_num"] > 5).astype(int), (d["outcome_num"] > -5).astype(int))
    d = d.sort_values(["subject", "session", "block", "trial"]).reset_index(drop=True)
    return d


def load_pit_params(repo_root: str) -> pd.DataFrame:
    pit_dir = os.path.join(repo_root, "data", "parameter_estimates", "pit")
    pfile = os.path.join(pit_dir, "pit_pavlovian_bias_samp10k_summary_with_age.csv")
    if not os.path.exists(pfile):
        raise FileNotFoundError(pfile)
    pp = pd.read_csv(pfile)
    pp = (
        pp.pivot_table(index=["subject_id", "session"], columns="parameter", values="param_value", aggfunc="first")
        .reset_index()
        .rename(columns={"subject_id": "subject"})
    )
    keep = ["subject", "session", "b1", "b2", "b3", "b4", "a1", "a2"]
    return pp[keep].dropna()


def predict_trialwise(df: pd.DataFrame, pars: pd.DataFrame) -> pd.DataFrame:
    d = df.merge(pars, on=["subject", "session"], how="inner").copy()
    rows = []
    for (subj, sess), g in d.groupby(["subject", "session"], sort=False):
        g = g.sort_values(["block", "trial"])
        stimuli = sorted(pd.unique(g["stimulus"]))
        smap = {s: i for i, s in enumerate(stimuli)}
        Q = np.full((len(stimuli), 2), 0.5, dtype=float)
        b1, b2, b3, b4, a1, a2 = [float(g[c].iloc[0]) for c in ["b1", "b2", "b3", "b4", "a1", "a2"]]
        for _, r in g.iterrows():
            k = smap[r["stimulus"]]
            y = int(r["choice"])
            v = int(r["val_bin"])
            rb = int(r["r_bin"])
            beta = b1 if v == 1 else b2
            tau = b3 if v == 1 else b4
            eta = a1 if v == 1 else a2
            p = inv_logit(beta * (Q[k, 1] - Q[k, 0]) + tau)
            rows.append(
                {
                    "subject": int(subj),
                    "session": int(sess),
                    "robot": str(r["robot"]).lower(),
                    "exposure": int(r["exposure"]),
                    "choice": float(y),
                    "Y_hat": float(p),
                }
            )
            delta = rb - Q[k, y]
            Q[k, y] += eta * delta
    return pd.DataFrame(rows)


def main():
    repo_root = os.getcwd()
    out_dir = os.path.join(repo_root, "outputs", "figures")
    os.makedirs(out_dir, exist_ok=True)
    out_png = os.path.join(out_dir, "pit_trt_ppc_reference_style.png")
    out_pdf = os.path.join(out_dir, "pit_trt_ppc_reference_style.pdf")

    d = load_pit_behavior(repo_root)
    pars = load_pit_params(repo_root)
    ppc = predict_trialwise(d, pars)

    robots = ["gw", "ngw", "gal", "ngal"]
    palette = ["#234f81", "#8e9cb8", "#bf8a82", "#812623"]
    panels = [("Session 1", [1]), ("Session 2", [2])]

    sns.set_theme(style="ticks", context="notebook", font_scale=1.2, rc={"font.family": "Arial"})
    fig = plt.figure(figsize=(7.0, 6.3))
    gs = fig.add_gridspec(2, 2, left=0.09, right=0.98, top=0.88, bottom=0.08, hspace=0.58, wspace=0.22)

    # Top row: learning curves
    for i, (label, sess_list) in enumerate(panels):
        ax = plt.subplot(gs[0, i])
        dd = ppc[ppc["session"].isin(sess_list)].copy()
        # Aggregate within subject first, then across subjects.
        dd_sub = (
            dd.groupby(["subject", "robot", "exposure"], as_index=False)
            .agg(choice=("choice", "mean"), Y_hat=("Y_hat", "mean"))
        )
        dd_grp = (
            dd_sub.groupby(["robot", "exposure"], as_index=False)
            .agg(
                choice=("choice", "mean"),
                Y_hat=("Y_hat", "mean"),
                n_subj=("subject", "nunique"),
            )
        )
        # Prevent unstable tail artifacts: keep exposure points with enough subjects.
        min_subjects = 20
        dd_grp = dd_grp[dd_grp["n_subj"] >= min_subjects].copy()

        for rlab, col in zip(robots, palette):
            drr = dd_grp[dd_grp["robot"] == rlab].sort_values("exposure")
            ax.plot(drr["exposure"], drr["choice"], color=col, linewidth=3)
            ax.plot(drr["exposure"], drr["Y_hat"], color="0.1", linewidth=2, linestyle=(0, (1, 1)))
        ax.axhline(0.5, color="k", alpha=0.08, zorder=-1)
        exp_ticks = [1, 3, 5, 7, 9, 11, 13, 15]
        ax.set(xlim=(0.7, 15.3), xticks=exp_ticks)
        ax.set_xticklabels(exp_ticks, fontsize=9, color="#606060")
        ax.set_xlabel("Trial", fontsize=9, color="#606060")
        if i == 0:
            ax.set_ylabel("p(Go)", fontsize=11, color="#606060")
        else:
            ax.set_ylabel("")
            ax.set_yticklabels([])
        ax.set_title(label, loc="left", fontsize=11, color="#606060")
        if i == 0:
            for c, r in zip(palette, robots):
                ax.plot([], [], color=c, label=r.upper(), lw=4)
            ax.plot([], [], color="0.1", linestyle=(0, (1, 1)), lw=2.2, label="MODEL")
            ax.legend(loc=2, bbox_to_anchor=(0, 1.23), ncol=5, frameon=False, fontsize=9, borderpad=0, borderaxespad=0, handletextpad=0.45)
            ax.annotate("A. Observed & model-predicted learning curves", (0, 0), (-0.13, 1.25), "axes fraction", ha="left", va="bottom", color="#505050", fontsize=14)
        sns.despine(ax=ax, top=True, right=True)

    # Bottom row: scatter
    rmse = lambda x: np.sqrt(np.mean(np.square(x)))
    for i, (label, sess_list) in enumerate(panels):
        ax = plt.subplot(gs[1, i])
        dd = ppc[ppc["session"].isin(sess_list)].copy()
        gb = dd.groupby(["subject", "robot"], as_index=False).agg(choice=("choice", "mean"), Y_hat=("Y_hat", "mean"))
        r = gb[["choice", "Y_hat"]].corr(method="spearman").values[0, 1]
        e = rmse(gb["choice"] - gb["Y_hat"])
        sns.scatterplot(x="choice", y="Y_hat", hue="robot", data=gb, hue_order=robots, palette=palette, legend=False, ax=ax, s=32)
        ax.plot([-1, 2], [-1, 2], color="k", alpha=0.35, zorder=-1)
        ax.annotate(f"RMSE = {e:0.3f}\n$\\rho$ = {r:0.3f}", (0, 0), (0.01, 0.98), "axes fraction", ha="left", va="top", color="#505050", fontsize=10)
        ax.set(xlim=(-0.02, 1.02), ylim=(-0.02, 1.02), xticks=[0, 0.2, 0.4, 0.6, 0.8, 1.0], yticks=[0, 0.2, 0.4, 0.6, 0.8, 1.0])
        ax.set_xticklabels([0, 0.2, 0.4, 0.6, 0.8, 1.0], fontsize=9, color="#606060")
        if i == 0:
            ax.set_ylabel("Predicted", fontsize=11, color="#606060")
            for c, rlab in zip(palette, robots):
                ax.scatter([], [], color=c, label=rlab.upper(), s=20)
            ax.legend(loc=2, bbox_to_anchor=(0, 1.23), ncol=4, frameon=False, fontsize=9, borderpad=0, borderaxespad=0, handletextpad=0.45)
            ax.annotate("B. Observed & model-predicted choice behavior", (0, 0), (-0.13, 1.25), "axes fraction", ha="left", va="bottom", color="#505050", fontsize=14)
        else:
            ax.set_ylabel("")
            ax.set_yticklabels([])
        ax.set_xlabel("Observed", fontsize=9, color="#606060")
        ax.set_title(label, loc="left", fontsize=11, color="#606060")
        sns.despine(ax=ax, top=True, right=True)

    plt.savefig(out_png, dpi=320)
    plt.savefig(out_pdf)
    plt.close(fig)
    print(f"Saved: {out_png}")
    print(f"Saved: {out_pdf}")


if __name__ == "__main__":
    main()
