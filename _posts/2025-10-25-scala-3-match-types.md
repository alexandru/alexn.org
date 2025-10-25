---
title: "Scala 3 / Match Types"
image: /assets/media/articles/2025-scala-match-types.png
image_hide_in_post: true
mathjax: true
tags:
  - Scala
  - Scala 3
  - Programming
description: >
  Scala has a neat new feature, resembling TypeScript's "conditional types", but more powerful.
---

<p class="intro" markdown=1>
Scala has a neat feature called [match types](https://docs.scala-lang.org/scala3/reference/new-types/match-types.html). Let's play…
</p>

Here's an example:

```scala
type Head[T] = T match
    case Array[a]        => Option[a]
    case List[a]         => Option[a]
    case String          => Option[Char]
    case NonEmptyList[a] => a
    case Map[k, v]       => Option[(k, v)]
    case k *: v          => k
    case _               => Nothing

def head[T](t: T): Head[T] = t match
    case ref: Array[a] =>
        ref.headOption
    case ref: List[a] =>
        ref.headOption
    case ref: String =>
        ref.headOption
    case ref: NonEmptyList[a] =>
        ref.head
    case ref: Map[k, v] =>
        ref.headOption
    case ref: (k *: v) =>
        ref.head.asInstanceOf[Head[k *: v]]
    case _ =>
        throw new IllegalArgumentException()

// Using it works as expected, with the compiler
// correctly inferring the types in each case:
val v1: Option[Int] =
    head(Array(1, 2, 3))
val v2: Option[String] =
    head(List("a", "b", "c"))
val v3: Option[Char] =
    head("hello")
val v4: Int =
    head(NonEmptyList.of(10, 20, 30))
val v5: Option[(String, Int)] =
    head(Map("a" -> 1, "b" -> 2))
val v6: String =
    head("hello" *: 42 *: true *: EmptyTuple)
val v7: Nothing =
    head(())
val v8: Nothing =
    head(123)
```

The above exposes an ability called [dependent typing](https://en.wikipedia.org/wiki/Dependent_type).

Scala isn't alone in having this ability, here's a TypeScript equivalent using its [conditional types](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html) ([archive](https://web.archive.org/web/20251011202517/https://www.typescriptlang.org/docs/handbook/2/conditional-types.html)), although note that Scala's match types are more powerful (and better looking):

```typescript
// TypeScript code

type Head<T> =
  // Warn: tuples are arrays at runtime
  T extends [infer K, ...infer _] ? K :
  T extends Array<infer A> ? A | undefined :
  T extends string ? string | undefined :
  T extends Map<infer K, infer V> ? [K, V] | undefined :
  never;

function head<T>(t: T): Head<T> {
  if (Array.isArray(t)) {
    // covers arrays and tuples at runtime
    return (t[0] ?? undefined) as Head<T>;
  }
  if (typeof t === "string") {
    return (t[0] ?? undefined) as Head<T>;
  }
  if (t instanceof Map) {
    const it = t.entries().next();
    return (it.done ? undefined : it.value) as Head<T>;
  }
  throw new Error("Unsupported type");
}

// Examples:
const v1: number | undefined =
    head([1, 2, 3]);
const v2: string | undefined =
    head(["a", "b", "c"]);
const v3: string | undefined =
    head("hello");
const v4: [string, number] | undefined =
    head(new Map([["a", 1], ["b", 2]]));
const v5: string = // tuple
    head(["hello", 42, true] as [string, number, boolean]);
```

## Recursivity

Scala's match types can also have _recursive definitions_, so for example:

```scala
type AtomOf[T] = T match
    case Iterable[a] => AtomOf[a]
    case t => t

// These are valid
val x: AtomOf[List[List[String]]] = "atom"
val y: AtomOf[Int] = 42
val z: AtomOf[List[Set[Map[String, Int]]]] = ("key", 1)
```

This makes inferring types related to tuples easier, e.g., straight from that documentation page, we can see that tuple concatenation can be expressed:

```scala
type Concat[Xs <: Tuple, Ys <: Tuple] = Xs match
    case EmptyTuple => Ys
    case h *: t     => h *: Concat[t, Ys]
```

If you want to waste time on things that bring you joy, you can now do type-level arithmetic, even without the awesome utilities in `scala.compiletime.ops.int`, taking inspiration from [Peano's axioms](https://en.wikipedia.org/wiki/Peano_axioms#Addition):

$$
\begin{cases}
a + 0 = a \\
a + Succ(b) = Succ(a + b)
\end{cases}
\implies Succ(a) + b = a + Succ(b)
$$

Which can be expressed almost literally:

```scala
import scala.compiletime.ops.int.S as Succ

type Sum[A <: Int, B <: Int] <: Int =
    A match
        case 0        => B
        case Succ[a0] => Sum[a0, Succ[B]]

val x: Sum[3, 4] = 7 // works
val y: Sum[3, 4] = 8 // fails with a compile-time error
```

As a note, one would think that `Succ` could be defined like this:

```scala
type Succ[A <: Int] <: Int =
    A match
        case 0 => 1
        case 1 => 2
        case 2 => 3
        //...
        case 2147483646 => 2147483647
````

But I couldn't make it work, maybe some kind soul from the Internet could explain why. Thankfully, it's already defined by the Scala standard library at `scala.compiletime.ops.int.S`, and this one works. And note that the Scala library defines types in terms of `S`, with gems such as this one:

```scala
// Standard library
package scala

object Tuple:
    /** Literal constant Int size of a tuple */
    type Size[X <: Tuple] <: Int = X match
        case EmptyTuple => 0
        case x *: xs => S[Size[xs]]

//...
val x: Tuple.Size[(Int, String, Double)] = 3
```

You can just smell the Turing completeness 😁

## Caveat

Match types without exhaustive matches don't really work. And the behavior changed somewhat in later Scala versions. For example, the following would trigger a compile time error in Scala `3.3.7` ([LTS](https://www.scala-lang.org/blog/2022/08/17/long-term-compatibility-plans.html)), but not in the latest `3.7.3`:

```scala
type Head[T] = T match
    case Array[a] => Option[a]
    case List[a]  => Option[a]

def head[T](t: T): Head[T] = t match
    case ref: Array[a] =>
        ref.headOption
    case ref: List[a] =>
        ref.headOption

// ... these calls would trigger compile-time errors in 3.3.7,
// but not in later versions...
head(Iterator(1))
head("a string")
```

The issue here is that `Head[String]`, in the above definition, is not allowed to exist in Scala 3.3.7 (LTS), but is allowed to exist in later versions. For me, this was surprising. But note the LTS is not free of surprises, as this sample compiles just fine on Scala 3.3.7 (LTS), when my intuition suggests it should not:

```scala
class Foo[T](val value: T)

type Unpacked[T] = T match
    case Foo[a] => a

def unpack[T](t: T): Unpacked[T] = t match
    case ref: Foo[a] => ref.value

// No compile-time errors whatsoever, in either versions,
// just runtime  exceptions:
unpack("a string")
unpack(List(1,2,3))
```

The kicker here is that you can make the above fail at compile-time, on Scala 3.3.7 LTS, if you add the `final` keyword to that `Foo`.

```scala
final class Foo[T](val value: T)

type Unpacked[T] = T match
    case Foo[a] => a

// Compile-time error in Scala 3.3.7
// Compilation passes in Scala 3.7.3
unpack("a string")
unpack(List(1,2,3))
```

My shoddy rationalization goes like this: If `Foo` is an open class (a class that can be extended or an interface/trait), it means that `String` could eventually inherit from it in later Java/Scala versions. That's highly unlikely, but the compiler probably has no way of knowing that. But it's a poor rationalization, because TBH, I don't see a problem with upgrades to `String` making `Head[String]` exist. It would be worse if it happened the other way around, IMO. This may be one of those cases in which the compiler team couldn't make it work well, so decided to just shrug. So we'll have to live with it.

**The solution** to the above is to just allow it to exist, by having a `case _ => Nothing` branch:

```scala
type Head[T] = T match
    case Array[a] => Option[a]
    case List[a]  => Option[a]
    case _        => Nothing

// Type allowed to exist, but it reduces to Nothing
def x: Head[String] = throw IllegalArgumentException("Boo")
val y: Nothing = x
```

And keep in mind that this match type is a return type that's equivalent to a "union type" function parameter, which is how you can protect functions:

```scala
type Head[T] = T match
    case Array[a] => Option[a]
    case List[a]  => Option[a]
    case _        => Nothing

// Protecting the function call by using an "untagged union type"
// as the "upper bound" of our type parameter.
def head[T <: Array[?] | List[?]](t: T): Head[T] = t match
    case ref: Array[a] =>
        ref.headOption
    case ref: List[a] =>
        ref.headOption
    case _ =>
        // Note we don't really need this branch, but the compiler
        // can't see it, and it also gives us a really scary compiler
        // error, if we try removing it.
        throw IllegalArgumentException("Boo")
````
