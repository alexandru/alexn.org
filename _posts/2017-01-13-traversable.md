---
title: "Why Scala's Traversable Is Bad Design"
tags:
  - Scala
description:
  Traversable was a design mistake, is redundant and we should remove it.
image: /assets/media/articles/scala.png
---

<p class="intro" markdown='1'>Given there's a
[Scala collection redesign](https://contributors.scala-lang.org/t/ongoing-work-on-standard-collections-redesign/293)
discussion going on, it's a good time to talk about one of my personal pet peeves:
the existence of [Traversable](http://www.scala-lang.org/api/2.12.1/scala/collection/Traversable.html)
in the standard library, along with its variants like `TraversableLike` and `TraversableOnce`.
Apparently this interface is missing in the new design and that's awesome.</p>

It's easy to make API mistakes, we all do it and it's important to
learn from past mistakes, this document serving as a lesson for why
`Traversable` is a bad idea.

Claims:

1. `Traversable` has implicit behavior assumptions that are not visible
   in its exposed signature, the API being error prone
2. Iterating over a `Traversable` has worse performance than `Iterator`
3. There exists no `Traversable` data type that doesn't admit an efficient
   `Iterator` implementation, thus `Traversable` being completely redundant

As a reminder and you can also
[read the docs](http://docs.scala-lang.org/overviews/collections/trait-traversable.html),
the `Traversable` is a trait like the following:

```scala
trait Traversable[+A] {
  def foreach(f: A => Unit): Unit
}
```

The standard library also has the venerable `Iterable` / `Iterator`:

```scala
trait Iterable[+A] {
  def iterator(): Iterator[A]
}

trait Iterator[+A] {
  def hasNext: Boolean
  def next(): A
}
```

Can you spot the similarities?

You should, because these 2 interfaces are supposed to be
[duals](https://en.wikipedia.org/wiki/Duality_(mathematics)).
So if you think of `Traversable` as being defined by that
`foreach` function, then `Iterable` is that function with
its arrows reversed:

```scala
type Traversable[A] = (A => ()) => ()

type Iterable[A] = () => (() => A)
```

Now this is interesting. For one `Traversable` is a sort of
inversion of control technique, so instead of having a cursor
that you have to manually advance, you now register a callback to
a function and that callback gets called for you on each element.
This actually frees us from certain `Iterator` constraints.
For example with a push-based API we should no longer care when
those function calls happen.

But you should already spot problems with the above
definition. Our `Iterable` function signature isn't complete,
this one is:

```scala
type Iterable[+A] = () => Iterator[A]

type Iterator[+A] = () => Try[Option[A]]
```

Or in other words any `Iterator` can:

1. give us the next element,
2. or signal completion or failure

This means that the actual dual of `Iterator` is:

```scala
type Observer[A] = Try[Option[A]] => Unit
```

Or for those OOP-oriented among us, I give you the `Observer`
as championed by [Rx.NET](https://github.com/Reactive-Extensions/Rx.NET),
as the true dual of `Iterator`:

```scala
trait Observer[-A] {
  def onNext(a: A): Unit
  def onComplete(): Unit
  def onError(ex: Throwable): Unit
}
```

(Hello **[Monix](https://monix.io/)** :-))

This matters because `Traversable` has **no way to signal completion or failure**,
unless you get a guarantee that all the processing happens synchronously, everything
being over after the invocation of its `foreach`.

As an abstraction, this makes it useless when compared with `Iterable`
and `Iterator`. If you introduce the synchronous execution constraint,
there exists no data type that can implement `Traversable` and that doesn't
admit an `Iterator` implementation. None.

Even more problematic in my opinion is that this restriction isn't
visible in its API, unless your eyes are trained for it. With
`Iterator.next()` whether you want it or not, you have to process things
synchronously, because *the signature says so*.

Also problematic is `TraversableOnce`, which is supposed to be a
traversable that can only be traversed once, like its name says.
We've got this:

```scala
trait TraversableOnce[+A] {
  def foreach(f: A => Unit): Unit
}

trait Traversable[+A] extends TraversableOnce[A]
```

Besides the name and the inheritance relationship, there is no difference.
This is another problem. Even if the API is effectful/impure, we should still
be able to use types serving as documentation. Contrast with the
`Iterable` / `Iterator` separation. Iterating over an `Iterator` is known to
consume it and you can see this in its API. And the generator/factory part is in
`Iterable`, which is good separation of concerns.

`Traversable` also has worse performance than `Iterator`.
The ugly truth is that the JVM hasn't been doing a good job at
inlining that function reference you pass to `foreach`. This is called
[the inlining problem](http://www.azulsystems.com/blog/cliff/2011-04-04-fixing-the-inlining-problem),
which happens for megamorphic function calls in hot inner loops.

So there you have it and I hope that along with the redesign we'll get rid
of `Traversable`.

<p class='info-bubble' markdown='1'>
My opinions have been highly influenced by the work of Erik Meijer,
if you want to learn more checkout this presentation:

[Contravariance is the Dual of Covariance Implies Iterable is the Dual of Observable](https://vimeo.com/98922027).
</p>
