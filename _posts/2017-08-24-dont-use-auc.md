---
layout: post
title: Don't use AUC for model selection and definitely don't use accuracy
---



It's pretty hard to build a predictive model, let's be honest. My [previous
post](http://3inar.github.io/2017/04/09/undersampling.html) was about the
strange practice of under-/oversampling. We impose this on ourselves because we want to
do yes/no classification instead of predicting probability. This post is
on the same theme. It has a very clear message: if we use accuracy-like model
performance measures (looking at you, AUC, F1, etc.) we reduce our ability to
select the best model.

I often do little simulations to try to make sense of a confusing world. Below I
present some pretty convincing evidence for the case of dropping classification
in favor of prediction. At least in the model selection phase.

# A simulation model
I will make a simulation model based on the one in my undersampling post.
Once again the log odds of class `True` is \\( \textrm{logit}(p) = -9 +6x, \\) but I 
now sample \\(X \sim N(1.5, 1)\\). This is different from last because I no longer want 
severe class imbalance. I will also add an uninformative noise variable
\\(X_{\epsilon} \sim N(0, 2)\\) post hoc. The below function generates a data set 
to these specifications.


{% highlight r %}
set.seed(23082017)

generate_data <- function(n=100) {
  b_0 <- -9
  b_1 <- 6
  
  # simulate data
  x <- rnorm(n, mean=1.5, sd=1)
  log_odds <- b_0 + b_1*x
  p_y <- 1/(1 + exp(-log_odds))
  y <- factor(runif(length(p_y)) <= p_y, levels = c("FALSE", "TRUE"))
  
  # noise
  x_noise <- rnorm(n, mean=0, sd=2)
  
  data.frame(y, x, x_noise)
}
{% endhighlight %}

This suggests two logistic regression models:

* The true model, \\( \textrm{logit}(p) = \beta_0 + \beta_1x + \epsilon; \\)
* A clearly worse model, \\( \textrm{logit}(p) = \beta_0 + \beta_1x + \beta_2x_{\epsilon} + \epsilon. \\)

Imagine that we didn't know the truth. Our goal is to choose between the two
models: which one predicts better?

# Three performance metrics
I will compare three metrics for model performance on held-out data. 

* Accuracy is
the fraction of times we got the classification right. For this metric I will adopt the 
standard decision rule of classifying as `True` when \\(\hat p > .5\\). 
* The area under the ROC
curve is a strange measure that luckliy directly corresponds to the
probability of ranking a `True` higher than a `False`. 

So both of these measures
have a straight-forward interpretation, which is nice. But since the main
thesis of this post is that you shouldn't use them, let's look at a third
metric: 

* Brier score is the mean squared error between estimated 
probabilities and the true probabilities (the true probabilities are either
unity or zero). It measures the  calibration of your probability estimates, but
has no simple interpretation.


{% highlight r %}
library(AUC)

# three score functions
auc_cost <- function(truth, predicted) {
  auc(roc(predicted, as.factor(truth)))
}

brier_cost <- function(truth, predicted) {
  mean((truth-predicted)^2)
}

accuracy_cost <- function(truth, predicted) {
  predicted <- ifelse(predicted > .5, 1, 0)
  sum(predicted==truth)/length(predicted)
}
{% endhighlight %}

# An experiment
I will simulate the scenario where we compare the two methods by five-fold cross
validation to get a score for each. I want to estimate the statistical power of
each metric: the probability that it gives the true model a better score.

{% highlight r %}
library(plyr)
library(boot)
K <- 5

experiment <- function(cost_function) {
  data <- generate_data()
  glm_fit <- glm(y~x, data=data, family=binomial)
  glm_fit_noise <- glm(y~x+x_noise, data=data, family=binomial)
  
  # score the correct model
  cv <- cv.glm(data, glm_fit, cost_function, K)
  good <- cv$delta[1]
  
  # score the model with a noise predictor
  cv <- cv.glm(data, glm_fit_noise, cost_function, K)
  bad <- cv$delta[1]
  
  c(good=good, bad=bad)
}
{% endhighlight %}

Below I run the experiment 10000 times for each of the three performance
metrics. Beware that if you run this yourself it'll take a while! Afterward I 
go over the scores of the two models and check whether the 
One True Model scored better. I use this below to estimate power.

{% highlight r %}
nsim <- 10000
auc_scores <- raply(nsim, experiment(auc_cost))
brier_scores <- raply(nsim, experiment(brier_cost))
accuracy_scores <- raply(nsim, experiment(accuracy_cost))

auc_decision <- auc_scores[,1] > auc_scores[,2]
accuracy_decision <- accuracy_scores[,1] > accuracy_scores[,2]
brier_decision <- brier_scores[,1] < brier_scores[,2]  # brier score should be low
{% endhighlight %}

# Results

{% highlight r %}
cols = c("#66c2a5", "#fc8d62", "#8da0cb")
plot(brier_decision, type="n", ylim=c(.2,.8), main="Monte Carlo estimates of power", xlab="Simulation #",
     ylab="Power estimate", cex.lab=1.5, cex.axis=1.5, cex.main=1.5, cex.sub=1.2, bty="n")
lines(cumsum(brier_decision)/1:nsim, lwd=2.5, col=cols[1])
lines(cumsum(accuracy_decision)/1:nsim, lwd=2.5, col=cols[2])
lines(cumsum(auc_decision)/1:nsim, lwd=2.5, col=cols[3])

text(nsim, 0.71, paste0("Brier score (beta=", signif(mean(brier_decision), 2), ")"), col=cols[1], cex=1.2, pos=2)
text(nsim, 0.48, paste0("Accuracy (beta=", signif(mean(accuracy_decision), 2), ")"), col=cols[2], cex=1.2, pos=2)
text(nsim, 0.61, paste0("AUC (beta=", signif(mean(auc_decision), 2), ")"), col=cols[3], cex=1.2, pos=2)
{% endhighlight %}

![plot of chunk plots](/assets/Rfig/plots-1.svg)

The plot above shows the convergence of our three simulations toward the final 
estimates. Showing just the numbers isn't social media friendly. The
results are unequivocal. In this simulation, using Brier score gives you an 
extra \\(10 \% \\) power to detect the right model over AUC! Accuracy is worse
still: it is little better than making a monkey decide.


# Why is the Brier score better?
To get accuracy we impose a (more or less) random threshold on the prediction. 
Many would argue that this is a problem in itself. As a score it has the problem
that a miniscule improvement in model can lead to any size improvement in 
accuracy. Consider the following: among \\(n\\) observations to classify, we 
gave a `True` the probability of \\(.5\\). Mistake. Classified as `False`. If we
improve the model a very little so that the probability is now \\(.5001\\) we
get a discrete jump of \\(1/n\\) in accuracy! We've crossed the magical barrier.
Any further improvement in predicted probability makes no difference. The jump
from \\(.5\\) to \\(.5001\\) is as good as a jump from \\(.5\\) to \\(1\\). 
Similarly, a model that predicts a probability of \\(.5\\) for all `False`s and 
\\(.5001\\) for all `True`s has perfect accuracy. It's as good as a model that 
predicted zero for all `False`s and unity for all `True`s. Clearly that's 
nonsense. Similar reasoning applies to AUC, which is just accuracy stretched 
out, or indeed anything based on counting "correct" classifications. The Brier 
score is a [proper scoring 
rule](https://en.wikipedia.org/wiki/Scoring_rule#ProperScoringRules). Any change
in predictions results in a proportional change in Brier score. Hence the Brier 
score is a more sensitive and sensible instrument. It reflects the actual 
improvement in model.

# Full disclosure
Recently I ran days, maybe weeks, worth of resampling validation 
on our local supercomputer. All based on AUC score. I have yet to rerun
those experiments; maybe I should follow my own advice.