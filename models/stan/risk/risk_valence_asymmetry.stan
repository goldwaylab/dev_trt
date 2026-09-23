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
    matrix[6,2] theta_mu;
    matrix[6,NJ] theta_c_pr;
    matrix[6,NJ] theta_d_pr;
    matrix<lower=0>[6,2] sigma;
}
transformed parameters {
    array[2] vector[NJ] b1;
    array[2] vector[NJ] a1;
    array[2] vector[NJ] a2;
    array[2] vector[NJ] a3;
    array[2] vector[NJ] a4;
    array[2] vector[NJ] q0;
    {
        matrix[NJ,6] theta_c = transpose(diag_pre_multiply(sigma[,1], theta_c_pr));
        matrix[NJ,6] theta_d = transpose(diag_pre_multiply(sigma[,2], theta_d_pr));
        b1[1] = (theta_mu[1,1] + theta_c[,1] - theta_d[,1]) * 10;
        b1[2] = (theta_mu[1,2] + theta_c[,1] + theta_d[,1]) * 10;
        a1[1] = Phi_approx(theta_mu[2,1] + theta_c[,2] - theta_d[,2]);
        a1[2] = Phi_approx(theta_mu[2,2] + theta_c[,2] + theta_d[,2]);
        a2[1] = Phi_approx(theta_mu[3,1] + theta_c[,3] - theta_d[,3]);
        a2[2] = Phi_approx(theta_mu[3,2] + theta_c[,3] + theta_d[,3]);
        a3[1] = Phi_approx(theta_mu[4,1] + theta_c[,4] - theta_d[,4]);
        a3[2] = Phi_approx(theta_mu[4,2] + theta_c[,4] + theta_d[,4]);
        a4[1] = Phi_approx(theta_mu[5,1] + theta_c[,5] - theta_d[,5]);
        a4[2] = Phi_approx(theta_mu[5,2] + theta_c[,5] + theta_d[,5]);
        q0[1] = Phi_approx(theta_mu[6,1] + theta_c[,6] - theta_d[,6]);
        q0[2] = Phi_approx(theta_mu[6,2] + theta_c[,6] + theta_d[,6]);
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
        mu[n] = b1[M[n],J[n]] * (Q[J[n],K[n],M[n]] - 0.5);
        delta = R[n] - Q[J[n],K[n],M[n]];
        if (delta > 0) {
            eta = (Y[n] == 1) ? a1[M[n],J[n]] : a3[M[n],J[n]];
        } else if (delta < 0) {
            eta = (Y[n] == 1) ? a2[M[n],J[n]] : a4[M[n],J[n]];
        } else {
            eta = 0;
        }
        Q[J[n],K[n],M[n]] += eta * delta;
    }
    target += bernoulli_logit_lpmf(Y | mu);
    target += normal_lpdf(to_vector(theta_mu) | 0, 2);
    target += std_normal_lpdf(to_vector(theta_c_pr));
    target += std_normal_lpdf(to_vector(theta_d_pr));
    target += student_t_lpdf(to_vector(sigma) | 3, 0, 1);
}
