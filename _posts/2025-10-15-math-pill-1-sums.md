---
title: "Math Pill #1: Sums"
mathjax: true
tags:
  - Learning
  - Math
---

My son started high-school, so I'm helping him with mathematics. It's been a long time, and I have to re-learn. But it's fun, and I'm hoping to start a [series of articles](/blog/tag/math/).

<p class="info-bubble" markdown="1">
**Note:** Math formulas in this article are rendered as SVG images for better portability and accessibility.
</p>

Here's an interesting sum:

$$
S = \frac{1}{3 \cdot 7} + \frac{1}{7 \cdot 11} + \frac{1}{11 \cdot 15} + \cdots + \frac{1}{99 \cdot 103}
$$

In order to write it with the summation notation, we first need to observe that the difference between elements in this number sequence is 4, therefore `4k` is involved in the formula of the general term:

$$
S = \sum_{k=1}^{25} \frac{1}{(4k - 1)(4k + 3)}
$$

Such sums are actually [telescopic](https://en.wikipedia.org/wiki/Telescoping_series). And when you have fractions like these with a constant numerator, the general term can be split in 2 fractions, with the help of an equation, needing to find an `a` satisfying this:

$$
\frac{1}{(4k-1)(4k+3)} = a \left( \frac{1}{4k-1} - \frac{1}{4k+3} \right)
$$

$$
a \left( (4k+3) - (4k-1) \right) = a \cdot 4 = 1
\implies a = \frac{1}{4}
$$

The sum becomes:

$$
\begin{aligned}
S &= \sum_{k=1}^{25} \frac{1}{(4k-1)(4k+3)} \\
&= \sum_{k=1}^{25} \frac{1}{4} \left( \frac{1}{4k-1} - \frac{1}{4k+3} \right) \\
&= \frac{1}{4} \sum_{k=1}^{25} \left( \frac{1}{4k-1} - \frac{1}{4k+3} \right)
\end{aligned}
$$

Expanding it:

$$
S = \frac{1}{4} \left( \frac{1}{3} - \frac{1}{7} + \frac{1}{7} - \frac{1}{11} + \frac{1}{11} - \frac{1}{15} + \ldots + \frac{1}{99} - \frac{1}{103} \right)
$$

The terms get cancelled, the result being:

$$
S = \frac{1}{4} \left( \frac{1}{3} - \frac{1}{103} \right)
$$

## More samples

We can apply this solution to other similar sums as well, for example:

$$
\sum_{k=1}^{n} \frac{1}{(2k-1)(2k+1)(2k+3)}
$$

In which case the fraction decomposition can be found with this equation:

$$
\frac{1}{(2k-1)(2k+1)(2k+3)} = a \left( \frac{1}{(2k-1)(2k+1)} - \frac{1}{(2k+1)(2k+3)} \right)
$$

And it works with more denominator factors as well:

$$
\sum_{k=1}^{n} \frac{1}{k(k+1)(k+2)(k+3)}
$$

With the equation for finding the fraction decomposition being:

$$
\frac{1}{k(k+1)(k+2)(k+3)} = a \left( \frac{1}{k(k+1)(k+2)} - \frac{1}{(k+1)(k+2)(k+3)} \right)
$$

## Non-constant numerators

For this one we no longer have a constant numerator and the above solution no longer works:

$$
S = \sum_{k=1}^n \frac{7k^2 + k}{(7k-3)(7k+4)}
$$

To do this fraction decomposition, we now need to find 2 constants, `a` and `b`, the equation now being:

$$
\frac{7k^2 + k}{(7k-3)(7k+4)} = a + \frac{b}{7k-3} - \frac{b}{7k+4}
$$

To solve it, after eliminating the denominator, the trick is to group by powers of `k`:

$$
\begin{aligned}
7k^2 + k &= a(7k-3)(7k+4) + b(7k+4) - b(7k-3) \\
7k^2 + k &= a(49k^2 + 28k - 21k - 12) + 7kb + 4b - 7kb + 3b \\
0 &= 49a k^2 + 7a k + 7b - 12a \\
0 &= k^2 (49a-7) + k(-1+7a) + (7b - 12a)
\end{aligned}
$$

`k` being variable, it means that, in order for the above equation to have solutions, we need the constants to nullify `k`, so we have this system of equations:

$$
\left\{
\begin{array}{l}
49a - 7 = 0 \\
7a - 1 = 0 \\
7b - 12a = 0
\end{array}
\right.
$$

$$
\begin{aligned}
a &= \frac{1}{7} \\
7b - \frac{12}{7} &= 0 \\
7b &= \frac{12}{7} \\
b &= \frac{12}{49}
\end{aligned}
$$

And now we can finally write the sum as:

$$
\begin{aligned}
S &= \sum_{k=1}^{n} \left( \frac{1}{7} + \frac{12}{49} \left( \frac{1}{7k-3} - \frac{1}{7k+4} \right) \right) \\
&= \frac{n}{7} + \frac{12}{49} \sum_{k=1}^{n} \left( \frac{1}{7k-3} - \frac{1}{7k+4} \right) \\
&= \frac{n}{7} + \frac{12}{49} \left( \frac{1}{4} - \frac{1}{7n+4} \right)
\end{aligned}
$$
