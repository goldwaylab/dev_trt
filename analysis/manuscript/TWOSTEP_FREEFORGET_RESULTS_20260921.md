# Two-step free-forgetting model: full-sample results

> **Note on this public copy (added 2026-09-22):** this doc was written during
> internal analysis and links to full intermediate artifacts (posterior draws,
> per-batch recovery files, every figure variant) on the lab's internal storage.
> Only the joint fit's summary/subjects/metadata and the final reliability CSVs
> referenced here are included in this repo, under `data/parameter_estimates/twostep/`
> and `models/stan/twostep/two_step_free_forgetting_nc.stan`; the reported numbers
> are cross-checked in `analysis/manuscript/manuscript_targets.R` and
> `verify_manuscript_results.R`. Posterior draws (>400MB) are not distributed here.

## Status

The full joint model and both independent-session models are complete. The
posterior predictive check is complete for all 141 participants. Production
parameter and reliability recovery is also complete for 500 simulated
participants. The recovery results support strong participant-level parameter
recovery, with the convergence and reliability-calibration caveats described
below.

## Model and sample

The revised model separates the experienced-action learning rate (eta;
`alpha1`) from the unchosen-value forgetting rate (phi; `forget`). It also
estimates model-based choice sensitivity (beta-MB), model-free choice
sensitivity (beta-MF), second-stage inverse temperature (beta-2), and signed
first-stage choice stickiness (beta-c). The joint analysis included 141
participants and 53,372 trials (27,431 in Session 1; 25,941 in Session 2).

The joint fit used four chains with 5,000 warmup and 10,000 retained iterations
per chain (`adapt_delta` = .95, maximum tree depth = 12). There were no
divergences or maximum-tree-depth hits. E-BFMI ranged from .689 to .698. R-hat
was at most 1.001 for all participant-by-session estimates; one variance
hyperparameter had R-hat = 1.011. Both independent-session fits had maximum
R-hat = 1.001 and no divergences.

## Reliability

Intervals for Spearman correlations are participant-bootstrap percentile
intervals (10,000 resamples). The manuscript's model-derived ICC(C,1) was
calculated across participant- and session-specific posterior mean parameter
estimates from the joint model, with participant-bootstrap confidence
intervals. The posterior latent correlation from the joint variance components
is retained below as a separate sensitivity estimate.

| Parameter | Spearman rho [95% CI] | Model-derived ICC(C,1) [95% bootstrap CI] | Posterior latent correlation [95% CrI] |
|---|---:|---:|---:|
| beta-MB | .973 [.955, .982] | .935 [.904, .960] | .907 [.766, .984] |
| eta | .878 [.816, .919] | .895 [.853, .929] | .858 [.775, .913] |
| beta-2 | .827 [.745, .887] | .879 [.803, .914] | .763 [.612, .869] |
| beta-MF | .741 [.645, .813] | .649 [.503, .772] | .620 [.407, .785] |
| beta-c | .729 [.632, .802] | .746 [.647, .820] | .661 [.512, .775] |
| phi | .657 [.532, .761] | .745 [.636, .823] | .631 [.435, .782] |

All Spearman correlations were different from zero (all p < 1e-18). The
point-estimate age-interaction screen (`session 2 ~ session 1 * standardized
age`) found no reliable moderation: eta, p = .994; phi, p = .134; beta-MB,
p = .100; beta-MF, p = .954; beta-2, p = .562; and beta-c, p = .757.

Attenuation-corrected cross-session correlations from the independent-session
hierarchical fits were .98 (95% credible interval [.88, >.99]) for beta-MB,
.89 ([.56, >.99]) for beta-MF, .76 ([.66, .83]) for eta, .71 ([.50, .87])
for phi, .74 ([.61, .84]) for beta-c, and .82 ([.55, .98]) for beta-2. All
six errors-in-variables fits had R-hat <= 1.003, no divergences, and no
maximum-tree-depth hits.

In the age-moderated errors-in-variables model, every 95% credible interval for
the age effect on reliability included zero: beta-MB, -.29 [-1.41, 1.07];
beta-MF, -.16 [-1.34, 1.02]; eta, -.11 [-.33, .12]; phi, .21 [-.27, .94];
beta-c, .05 [-.26, .35]; and beta-2, -.09 [-1.28, 1.01]. The learning rate
showed an independent positive age-related shift in its Session 1 latent mean
(.07 [.02, .12]) but not Session 2 (.04 [-.00, .09]).

## Descriptive age-parameter relationships

Participant-level posterior means were available with age for 130 participants
(10–25 years). Learning rate increased modestly with age in both sessions
(Session 1: Spearman rho = .25, p = .004; Session 2: rho = .20, p = .024).
After false-discovery-rate correction across all 12 session-specific tests, the
Session 1 association remained below .05 (q = .044), whereas the Session 2
association did not (q = .142). The other five parameters showed no clear
rank-order association with age in either session (all absolute rho <= .13,
all uncorrected p >= .15). These are descriptive associations between age and
parameter levels; they are distinct from tests of whether age moderates
cross-session reliability and do not replace the prespecified latent age model.

The same descriptive analysis in the original linked-forgetting model gave a
similar pattern. The age correlation for eta was .22 (p = .012) in Session 1
and .16 (p = .067) in Session 2, compared with .25 (p = .004) and .20
(p = .024), respectively, in the free-forgetting model. Paired bootstrap
intervals for the changes in eta included zero in both sessions (Session 1:
delta rho = +.03, 95% CI [-.04, .11]; Session 2: +.04 [-.02, .10]). None of
the ten paired old-versus-new changes survived false-discovery-rate correction.
Thus, separating forgetting from learning preserves—and modestly strengthens—
the descriptive age association with learning rate without introducing a clear
age association for the new forgetting parameter (Session 1: rho = -.04,
p = .617; Session 2: rho = .01, p = .892).

These parameter-level results should not be conflated with the significant
age effect on the behavioral model-based signature. In the trial-level stay
GLMM, the reward-by-transition interaction strengthened with age
(reward x transition x age: chi-square = 6.67, p = .010 in the canonical raw
pipeline; p = .014 in the harmonized report). A subject-level reward-by-
transition contrast gave the same direction (Spearman rho = .198, p = .018).
This behavioral effect is calculated directly from observed choices and is
therefore unchanged by whether the computational model links or freely
estimates forgetting. Within the smaller test-retest cohort, the descriptive
correlation between age and the computational beta-MB posterior mean was not
significant in either model. This reflects reduced precision rather than a
contradictory effect direction: the original Session-1 TRT association
(Pearson r = .142, N = 130) is nearly identical in magnitude to the significant
original-model association in the earlier full cross-sectional EM/Laplace
analysis (r = .145, N = 933, p = 8.6e-06). The updated free-forgetting TRT estimate was
also positive (Session 1: r = .160, p = .069; Session 2: r = .151, p = .086).

Matched EM/Laplace refits to the refreshed full baseline sample (N = 933)
confirmed this effect: beta-MB correlated positively with age in both the
linked-forgetting model (r = .163, p = 5.6e-07) and the free-forgetting model
(r = .167, p = 3.1e-07). The paired change was negligible (delta r = +.004,
95% bootstrap CI [-.018, .025]). The exact discovery cohort (N = 448) showed
the same pattern: r = .120 (p = .011) in the linked model and r = .130
(p = .0057) in the free model, with no reliable model-related change
(delta r = +.010, 95% bootstrap CI [-.021, .040]). Thus, freeing forgetting
does not explain away the positive age association with model-based control.
These EM/Laplace analyses concern cross-sectional parameter levels; the
updated latent parameter-age and age-moderation-of-reliability models remain
separate analyses.

## Model comparison

The free-forgetting and original models were fitted independently to identical
participants and observations in each session. WAIC favored the revised model
by 955.2 points in Session 1 (50,665.2 vs. 51,620.3) and 806.4 points in Session
2 (46,185.4 vs. 46,991.8). WAIC already penalizes the added parameter. The
trialwise PSIS-LOO estimates gave the same ordering, but approximately 2% of
observations had Pareto k > .7 and the maximum was infinite, so LOOIC should not
be the primary reported comparison.

As a complementary check in the baseline cross-sectional sample, matched
EM/Laplace fits also strongly favored the free-forgetting model. Integrated AIC
was 166,747.4 for the free model versus 169,327.2 for the linked model in the
full sample (N = 933; delta iAIC = -2,579.8), and 80,045.6 versus 81,339.0 in
the discovery cohort (N = 448; delta iAIC = -1,293.4). Each comparison used
identical participants and trials and the best of three optimization starts.

## Posterior predictive check

Participant-level observed-versus-predicted stay probabilities were strongly
aligned in both sessions: Session 1, rho = .951 and RMSE = .039; Session 2,
rho = .937 and RMSE = .040.

Most importantly, the revised model produced the previously missing
common-versus-rare separation after an unrewarded trial. The observed
rare-minus-common difference was .089 in Session 1 and .100 in Session 2; the
model predicted .045 and .040, respectively. Thus, the direction and a clear
portion of the effect are recovered, although its magnitude remains
underestimated. Following reward, the observed common-minus-rare differences
were .077 and .069, compared with predicted differences of .091 and .082.

## Production parameter and reliability recovery

The production recovery simulated 500 participants (four independent batches
of 125), with 200 trials per session, from one audited posterior draw of the
fitted six-parameter model. The same model was then refitted using one chain
per batch with 2,000 warmup and 2,000 retained iterations. All four batches had
zero divergences and zero maximum-tree-depth hits, and E-BFMI was satisfactory.
Maximum split R-hat by batch was 1.024, 1.093, 1.062, and 1.022; the elevated
values in Batches 2 and 3 affected subsets of latent and hyperparameters, so
the recovery magnitudes should be interpreted with this convergence caveat.

Participant-session parameter estimates were recovered well. True-versus-
recovered Spearman correlations in Sessions 1 and 2 were respectively .964
and .951 for eta, .847 and .885 for phi, .760 and .769 for beta-MB, .761 and
.763 for beta-MF, .837 and .859 for beta-2, and .908 and .935 for beta-c.
Across the 12 parameter-by-session estimates, 95% interval coverage ranged
from 89.6% to 97.2%, and mean bias was small relative to each parameter's
scale. To match the parameter-recovery figures for the other two tasks,
Supplementary Figure S3 pools the two sessions and reports Pearson
correlations: beta-MB = .84, beta-MF = .85, eta = .96, phi = .86, beta-c =
.93, and beta-2 = .87 (1,000 participant-session observations per panel).

Recovery of cross-session reliability was directionally informative but not
perfectly calibrated. Generating-to-recovered Spearman correlations were .963
to .990 for beta-MB, .847 to .893 for eta, .693 to .829 for beta-2, .635 to
.727 for beta-c, .598 to .730 for phi, and .555 to .742 for beta-MF. Thus,
the recovered reliability values were systematically higher than the
generating values, with the largest discrepancy for beta-MF (+.186). The
empirical test-retest correlations should therefore be interpreted as
potentially upward biased, especially for beta-MF, rather than as perfectly
calibrated recovery targets.

## Manuscript-ready reliability paragraph

In the model-based/model-free task, all six parameters showed significant
cross-session rank-order correspondence. Spearman's rho was .97 (95% CI [.95,
.98]) for beta-MB, .88 ([.82, .92]) for eta, .83 ([.75, .89]) for beta-2, .74
([.65, .81]) for beta-MF, .73 ([.63, .80]) for beta-c, and .66 ([.53, .76])
for phi. Model-derived ICC(C,1)s were .93 (95% CI [.90, .96]) for beta-MB,
.89 ([.85, .93]) for eta, .88 ([.80, .91]) for beta-2, .75 ([.65, .82]) for
beta-c, .74 ([.64, .82]) for phi, and .65 ([.50, .77]) for beta-MF.

## Remaining manuscript work

The latent age-moderation and latent-mean models are complete for all six
parameters. Remaining work is limited to replacing the manuscript's numbers,
captions, and figure files with the validated outputs listed below.

## Primary source files

- Joint fit summary: `data/parameter_estimates/twostep/twostep_freeforget_samp10k_completecase_freeforget_localbackup_20260919_summary_20260920_123825.tsv`
- Joint fit draws: `data/parameter_estimates/twostep/twostep_freeforget_samp10k_completecase_freeforget_localbackup_20260919_draws_20260920_123825.tsv.gz`
- Reliability table: `data/parameter_estimates/twostep/twostep_freeforget_samp10k_completecase_reliability_posterior_icc_20260922.csv`
- Age screen: `data/parameter_estimates/twostep/twostep_freeforget_samp10k_completecase_age_moderation.csv`
- PPC metrics: `outputs/figures/supp_figure_s6_twostep_freeforget_completecase_ppc_full_n141_20260920_metrics.csv`
- PPC group-condition values: `outputs/figures/supp_figure_s6_twostep_freeforget_completecase_ppc_full_n141_20260920_group_conditions.csv`
- PPC figure: `outputs/figures/supp_figure_s6_twostep_freeforget_completecase_ppc_full_n141_20260920.png`
- Main paired TRT reliability figure: `outputs/figures/twostep_freeforget_trt_icc_vs_attenuation_manuscript_20260922.png`
- Overall TRT reliability figure: `outputs/figures/twostep_freeforget_samp10k_trt_reliability_overall_20260922.png`
- Age-stratified descriptive TRT figure: `outputs/figures/twostep_freeforget_samp10k_trt_reliability_by_age_20260921.png`
- Descriptive parameter-age figure: `outputs/figures/twostep_freeforget_parameter_age_relations_20260922.png`
- Parameter-age metrics: `outputs/figures/twostep_freeforget_parameter_age_relations_20260922_metrics.csv`
- Parameter-age caption: `outputs/figures/twostep_freeforget_parameter_age_relations_20260922_caption.md`
- Old-versus-new parameter-age comparison: `outputs/figures/twostep_old_vs_freeforget_age_relations_20260922.png`
- Old-versus-new parameter-age metrics: `outputs/figures/twostep_old_vs_freeforget_age_relations_20260922_metrics.csv`
- Old-versus-new parameter-age caption: `outputs/figures/twostep_old_vs_freeforget_age_relations_20260922_caption.md`
- Paired TRT figure caption: `outputs/figures/twostep_freeforget_trt_icc_vs_attenuation_manuscript_20260922_caption.md`
- Overall TRT figure caption: `outputs/figures/twostep_freeforget_samp10k_trt_reliability_caption_20260922.md`
- Attenuation-corrected summary: `../within_session_reliability/risk_betabinom/outputs/attenuation_twostep_freeforget_samp10k_completecase_freeforget_20260921_summary.csv`
- Old-versus-new comparison: `analysis/manuscript/TWOSTEP_OLD_NEW_COMPARISON_AND_FORGETTING_RATIONALE_20260921.md`
- Production recovery directory: `analysis/recovery/twostep_freeforget_completecase_recovery_20260921/`
- Merged recovery summary: `analysis/recovery/twostep_freeforget_completecase_recovery_20260921/twostep_freeforget_completecase_recovery_joint500_freeforget_20260921_merged_20260922_023337_summary.csv`
- Merged reliability recovery: `analysis/recovery/twostep_freeforget_completecase_recovery_20260921/twostep_freeforget_completecase_recovery_joint500_freeforget_20260921_merged_20260922_023337_reliability.csv`
- Recovery figure: `outputs/figures/twostep_freeforget_production_recovery_n500_20260922.png`
- Recovery figure caption: `outputs/figures/twostep_freeforget_production_recovery_n500_20260922_caption.md`
- Matched Supplementary Figure S3: `outputs/figures/param_recovery_twostep_freeforget_posterior_scatter_grid_sh_20260922.png`
- Supplementary Figure S3 source values: `outputs/figures/param_recovery_twostep_freeforget_posterior_scatter_grid_sh_20260922_metrics.csv`
- Supplementary Figure S3 caption: `outputs/figures/param_recovery_twostep_freeforget_posterior_scatter_grid_sh_20260922_caption.md`
