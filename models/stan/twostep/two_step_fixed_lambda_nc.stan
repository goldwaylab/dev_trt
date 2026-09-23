// ================================================================
// Two-Step RL TRT — same as trt_lambda1_mle_aligned_nc but LAMBDA FIXED AT 1
// Stage-1: beta1m*MB + beta1t*MF + betac*pc; TD update uses full eligibility (lambda=1).
// ================================================================

data {
  int<lower=1> N;
  int<lower=1> NS;
  int<lower=1> M;

  array[N] int<lower=1, upper=NS> subj;
  array[N] int<lower=1, upper=M> session;

  array[N] int<lower=0, upper=1> c1;
  array[N] int<lower=0, upper=1> c2;
  array[N] int<lower=1, upper=2> st;
  array[N] int<lower=0, upper=1> r;
}

parameters {
  row_vector[M] alpha1_mu;
  matrix[4, M] beta_mu;

  vector[NS] alpha1_c_pr;
  vector[NS] alpha1_d_pr;
  matrix[4, NS] beta_c_pr;
  matrix[4, NS] beta_d_pr;

  vector<lower=0>[M] sigma_alpha1_c;
  vector<lower=0>[M] sigma_alpha1_d;
  matrix<lower=0>[4, M] sigma_beta_c;
  matrix<lower=0>[4, M] sigma_beta_d;
}

transformed parameters {
  array[NS, M] real<lower=0, upper=1> alpha1;
  array[NS, M] real<lower=0> beta1m;
  array[NS, M] real<lower=0> beta1t;
  array[NS, M] real<lower=0> beta2;
  array[NS, M] real betac;

  for (s in 1:NS) {
    for (m in 1:M) {
      real alpha1_logit;
      if (m == 1) {
        alpha1_logit = alpha1_mu[1] +
                       sigma_alpha1_c[1] * alpha1_c_pr[s] -
                       sigma_alpha1_d[1] * alpha1_d_pr[s];
      } else {
        alpha1_logit = alpha1_mu[2] +
                       sigma_alpha1_c[2] * alpha1_c_pr[s] +
                       sigma_alpha1_d[2] * alpha1_d_pr[s];
      }
      // Phi (exact standard-normal CDF), not inv_logit, to match the
      // validated Julia EM reference (twostep_choice_em.jl: phi(p[1])).
      alpha1[s,m] = Phi(alpha1_logit);

      real beta1m_log;
      real beta1t_log;
      real beta2_log;
      real betac_log;

      if (m == 1) {
        beta1m_log = beta_mu[1,1] + sigma_beta_c[1,1] * beta_c_pr[1,s] - sigma_beta_d[1,1] * beta_d_pr[1,s];
        beta1t_log = beta_mu[2,1] + sigma_beta_c[2,1] * beta_c_pr[2,s] - sigma_beta_d[2,1] * beta_d_pr[2,s];
        beta2_log  = beta_mu[3,1] + sigma_beta_c[3,1] * beta_c_pr[3,s] - sigma_beta_d[3,1] * beta_d_pr[3,s];
        betac_log  = beta_mu[4,1] + sigma_beta_c[4,1] * beta_c_pr[4,s] - sigma_beta_d[4,1] * beta_d_pr[4,s];
      } else {
        beta1m_log = beta_mu[1,2] + sigma_beta_c[1,2] * beta_c_pr[1,s] + sigma_beta_d[1,2] * beta_d_pr[1,s];
        beta1t_log = beta_mu[2,2] + sigma_beta_c[2,2] * beta_c_pr[2,s] + sigma_beta_d[2,2] * beta_d_pr[2,s];
        beta2_log  = beta_mu[3,2] + sigma_beta_c[3,2] * beta_c_pr[3,s] + sigma_beta_d[3,2] * beta_d_pr[3,s];
        betac_log  = beta_mu[4,2] + sigma_beta_c[4,2] * beta_c_pr[4,s] + sigma_beta_d[4,2] * beta_d_pr[4,s];
      }

      beta1m[s,m] = exp(beta1m_log);
      beta1t[s,m] = exp(beta1t_log);
      beta2[s,m]  = exp(beta2_log);
      // Unconstrained, not exp() -- stickiness can be negative (switching);
      // the Julia reference never constrains it positive and this file
      // previously did, wrongly.
      betac[s,m]  = betac_log;
    }
  }
}

model {
  alpha1_mu ~ normal(0, 1.5);
  to_vector(beta_mu[1:3, 1:M]) ~ normal(1.1, 1.0);
  // betac is signed and linear, unlike the three positive log-scale betas.
  to_vector(beta_mu[4, 1:M]) ~ normal(0, 1.0);

  alpha1_c_pr ~ std_normal();
  alpha1_d_pr ~ std_normal();
  to_vector(beta_c_pr) ~ std_normal();
  to_vector(beta_d_pr) ~ std_normal();

  to_vector(sigma_alpha1_c) ~ normal(0, 0.5) T[0, ];
  to_vector(sigma_alpha1_d) ~ normal(0, 0.5) T[0, ];
  to_vector(sigma_beta_c) ~ normal(0, 0.3) T[0, ];
  to_vector(sigma_beta_d) ~ normal(0, 0.3) T[0, ];

  array[NS, M] int pc;
  array[NS, M, 2, 2] int tcounts;
  array[NS, M, 2] real qm;
  array[NS, M, 2] real qt1;
  array[NS, M, 2, 2] real qt2;

  for (s in 1:NS)
    for (m in 1:M) {
      pc[s,m] = 0;
      for (i in 1:2) {
        qm[s,m,i]  = 0;
        qt1[s,m,i] = 0;
        for (j in 1:2) {
          tcounts[s,m,i,j] = 0;
          qt2[s,m,i,j] = 0;
        }
      }
    }

  for (n in 1:N) {
    int s  = subj[n];
    int m  = session[n];
    int S2 = st[n];
    int A1 = c1[n];
    int A2 = c2[n];
    int Rw = r[n];
    int A1i = A1 + 1;
    int A2i = A2 + 1;
    int ns  = 3 - S2;

    int common = (tcounts[s,m,1,1] + tcounts[s,m,2,2]
                - tcounts[s,m,1,2] - tcounts[s,m,2,1]) > 0;

    qm[s,m,1] = common
                ? fmax(qt2[s,m,1,1], qt2[s,m,1,2])
                : fmax(qt2[s,m,2,1], qt2[s,m,2,2]);
    qm[s,m,2] = common
                ? fmax(qt2[s,m,2,1], qt2[s,m,2,2])
                : fmax(qt2[s,m,1,1], qt2[s,m,1,2]);

    target += bernoulli_logit_lpmf(A1 |
      beta1m[s,m] * (qm[s,m,2] - qm[s,m,1]) +
      beta1t[s,m] * (qt1[s,m,2] - qt1[s,m,1]) +
      betac[s,m]  * pc[s,m]
    );

    pc[s,m] = 2 * A1 - 1;
    tcounts[s,m,A1i, S2] += 1;

    target += bernoulli_logit_lpmf(A2 |
      beta2[s,m] * (qt2[s,m,S2,2] - qt2[s,m,S2,1])
    );

    real tdQ2 = Rw - qt2[s,m,S2, A2i];
    qt1[s,m,A1i] = qt1[s,m,A1i] * (1 - alpha1[s,m]) +
                   alpha1[s,m] * qt2[s,m,S2, A2i] +
                   1.0 * alpha1[s,m] * tdQ2;

    qt2[s,m,S2, A2i] = qt2[s,m,S2, A2i] * (1 - alpha1[s,m]) +
                      alpha1[s,m] * Rw;

    {
      int nc1 = 3 - A1i;
      int nc2 = 3 - A2i;
      qt1[s,m,nc1]       *= (1 - alpha1[s,m]);
      qt2[s,m,S2, nc2]   *= (1 - alpha1[s,m]);
      qt2[s,m,ns, 1]     *= (1 - alpha1[s,m]);
      qt2[s,m,ns, 2]     *= (1 - alpha1[s,m]);
    }
  }
}

generated quantities {
  array[NS, M] real alpha1_sess;
  array[NS, M] real beta1m_sess;
  array[NS, M] real beta1t_sess;
  array[NS, M] real beta2_sess;
  array[NS, M] real betac_sess;

  array[NS] real<lower=0, upper=1> alpha1_common;
  array[NS] real<lower=0> beta1m_common;
  array[NS] real<lower=0> beta1t_common;
  array[NS] real<lower=0> beta2_common;
  array[NS] real betac_common;

  array[NS] real alpha1_divergent;
  array[NS] real beta1m_divergent;
  array[NS] real beta1t_divergent;
  array[NS] real beta2_divergent;
  array[NS] real betac_divergent;

  for (s in 1:NS) {
    real alpha1_logit_common = (alpha1_mu[1] + alpha1_mu[2]) / 2.0 +
                                (sigma_alpha1_c[1] + sigma_alpha1_c[2]) / 2.0 * alpha1_c_pr[s];
    alpha1_common[s] = Phi(alpha1_logit_common);

    real beta1m_log_common = (beta_mu[1,1] + beta_mu[1,2]) / 2.0 +
                              (sigma_beta_c[1,1] + sigma_beta_c[1,2]) / 2.0 * beta_c_pr[1,s];
    beta1m_common[s] = exp(beta1m_log_common);

    real beta1t_log_common = (beta_mu[2,1] + beta_mu[2,2]) / 2.0 +
                              (sigma_beta_c[2,1] + sigma_beta_c[2,2]) / 2.0 * beta_c_pr[2,s];
    beta1t_common[s] = exp(beta1t_log_common);

    real beta2_log_common = (beta_mu[3,1] + beta_mu[3,2]) / 2.0 +
                             (sigma_beta_c[3,1] + sigma_beta_c[3,2]) / 2.0 * beta_c_pr[3,s];
    beta2_common[s] = exp(beta2_log_common);

    real betac_log_common = (beta_mu[4,1] + beta_mu[4,2]) / 2.0 +
                            (sigma_beta_c[4,1] + sigma_beta_c[4,2]) / 2.0 * beta_c_pr[4,s];
    betac_common[s] = betac_log_common;

    alpha1_divergent[s] = (alpha1_mu[2] - alpha1_mu[1]) +
                           (sigma_alpha1_d[1] + sigma_alpha1_d[2]) * alpha1_d_pr[s];
    beta1m_divergent[s] = (beta_mu[1,2] - beta_mu[1,1]) +
                          (sigma_beta_d[1,1] + sigma_beta_d[1,2]) * beta_d_pr[1,s];
    beta1t_divergent[s] = (beta_mu[2,2] - beta_mu[2,1]) +
                          (sigma_beta_d[2,1] + sigma_beta_d[2,2]) * beta_d_pr[2,s];
    beta2_divergent[s] = (beta_mu[3,2] - beta_mu[3,1]) +
                         (sigma_beta_d[3,1] + sigma_beta_d[3,2]) * beta_d_pr[3,s];
    betac_divergent[s] = (beta_mu[4,2] - beta_mu[4,1]) +
                         (sigma_beta_d[4,1] + sigma_beta_d[4,2]) * beta_d_pr[4,s];

    for (m in 1:M) {
      alpha1_sess[s,m] = alpha1[s,m];
      beta1m_sess[s,m] = beta1m[s,m];
      beta1t_sess[s,m] = beta1t[s,m];
      beta2_sess[s,m]  = beta2[s,m];
      betac_sess[s,m]  = betac[s,m];
    }
  }
}
