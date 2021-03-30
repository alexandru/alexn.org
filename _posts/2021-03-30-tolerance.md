---
title: "Tolerance"
date: 2021-03-30 23:12:35+0300
image: /assets/media/articles/tolerance.png
image_hide_in_post: true
tags: 
  - FP
  - OOP
  - Personal
  - Programming
description: "I just refactored a piece of code. I deleted 6 source code files, and rebuilt the functionality with a bunch of dirty OOP classes shoved in a single file 😱"
---

<p class="intro withcap" markdown="1">
  I just refactored a piece of code. I deleted 6 source code files, and rebuilt the functionality with a bunch of dirty OOP classes shoved in a single file 😱
</p>

I used OOP for simplification, and in the process I got rid of type parameters, type classes, and implicit parameters. Plain-old OOP design saved the day, i.e. shove those side effects behind an interface, and pass those objects around, blissfully unaware as to what they do (launching rockets A-OK). *It was glorious!* I can't remember the last time it felt this good.

Then it dawned on me that I wrote that code to begin with. This piece already underwent a major refactoring, having introduced extra complexity, without catching the subtleties, or smelling the stench of my own doing. What's going on?

I started blaming the COVID-19 pandemic, it's been a year since I've been lethargic (aka mild to moderate depression), missing the creative energy that I remember since before the world went mad. But then I started giving myself some credit, because the truth is ... as I grow old, I tolerate people more, while tolerating BS in programming less.

<figure>
  <img src="{% link assets/media/articles/tolerance.png %}" alt="" class="transparency-fix" />
  <figcaption>The normal distribution of BS tolerance, it's all downhill after 30, yikes!</figcaption>
</figure>

This is another way of saying that you should never forget *YAGNI*[^1], *KISS*[^2], the *Principle of Least Surprise*[^3], or whatever kids call it these days. Just because you can, doesn't mean you should, with great power comes great responsibility, learn from my mistakes, etc, etc. Also, sometimes *DRY*[^4] is a bad philosophy, copy/paste that shit.

Now get off my lawn.

[^1]: [You Ain't Gonna Need It](https://en.wikipedia.org/wiki/You_aren%27t_gonna_need_it) is what agile developers crave for
[^2]: [Keep It Simple Stupid](https://en.wikipedia.org/wiki/KISS_principle) was a hip phrase back in my Ruby days, but searching "KISS Ruby" on Google yielded some strange results
[^3]: OOP and FP developers actually understand different things by the [rule of least power](https://en.wikipedia.org/wiki/Rule_of_least_power) 🤷‍♂️
[^4]: [Don't Repeat Yourself](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself) is not the mantra of Go developers
