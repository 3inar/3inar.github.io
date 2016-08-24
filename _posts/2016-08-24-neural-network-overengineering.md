---
layout: post
title: Neural network overengineering
---


In my idle hours (ie when I should have been writing a paper), I came across this
blog post where the author [trained a neural netwok in the fine art of wine tasting](https://medium.com/autonomous-agents/how-to-train-your-neuralnetwork-for-wine-tasting-1b49e0adff3a#.l2fhfa6hr).
I am basically deep down a very lazy person, and from what little I understand of
NNs, there are quite a few knobs to fiddle with, which really who has the time
with all this untasted wine floating about? 5.56 hidden nodes? 600 epochs? 
Feature scaling? Honestly! What I need is something _simple_.

Now for simplicity you can hardly beat good old Naive Bayes.
For those of us who forget, Naive Bayes is to assume that the predictors 
\\( x_i \\) in an observation \\( \mathbf x = [x_1, x_1, \ldots, x_p] \\) are independent
so that the probability of a given sample, \\( \mathbf x\\), belonging to a given class, 
\\(C\\), is \\( p(C | X = \mathbf x) \propto p(C)\prod_{i=1}^p p(x_i|C) \\). The 
class-conditional densities, \\(p(x_i | C)\\), are usually fit as 
maximum-likelihood-estimate Gaussians.

Anyway, [get the data from UCI](https://archive.ics.uci.edu/ml/datasets/Wine)
and have a go. Follow this simple guide and you too will have
created a wine-tasting AI to threaten the job security of sommeliers 
everywhere. First let's load the data and have a look at it. 

{% highlight r %}
set.seed(220816) # for reproducibility 

# load data, first column in file is class
wino <- read.csv("data/wine.data", header=F)
x <- as.matrix(wino[, -1])
y <- as.factor(wino[, 1])

# from wine.names
colnames(x) <- c("Alcohol", "Malic acid", "Ash", "Alcalinity of ash",
  "Magnesium", "Total phenols", "Flavanoids", "Nonflavanoid phenols",
  "Proanthocyanins", "Color intensity", "Hue", "OD280/OD315 of diluted wines",
  "Proline")

# set aside 0.35 of the samples for independent test set as per other blog
test_idx <- sample(1:length(y), ceiling(length(y)*0.35))
{% endhighlight %}

To get a feel for the data we'll plot the class-conditional densities of 
the different predictors. We exclude the  training samples, of course, 
so as not to fool ourselves. The code for this plot is kind of ugly and 
unintersting so I'll just hide it.
![plot of chunk density_estimates](/assets/Rfig/density_estimates-1.svg)

Doesn't look too bad. Some of these don't look particularly Gaussian, 
but let's just say that we're doing smoothing. Now to fit our model and 
look at how it classifies the different wines.

{% highlight r %}
library(e1071) # provides naiveBayes()
nbfit <- naiveBayes(x[-test_idx, ], y[-test_idx])

pred <- predict(nbfit, x[test_idx, ], type="class")
confusion <- table(pred, y[test_idx]); confusion
{% endhighlight %}



{% highlight text %}
##     
## pred  1  2  3
##    1 18  0  0
##    2  0 29  0
##    3  0  1 15
{% endhighlight %}

That's a pretty friendly-looking confusion matrix; we only have a single 
misclassification. Accuracy is the number of correctly classified observations 
over the total number of observations classified:

{% highlight r %}
acc_est <- sum(diag(confusion))/sum(confusion); acc_est
{% endhighlight %}



{% highlight text %}
## [1] 0.984127
{% endhighlight %}

So that's pretty good. Since I believe in uncertainty estimates, we'll do a 
bootstrapped quantile confidence interval. I estimate by 100% guessing that
5000 bootstrap samples is enough. Much more than enough probably.

{% highlight r %}
library(plyr)
boots <- raply(5000, sample((1:nrow(x))[-test_idx], replace=T))

stats <- aaply(boots, 1, function(bsindex) {
  nbfit <- naiveBayes(x[bsindex, ], y[bsindex])

  pred <- predict(nbfit, x[test_idx, ], type="class")
  confusion <- table(pred, y[test_idx])
  sum(diag(confusion))/sum(confusion)
})

quantile(stats, c(0.025, 0.975))
{% endhighlight %}



{% highlight text %}
##     2.5%    97.5% 
## 0.952381 1.000000
{% endhighlight %}

The results are in: our intelligent wine tasting machine has an estimated accuracy 
of 0.98 with a 0.95 CI of 
[0.95, 1].
That's good enough for me, and what's more I never have to drink wine alone again.
