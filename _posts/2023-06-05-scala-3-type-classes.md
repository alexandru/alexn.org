---
title: "Scala 3's Type Classes"
image:
# image_caption:
# date:
# last_modified_at:
# generate_toc: true
tags:
  - FP
  - Programming
  - Scala
  - Scala 3
description: >
  In Scala, type classes are first-class, and Scala 3 has many improvements. The support for type classes highlights this language's value proposition: compile-time safety and expressiveness. Let's do a deep dive into type classes, and what's new in Scala 3.
---

<p class="intro" markdown=1>
In Scala, [type classes](https://en.wikipedia.org/wiki/Type_class) are first-class[^1], and Scala 3 has many improvements. The support for type classes highlights this language's value proposition: compile-time safety and expressiveness. Let's do a deep dive into type classes, and what's new in Scala 3.
</p>

## Sample: a serialization problem

Let's implement a serialization protocol for logging. We'll define

```scala
//> using scala "3.3.0"

enum LogMessage:
  case OfString(value: String, details: Option[LogMessage])
  case OfList(value: List[LogMessage])
  case OfMap(value: Map[String, LogMessage])
  case OfException(value: Throwable)

trait LogShow[T]:
  extension (t: T)
    def logShow: LogMessage
```

## What are Type Classes?

Scala provides implicit parameters (AKA contextual parameters, AKA given instances and using clauses)[^2], being one of its most fundamental features. If Haskell is the standard for what type-classes should look like, Scala's Implicits are like a superset of type-classes, being more powerful, as you can express more with implicits[^3].

What are implicits? What are type classes? Simply put (but not easy to understand):

> A way to associate types to values, solved at compile-time.

This should be more clear when noticing the signature of `implicitly` (AKA the new `summon` in Scala 3), which is effectively turning types into values. What these functions are saying is *"give me the canonical value for type `T`"*:

```scala raw
// Scala 2
def implicitly[T](implicit e: T): T = e

// Scala 3
transparent inline def summon[T](using x: T): T = x
```

## Full Sample

```scala
#!/usr/bin/env -S scala-cli shebang

//> using scala "3.3.0"

println("Hello!")
```


[^1]: See [First-class citizen](https://en.wikipedia.org/wiki/First-class_citizen) on Wikipedia. Because Scala is a language that supports multiple ways to do polymorphism, most importantly OOP subtyping, the notion that Scala's type classes are first-class can be confusing, but ironically, Scala's type classes are more first-class than Haskell's, as Scala's type-classes are just types, and instances are just values passed around as normal function parameters.
[^2]: See the "[Contextual abstractions](https://docs.scala-lang.org/scala3/reference/contextual/index.html)" chapter in Scala's documentation.
[^3]: The paper ["Type Classes as Objects and Implicits"](https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=d30d65ca9ce7891352024a5c71ebe0ae8c41f7ac) ([archive](https://web.archive.org/web/20230605144555/https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=d30d65ca9ce7891352024a5c71ebe0ae8c41f7ac)) does a good job highlighting that implicits took the essence of type classes, being more powerful.
