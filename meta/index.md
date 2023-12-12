# header1
## header2
### header3
#### header4
##### header5
###### header6

Paragraph with **bold**, _italic_, `code`, [internal link](meta/), [external link](github.com).

Here we refer to the important book @Axler_2015

## math
This is a sentence containing some inline math, $\sqrt{\frac{\pi}{\beta}}$, I
will follow it with a block of math below: 

$$
\begin{align}
A & = \frac{\pi r^2}{2} \\
 & = \frac{1}{2} \pi r^2
\end{align}
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
