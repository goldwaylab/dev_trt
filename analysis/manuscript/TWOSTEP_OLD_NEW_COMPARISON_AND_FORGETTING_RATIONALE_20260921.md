# Two-step model revision: old-versus-new comparison and forgetting rationale

## Scope of the comparison

This comparison uses the corrected original fixed-lambda model and the final
six-parameter free-forgetting model. Both were fitted to the same 141
participants and the same 53,372 valid trials (27,431 in Session 1 and 25,941
in Session 2). Earlier two-step results based on 54,141 trials are excluded
because missing choices or transitions were incorrectly converted into
observed values during preprocessing.

The name “fixed-lambda model” refers to the eligibility trace, which was fixed
at lambda = 1 in both models. The revised parameter is not lambda. The change
was to separate unchosen-value forgetting from the experienced-action learning
rate.

## Model structure

| Feature | Corrected original model | Free-forgetting model |
|---|---|---|
| Number of parameters | 5 | 6 |
| Experienced-action learning | Learning rate eta | Learning rate eta |
| Unchosen-value decay | Fixed to the same value as eta | Separately estimated forgetting rate phi |
| Eligibility trace | Fixed at lambda = 1 | Fixed at lambda = 1 |
| Other parameters | beta-MB, beta-MF, beta-2, beta-c | beta-MB, beta-MF, beta-2, beta-c |
| Main implication | Learning and forgetting cannot vary independently | Learning from outcomes and forgetting of unchosen values can vary independently |

## Fit and posterior predictive performance

Lower WAIC and RMSE are better; higher Spearman rho is better. Delta WAIC is
the new model minus the old model, so negative values favor the new model.

| Metric | Session 1: old | Session 1: new | Session 2: old | Session 2: new |
|---|---:|---:|---:|---:|
| WAIC | 51,620.3 | 50,665.2 | 46,991.8 | 46,185.4 |
| Delta WAIC | — | -955.2 | — | -806.4 |
| Participant-level PPC Spearman rho | .931 | .951 | .912 | .937 |
| Participant-level PPC RMSE | .045 | .039 | .047 | .040 |
| Observed no-reward rare-minus-common stay contrast | .089 | .089 | .100 | .100 |
| Predicted no-reward rare-minus-common stay contrast | .009 | .045 | .005 | .040 |
| Proportion of observed no-reward contrast reproduced | 10% | 51% | 5% | 40% |

The new model therefore improves overall predictive correspondence and
recovers a clear portion of the transition effect after no reward. It does not
fully reproduce the magnitude of this effect, particularly in Session 2.

## Test-retest comparison

All estimates below use N = 141. Spearman intervals are participant-bootstrap
95% intervals. Model-derived ICCs were calculated within each joint posterior
draw from the common and session-divergent variance components; their intervals
are 95% posterior credible intervals.
Attenuation-corrected estimates come from the independently fitted session
models and a Bayesian errors-in-variables analysis.

| Parameter | Spearman rho: old | Spearman rho: new | Model-derived ICC: old | Model-derived ICC: new | Attenuation-corrected rho: old | Attenuation-corrected rho: new |
|---|---:|---:|---:|---:|---:|---:|
| beta-MB | .977 [.964, .983] | .973 [.955, .982] | .910 [.718, .993] | .907 [.766, .984] | .950 [.706, .998] | .976 [.876, .999] |
| beta-MF | .717 [.614, .796] | .741 [.645, .813] | .620 [.411, .785] | .620 [.407, .785] | .908 [.634, .996] | .892 [.557, .996] |
| eta | .836 [.761, .889] | .878 [.816, .919] | .815 [.721, .880] | .858 [.775, .913] | .743 [.634, .824] | .763 [.663, .835] |
| phi | — | .657 [.532, .761] | — | .631 [.435, .782] | — | .714 [.495, .875] |
| beta-c | .731 [.642, .799] | .729 [.632, .802] | .628 [.470, .753] | .661 [.512, .775] | .740 [.593, .850] | .742 [.607, .843] |
| beta-2 | .673 [.557, .765] | .827 [.745, .887] | .633 [.488, .745] | .763 [.612, .869] | .633 [.425, .786] | .821 [.550, .981] |

The revision does not materially alter the reliability conclusion for
beta-MB, beta-MF, eta, or beta-c. The largest improvement is for beta-2. The
new forgetting parameter itself has moderate cross-session rank stability and
model-derived reliability.

## How the posterior predictive failure identified the coupling problem

The observed data showed a reliable rare-versus-common separation after
unrewarded trials. The corrected original model predicted almost no separation
in that condition: .009 versus an observed .089 in Session 1, and .005 versus
an observed .100 in Session 2. This was not a plotting error; replaying the
model's exact trialwise update produced the same result.

Inspection of the original update equations exposed a structural constraint.
The learning rate eta updated the selected first- and second-stage values, but
the same eta also decayed every unchosen or unvisited value. When reward was
zero, the selected values were multiplied by 1 - eta. Because unchosen values
were also multiplied by 1 - eta, all relevant action values were scaled by the
same factor. A zero-outcome trial could shrink existing value differences but
could not generate the new relative-value contrast needed to express a strong
common-versus-rare effect on the next first-stage choice.

This explanation was tested rather than inferred from the PPC alone. Four
candidate models were fitted to the same data: the original model, free
forgetting, a one-trial model-based recency term, and both extensions together.
Separating forgetting from learning improved hierarchical-EM iAIC by 426
points in Session 1 and 340 points in Session 2 and restored a visible
no-reward transition contrast. Adding the recency term on top of free
forgetting improved iAIC by only 1.6 points in Session 1 and 29.6 points in
Session 2. A matched 20-participant Stan pilot and the final N = 141 fits then
replicated the fit and PPC improvement. This converging algebraic, predictive,
and model-comparison evidence motivated selection of the parsimonious
free-forgetting model.

## Definition and implementation of the forgetting parameter

Let eta be the experienced-action learning rate and phi the unchosen-value
forgetting rate. Both are participant- and session-specific parameters bounded
between 0 and 1.

For the selected second-stage action, the ordinary outcome update is

`Q2(s_t, a2_t) <- Q2(s_t, a2_t) + eta * [r_t - Q2(s_t, a2_t)]`.

The selected first-stage model-free value is updated through the second-stage
prediction error with eligibility trace lambda fixed at 1. Under lambda = 1,
the implemented equation simplifies to

`QMF(a1_t) <- QMF(a1_t) + eta * [r_t - QMF(a1_t)]`.

The new parameter is applied only to values that were not selected or visited
on that trial:

`Q <- (1 - phi) * Q`.

Specifically, this decay is applied to:

1. the unchosen first-stage action;
2. the unchosen action in the visited second-stage state; and
3. both actions in the unvisited second-stage state.

Thus, phi = 0 means no forgetting, whereas phi = 1 resets every unchosen or
unvisited value to zero after each trial. The decay reference point is zero.
Selected values are updated using eta and are not additionally decayed by phi.

In the hierarchical Stan model, eta and phi are each represented by separate
group means, stable participant components, and session-divergent participant
components. Their unconstrained latent values are transformed with the normal
CDF, `Phi(.)`, to place both parameters in the unit interval. The group-level
latent means have Normal(0, 1.5) priors, and the common and divergent scale
parameters have half-Normal(0, 0.5) priors. The model-based value computation,
model-free value computation, choice stickiness, second-stage softmax, and
lambda = 1 eligibility trace are otherwise unchanged.

## Current boundary on interpretation

The final full-sample joint fit, independent-session fits, posterior predictive
checks, WAIC comparison, Spearman correlations, model-derived ICCs, and
attenuation-corrected correlations are complete. Production parameter recovery
for the six-parameter model is not yet available locally; the eight-participant
smoke run demonstrates that the pipeline executes but is not a reportable
recovery result. The latent age-moderation analysis also remains to be updated
before replacing all age-related manuscript claims.
