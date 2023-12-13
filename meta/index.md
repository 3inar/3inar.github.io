# Meta page
This is a page about my website. Mostly it is a testing ground for stylesheets.
To read a little bit about why my page is the way it is, check out [this
post](http://localhost:8000/notes/202312131102.html).

Below follows many different elements that may occur on a website, so see how
they look on my site specifically. 

# header1
## header2
### header3
#### header4
##### header5
###### header6

## Lorem Ipsum
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum

## various elements
Paragraph with **bold**, _italic_, `code`, [internal link](/meta/), [external link](https://github.com).

Here we refer to the important book @Axler_2015

> This is a block quote with **bold**, _italic_, `code`, 
> [internal link](/meta/), [external link](https://github.com).

Here is a list containing

* Some **bold**
* Some _italic_
* Some `code`
* Some $A\mathbf x = \mathbf y$
* A nested
    * list with **bold**
    * list with _italic_, `code`, [internal link](meta/), 
      [external link](github.com).

## math
This is a sentence containing some inline math, $\sqrt{\frac{\pi}{\beta}}$, I
will follow it with a block of math below: 

$$
\begin{align*}
A & = \frac{\pi r^2}{2} \\
 & = \frac{1}{2} \pi r^2
\end{align*}
$$

## code again
R code:
```r
func <- function() {
  runif(100)
}
```

julia code
```julia
using LinearAlgebra
a = [1 2; 3 4]
svd(a)
```

## A small and a large image
From [wikimedia commons](https://commons.wikimedia.org/wiki/File:NickCaveCroydon040921_%282_of_41%29_%2851427855295%29.jpg)

![](test_small.jpg)

![](test.jpg)
