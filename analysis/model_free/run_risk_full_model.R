## run_risk_full_model.R
##
## Single full mixed-effects model for the risk task with maximal random effects.
##
## Fixed effects: z_age * probability * session * z_exposure
## Random effects: maximal structure justified by within-subject design, with
##   fallback to simpler structures if convergence fails.
##
## Within-subject factors (all warrant random slopes):
##   probability  – each participant sees all 3 levels
##   session      – each participant has both sessions
##   z_exposure   – each participant has all exposure bins
##
## Strategy: try models in order of complexity, report which one converged.
##
## Output written to: analysis/model_free/risk_full_model_results.txt

library(tidyverse)
library(afex)
library(emmeans)
library(lme4)

REPO_ROOT <- rprojroot::find_root(rprojroot::is_git_root)
source(file.path(REPO_ROOT, "config.R"))

out_file <- file.path(REPO_ROOT, "analysis", "model_free", "risk_full_model_results.txt")
sink(out_file, split = TRUE)

cat("=============================================================\n")
cat(" RISK TASK – Full model with maximal random effects\n")
cat(" Fixed: z_age * probability * session * z_exposure\n")
cat("=============================================================\n\n")

# ------------------------------------------------------------------
# 1. Load & clean data
# ------------------------------------------------------------------
s1 <- read.csv(RISK_BEHAVIORAL_S1) %>% mutate(session = "session_1")
s2 <- read.csv(RISK_BEHAVIORAL_S2) %>% mutate(session = "session_2")
risk_data <- bind_rows(s1, s2)

both <- intersect(unique(s1$subject), unique(s2$subject))
risk_data <- risk_data %>% filter(subject %in% both)

cat(sprintf("N participants (both sessions): %d\n", length(both)))
cat(sprintf("Total rows (trial level):       %d\n\n", nrow(risk_data)))

# ------------------------------------------------------------------
# 2. Prepare variables
# ------------------------------------------------------------------
risk_test <- risk_data %>%
  filter(!is.na(exposure), !is.na(choice), !is.na(probability)) %>%
  mutate(
    participantId = as.character(subject),
    choice        = as.numeric(choice),
    probability   = factor(probability, levels = c(0.2, 0.5, 0.8),
                           labels = c("0.2", "0.5", "0.8")),
    session       = factor(session, levels = c("session_1", "session_2")),
    z_age         = as.numeric(scale(age)),
    z_exposure    = as.numeric(scale(as.numeric(exposure))),
    age_group     = factor(
      case_when(
        age >= 10 & age < 15 ~ "10-15",
        age >= 15 & age < 20 ~ "15-20",
        age >= 20 & age <= 25 ~ "20-25"
      ),
      levels = c("10-15", "15-20", "20-25")
    )
  )

# ------------------------------------------------------------------
# 3. Aggregate to exposure-level means per participant
# ------------------------------------------------------------------
exp_data <- risk_test %>%
  group_by(participantId, z_age, probability, session, z_exposure) %>%
  summarise(mean_choice = mean(choice, na.rm = TRUE), .groups = "drop")

cat(sprintf("Aggregated exposure-level rows: %d\n\n", nrow(exp_data)))

# ------------------------------------------------------------------
# 4. Fit models – maximal to minimal, stop at first convergence
# ------------------------------------------------------------------
# All random slopes are justified: every participant experiences all levels
# of probability, session, and z_exposure (fully within-subject design).
#
# Model hierarchy (most to least complex):
#   M1: (probability * session * z_exposure | participantId)   <- maximal
#   M2: (probability * z_exposure + session | participantId)   <- drop 3-way RE interaction
#   M3: (probability + session + z_exposure | participantId)   <- main-effects only
#   M4: (probability + z_exposure | participantId)             <- drop session slope
#   M5: (1 | participantId)                                    <- intercept only (minimal)

fixed_fx <- mean_choice ~ z_age * probability * session * z_exposure

random_structures <- list(
  M1 = "(probability * session * z_exposure | participantId)",
  M2 = "(probability * z_exposure + session | participantId)",
  M3 = "(probability + session + z_exposure | participantId)",
  M4 = "(probability + z_exposure | participantId)",
  M5 = "(1 | participantId)"
)

ctrl <- lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 2e6))

fit_model <- function(re_str) {
  formula_str <- paste("mean_choice ~ z_age * probability * session * z_exposure +", re_str)
  cat(sprintf("\nTrying: %s\n", re_str))
  tryCatch({
    m <- mixed(
      as.formula(formula_str),
      data    = exp_data,
      method  = "S",
      control = ctrl,
      check_contrasts = FALSE
    )
    # Check for convergence warnings
    warns <- m$full_model@optinfo$conv$lme4$messages
    if (!is.null(warns) && length(warns) > 0) {
      cat("  --> Convergence warning:", warns[[1]], "\n")
      return(NULL)
    }
    cat("  --> Converged OK\n")
    return(m)
  }, error = function(e) {
    cat("  --> Error:", conditionMessage(e), "\n")
    return(NULL)
  })
}

final_model <- NULL
final_re    <- NULL

for (nm in names(random_structures)) {
  result <- fit_model(random_structures[[nm]])
  if (!is.null(result)) {
    final_model <- result
    final_re    <- random_structures[[nm]]
    break
  }
}

if (is.null(final_model)) {
  cat("\nERROR: No model converged. Check data.\n")
  sink()
  stop("No model converged.")
}

cat(sprintf("\n\n=== FINAL MODEL: random effects = %s ===\n\n", final_re))

# ------------------------------------------------------------------
# 5. ANOVA table
# ------------------------------------------------------------------
cat("--- ANOVA table (Type III, Satterthwaite df) ---\n")
print(nice(final_model))

# ------------------------------------------------------------------
# 6. Marginal means: probability × session
# ------------------------------------------------------------------
cat("\n--- Marginal means: probability × session ---\n")
emm_ps <- emmeans(final_model$full_model,
                  ~ probability * session,
                  pbkrtest.limit = 2e5,
                  lmerTest.limit = 2e5)
print(summary(emm_ps))

# ------------------------------------------------------------------
# 7. Post-hoc: session contrast within each probability
# ------------------------------------------------------------------
cat("\n--- Post-hoc: session contrast within each probability ---\n")
print(pairs(emm_ps, by = "probability", adjust = "none"))

# ------------------------------------------------------------------
# 8. SDs of individual mean choices per probability × session
# ------------------------------------------------------------------
cat("\n--- SD of individual mean choices (probability × session) ---\n")
ind_means <- risk_test %>%
  group_by(participantId, probability, session) %>%
  summarise(m = mean(choice, na.rm = TRUE), .groups = "drop")

sd_table <- ind_means %>%
  group_by(probability, session) %>%
  summarise(M = round(mean(m), 3), SD = round(sd(m), 3), .groups = "drop")
print(sd_table)

# ------------------------------------------------------------------
# 9. Follow-up: age × session interaction by age group
#    (interpretability: 10-15, 15-20, 20-25)
# ------------------------------------------------------------------
cat("\n--- Follow-up: session effect within each age group ---\n")
cat("(marginal over probability and exposure)\n\n")

# Ns per age group
cat("N participants per age group:\n")
ag_n <- risk_test %>%
  distinct(participantId, age_group) %>%
  count(age_group)
print(ag_n)
cat("\n")

# emmeans at the three age group values
# We pass the age_group levels as `at` values mapped back to z_age
# by computing the mean z_age within each group
age_group_means <- risk_test %>%
  distinct(participantId, z_age, age_group) %>%
  group_by(age_group) %>%
  summarise(mean_z_age = mean(z_age), .groups = "drop")

cat("Mean z_age per group:\n")
print(age_group_means)
cat("\n")

emm_age_session <- emmeans(
  final_model$full_model,
  ~ session | z_age,
  at      = list(z_age = age_group_means$mean_z_age),
  pbkrtest.limit = 2e5,
  lmerTest.limit = 2e5
)

# Rename z_age levels to age group labels for readability
emm_age_session_summ <- summary(emm_age_session)
emm_age_session_summ$age_group <- age_group_means$age_group[
  match(round(emm_age_session_summ$z_age, 4),
        round(age_group_means$mean_z_age, 4))
]
cat("Marginal means for session × age group:\n")
print(emm_age_session_summ)

cat("\nSession contrasts within each age group:\n")
pairs_age_session <- pairs(emm_age_session, by = "z_age", adjust = "none")
pairs_summ <- summary(pairs_age_session)
pairs_summ$age_group <- age_group_means$age_group[
  match(round(pairs_summ$z_age, 4),
        round(age_group_means$mean_z_age, 4))
]
print(pairs_summ)

# ------------------------------------------------------------------
# 10. Random effects variance summary
# ------------------------------------------------------------------
cat("\n--- Random effects variance components ---\n")
print(VarCorr(final_model$full_model))

sink()
cat("\nDone. Results saved to:\n", out_file, "\n")
