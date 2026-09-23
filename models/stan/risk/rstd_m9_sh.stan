data {
    int<lower=1> N;
    array[N] int<lower=1> J;
    array[N] int<lower=1> K;
    array[N] int<lower=1, upper=2> M;
    array[N] int<lower=0, upper=1> Y;
    array[N] int<lower=0, upper=1> R;
}
transformed data {
    int NJ = max(J);
    int NK = max(K);
}
parameters {
    matrix[4,2] theta_mu;
    matrix[4,NJ] theta_c_pr;
    matrix[4,NJ] theta_d_pr;
    matrix<lower=0>[4,2] sigma;
}
transformed parameters {
    array[2] vector[NJ] b1;
    array[2] vector[NJ] a_conf;
    array[2] vector[NJ] a_disc;
    array[2] vector[NJ] q0;
    {
        matrix[NJ,4] theta_c = transpose(diag_pre_multiply(sigma[,1], theta_c_pr));
        matrix[NJ,4] theta_d = transpose(diag_pre_multiply(sigma[,2], theta_d_pr));
        b1[1] = (theta_mu[1,1] + theta_c[,1] - theta_d[,1]) * 10;
        b1[2] = (theta_mu[1,2] + theta_c[,1] + theta_d[,1]) * 10;
        a_conf[1] = Phi_approx(theta_mu[2,1] + theta_c[,2] - theta_d[,2]);
        a_conf[2] = Phi_approx(theta_mu[2,2] + theta_c[,2] + theta_d[,2]);
        a_disc[1] = Phi_approx(theta_mu[3,1] + theta_c[,3] - theta_d[,3]);
        a_disc[2] = Phi_approx(theta_mu[3,2] + theta_c[,3] + theta_d[,3]);
        q0[1] = Phi_approx(theta_mu[4,1] + theta_c[,4] - theta_d[,4]);
        q0[2] = Phi_approx(theta_mu[4,2] + theta_c[,4] + theta_d[,4]);
    }
}
model {
    array[NJ,NK,2] real Q;
    Q[,,1] = to_array_2d(rep_matrix(q0[1], NK));
    Q[,,2] = to_array_2d(rep_matrix(q0[2], NK));
    vector[N] mu;
    for (n in 1:N) {
        real delta;
        real eta;
        int confirm;
        mu[n] = b1[M[n],J[n]] * (Q[J[n],K[n],M[n]] - 0.5);
        delta = R[n] - Q[J[n],K[n],M[n]];
        confirm = ((Y[n] == 1 && delta > 0) || (Y[n] == 0 && delta < 0));
        if (delta == 0) {
            eta = 0;
        } else {
            eta = confirm ? a_conf[M[n],J[n]] : a_disc[M[n],J[n]];
        }
        Q[J[n],K[n],M[n]] += eta * delta;
    }
    target += bernoulli_logit_lpmf(Y | mu);
    target += normal_lpdf(to_vector(theta_mu) | 0, 2);
    target += std_normal_lpdf(to_vector(theta_c_pr));
    target += std_normal_lpdf(to_vector(theta_d_pr));
    target += student_t_lpdf(to_vector(sigma) | 3, 0, 1);
}
