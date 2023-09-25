---
title: "OOP classes vs Higher-order Functions (HOFs)"
image: /assets/media/articles/2023-oop-hof.png
date: 2023-09-24 17:47:35 +03:00
last_modified_at: 2023-09-25 10:30:01 +03:00
tags:
  - FP
  - OOP
  - Scala
description: >
  What's the difference?
social_description: >
  What's the difference?
---

<p class="intro">
  What's the difference between OOP classes and Higher-order Function (HOF)?
</p>

Here's an abstract OOP class:

```scala
abstract class MyComponent[I, O] {
  // Abstract methods
  def foo(input: I): I
  def bar(input: I): O

  // Inherited implementation
  final def apply(input: I): O = {
    // Implementation doesn't matter
    val i = foo(input)
    bar(i)
  }
}
```

Here's an equivalent "final" OOP class:

```scala
final class MyComponent[I, O](
  foo: I => I,
  bar: I => O
) {
  def apply(input: I): O = {
    // Same implementation as above
    val i = foo(input)
    bar(i)
  }
}
```

And here's an equivalent Higher-order Function (HOF):

```scala
def process[I, O](foo: I => I, bar: I => O)(input: I): O = {
  // Same implementation as above
  val i = foo(input)
  bar(i)
}
```

There is no difference between these 3 implementations, conceptually they are the same thing, exposing the same complexity. Maybe you heard that OOP inheritance is bad, but if you're implementing a HOF, or a final class like the above, it's the same thing.

Well, OK, the `abstract class` has some gotchas, and all of them are about breaking the [Liskov Substitution Principle](https://en.wikipedia.org/wiki/Liskov_substitution_principle).

## Gotcha 1: Overriding of non-final methods

Let's say that our `process` method is non-final. And we override it such that `foo` is never called:

```scala
class Blah[I, O] extends MyComponent[I, O] {
  def foo(input: I): I = ???
  def bar(input: I): O = ???

  override def process(input: I): O =
    bar(i)
}
```

Well, this would break an implicit, possibly undocumented contract that clients may rely on. Imagine that this class generates pseudo-random numbers, and overriding `process` would make the output non-random.

This breaks the "Liskov substitution principle" because the derived class no longer behaves like the inherited class. This is why methods should be non-final with intention. So *make methods final by default*. C++, C# and Kotlin actually [got this right](https://www.artima.com/articles/versioning-virtual-and-override), as in these langauges you have to be explicit about which methods can be overriden (e.g., `virtual` in C++/C#, `open` in Kotlin).

## Gotcha 2: Discrimination based on runtime type (instanceOf)

`instanceOf` checks and OOP [downcasting](https://en.wikipedia.org/wiki/Downcasting) makes it possible to break encapsulation and discriminate, client-side, based on what "type of component" you have. `instanceOf` on open OOP classes (non-sealed) is an antipattern that's going to come back to haunt you. Imagine we have this real-world example:

```scala
class ParsingException(message: String) extends Exception(message)
```

But we need to add information to caught exceptions, like an `operationName: String`, so we define this:

```scala
class ExceptionWithDetails(
  operationName: String,
  cause: Throwable,
) extends Exception(cause.getMessage, cause)
```

Well, what happens if another part of our code does something like this:

```scala
def clasifyException(e: Throwable): ExceptionType =
  e match {
    case _: ParsingException => Input
    case _: TimeoutException => ServiceNotAvailable
    case _                   => Unknown
  }
```

In this case, wrapping `ParsingException` in `ExceptionWithDetails` would break the logic of `clasifyException`. Using `instanceOf` checks on `Throwable` clearly means that you know something about the implementation. And this is an [encapsulation](https://en.wikipedia.org/wiki/Encapsulation_(computer_programming)) violation. I'm not being entirely fair here, because Java's Exceptions are meant to be used like this, and at least they have a standard `cause` in their API that you can use for wrapping and unwrapping exceptions.

Here's another example:

```scala
trait ExecutionContext {
  def execute(r: Runnable): Unit
  def reportFailure(e: Throwable): Unit
}

final class SafeExecutionContext(ec: ExecutionContext) {
  def execute(r: Runnable): Unit =
    try ec.execute(r)
    catch { case e: Throwable => ec.reportFailure(e) }

  def reportFailure(e: Throwable): Unit =
    ec.reportFailure(e)
}
```

This way of adding behavior by wrapping classes is actually a best practice (composition over inheritance!). But clearly, by wrapping any `ExecutionContext` into a `SafeExecutionContext`, access to the runtime type of the wrapped implementation becomes inaccessible, so any discrimination you make via `instanceOf` is error-prone. The "composition over inheritance" principle makes `instanceOf` checks error-prone.

It would have been great if Scala had a linting option that banned `instanceOf` checks (pattern matching included) on open types (with the possibility to override, of course).

## So, HOFs versus OOP classes?

I haven't talked about side effects. Classes are great at encapsulating shared mutable state. But capturing mutable state in closures is trivial, so that's not an argument.

On what to choose ... it doesn't matter.

The problem all of them have is one of complexity. Those functions, taken as parameters, need clearly defined contracts, otherwise the user can unknowingly break such implicit contract. Which is why in code-bases that do this, people basically copy-paste the original call-site. Defining a set of functions with a clearly defined contract can clearly be done ... with better types, with a provided TCK, or via documentation. Having some algebraic reasoning in there would be great. But it's not trivial.

Passing functions as arguments, or implementing them while inheriting from an abstract class, is most often done for *implementation reuse*. I prefer the reuse of well encapsulated components with APIs that make them usable in multiple scenarios, instead of the reuse of implementation details. Or in other words, if we are talking of OOP, I prefer the reuse of `final` classes that don't take functions as parameters. And when functions take functions as parameters, well, they need clearly defined laws. But granted, this isn't an easy thing to do, as it's like telling people to design good microservices.

Of course, many times, you just gotta do what you gotta do. Implementation reuse is better than no reuse.
