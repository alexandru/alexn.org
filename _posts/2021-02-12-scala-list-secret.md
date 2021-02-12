---
title: "Scala's List has a Secret"
date: 2021-02-12 13:32:33+0200
image: /assets/media/articles/scala-list.png
image_hide_in_post: true
tags: 
  - FP
  - Multithreading
  - Programming
  - Scala
description: "OOP couples the data with the methods operating on it, and this is considered bad in FP circles. But is it?"
---

OOP couples the "data" with the methods operating on it, and that's considered bad in FP circles, because supposedly data outlives the functions operating on it. Also in static FP circles, dumb data structures are reusable, so it's a good idea to make them generic, and add restrictions on the functions themselves.

Few data structures could be simpler than an immutable `List` definition, right? At least as far as recursive data structures go 🙂 For the standard `List` you'd expect the following:

```scala
sealed abstract class List[+A]

final case class :: [+A](head: A, tail: List[A])
  extends List[A]

case object Nil extends List[Nothing]
```

Oh boy, I've got news for you — this is the actual definition from Scala's standard library:

```scala
sealed abstract class List[+A]

final case class :: [+A](
  head: A, 
  private[scala] var next: List[A @uncheckedVariance]) 
  extends List[A]

case object Nil extends List[Nothing]
```

Yikes, that private `next` value is a `var`. They added it as a `var` such that [ListBuffer](https://www.scala-lang.org/api/current/scala/collection/mutable/ListBuffer.html) can build a list more efficiently, because an immutable `List` is in essence a [Stack](https://en.wikipedia.org/wiki/Stack_(abstract_data_type)), so to build one, you'd need to do an O(n) reversal at the end.

With the pure definition, we'd build `List` values like this:

```scala
def map[A, B](self: List[A])(f: A => B): List[B] = {
  var buffer = List.empty[B]
  for (elem <- self) { buffer = f(elem) :: buffer  }
  // Extra O(n) tax if that list would be pure, no way around it
  buffer.reverse
}
```

But with `ListBuffer`, due to making use of that `var`:

```scala
def map[A, B](self: List[A])(f: A => B): List[B] = {
  val buffer = ListBuffer.empty[B]
  for (elem <- self) { buffer += f(elem)  }
  // O(1), no inefficiency
  buffer.toList
}
```

Contrary to popular opinion, this means `List` does not benefit from `final`'s guarantees by the [Java Memory Model](https://en.wikipedia.org/wiki/Java_memory_model). So it might have visibility issues in a multi-threaded context (e.g. you might end up with a `tail` being `null` when it shouldn't be). Which is probably why we see this in `ListBuffer#toList`:

```scala
override def toList: List[A] = {
  aliased = nonEmpty
  // We've accumulated a number of mutations to `List.tail` by this stage.
  // Make sure they are visible to threads that the client of this ListBuffer might be about
  // to share this List with.
  releaseFence()
  first
}
```

Yikes, they are adding a manual [memory barrier](https://en.wikipedia.org/wiki/Memory_barrier) 😲 I guess it beats a reversal of a list. But this goes to show the necessity of coupling data structures with the methods operating on them.

> FP developers don't care about resources, because of the expectation that resources should be handled by the runtime, but sometimes that isn't possible or optimal — even dumb data structures are resources and sometimes need special resource management, for efficiency reasons. In which case coupling the data with the methods operating on it is healthy 😉
