---
title: "Functional Programming Inception (Presentation)"
tags:
  - FP
  - Code
  - Scala
  - Monix
description:
  My presentation from the Bucharest FP meetup.
image: /assets/media/articles/2017-fp-inception.png
image_hide_in_post: true
---

<script async class="speakerdeck-embed" data-id="ed894a1f20a141bab121d83d1fa54b68" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>

<p class="intro" markdown='1'>
  My presentation from the [Bucharest FP](http://bucharestfp.ro/) meetup.
</p>

Resources:

- [Slides (PDF file)](/assets/pdfs/FP-Inception-Bucharest.pdf)

Links from the presentation:

- [Monix](https://monix.io)
- [Typelevel Cats](http://typelevel.org/cats/)
- [Discipline](https://github.com/typelevel/discipline)
- [ScalaCheck](https://www.scalacheck.org/)
- [Generic Iterant Implementation](https://github.com/monix/monix/pull/280)
- [Simplified Task-based Implementation](https://github.com/monix/monix/pull/331)

## Abstract

Designing functionality that exhibits the properties of functional
programming is hard because it requires a mentality change, coping
with immutability and consideration for recursion, performance and
polymorphism. This talk is a lesson in FP design that makes use of
Scala’s hybrid OOP+FP nature.

We are going to start from Scala’s (and Java’s) ubiquitous
Iterator/Iterable types which expose the famous iterator pattern,
analyzing its strengths and weaknesses. And then we are going to work
our way up to a fully featured FP replacement that has referential
transparency and that fixes everything that’s wrong with Iterator,
while being more generic.

This lesson in design involves talking about immutability, imperative
programming, asynchrony and problems encountered when going FP, like
performance considerations, recursion and memory leaks. We are also
going to talk about ADTs, higher kinded polymorphism and type-classes
versus OOP subtyping. Interestingly the example presented will use
both OOP subtyping and type-classes and thus we can make a clear
comparison about what to use and when - a problem that the Scala
developer has in his daily work.
