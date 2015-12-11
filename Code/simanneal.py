from time import process_time

import numpy as np
from scipy.stats import multivariate_normal as mnorm


def sa_gmm(data, init_mu, init_sigma, init_mix, temp_func,
           num_iter=100, seed=None, verbose=False):
    if len(init_mu) != len(init_sigma) or len(init_sigma) != len(init_mix):
        raise ValueError(
            'Number of initial values needs to be consistent.')
    if not np.isclose(sum(init_mix), 1):
        raise ValueError(
            'Initial mixing components should add to 1.')

    num_groups = len(init_mu)
    n = len(data)
    try:
        p = len(init_mu[0])
    except TypeError:
        p = 1
    if seed is not None:
        np.random.seed(seed)

    curr_mu = init_mu.copy()
    curr_sigma = init_sigma.copy()
    cand_mu = init_mu.copy()
    cand_sigma = init_sigma.copy()
    curr_mix = init_mix.copy()

    curr_classes = np.random.multinomial(1, curr_mix, size=n)
    curr_loglik = calc_loglik(
        data, calc_pdfs(data, curr_mu, curr_sigma), curr_classes)
    cand_classes = np.zeros((n, num_groups), dtype=int)

    best_mu = curr_mu
    best_sigma = curr_sigma
    best_classes = curr_classes
    best_mix = curr_mix
    best_loglik = curr_loglik

    logliks = np.zeros(num_iter+1)
    logliks[0] = curr_loglik
    time_iter = np.zeros(num_iter+1)

    for iternum in range(num_iter):
        if verbose:  # Status updates
            if np.isclose(iternum // 100, iternum / 100) and iternum != 0:
                print()
            if np.isclose(iternum // 10, iternum / 10) and iternum != 0:
                print('.', end='', flush=True)

        start = process_time()
        pdfs = calc_pdfs(data, curr_mu, curr_sigma)
        probs = _calc_probs(pdfs, curr_mix, 1.)

        for i, prob in enumerate(probs):
            cand_classes[i] = np.random.multinomial(1, prob)
        for k in range(num_groups):
            cand_mu[k] = np.mean(data[cand_classes[:,k] == 1], axis=0)
            cand_sigma[k] = np.cov(data[cand_classes[:,k] == 1], rowvar=0)
        cand_loglik = calc_loglik(
            data, calc_pdfs(data, cand_mu, cand_sigma), cand_classes)

        accept = np.random.uniform()
        log_accept_prob = (cand_loglik - curr_loglik)/temp_func(iternum)
        if cand_loglik >= curr_loglik or np.log(accept) < log_accept_prob:
            curr_classes = cand_classes
            curr_loglik = cand_loglik
            curr_mu = cand_mu
            curr_sigma = cand_sigma

            curr_mix = np.mean(curr_classes, axis=0)

        if curr_loglik > best_loglik:
            best_mu = curr_mu
            best_sigma = curr_sigma
            best_classes = curr_classes
            best_mix = curr_mix
            best_loglik = curr_loglik

        time_iter[iternum+1] += process_time() - start
        logliks[iternum+1] = best_loglik

    times = np.cumsum(time_iter)

    return (best_mu, best_sigma, best_mix, best_classes), (logliks, times)


def _calc_probs(pdfs, mix, b):
    weighted_pdfs = (mix*pdfs)**b
    tot_pdfs = np.sum(weighted_pdfs, axis=1)
    probs = weighted_pdfs / tot_pdfs[:,np.newaxis]
    return probs


def calc_pdfs(data, mus, sigmas):
    '''
    Calculates pdf of each observation for each group.

    Parameters
    ----------
    data : 2-d array
    mus : 2-d array
        Array of mean vectors.
    sigmas : list of 2-d arrays or 3-d array
        Covariance matrices.

    Returns
    -------
    pdfs : 2-d array
        pdfs[i, j] contains the pdf for the ith observation using the jth
        group.

    '''
    num_groups = len(mus)
    pdfs = np.zeros((len(data), num_groups))
    for k in range(num_groups):
        pdfs[:,k] = mnorm.pdf(data, mus[k], sigmas[k])
    return pdfs


def calc_loglik(data, pdfs, probs):
    '''
    Calculates the log likelihood of the data. If probs is an indicator, then
    the log likelihood of the data is
    ``log p(x) = sum_i sum_k probs_ik log p_k(x_i)''
    This motivates the weighted log-likelihood to use when probs contains
    probabilities which has the same formula.

    Parameters
    ----------
    data : 2-d array
    pdfs : 2-d array
        Array of pdfs of each observation for each group.
    probs : 2-d array
        Array of the probability that each observation is in each group.

    Returns
    -------
    loglik : float
        Log likelihood of the data.

    '''
    logpdfs = np.log(pdfs)
    loglik = np.sum(probs * logpdfs)
    return(loglik)


if __name__ == '__main__':
    import matplotlib.pyplot as plt
    from matplotlib import colors

    n = 2000
    np.random.seed(29643)

    # Simulate 3 groups
    num_groups = 3
    mu = np.array([[0., 2.], [2., 1.], [2., 3.]])
    sigma = np.array(
        [[[1.0,  0.1], [ 0.1, 0.3]],
         [[1.0, -0.1], [-0.1, 1.0]],
         [[0.5, -0.5], [-0.5, 1.0]]])
    mix = np.array([.15, .7, .15])

    xs = [mnorm.rvs(mu[k], sigma[k], size=n) for k in range(3)]
    z = np.random.multinomial(1, mix, size=n).astype('Bool')

    x = xs[0].copy()
    x[z[:,1]] = xs[1][z[:,1]]
    x[z[:,2]] = xs[2][z[:,2]]

    z_ind = np.zeros(n, dtype=int)
    z_ind[z[:,1]] = 1
    z_ind[z[:,2]] = 2

    # Plot data
    cmap, norm = colors.from_levels_and_colors(
        levels=[0, 1, 2], colors=['magenta', 'cyan', 'green'], extend='max')

    fig = plt.figure()
    ax = fig.add_subplot(1, 1, 1)
    ax.scatter(x[:,0], x[:,1], c=z_ind, cmap=cmap, norm=norm)
    fig.savefig('./sim_data.pdf')

    # Estimate
    init_mu = np.array([[0., 0.], [1., 1.], [2., 2.]])
    init_sigma = [np.identity(2) for i in range(3)]
    init_mix = np.array([1., 1., 1.])/3

    res_em, (logliks_em, times_em) = em_gmm(
        x, init_mu, init_sigma, init_mix, num_iter=250)

    res_da, (logliks_da, times_da) = em_gmm(
        x, init_mu, init_sigma, init_mix, num_iter=250,
        beta_func=lambda i: 1.-np.exp(-(i+1)/10))

    res_sa, (logliks_sa, times_sa) = sa_gmm(
        x, init_mu, init_sigma, init_mix, num_iter=250, seed=234254,
        temp_func=lambda i: max(1e-4, 100*.992**i))

    # Plotting
    data_mu = np.array(
        [np.mean(x[z_ind == k], axis=0) for k in range(num_groups)])
    data_sigma = np.array(
        [np.cov(x[z_ind == k], rowvar=0) for k in range(num_groups)])

    data_loglik = calc_loglik(
        x, calc_pdfs(x, data_mu, data_sigma), z)
    true_loglik = calc_loglik(x, calc_pdfs(x, mu, sigma), z)

    fig = plt.figure()
    ax = fig.add_subplot(1, 1, 1)
    ax.plot(logliks_em)
    ax.plot(logliks_da)
    ax.plot(logliks_sa)
    ax.axhline(y=data_loglik, color='k')
    fig.savefig('./logliks.pdf')
