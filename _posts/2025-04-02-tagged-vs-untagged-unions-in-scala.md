---
title: "Tagged vs Untagged Unions (in Scala)"
date: 2025-04-02T11:30:19+03:00
last_modified_at: 2025-04-02T12:32:15+03:00
image: /assets/media/articles/2025-untagged-types.png
image_hide_in_post: true
tags:
  - Scala
  - Scala 3
  - Programming
description: >
  What's the difference between `Option[A]` and `A | Null`? What about between `Either[A, B]` and `A | B`?
---

<p class="intro" markdown=1>
What's the difference between `Option[A]` and `A | Null`? How about between `Either[A, B]` and `A | B`?
</p>

Scala has had the [Option](https://scala-lang.org/api/3.x/scala/Option.html) data-type for dealing with `null` values:

```scala
val person: Option[Person] = ???

// You can pattern match on it:
person match {
  case Some(e) => updateState(e)
  case None => doNothing
}

// You can combine it with other values, sequentially:
for {
  p <- person
  a <- p.address
  t <- transaction
} yield updateState(a, t)

// ... or in parallel (with the ability to get all error messages):
import cats.syntax.all.*

(person, transaction).mapN { (p, t) =>
  updateState(p, t)
}
```

The big benefit of `Option` is that it's a "monadic type", which also has to do with the fact that it's a "boxed" type, meaning that `Option[Option[T]]` is not the same as `Option[T]`. This is very important, as that means that `Option` has predictable behaviour (it's lawful), and can be used in instances in which `Option[Option[T]]` makes sense:

```scala
case class Person(
  name: String,
  address: Option[Address]
)

// For an HTTP PATCH, if a field is provided, it should be 
// updated, otherwise, if `None`, then the old value is kept.
case class PersonHttpPatchRequest(
  name: Option[String],
  address: Option[Option[Address]]
)
```

Scala 3 also has `A | Null` as a type, with the [explicit-nulls](https://docs.scala-lang.org/scala3/reference/experimental/explicit-nulls.html) compiler option being required to make it useful. This is similar to what [Kotlin provides](https://kotlinlang.org/docs/null-safety.html), the so-called `A?`, although slightly less mature.

The downside of `A | Null` is that it's not a monadic type. It's not lawful in the same way as `Option` is. And that's because it's not a boxed type. `A | Null | Null` is the same as `A | Null`. Therefore, this no longer works: 

```scala
case class Person(
  name: String,
  address: Address | Null
)

// Oops! This isn't right:
case class PersonHttpPatchRequest(
  name: String | Null,
  address: String | Null | Null
)
```

Another downside is that you can't really use `A | B` for expressing `Either[Error, Result]`. This is because you don't know which is the error and which is the result.

```scala
trait Parser[A] {
  // Doesn't work as `parse` could produce a `Right(ParseError)`, 
  // after all, I can't see why errors shouldn't be serializable 
  // and deserializable.
  def parse(input: String): ParseError | A 
}
```

The `A | B` type is auto-flattening because `A | B` is a supertype of `A`, meaning that `A <: A | B` and `B <: A | B`. So `A | Null | Null` is the same as `A | Null`, which is a supertype of `A`.

This has 2 advantages:
1. Scala is an OOP language, and we care about the variance of type parameters, so `A | B` is better than `AA >: A` in the type signature of methods.
2. `A | Null` being a supertype it means that using it can preserve backwards-compatibility.

For the first point, consider this:

```scala
// we've got a covariant type parameter
sealed trait List[+A] { 

  def prepend1[B >: A](value: B): List[B] = ???

  def prepend2[B](value: B): List[A | B] = ???
}
```

Which of these two methods is better? IMO, it's the second one because it's more expressive, whereas the first one is losing information. In fairness, the Scala compiler can and probably does infer that `B >: A` can be `A | B`, so we're essentially comparing Scala 2 with Scala 3 here. And I'd rather talk about a `List[Int | String]`, for example, than a `List[Any]`.

For the second point, given these methods:

```scala
// For testing contra-variance
def foo(value: A): B
```

If we change its signature to using `A | Null`, then we aren't breaking compatibility, because all the call sites still work:

```scala
// Contra-variance, still compatible
def foo(value: A | Null): B

// ....
// Still works in all the older code
val a: A = ???
foo(a) 
```

But if we'd use `Option[A]` instead, we'd break source and binary compatibility, which is especially problematic on the JVM due to all the dynamic linking of transitive dependencies:

```scala
def foo(value: Option[A]): B

// ...
// This now breaks
val a: A = ???
foo(a) // Error
```

Of course, the old fashioned way of dealing with this is to use method overloading, assuming you can do it, because there are cases in which it doesn't due to type erasure:

```scala
def foo(value: A): B = foo(Some(value))
def foo(value: Option[A]): B
```

Also, it wouldn't work for return types, so for example:

```scala
// If we are forced to keep this signature
def foo(value: A): Option[B]

// We can't add an overload like this
def foo(value: A): B
```

So there you have it. Currently, there's no free lunch and I actually like both.
