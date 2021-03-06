rm(list = ls())

library('ggplot2')
library('reshape2')
library('plyr')
library('extrafont')

# setwd("~/Google Drive/Classes/Stats 608/Project/Code")
true_loglik = -5196.976212643527


# Plot simulated data
data = read.csv('./intermediate_data/sim_data.csv')

data$z = factor(data$z)
gplot_data = ggplot(data, aes(x=x1, y=x2, color=z)) +
    geom_point(alpha=.8) +
    xlab('') + ylab('') +
    theme_bw() +
    theme(legend.position="none")

pdf('./figures/sim_data.pdf', height=4.5, width=6, family='CM Roman')
print(gplot_data)
dev.off()


# PLot single run results
results = read.csv('./intermediate_data/singlerun_results.csv')
results$iter = 1:nrow(results)
results = reshape(results, direction='long',
    varying=c("logliks_em", "times_em",
              "logliks_da", "times_da",
              "logliks_sa", "times_sa"),
    idvar='iter', timevar='method', sep='_')
results$method[results$method == 'em'] = 'EM Algorithm'
results$method[results$method == 'da'] = 'Deterministic Anneal'
results$method[results$method == 'sa'] = 'Stochastic EM'

sa = read.csv('./intermediate_data/sa_singlerun.csv')
sa$iter = 1:nrow(sa)
sa = reshape(sa, direction='long',
    varying=c("logliks_curr", "logliks_best"),
    idvar='iter', timevar='type', sep='_')
sa$type[sa$type == 'curr'] = 'Current'
sa$type[sa$type == 'best'] = 'Best'

gplot_byiter = ggplot(results, aes(x=iter, y=logliks, color=method)) +
    geom_line() +
    geom_hline(yintercept=true_loglik) +
    coord_cartesian(ylim=c(-6350, -4850)) +
    xlab('Iterations') + ylab('Log Likelihood') +
    theme_bw() +
    theme(legend.position=c(1,0), legend.justification=c(1,0),
          legend.title=element_blank(),
          legend.background=element_rect(color="lightgrey"))

gplot_bytime = ggplot(results, aes(x=times, y=logliks, color=method)) +
    geom_line() +
    geom_hline(yintercept=true_loglik) +
    coord_cartesian(ylim=c(-6350, -4850)) + xlim(NA, 0.45) +
    xlab('Time') + ylab('Log Likelihood') +
    theme_bw() +
    theme(legend.position=c(1,0), legend.justification=c(1,0),
          legend.title=element_blank(),
          legend.background=element_rect(color="lightgrey"))

gplot_singlesa = ggplot(sa, aes(x=iter, y=logliks, color=type)) +
    geom_line() +
    geom_hline(yintercept=true_loglik) +
    coord_cartesian(ylim=c(-6350, -4850)) +
    xlab('Iterations') + ylab('Log Likelihood') +
    theme_bw() +
    theme(legend.position=c(1,0), legend.justification=c(1,0),
          legend.title=element_blank(),
          legend.background=element_rect(color="lightgrey"))

pdf('./figures/results_byiter.pdf', height=4.5, width=5.5, family='CM Roman')
print(gplot_byiter)
dev.off()
pdf('./figures/results_bytime.pdf', height=4.5, width=5.5, family='CM Roman')
print(gplot_bytime)
dev.off()
pdf('./figures/sa_singlerun.pdf', height=4.5, width=5.5, family='CM Roman')
print(gplot_singlesa)
dev.off()


# Plot multiple runs
sa_950 = read.csv('./intermediate_data/sa_t950.csv')
sa_975 = read.csv('./intermediate_data/sa_t975.csv')
sa_992 = read.csv('./intermediate_data/sa_t992.csv')
sa_999 = read.csv('./intermediate_data/sa_t999.csv')
sa_950$run = as.factor(sa_950$run)
sa_975$run = as.factor(sa_975$run)
sa_992$run = as.factor(sa_992$run)
sa_999$run = as.factor(sa_999$run)

sa_950_mean = ddply(sa_950, .(iter), summarize,  loglik=mean(loglik_best))
sa_975_mean = ddply(sa_975, .(iter), summarize,  loglik=mean(loglik_best))
sa_992_mean = ddply(sa_992, .(iter), summarize,  loglik=mean(loglik_best))
sa_999_mean = ddply(sa_999, .(iter), summarize,  loglik=mean(loglik_best))
sa_950_mean$alpha = '0.950'
sa_975_mean$alpha = '0.975'
sa_992_mean$alpha = '0.992'
sa_999_mean$alpha = '0.999'

sa_means = rbind(sa_950_mean, sa_975_mean, sa_992_mean, sa_999_mean)


gplot_sa950 = ggplot(sa_950[sa_950$run %in% 0:9,],
                     aes(x=iter, y=loglik_best)) +
    geom_line(aes(color=run)) +
    geom_hline(yintercept=true_loglik) +
    coord_cartesian(ylim=c(-6350, -4850)) +
    xlab('Iterations') + ylab('Log Likelihood') +
    theme_bw() +
    theme(legend.position="none")

gplot_sa975 = ggplot(sa_975[sa_975$run %in% 0:9,],
                     aes(x=iter, y=loglik_best)) +
    geom_line(aes(color=run)) +
    geom_hline(yintercept=true_loglik) +
    coord_cartesian(ylim=c(-6350, -4850)) +
    xlab('Iterations') + ylab('Log Likelihood') +
    theme_bw() +
    theme(legend.position="none")

gplot_sa992 = ggplot(sa_992[sa_992$run %in% 0:9,],
                     aes(x=iter, y=loglik_best)) +
    geom_line(aes(color=run)) +
    geom_hline(yintercept=true_loglik) +
    coord_cartesian(ylim=c(-6350, -4850)) +
    xlab('Iterations') + ylab('Log Likelihood') +
    theme_bw() +
    theme(legend.position="none")

gplot_sa999 = ggplot(sa_999[sa_999$run %in% 0:9,],
                     aes(x=iter, y=loglik_best)) +
    geom_line(aes(color=run)) +
    geom_hline(yintercept=true_loglik) +
    coord_cartesian(ylim=c(-6350, -4850)) +
    xlab('Iterations') + ylab('Log Likelihood') +
    theme_bw() +
    theme(legend.position="none")

gplot_sameans = ggplot(sa_means, aes(x=iter, y=loglik, color=alpha)) +
    geom_line() +
    geom_hline(yintercept=true_loglik) +
    coord_cartesian(ylim=c(-5650, -4950)) +
    xlab('Iterations') + ylab('Log Likelihood') +
    theme_bw() +
    theme(legend.position=c(1,0), legend.justification=c(1,0),
          legend.title=element_blank(),
          legend.background=element_rect(color="lightgrey"))

# pdf('./figures/sa950.pdf', height=4.5, width=5.5, family='CM Roman')
# print(gplot_sa950)
# dev.off()
# pdf('./figures/sa975.pdf', height=4.5, width=5.5, family='CM Roman')
# print(gplot_sa975)
# dev.off()
pdf('./figures/sa992.pdf', height=4.5, width=5.5, family='CM Roman')
print(gplot_sa992)
dev.off()
# pdf('./figures/sa999.pdf', height=4.5, width=5.5, family='CM Roman')
# print(gplot_sa999)
# dev.off()

# pdf('./figures/sameans_byalpha.pdf', height=4.5, width=5.5, family='CM Roman')
# print(gplot_sameans)
# dev.off()


# Plot additional simulations
dat_em = read.csv("./intermediate_data/em_2000.csv")
dat_da = read.csv("./intermediate_data/da_2000.csv")
dat_sa = read.csv("./intermediate_data/sa_2000.csv")
dat_sa = dat_sa[,-3]
names(dat_sa) = names(dat_em)
dat_em$typ = as.factor("EM Algorithm")
dat_da$typ = as.factor("Deterministic Anneal")
dat_sa$typ = as.factor("Stochastic EM")
dat_em$size = as.factor(2000)
dat_da$size = as.factor(2000)
dat_sa$size = as.factor(2000)
dat_em = dat_em[!is.na(dat_em$loglik_curr),]
dat_da = dat_da[!is.na(dat_da$loglik_curr),]
dat_sa = dat_sa[!is.na(dat_sa$loglik_curr),]
dat = rbind(dat_em, dat_da, dat_sa)

dat_em = read.csv("./intermediate_data/em_1000.csv")
dat_da = read.csv("./intermediate_data/da_1000.csv")
dat_sa = read.csv("./intermediate_data/sa_1000.csv")
dat_sa = dat_sa[,-3]
names(dat_sa) = names(dat_em)
dat_em$typ = as.factor("EM Algorithm")
dat_da$typ = as.factor("Deterministic Anneal")
dat_sa$typ = as.factor("Stochastic EM")
dat_em$size = as.factor(1000)
dat_da$size = as.factor(1000)
dat_sa$size = as.factor(1000)
dat_em = dat_em[!is.na(dat_em$loglik_curr),]
dat_da = dat_da[!is.na(dat_da$loglik_curr),]
dat_sa = dat_sa[!is.na(dat_sa$loglik_curr),]
dat = rbind(dat, dat_em, dat_da, dat_sa)

dat_em = read.csv("./intermediate_data/em_500.csv")
dat_da = read.csv("./intermediate_data/da_500.csv")
dat_sa = read.csv("./intermediate_data/sa_500.csv")
dat_sa = dat_sa[,-3]
names(dat_sa) = names(dat_em)
dat_em$typ = as.factor("EM Algorithm")
dat_da$typ = as.factor("Deterministic Anneal")
dat_sa$typ = as.factor("Stochastic EM")
dat_em$size = as.factor(500)
dat_da$size = as.factor(500)
dat_sa$size = as.factor(500)
dat_em = dat_em[!is.na(dat_em$loglik_curr),]
dat_da = dat_da[!is.na(dat_da$loglik_curr),]
dat_sa = dat_sa[!is.na(dat_sa$loglik_curr),]
dat = rbind(dat, dat_em, dat_da, dat_sa)

pw_avg_lik = ddply(dat, c("typ", "iter", "size"), summarise,
                   avg_lik = mean(loglik_curr))

pw2000 = subset(pw_avg_lik, size==2000)
pw1000 = subset(pw_avg_lik, size==1000)
pw500 = subset(pw_avg_lik, size==500)

gplot_2000 = ggplot(pw2000, aes(x=iter, y=avg_lik, color=typ)) +
   geom_line() +
   coord_cartesian(ylim=c(-6500, -4850)) + xlim(NA, 200) +
   xlab('Iterations') + ylab('Log Likelihood') +
   theme_bw() +
   theme(legend.position=c(1,0), legend.justification=c(1,0),
         legend.title=element_blank(),
         legend.background=element_rect(color="lightgrey"))

gplot_1000 = ggplot(pw1000, aes(x=iter, y=avg_lik)) +
   geom_line(aes(colour=typ)) +
   coord_cartesian(ylim=c(-3500, -2400)) + xlim(NA, 200) +
   xlab('Iterations') + ylab('Log Likelihood') +
   theme_bw() +
   theme(legend.position=c(1,0), legend.justification=c(1,0),
         legend.title=element_blank(),
         legend.background=element_rect(color="lightgrey"))

gplot_500 = ggplot(pw500, aes(x=iter, y=avg_lik)) +
   geom_line(aes(colour=typ)) +
   coord_cartesian(ylim=c(-1800, -1150)) + xlim(NA, 200) +
   xlab('Iterations') + ylab('Log Likelihood') +
   theme_bw() +
   theme(legend.position=c(1,0), legend.justification=c(1,0),
         legend.title=element_blank(),
         legend.background=element_rect(color="lightgrey"))

pdf('figures/avg_lik_2000.pdf', height=4.5, width=5.5, family='CM Roman')
print(gplot_2000)
dev.off()
# pdf('figures/avg_lik_1000.pdf', height=4.5, width=5.5, family='CM Roman')
# print(gplot_1000)
# dev.off()
pdf('figures/avg_lik_500.pdf', height=4.5, width=5.5, family='CM Roman')
print(gplot_500)
dev.off()


# Plot EM comparisons
mix_df = read.csv("./intermediate_data/em_mix.csv")
mu_df = read.csv("./intermediate_data/em_mean.csv")
mix_df = subset(mix_df, iter < 300)
mu_df = subset(mu_df, iter < 300)
names(mix_df) = names(mu_df) = c("run", "iter", "loglik")
fn = function(vect) {
   return(vect - max(vect))
}

mix_df_plot = ddply(mix_df, "run", transform, dist_fc = fn(loglik))
mu_df_plot = ddply(mu_df, "run", transform, dist_fc = fn(loglik))

gplot_mix = ggplot(mix_df_plot, aes(x=iter, y=-dist_fc)) +
   geom_line(aes(color=as.factor(run))) +
   xlab('Iteration') + ylab('Distance from max loglik') +
   theme_bw() +
   theme(legend.position=c(1,1), legend.justification=c(1,1),
         legend.title=element_blank(),
         legend.background=element_rect(color="lightgrey")) +
   scale_color_discrete(name="", breaks=c(0,1),
                        labels=c("Unbalanced", "Balanced"))

gplot_overlap = ggplot(mu_df_plot, aes(x=iter, y=-dist_fc)) +
   geom_line(aes(color=as.factor(run))) +
   xlab('Iteration') + ylab('Distance from max loglik') +
   theme_bw() +
   theme(legend.position=c(1,1), legend.justification=c(1,1),
         legend.title=element_blank(),
         legend.background=element_rect(color="lightgrey")) +
   scale_color_discrete(name="", breaks=c(0,1),
                        labels=c("More Overlap", "Less Overlap"))

pdf('figures/em_imbalance.pdf', height=4.5, width=5.5, family='CM Roman')
print(gplot_mix)
dev.off()
pdf('figures/em_overlap.pdf', height=4.5, width=5.5, family='CM Roman')
print(gplot_overlap)
dev.off()
