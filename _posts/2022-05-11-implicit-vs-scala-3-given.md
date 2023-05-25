---
title: "Implicit vs Scala 3's Given"
image: /assets/media/articles/scala-3-given.png
image_hide_in_post: true
tags: 
  - FP
  - Programming Rant
  - Scala
  - Scala3
description: >
  I don't like `given`, as an alternative to `implicit` in Scala 3. The more I try working with it, the more it annoys me; and my understanding may be superficial, but I don't like this direction. Here's a comparisson between `given` and `implicit`, that I hope is fair...
---

<p class="intro withcap" markdown=1>
I don't like `given`, as an alternative to `implicit` in <nobr>Scala 3</nobr>. The more I try working with it, the more it annoys me; and my understanding may be superficial, but I don't like this direction. Here's a comparisson between `given` and `implicit`, that I hope is fair...
</p>

<p class="info-bubble" markdown=1>
This article uses Scala `3.1.2`, which is the most recent version at the time of writing. I just played around, and may have an incomplete understanding — so instead of doing thorough research, I prefer to complain, in order to have others jump in and correct my misunderstandings 😜 Take this with a grain of salt.
</p>

## Evaluation

Let's define a type-safe alias for representing email addresses,
and we'd like to implement [cats.Show](https://typelevel.org/cats/typeclasses/show.html)
and [cats.Eq](https://typelevel.org/cats/typeclasses/eq.html).

In Scala 2.13 we'd define the *"type-class instances"* in the class's 
[companion object](https://docs.scala-lang.org/overviews/scala-book/companion-objects.html), like so:

```scala
package data

import cats._
import cats.syntax.all._

final case class EmailAddress(value: String)

object EmailAddress {
  implicit val show: Show[EmailAddress] = {
    println("Initializing Show")
    v => v.value
  }

  implicit val equals: Eq[EmailAddress] = {
    println("Initializing Eq")
    (x, y) => x.value === y.value
  }
}
```

If we'd like to use these instances, they are available in the 
"global scope", so we can do:

```scala
package main // another package

import cats.syntax.all._
import data.EmailAddress

object Main extends App {
  val email = EmailAddress("noreply@alexn.org")

  println("------")
  println(s"Show: ${email.show}")
  println(s"Is equal to itself: ${email === email}")

  println("\nMemoized?\n-------")
  println(s"show: ${implicitly[Show[EmailAddress]] == implicitly[Show[EmailAddress]]}")
  println(s"equals: ${implicitly[Eq[EmailAddress]] == implicitly[Eq[EmailAddress]]}")
  println()
}
```

Which would print:

```
Initializing Show
Initializing Eq
------
Show: noreply@alexn.org
Is equal to itself: true

Memoized?
-------
show: true
equals: true
```

Let's switch to `given`, which should replace the `implicit` flag on these instances. In the official [Scala 3 documentation](https://docs.scala-lang.org/scala3/reference/contextual/givens.html), the `given` definitions are given outside the companion object, like so:

```scala
//...

final case class EmailAddress(value: String)

given show: Show[EmailAddress] = {
  println("Initializing Show")
  v => v.value
}

given equals: Eq[EmailAddress] = {
  println("Initializing Eq")
  (x, y) => x.value === y.value
}
```

This is because in Scala 3 the "package objects" don't need syntax, so you can just dump such definitions in a file.  There's just one problem — these instances are no longer global, so when we try compiling our project, the compiler now says:

```
[error]    |no implicit argument of type cats.Show[example.EmailAddress] was found for parameter e of method implicitly in object Predef
[error]    |
[error]    |The following import might fix the problem:
[error]    |
[error]    |  import example.show
```

Well, there is one thing about Scala 3 that I love here: the errors on missing implicits are awesome, because they suggest the possible imports ❤️

But if you want global visibility, and you should, you still have to place them in a companion object; so the official documentation is a little confusing right now.

```scala
//...

final case class EmailAddress(value: String)

object EmailAddress {
  given show: Show[EmailAddress] = {
    println("Initializing Show")
    v => v.value
  }

  given equals: Eq[EmailAddress] = {
    println("Initializing Eq")
    (x, y) => x.value === y.value
  }
}
```

Now it works, but there's a difference:

```
------
Initializing Show
Initialized: noreply@alexn.org
Initializing Eq
Equal to itself: true

Memoized?
-------
show: true
equals: true
```

These `given` instances are defined as `lazy val`, in fact. The documentation even has this sample:

```scala
given global: ExecutionContext = ForkJoinPool()
```

Kind of makes sense for this to be lazily evaluated, but consider how you'd define this value in Scala 2.x:

```scala
implicit lazy val global: ExecutionContext = ForkJoinPool()
```

To me, in a strictly evaluated language like Scala, this definition is much clearer, whereas the `given` definition "complects" storage / evaluation, which to me is a separate concern. In a language like Scala, how our values get initialized is a pretty big problem that we always care about.

But wait, is a `given` always a `lazy val`? What if we add a type parameter?

```scala
final case class EmailAddress(value: String)

object EmailAddress {
  //...
  // Forcing a type parameter that doesn't do anything:
  given equals[T <: EmailAddress]: Eq[T] = {
    println("Initializing Eq")
    (x, y) => x.value === y.value
  }
}
```

As you're probably going to guess, the answer is no — adding a 
simple type parameter turns this `given` definition into a `def`,
so now we get this output:

```
------
Initializing Show
Initialized: noreply@alexn.org
Initializing Eq
Equal to itself: true

Memoized?
-------
show: true
Initializing Eq
Initializing Eq
equals: false
```

This isn't obvious at all, because in fact the object reference 
for this `Eq` instance could be reused, this being perfectly safe:

```scala
object EmailAddress {
  //...
  given equals[T <: EmailAddress]: Eq[T] = 
    // This cast is perfectly safe due to 
    // contra-variance of function parameters 😉
    eqRef.asInstanceOf[Eq[T]]

  private val eqRef: Eq[EmailAddress] = {
    println("Initializing Eq")
    (x, y) => x.value === y.value
  }
}
```

Well, compare and contrast with usage of `implicit`:

```scala
implicit def equals[T <: EmailAddress]: Eq[T]
```

Which signature is easier to read?

But what if we don't want the `lazy val`? What if we always want the behavior of a `def`? The `lazy val` implies synchronization behavior that we may want to avoid.

Scala 3 supports an `inline` keyword, which is pretty cool, and does what you'd expect:

```scala
//...
object EmailAddress {
  //...
  inline given equals: Eq[EmailAddress] = {
    println("Initializing Eq")
    (x, y) => x.value === y.value
  }
}
```

But that's not quite the same as a `def`. Inlining functions is cool, sometimes, for performance reasons, but other times [the effects are unpredictable](https://en.wikipedia.org/wiki/Inline_expansion#Effect_on_performance) and should be used with care.

Compare and contrast:

```scala
implicit def equals: Eq[EmailAddress]
```

In this context, the only advantage of using `given` is in eliminating the name of those values:

```scala
object EmailAddress {
  given Show[EmailAddress] =
    v => v.value

  given Eq[EmailAddress] =
    (x, y) => x.value === y.value
}
```

Sure, this looks cool. Kind of a high price to pay though. And there's more ...

## Final

Consider this example:

```scala
final case class TypeInfo[T](
  typeName: String,
  packageName: String,
)

trait Newtype[Src] {
  opaque type Type = Src

  implicit val typeInfo: TypeInfo[Type] = {
    val raw = getClass
    TypeInfo(
      typeName = raw.getSimpleName.replaceFirst("[$]$", ""),
      packageName = raw.getPackageName,
    )
  }
}

object FullName extends Newtype[String] {
  // Override, as the default logic may not be suitable;
  override implicit val typeInfo =
    TypeInfo(
      typeName = "FullName",
      packageName = "example",
    )
}
```

I'm using this same pattern in [monix/newtypes](https://github.com/monix/newtypes), this being an instance in which an implicit value is provided by a trait, but we leave the possibility of overriding it, and for good reasons.

What if we'd use `given`?

```scala
trait Newtype[Src] {
  opaque type Type = Src

  given typeInfo: TypeInfo[Type] = {
    val raw = getClass
    TypeInfo(
      typeName = raw.getSimpleName.replaceFirst("[$]$", ""),
      packageName = raw.getPackageName,
    )
  }
}
```

Well, that doesn't work, because the declared `given` is a `final` member, therefore we can no longer override it:

```
[error] -- [E164] Declaration Error: ...
[error] 22 |  override implicit val typeInfo =
[error]    |                        ^
[error]    |error overriding given instance typeInfo in trait Newtype of type example.TypeInfo[example.FullName.Type];
[error]    |  value typeInfo of type example.TypeInfo[example.FullName.Type] cannot override final member given instance typeInfo in trait Newtype
```

So finally, this:

```scala
given typeInfo: TypeInfo[Type]
```

Is actually equivalent with this:

```scala
implicit final lazy val typeInfo: TypeInfo[Type]
```

Yikes; that's not obvious 😏

## Vocabulary

The [documentation](https://docs.scala-lang.org/scala3/reference/contextual/givens.html) can definitely improve, but I don't think the documentation is the problem.

As a **vocabulary preference**, I don't see how `given` makes things easier to understand, especially for beginners, but this is a subjective opinion, and it may be a matter of learned taste. It's exactly the same concept, though, using `given` and `using` does not make things easier to understand, unless the power of implicits is limited, implicits being hard to understand due to their power, not due to their naming. And I don't see how beginners could be given an explanation that doesn't use the term *"implicit parameters"*, something that *"givens"* obscures. But I concede that I may lack imagination for teaching 🤷‍♂️

I will argue that the existence of both `implicit` and `given` introduces more Perl-like [TIMTOWTDI](https://en.wikipedia.org/wiki/There%27s_more_than_one_way_to_do_it), but in a bad way (I'm saying this as a guy that loves TIMTOWTDI, usually). If `given` is the future, I'd like to say that `implicit` should be deprecated, but given the current behavior of `given`, I hope `implicit` stays 🤨

Does `given` have any redeeming quality that I'm not seeing? Maybe any good design reasons for why it forces the current behavior?
