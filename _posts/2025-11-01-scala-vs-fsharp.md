---
title: "Scala vs F#"
date: 2025-11-01T08:58:37+02:00
last_modified_at: 2025-11-02T08:09:06+02:00
image: /assets/media/articles/2025-scala-vs-fsharp.png
image_caption: >
  Scala logo on the left, F# logo on the right.
tags:
  - FP
  - Scala
  - FSharp
  - JVM
  - dotNet
description: >
  Which language leans more towards functional programming? In this binary choice, people have perceived F# to be that language, due to its ML roots, but I have a different perspective... 
---

<p class="intro">
  Which language leans more towards functional programming? In this binary choice, people have perceived F# to be that language, due to its ML roots, but I have a different perspective... 
</p>

<p class="warn-bubble" markdown="1">
**Before bringing your pitchforks:** I'm an expert in Scala, but I only have superficial experience with F#, so take this opinion for what it is. I also think both languages are great, and this is just an opinion on which one I prefer.
</p>

F# is a wonderful language, and the primary choice between Scala and F# would actually be driven by your preferred choice of platform and ecosystem (JVM vs .NET). That being said,

Scala is actually a more “functional” language than F# because it wins in the expressiveness and the FP culture departments.

First, in Scala, you can work with higher-kinded types and type classes. To understand why that’s important, consider that Scala does not need .NET’s flavor of reification for generics because what it has is far more potent. These are features that Don Syme [has been explicitly against](https://github.com/fsharp/fslang-suggestions/issues/243#issuecomment-916079347) because, according to him, it complicates the type system. This is partially true, I'm actually inclined to agree; however, in my experience, the actual problems in programming come from elsewhere, code reuse and static type-safety being good. And I’d also argue that this opinion against type-classes and higher-kinds may also be due to bias, with .NET itself making higher-kinds more complicated due to its runtime-based reification (you can do type-erasure on .NET, but people and libraries expect reification, which would mean interop would suffer). The irony of .NET's original marketing is that the JVM has been an easier-to-target platform for languages that are not Java or C#.

To give an example of a type-class in action:

```scala
// Scala 3
def sumList[A](list: List[A])(using Numeric[A]): A =
    val n = summon[Numeric[A]]
    list.foldLeft(n.zero)(n.plus)
```

I hope I’m not getting this wrong, it’s been a while since I worked with F#, but its standard library does something like this, which isn’t something you actually see in common code:

```fsharp
// F#
let inline sumList (list: ^T list) : ^T 
    when ^T : (static member (+) : ^T * ^T -> ^T) 
    and ^T : (static member Zero : ^T) =
    List.fold (+) LanguagePrimitives.GenericZero list
```

To note:
- Scala's version is a simple function making use of implicit parameters, `Numeric` being a type-class;
- F#'s version is an `inline` function (due to adding restrictions not natively supported by .NET), and the restrictions refer to "static members" — note that Scala no longer has the notion of "static methods" in the language (although the JVM does).

You can express this in the latest C#, actually, as they’ve added *"abstract static methods"* ([link](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/proposals/csharp-11.0/static-abstracts-in-interfaces)), which are frowned upon in F#, the general advice for F# devs being to steer clear of them, unless they need it for interop. So, C# almost has type classes.

```csharp
// C#
interface INumeric<T> where T : INumeric<T>
{
    static abstract T Zero { get; }
    static abstract T Plus(T a, T b);
}

static T SumList<T>(List<T> list) where T : INumeric<T>
{
    return list.Aggregate(T.Zero, (acc, x) => T.Plus(acc, x));
}
```

But, let’s go one more level — we can work on any list-like type, that we can express as a type parameter, and note that working with a generic type restricted to implementing `Foldable` is different in nature to using `Iterable` / `Enumerator` (OOP subtyping):

```scala
// Scala 3
import cats.Foldable
import cats.syntax.all.given

def sumAll[F[_], A](list: F[A])(using Foldable[F], Numeric[A]): A =
    val n = summon[Numeric[A]]
    list.foldLeft(n.zero)(n.plus)

// Now it works for any sequence
sumAll(Vector(1,2,3))
sumAll(List(1,2,3))
sumAll(Array(1,2,3))
```

The true power of higher-kinds manifests when we have to keep that list type in the returned value, something that OOP subtyping (or .NET's generics reification) can't achieve:

```scala
// Scala 3
import cats.{Foldable, MonoidK}

def flatten[F[_], A](list: F[F[A]])(using Foldable[F], MonoidK[F]): F[A] =
    val m = summon[MonoidK[F]]
    list.foldLeft(m.empty[A])(m.combineK)

// Note how the type gets preserved
val l1: List[Int] = 
    flatten(List(List(1,2,3), List(4,5,6)))
val l2: Array[Int] =
    flatten(Array(Array(1,2,3), Array(4,5,6)))
```

And there's a lot more to talk about here, such as the ability to auto-derive type-class instances, which in Scala is great. For instance, in Scala, you can develop something like [Kotlin Serialization](https://kotlinlang.org/docs/serialization.html) as a library, a library that can work for basic needs and that's very type-safe, in a day. You don't even need macros for it, unless you want customizability (e.g., by annotations).

This difference is not only academic, manifesting itself for example in F#'s [AsyncSeq](https://github.com/fsprojects/FSharp.Control.AsyncSeq), which is a library combining `Async` with `Seq`. This is nice and all, but in Scala, all the features in this `AsyncSeq` are expressed more generically in the [Typelevel Cats](https://typelevel.org/cats/) library, increasing reuse for other types. To make a comparison, it’s like in Go, when people needing generics were simply duplicating the code for all the types they care about. This arguably works for some common cases, but also sucks.

F# does have Hindley-Milner type inference, however, it only works as long as OOP subtyping isn’t involved, and due to its .NET interop and dependence, it has a lot of OOP subtyping. Hindley-Milner in general, being a type system with global type inference, makes error messages hard to read and understand, although, granted, this is more relevant in languages with more advanced type systems. Even in languages with HM (e.g., Haskell), the general advice is for public functions to have explicit types; otherwise the contract exposed is fragile. And also, the more advanced the type system, the more difficult HM becomes. For example, the more advanced features of Haskell you use, the more HM breaks down. See also Idris, in which type inference is undecidable in general.

I always felt that this is a general problem with F#, inspired by two separate worlds, and not trying hard enough to combine them. For example, its generic types can have restrictions that can’t be expressed in .NET (like in the `sumList` above). Therefore, to use them, you can only use `inline` functions, which are functions that are not seen by the .NET runtime, so they can’t be passed around as *values*. In fairness, Scala 3 makes heavy use of `inline` functions as well, for compile-time magic and macros, but in Scala you can use inline functions to reify types and then expose any compile-time information to normal functions, via implicit parameters. So it doesn't have the mixture I've felt while using F#.

F# has a sort of mixed personality to it, not trying too much to mix the functional aspects with OOP, like Scala or OCaml are trying. This can be considered a feature, except, one interacts with .NET and OOP *a lot* in F#, more than in your typical Scala FP project (IMO, YMMV). To give one example, when I last tried, in F# serialization was still done using runtime reflection, whereas in Scala we have libraries like [Circe](https://github.com/circe/circe) which work entirely at compile-time, providing static type-safety, and exposing a very FP API. If you compare .NET's solutions for serialization with Java's Jackson, for sure, .NET wins due to generics reification, but if you compare .NET with Scala's solutions, or even with Kotlin's Serialization, it leaves something to be desired (in the type-safety department, at least).

Back to the FP aspects, Scala has a very healthy ecosystem of FP libraries. FP has been so successful in Scala that it ended up with two mature and competing ecosystems for it, i.e. [Typelevel](https://typelevel.org/) and [ZIO](https://zio.dev/). Scala has one of the best books on FP around: [FP in Scala](https://www.manning.com/books/functional-programming-in-scala-second-edition). And it has also inspired other ecosystems, see [Effect](https://github.com/Effect-TS/effect).

Note that there are aspects of F# that I like. Off the top of my head, I can think of:

* [Type providers](https://learn.microsoft.com/en-us/dotnet/fsharp/tutorials/type-providers/) — you could build something similar in Scala in a library, actually, however it’s challenging, and I haven’t seen something polished yet; 
* [Computation expressions](https://learn.microsoft.com/en-us/dotnet/fsharp/language-reference/computation-expressions) — Scala has “for comprehensions”, but F#'s computation expressions are more evolved; this is for working with "monadic" or "applicative" types, but note that Scala also has plans to go the way of Kotlin and provide [direct style support](./2025-08-29-scala-gamble-with-direct-style.md) (thus providing an alternative to monads because it was too boring before 😜);
* [LINQ support](https://learn.microsoft.com/en-us/dotnet/fsharp/language-reference/query-expressions) — Scala has had libraries that are equivalent, such as [Quill](https://github.com/zio/zio-protoquill), and while it's nice that in Scala we can bring the full power of LINQ as a library, I also feel that proper support needs to be baked into the language, or it's forever plagued with issues;
* [Active patterns](https://learn.microsoft.com/en-us/dotnet/fsharp/language-reference/active-patterns), although Scala’s pattern matching is quite nice, too.

F# also has features that Scala can do better, but that are nice to have regardless, and worth mentioning, such as “units of measure” or “code quotations”.

F# resembles Python, in the sense that its designers have introduced features to solve concrete use-cases. But, just like in Python, it has features that don’t feel orthogonal or very generic; in Python, for instance, I can think of several features that were added to avoid adding multi-line lambdas. So much for the *"one way of doing things"*.

But overall, F# is a language I would enjoy very much, if I wanted to target .NET. And .NET can be … an acquired taste.

I’ve always preferred the Java ecosystem because it has always been closer in spirit and culture to Linux and Open-Source. This has pros and cons. .NET feels more like a cathedral and Java feels more like a bazaar. In terms of ecosystem, the difference is night and day. For instance, Oracle has a lot of power, as they still develop and own Java, but they don't provide the IDE or the libraries or the tooling most people use. They don't even have the most popular OpenJDK distribution. And if they stop being good stewards, OpenJDK can get forked, as they aren't the only contributors to it. I like having competition, choices, communities (plural), instead of having Microsoft impose its solution du jour.

The JVM also has had a great evolution, in some ways leapfrogging .NET (e.g., runtime optimizations, the “pauseless” GC implementations Project Loom, GraalVM), and in some ways closing the gaps (upcoming Valhalla, which finally brings value types and maybe generics specialization). There's still plenty of healthy competition going on. .NET going for 'abstract static methods', being close to type-classes, is forcing Java to push for [type-classes support](https://youtu.be/Gz7Or9C0TpM). Fun times.

People do have good reasons to love the .NET ecosystem as well, since it has evolved a lot, too. It's now open-source, multi-platform, performant, and it's still the preferred high-level platform for games — which is why I may teach my son some C# or F# 😁
