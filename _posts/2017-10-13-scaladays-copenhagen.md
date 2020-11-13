---
title: "Scala Days 2017 — Monix Task"
tags:
  - FP
  - Code
  - Scala
  - Monix
  - Presentation
description:
  My presentation from Scala Days 2017, Chicago (April) and Copenhagen (June),
  on the design of Monix's Task.
youtube: wi97X8_JQUk
---

<p class="intro withcap" markdown='1'>Presentation from [Scala Days](http://scaladays.org/), held in 
[Chicago](http://event.scaladays.org/scaladays-chicago-2017)
and [Copenhagen](http://event.scaladays.org/scaladays-cph-2017):</p>

- [Slides (PDF file)](/assets/pdfs/monix-task-scaladays.pdf)
- [Video (YouTube)](https://www.youtube.com/watch?v=wi97X8_JQUk)

{% include youtube.html ratio=56.25 %}

## Abstract

<figure>
  <img src="{% link /assets/media/articles/scaladays.jpg %}" />
</figure>

Scala’s Future from the standard library is great, but sometimes we need more. A Future strives to be a value, one detached from time and for this reason its capabilities are restricted and for some use-cases its behavior ends up being unintuitive. Therefore, while the Future/Promise pattern is great for representing asynchronous results of processes that may or may not be started yet, it cannot be used as a specification for an asynchronous computation.

The Monix Task is in essence about dealing with asynchronous computations and non-determinism, being inspired by the Scalaz Task and designed from the ground up for performance and to be compatible with Scala.js/Javascript runtimes and with the Cats library. It also makes use of Scala’s Future to represent results, the two being complementary.

In this talk I’ll show you its design, when you should use it and why in dealing with asynchronicity it’s better to work with Task instead of blocking threads.