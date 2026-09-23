# Manuscript-reported targets for automated verification.
# Tolerances allow for rounding in prose (2–3 decimal places).

manuscript_targets <- function() {
  list(
    risk = list(
      list(id = "risk_prob_F", effect = "probability", stat = "F", value = 451.16, tol = 0.5),
      list(id = "risk_prob_exposure_F", effect = "probability:z_exposure", stat = "F", value = 289.90, tol = 0.5),
      list(id = "risk_age_prob_exposure_F", effect = "z_age:probability:z_exposure", stat = "F", value = 4.25, tol = 0.15),
      list(id = "risk_age_prob_p", effect = "z_age:probability", stat = "p", value = 0.258, tol = 0.01),
      list(id = "risk_session_F", effect = "session", stat = "F", value = 0.99, tol = 0.1),
      list(id = "risk_prob_session_F", effect = "probability:session", stat = "F", value = 37.04, tol = 0.5),
      list(id = "risk_mean_p02_s1", effect = "mean_0.2_s1", stat = "mean", value = 0.278, tol = 0.005),
      list(id = "risk_mean_p05_s1", effect = "mean_0.5_s1", stat = "mean", value = 0.539, tol = 0.005),
      list(id = "risk_mean_p08_s1", effect = "mean_0.8_s1", stat = "mean", value = 0.777, tol = 0.005),
      list(id = "risk_mean_p02_s2", effect = "mean_0.2_s2", stat = "mean", value = 0.235, tol = 0.005),
      list(id = "risk_mean_p08_s2", effect = "mean_0.8_s2", stat = "mean", value = 0.800, tol = 0.005),
      list(id = "risk_posthoc_p02_t", effect = "posthoc_0.2_t", stat = "t", value = 4.80, tol = 0.15),
      list(id = "risk_posthoc_p08_t", effect = "posthoc_0.8_t", stat = "t", value = 2.53, tol = 0.15),
      list(id = "risk_age_session_F", effect = "z_age:session", stat = "F", value = 3.98, tol = 0.15),
      list(id = "risk_session_exposure_F", effect = "session:z_exposure", stat = "F", value = 4.65, tol = 0.15)
    ),
    pit_logit = list(
      list(id = "pit_valence_chi", effect = "valence", stat = "Chisq", value = 776.73, tol = 1.0),
      list(id = "pit_action_chi", effect = "action", stat = "Chisq", value = 3337.79, tol = 2.0),
      list(id = "pit_valence_action_chi", effect = "valence:action", stat = "Chisq", value = 7.63, tol = 0.15),
      list(id = "pit_action_exposure_chi", effect = "action:z_exposure", stat = "Chisq", value = 1543.83, tol = 2.0),
      list(id = "pit_valence_exposure_chi", effect = "valence:z_exposure", stat = "Chisq", value = 9.07, tol = 0.15),
      list(id = "pit_age_chi", effect = "z_age", stat = "Chisq", value = 0.45, tol = 0.1),
      list(id = "pit_action_age_chi", effect = "action:z_age", stat = "Chisq", value = 363.19, tol = 1.0),
      list(id = "pit_valence_age_chi", effect = "valence:z_age", stat = "Chisq", value = 18.44, tol = 0.2),
      list(id = "pit_session_chi", effect = "session", stat = "Chisq", value = 43.82, tol = 0.5),
      list(id = "pit_valence_session_chi", effect = "valence:session", stat = "Chisq", value = 56.09, tol = 0.5),
      list(id = "pit_exposure_session_chi", effect = "z_exposure:session", stat = "Chisq", value = 6.96, tol = 0.15),
      list(id = "pit_age_session_chi", effect = "z_age:session", stat = "Chisq", value = 0.13, tol = 0.1)
    ),
    pit_bias = list(
      list(id = "pit_bias_session_F", effect = "session", stat = "F", value = 14.44, tol = 1.0),
      list(id = "pit_bias_age_session_p", effect = "z_age:session", stat = "p", value = 0.970, tol = 0.04)
    ),
    twostep_stay = list(
      list(id = "ts_reward_chi", effect = "previous_reward", stat = "Chisq", value = 58.20, tol = 0.5),
      list(id = "ts_reward_trans_chi", effect = "previous_reward:previous_transition", stat = "Chisq", value = 61.91, tol = 0.5),
      list(id = "ts_age_chi", effect = "age_z", stat = "Chisq", value = 5.92, tol = 0.2),
      list(id = "ts_reward_age_chi", effect = "previous_reward:age_z", stat = "Chisq", value = 12.87, tol = 0.3),
      list(id = "ts_mb_age_chi", effect = "previous_reward:previous_transition:age_z", stat = "Chisq", value = 6.67, tol = 0.15),
      list(id = "ts_mb_session_chi", effect = "previous_reward:previous_transition:session", stat = "Chisq", value = 1.24, tol = 0.25, note = "manuscript_para2_harmonized_anova"),
      list(id = "ts_mb_age_session_chi", effect = "previous_reward:previous_transition:age_z:session", stat = "Chisq", value = 1.25, tol = 0.25, note = "manuscript_para2_harmonized_anova"),
      list(id = "ts_reward_session_chi", effect = "previous_reward:session", stat = "Chisq", value = 3.14, tol = 0.6, note = "manuscript_para2_harmonized_anova"),
      list(id = "ts_reward_age_session_chi", effect = "previous_reward:age_z:session", stat = "Chisq", value = 3.26, tol = 0.15, note = "manuscript_para2_harmonized_anova"),
      list(id = "ts_session_chi", effect = "session", stat = "Chisq", value = 54.87, tol = 6.0, note = "manuscript_para2_harmonized_anova"),
      list(id = "ts_age_session_chi", effect = "age_z:session", stat = "Chisq", value = 16.15, tol = 1.5, note = "manuscript_para2_harmonized_anova"),
      list(id = "ts_reward_chi_lrt", effect = "previous_reward", stat = "Chisq", value = 58.20, tol = 0.5, note = "cached_lrt_rt_excl"),
      list(id = "ts_session_chi_lrt", effect = "session", stat = "Chisq", value = 40.11, tol = 0.5, note = "cached_lrt_rt_excl"),
      # Added 2026-09-22: the manuscript's "stable across sessions" paragraph
      # (session-stability terms) quotes twostep_stay_model_manuscript_nice.csv
      # directly, not the para2_harmonized_anova pipeline above -- these five
      # terms had no target at all previously, despite being reported values.
      list(id = "ts_mb_session_chi_lrt", effect = "previous_reward:previous_transition:session", stat = "Chisq", value = 0.61, tol = 0.15, note = "cached_lrt_rt_excl"),
      list(id = "ts_mb_age_session_chi_lrt", effect = "previous_reward:previous_transition:age_z:session", stat = "Chisq", value = 1.53, tol = 0.2, note = "cached_lrt_rt_excl"),
      list(id = "ts_reward_session_chi_lrt", effect = "previous_reward:session", stat = "Chisq", value = 2.26, tol = 0.2, note = "cached_lrt_rt_excl"),
      list(id = "ts_age_session_chi_lrt", effect = "age_z:session", stat = "Chisq", value = 14.62, tol = 0.5, note = "cached_lrt_rt_excl"),
      list(id = "ts_reward_age_session_chi_lrt", effect = "previous_reward:age_z:session", stat = "Chisq", value = 4.04, tol = 0.2, note = "cached_lrt_rt_excl")
    ),
    # Current canonical model: rstd_m9_sh (b1 = beta, a_conf/a_disc = confirmatory/
    # disconfirmatory learning rate, q0 = initial Q-value). Values verified against
    # the manuscript's reported Spearman/ICC(C,1) numbers 2026-09-22 (ICC(C,1) here
    # is the Pearson correlation between participants' session-specific joint-model
    # posterior means, per the manuscript's own Methods definition).
    reliability_risk = list(
      list(id = "risk_rho_b1", param = "b1", stat = "spearman_rho", value = 0.79, tol = 0.02),
      list(id = "risk_rho_q0", param = "q0", stat = "spearman_rho", value = 0.80, tol = 0.02),
      list(id = "risk_rho_a_conf", param = "a_conf", stat = "spearman_rho", value = 0.72, tol = 0.02),
      list(id = "risk_rho_a_disc", param = "a_disc", stat = "spearman_rho", value = 0.66, tol = 0.02),
      list(id = "risk_icc_b1", param = "b1", stat = "icc", value = 0.77, tol = 0.02),
      list(id = "risk_icc_q0", param = "q0", stat = "icc", value = 0.81, tol = 0.02),
      list(id = "risk_icc_a_conf", param = "a_conf", stat = "icc", value = 0.74, tol = 0.02),
      list(id = "risk_icc_a_disc", param = "a_disc", stat = "icc", value = 0.62, tol = 0.02)
    ),
    # Current canonical model: pgng_m3_sh (b1 = beta, b3/b4 = go bias in gain/loss
    # context [tau_gain/tau_loss], a1 = learning rate eta). Verified 2026-09-22.
    reliability_pit = list(
      list(id = "pit_rho_b1", param = "b1", stat = "spearman_rho", value = 0.84, tol = 0.02),
      list(id = "pit_rho_b3", param = "b3", stat = "spearman_rho", value = 0.66, tol = 0.02),
      list(id = "pit_rho_b4", param = "b4", stat = "spearman_rho", value = 0.57, tol = 0.02),
      list(id = "pit_rho_a1", param = "a1", stat = "spearman_rho", value = 0.88, tol = 0.02),
      list(id = "pit_icc_b1", param = "b1", stat = "icc", value = 0.86, tol = 0.02),
      list(id = "pit_icc_b3", param = "b3", stat = "icc", value = 0.76, tol = 0.02),
      list(id = "pit_icc_b4", param = "b4", stat = "icc", value = 0.70, tol = 0.02),
      list(id = "pit_icc_a1", param = "a1", stat = "icc", value = 0.90, tol = 0.02)
    ),
    # Current canonical model: two-step FREE-FORGETTING (replaces the old fixed-
    # lambda 5-parameter model as of 2026-09-21; adds "forget"/phi, the unchosen-
    # value forgetting rate, separated out from the learning rate alpha1/eta).
    # See analysis/manuscript/TWOSTEP_FREEFORGET_RESULTS_20260921.md for the full
    # writeup (joint fit diagnostics, PPC, recovery, model comparison vs. the old
    # linked-forgetting model). Verified 2026-09-22.
    reliability_twostep = list(
      list(id = "ts_rho_beta1m", param = "beta1m", stat = "spearman_rho", value = 0.97, tol = 0.02),
      list(id = "ts_rho_beta1t", param = "beta1t", stat = "spearman_rho", value = 0.74, tol = 0.02),
      list(id = "ts_rho_alpha1", param = "alpha1", stat = "spearman_rho", value = 0.88, tol = 0.02),
      list(id = "ts_rho_forget", param = "forget", stat = "spearman_rho", value = 0.66, tol = 0.02),
      list(id = "ts_rho_betac", param = "betac", stat = "spearman_rho", value = 0.73, tol = 0.02),
      list(id = "ts_rho_beta2", param = "beta2", stat = "spearman_rho", value = 0.83, tol = 0.02),
      # tol widened slightly: manuscript value is from a 10,000-draw participant
      # bootstrap median; this repo's cached reproduction uses a plain Pearson r
      # (asymptotically equivalent, ~0.02 apart for this parameter in practice).
      list(id = "ts_icc_beta1m", param = "beta1m", stat = "icc", value = 0.93, tol = 0.025),
      list(id = "ts_icc_beta1t", param = "beta1t", stat = "icc", value = 0.65, tol = 0.02),
      list(id = "ts_icc_alpha1", param = "alpha1", stat = "icc", value = 0.89, tol = 0.02),
      list(id = "ts_icc_forget", param = "forget", stat = "icc", value = 0.74, tol = 0.02),
      list(id = "ts_icc_betac", param = "betac", stat = "icc", value = 0.75, tol = 0.02),
      list(id = "ts_icc_beta2", param = "beta2", stat = "icc", value = 0.88, tol = 0.02)
    )
  )
}
