---
title: "Monix Task - flatMap(Oslo) 2016"
description:
  My presentation from flatMap(Oslo) 2016.
  It's about the Monix Task, a new type for dealing
  with asynchronous processing on top of Scala and Scala.js.
tags:
  - FP
  - Monix
  - Scala
  - Video
youtube: rftcbxj7et0
---

{% include youtube.html ratio=56.25 %}

**Monix Task: Lazy, Async &amp; Awesome** -
my presentation from
[flatMap(Oslo) 2016](http://2016.flatmap.no/nedelcu.html#session):

- [Slides (PDF file)](/assets/pdfs/Monix-Task.pdf)
- [Video (YouTube)](https://www.youtube.com/watch?v=rftcbxj7et0)

Also see:

- [Akka &amp; Monix]({% link _posts/2016-05-15-monix-observable.md %}),
  Typelevel Summit, Oslo, 2016
- [Monix](https://monix.io) project

## Abstract

Scala’s Future from the standard library is great, but sometimes we need more.

A Future strives to be a value, one detached from time and for
this reason its capabilities are restricted and for some use-cases
its behavior ends up being unintuitive. Hence, while the Future/Promise
pattern is great for representing asynchronous results of processes that
may or may not be started yet, it cannot be used as a specification
for an asynchronous computation.

The Monix Task is in essence about dealing with asynchronous
computations and non-determinism, being inspired by the Scalaz Task
and designed from the ground up for performance and to be compatible with
Scala.js/Javascript runtimes and with the Cats library. It also makes use of
Scala’s Future to represent results, the two being complementary.

In this talk I’ll show you its design, when you should use it and
why in dealing with asynchronicity it’s better to work with Task
instead of blocking threads.
