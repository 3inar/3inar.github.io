---
layout: post
title: The most violent show on earth
---


So I'm currently at a ten month reserach stay in Paris. I'm reluctant in the 
face of change, so I often think of home while I'm in my small apartment in a
building with a slight mouse problem, or in my larger office with,
astonishingly, also a slight mouse problem (unconfirmed).

I come from a small town called Vadsø in the Norwegian county of Finnmark. It's 
a small town of some 6000 people; it's nice and quiet. **Or is it??** For some 
years we've had  the honor  of being the most violent town in Norway, if you
count the number of police reports for violence per 1000 citizens. These are numbers from
[Statistics Norway (SSB)](https://www.ssb.no/en/), which the papers usually 
pick up every year, like in 
[this 2015 article from the tabloid Dagbladet](http://www.dagbladet.no/2015/09/13/nyheter/innenriks/kriminalitet/vold/finnmark/40801169/). 
It's always the violent crimes statistic they're interested in.

The most recent numbers are from 2014. It's the same ones discussed in that
article. The numbers show Vadsø falling several ranks, with Hasvik (also in
Finnmark) taking a marked lead in the old ultraviolence. In fact Finmark has a
surprisingly strong precense in the top ten considering that it's the most
sparsely populated county in Norway. People must be traveling for hours to find
a good fight! Sadly I didn't go to journalist school, but I do have a slight
interest in numbers, so I'm going to have a look at these statistics.

### Fetching + tidying SSB data
My office wife through many years, [Bjørn](http://fjukstad.github.io/), has been
good enough to help me with the SSB API, most of the below is adapted from his
code. You can skip this if you're not too excited about tidying data sets.

{% highlight r %}
library(tidyverse)
library(stringr)
library(rjstat)

violence_url <-"http://data.ssb.no/api/v0/dataset/81194.json?lang=no"
population_url <- "http://data.ssb.no/api/v0/dataset/26975.json?lang=no"
  
# fetch crime reports
v <- violence_url %>% fromJSONstat %>% as.data.frame

# colnames have the format [long table name].variable, extract the last bit
colnames(v) <- gsub("^(.*[.])", "", colnames(v))

# n.o. reports and n.o. reports per 1000 citizens in same column, separate them
# with tidyr, rename new columns. the year column contains ranges like
# 2007-2008, which we'll translate to a single year
tid_new <- v$tid %>% str_split("-")
v <- spread(v, statistikkvariabel, value) %>% 
     mutate(tid=str_split(tid, pattern="-", simplify=T)[, 2])
colnames(v)[c(1,4,5)] = c("sted", "anmeldelser", "anmeldelser_pk")

# fetch population numbers
p <- population_url %>% fromJSONstat %>% as.data.frame
colnames(p) <- gsub("^(.*[.])", "", colnames(p))
p <- spread(p, statistikkvariabel, value)

# change names so that we ca join the two tables on "sted" and "tid"
colnames(p)[1] <- "sted"
colnames(p)[3] <- "personer"

crimes <- left_join(v, p)

# filter out anything that isn't violence in 2014. Additionally, some of the
# entries have population 0, so let's remove them. Order by crimes/1000,
# descending
violence14 <- crimes %>% filter(tid=="2014", lovbruddstype=="Voldskriminalitet") %>%
              filter(sted != "Alle kommuner", personer > 0) %>%
              select(-lovbruddstype, -tid) %>% 
              na.omit %>% 
              arrange(desc(anmeldelser_pk))
{% endhighlight %}

### What do these statistics look like
Let's look at the ten most violent towns and the ten least violent towns:

{% highlight r %}
top_n(violence14, n=10, anmeldelser_pk) # top 10 violence
{% endhighlight %}



{% highlight text %}
##                               sted anmeldelser anmeldelser_pk personer
## 1                           Hasvik          16           15.4     1037
## 2       Guovdageaidnu - Kautokeino          34           11.6     2931
## 3                         Hemsedal          25           10.9     2295
## 4  Porsanger - Porsángu - Porsanki          43           10.9     3963
## 5                            Bykle          10           10.5      948
## 6                          Seljord          30           10.0     2989
## 7                       Hammerfest         101            9.8    10287
## 8                            Vadsø          61            9.8     6223
## 9                     Sør-Varanger          96            9.5    10090
## 10                        Salangen          20            9.0     2223
## 11                           Vardø          19            9.0     2119
{% endhighlight %}



{% highlight r %}
top_n(violence14, n=-10, anmeldelser_pk) # 10 least violent
{% endhighlight %}



{% highlight text %}
##         sted anmeldelser anmeldelser_pk personer
## 1     Fitjar           6            2.0     3009
## 2     Hemnes           9            2.0     4553
## 3       Hole          13            2.0     6595
## 4    Meråker           5            2.0     2553
## 5      Selbu           8            2.0     4030
## 6      Stryn          14            2.0     7134
## 7   Surnadal          12            2.0     5954
## 8  Austevoll           9            1.8     4924
## 9       Sula          16            1.8     8651
## 10 Overhalla           6            1.6     3732
## 11    Åfjord           5            1.5     3242
## 12    Suldal           6            1.5     3881
## 13   Gausdal           9            1.4     6237
## 14    Sigdal           5            1.4     3509
{% endhighlight %}

There's a clear overrepresentation of Finnmark in the violence top ten; if you 
live in one of the -dals you're presumably going to have a much calmer time of 
it. Vadsø is sadly only the eight most violent. Common to both lists is that
it's all small towns. The biggest ones have a population of about 10,000. The
below plot shows the violent crime rate as a function of population size. The
red line is at the mean.


{% highlight r %}
with(violence14, {
  plot(personer/1000, anmeldelser_pk,
       xlab="population (in thousands)", ylab="violence rate", pch=20, 
       col=colors[4], main="crime rate as a f'n of population", bty="n")
  abline(h=mean(anmeldelser_pk), col=colors[5], lwd=1.5)
})
{% endhighlight %}

![plot of chunk rate_vs_pop](/assets/Rfig/rate_vs_pop-1.svg)

Hasvik s really sticking out there at the top left! The high-leverage point all
the way to the right is Oslo. If you feel that there is a lot more going on for 
better or worse in the smaller towns you might be right: Notice the slight 
funnel shape toward the mean as population increases. In a town of two people 
the population is 0.002 thousand people. If one person does violence to the 
other, the violence rate goes up by 1/0.002 = 500. This is the smallest
possible jump in crime rate in a town of two people, and the crime rate can only
be multiples of 500 there, assuming there are no semi-reported crimes. If the 
same thing were to happen in Oslo, with a 2014 population (in thousands) of 
about 634, we'd get a modest bump of 1/634 ≈ 0.002: the smallest possible crime 
rate jump in a town of 634 thousand people. Clearly there will be more variance 
in crime rate (or any sort of count per population) in small towns, which means 
that small towns will be overrepresented in both extremes, both most violent and
least violent.

An intro to stats course will probably teach you that the standard error of the 
mean is \\(\sigma_{\bar x} = \sigma/\sqrt{n},\\) with \\(n\\) the number of
samples you're taking the mean of. Howard Wainer calls this De Moivre's
equation, and also calls it
[the most dangerous equation in the world](http://press.princeton.edu/chapters/s8863.pdf).
You should read that `.pdf`, it's really good. I'll wait.

### Baseball and violent crime: basically the same thing?
Perhaps when looking at numbers like these it's a good idea to be honest about 
uncertainty, if only to avoid a smaller schools-type debacle as discussed in the
Wainer `.pdf`. I recently saw this interesting blog post from David Robinson
about
[using empirical Bayes to smooth batting averages](http://varianceexplained.org/r/empirical_bayes_baseball/).  
It's kind of a similar problem: some players have few chances at batting,
and the guy who only got two chances but hit them both will have a perfect hit
rate of 1, while she who tried hundreds of times is very likely to have a couple of
misses no matter her skill level. When viewed in extremes like this 
it's kind of obvious that the one statistic is more reliable than the other.

You can model batting averages as Bernoulli trials: you get \\(n\\) chances and
will hit or miss with probability \\(p\\) or \\(1-p\\), respectively. Estimate
\\(p\\) as number of hits over number of chances. Our crime rates aren't like
this; none of them are between zero and one to start with. Let's do some
sweeping generalizations, though: Let's say that in a given year a person only
reports either one or zero violent crimes, and that each person has the same 
probability of being involved in violent crime as the next, independent of each 
other. We could recalculate the crime rates as number of crime reports per 
person (cpp) instead of crime reports per thousands of people. The two
quantities are proportional, so the ranking will stay the same, and it will 
enable us to model crime reports as Bernoulli trials, and crime rate, \\(p\\),
as Beta-distributed. It wouldn't be strictly speaking true, but it might be
useful.

### Smoothing our estimates
Bayesian statistics are all about having some first guess about (actually prior 
distribution over) what a parameter such as our crime rate, \\(p\\), is, and 
adjusting this guess (to get a posterior distribution) as data becomes 
available. This is empirical Bayes because we will use the observed crime rates 
in all of Norway as a prior distribution. A purist would decide on a prior based
on gut-feel and know-how. 

We'll
[fit a Beta distribution](http://stats.stackexchange.com/questions/12232/calculating-the-parameters-of-a-beta-distribution-using-the-mean-and-variance) 
as prior because it is a handy distribution for probabilities 
(it is restricted to [0,1]), and because it is 
[a conjugate prior to the binomial likelihood](https://en.wikipedia.org/wiki/Conjugate_prior#Table_of_conjugate_distributions),
which means we can model a person's reporting a violent crime as a bernoulli 
trial and get an exact posterior in the shape of a shifted, scaled beta. We
won't even have to mess about with the usual Bayesian sampling procedures. In
other words, we start with an initial-guess beta distribution over crime rates
and use our observed rate in a given town to shift and adjust the prior into
another beta: the posterior.

{% highlight r %}
# calculate cpp
violence14 <- mutate(violence14, cpp=anmeldelser/personer)

# fit beta prior to cpp by method of moments
mu <- mean(violence14$cpp)
ssq <- var(violence14$cpp)
alpha_p <- ((1 - mu) / ssq - 1 / mu) * mu ^ 2
beta_p <- alpha_p * (1 / mu - 1)

# check the fit
hist(violence14$cpp, col=colors[4], border=F, nclass=25, prob=T, main="per capita violence")
curve(dbeta(x, alpha_p, beta_p), add=T, col=colors[5], lwd=1.5)
{% endhighlight %}

![plot of chunk fit_prior](/assets/Rfig/fit_prior-1.svg)

The histogram is our observed crime rates in a big pile, the red curve is our 
empirical prior based on these data. I think it looks fine. To gloss over some 
details: the Wikipedia link to conjugate priors and the David Robinson post 
above will tell you that the posterior mean for a given town, which is sensible 
prediction from the posterior, is \\( \frac{r + \alpha_0}{N + \alpha_0 + 
\beta_0} \\), where \\(r \\) is the observed number of violent crime reports, 
\\(N\\) is the population, and \\(\alpha_0, \beta_0\\) are the parameters of the
prior. These are our new estimates.

{% highlight r %}
violence14 <- mutate(violence14, posterior_cpp=(anmeldelser+alpha_p)/(personer+alpha_p+beta_p))
{% endhighlight %}

Let's compare the observed and posterior rates in a plot. The upper points
in the plot represent posterior estimates, while the lower points are the
observed rates. Corresponding estimates are connected by a line.

{% highlight r %}
op <- par(mar = c(4,5,2,2) + 0.1)
plot(c(range(select(violence14, cpp, posterior_cpp))), c(0,1), type="n", 
     ylab="", xlab="estimate", bty="n", yaxt="n")
axis(2, at=0:1, labels=c("observed", "adjusted"), las=1, tick=F)

post <- cbind(violence14$posterior_cpp, rep(1, nrow(violence14)))
raw <- cbind(violence14$cpp, rep(0, nrow(violence14)))
points(raw, pch=20, col=colors[4])
points(post, pch=20, col=colors[4])

plyr::a_ply(violence14, 1, function(x) {
  lines(c(x$posterior_cpp, x$cpp), c(1,0), col=colors[4])
})
{% endhighlight %}

![plot of chunk compare_adjustment](/assets/Rfig/compare_adjustment-1.svg)

This plot shows the effect of smoothing the observed crime rates toward the prior
distribution. We see that the more extreme estimates have been shrunk toward the
center because our prior distribution says that there shouldn't be that much
happening toward the tails. The crossing lines indicate towns that have been
shifted to a new position in the violence ranking. Hasvik is still reigning
champion.

### A more honest top ten
Since the posterior is just a shifted and scaled beta distribution, for which we
can easily calculate the parameters, we can compute credible intervals for these
new estimates. Credible intervals is the nicer sibling of confidence intervals,
what I show below are .99 credible intervals, which can be interpreted as
"based on this analysis I belive the parameter falls within this interval with
99% probability."

Oslo is, according to about 634 thousand people, the only city in Norway. It's 
clarly something to compare to when you're one of the *provinciaux*. Below are the
posterior point estimates and credible intervals for the top ten most violent
cities, plus the same for Oslo in the bottom, eleventh row.
The yellow points are the observed rates before adjustment. The posterior 
estimate for Oslo is also marked with a vertical line to compare with.

{% highlight r %}
# calculate the parameters of the posterior, get the .99 credible interval
violence14 <- mutate(violence14, alpha=alpha_p+anmeldelser) %>% 
              mutate(beta=beta_p+personer-anmeldelser) %>%
              mutate(lc=qbeta(0.005, alpha, beta)) %>%
              mutate(uc=qbeta(0.995, alpha, beta)) %>%
              select(-alpha, -beta)

# make top 10, plot it
post_oslo <- violence14[violence14$sted=="Oslo kommune", "posterior_cpp"]
top10 <- top_n(violence14, 10, posterior_cpp) %>% 
         rbind(filter(violence14, sted=="Oslo kommune")) %>% 
         arrange(posterior_cpp)

op <- par(mar = c(4,14,2,2) + 0.1)
n_c <- nrow(top10)
plot(c(range(select(top10, cpp, posterior_cpp, lc, uc))), c(0, n_c+1), type="n", 
     yaxt="n", bty="n", ylab="", xlab="", main="ten most violent towns + Oslo")
axis(2, at=1:n_c, labels=top10$sted, las=1, tick=F)
abline(v=post_oslo, col=colors[3])
points(top10$posterior_cpp, 1:n_c, pch=20, col=colors[4])
points(top10$lc, 1:n_c, pch="|", cex = 0.5, col=colors[4])
points(top10$uc, 1:n_c, pch="|", cex = 0.5, col=colors[4])

plyr::a_ply(1:n_c, 1, function(i) {
  obs <- top10[i, ]
  lines(c(obs$uc, obs$lc), c(i,i), col=colors[4], lwd=1.5)
})
points(top10$cpp, 1:n_c, pch=20, col=colors[1])
{% endhighlight %}

![plot of chunk now_top_ten](/assets/Rfig/now_top_ten-1.svg)

We can see that the violence rates in the top ten mostly have very wide credible
intervals because they were mostly estimated in smaller towns. The posterior 
estimate for Oslo is inside all the intervals. We can also see that the
estimates for the larger towns, Tønsberg, Ullensaker, and Oslo, didn't move much
or at all, while the one for tiny Hasvik of about one thousand people had a
large adjustment. It's hard for me to argue that Hasvik deserves to be called
most violent in Norway based on this; it really could have ended up anywhere in
the top ten or even outside of the top ten from natural variability. Really I
wouldn't stick my hand in the fire for this exact top ten at all, apart from
maybe Tønsberg and Ullensaker, which are larger towns where the violence rate
can be estimated more exactly. What's their deal anyway.

Meanwhile Oslo is pretty violent, and we can say so with reasonable accuracy. In
the adjusted rankings it's placed 15th out of 348, so it's not as though it's a
very ambitious goal to be less violent than Oslo.

{% highlight r %}
violence14 %>% arrange(desc(posterior_cpp)) %>% 
               select(sted) %>%  `==`("Oslo kommune") %>% which
{% endhighlight %}



{% highlight text %}
## [1] 15
{% endhighlight %}



{% highlight r %}
nrow(violence14)
{% endhighlight %}



{% highlight text %}
## [1] 348
{% endhighlight %}

### Bærum: a new hope
Below I show a random subset of 100 from the posterior ranking, I've left out 
the names to avoid overplotting. I also only show the posterior estimates. At
the very top, in red, I've shown the point estimate and .99 credible interval
from the prior distribution. This is what our best guess would be if we knew
nothing at all about a town.

{% highlight r %}
set.seed(67890)
violent_subset <- violence14 %>% sample_n(100) %>% arrange(posterior_cpp)
n_c <- nrow(violent_subset)
padding=3
plot(c(range(select(violent_subset, cpp, posterior_cpp, lc, uc))), c(0, n_c+padding), type="n", 
     yaxt="n", bty="n", ylab="", xlab="", main="violence across the board")

lines(qbeta(c(0.005, 0.995), alpha_p, beta_p), c(n_c+padding,n_c+padding), col=colors[5])
points(alpha_p/(alpha_p+beta_p), n_c+padding, pch=20, col=colors[5])
  
plyr::a_ply(1:n_c, 1, function(i) {
  obs <- violent_subset[i, ]
  lines(c(obs$uc, obs$lc), c(i,i), col=colors[4])
})
points(violent_subset$posterior_cpp, 1:n_c, pch=20, col=colors[2])
{% endhighlight %}

![plot of chunk random_subset](/assets/Rfig/random_subset-1.svg)

Interestingly there seems to be one town toward the bottom there that's 
genuinely not very violent compared to the rest of the country, as estimated 
with reasonable accuracy compared to the rest. It's Bærum, population 118,588.

{% highlight r %}
top_n(violent_subset, -10, posterior_cpp) %>% select(sted, personer, posterior_cpp)
{% endhighlight %}



{% highlight text %}
##           sted personer posterior_cpp
## 1    Overhalla     3732   0.002245948
## 2         Hole     6595   0.002320045
## 3        Bærum   118588   0.002572136
## 4       Tynset     5549   0.002685267
## 5     Oppegård    26255   0.002699850
## 6         Aure     3577   0.002748474
## 7  Østre Toten    14777   0.002762151
## 8     Sør-Fron     3191   0.002762684
## 9       Stange    19737   0.002824540
## 10        Kvam     8584   0.002876412
{% endhighlight %}

Bærum is a place I know literally nothing about, but go there if you don't like
violence. At the same time, however, I'd hold off on moving away from Vadsø or
Hasvik based on the number of violent crime reports in 2014. Unless you choose
to [believe in the law of small numbers](https://archive.li/faHW).
