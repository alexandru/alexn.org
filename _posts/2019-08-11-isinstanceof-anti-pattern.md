---
title: "Scala's isInstanceOf is an Anti-Pattern"
description: >-
  Scala has a much better way of discriminating between types.
  Scala has implicit parameters, with which you can describe type classes.
tags:
  - Best Of
  - Scala
image: /assets/media/articles/scala-instanceof-antipattern.png
generate_toc: true
---

<p class="intro" markdown="1">
  When you use `isInstanceOf[Class]` checks, that's an anti-pattern, as Scala has a much better way of discriminating between types. Scala has implicit parameters, with which you can describe [type classes](https://en.wikipedia.org/wiki/Type_class).
</p>

<p class='info-bubble' markdown='1'>
  When C# developers try Java, one primary complaint is about the lack of reification for Java's generics and by that they mean the ability to discriminate between different type parameters, so to differentiate between `List[Int]` and `List[String]` via `isInstanceOf` checks. Java and Scala do type erasure so a `List[String]` at runtime becomes a `List[Any]`.
  <br><br>
  Interestingly this complaint is not valid for Scala. Because of Scala's expressiveness, you shouldn't need to do `isInstanceOf` checks, unless it's for interoperability or for awkward micro optimizations that have no place in high level code. Reification is a runtime construct and Scala solves the associated use cases by moving all of that at compile time, via implicit parameters.
</p>

Let's do an exercise ...

## The Anti-Pattern

Given some piece of heavy logic, let's say you want to describe a function that can execute a block of code, along with some finalizer, something like this:

```scala
def guarantee[R](f: => R)(finalizer: => Unit): R =
  try f finally finalizer
```

And usage:

```scala
guarantee {
  println("Executing!")
  1 + 1
} {
  println("Done!")
}
```

Then one of your colleagues comes along and tries it with `Future`:

```scala
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

guarantee {
  Future {
    println("Executing!")
    1 + 1
  }
} {
  println("Done!")
}

//=> Done!
//=> Executing!
```

Oops! This doesn't work, so one of you might get the bright idea to do this instead:

```scala
import scala.util.control.NonFatal

def guarantee[R](f: => R)(finalizer: => Unit): R =
  try {
    f match {
      // Anti-pattern
      case ref: Future[_] =>
        ref.transform { r => finalizer; r }
          .asInstanceOf[R]
      case result =>
        finalizer
        result
    }
  } catch {
    case NonFatal(e) =>
      finalizer
      throw e
  }
```

This logic isn't extensible — What happens when you'll want to introduce logic for Java's `CompletableFuture`, Monix's `Task`, Cats-Effect's `IO` and so on? Each type gets its own branch?

We've run into the [expression problem](https://en.wikipedia.org/wiki/Expression_problem) and yet our `R` data type is not a [tagged union](https://en.wikipedia.org/wiki/Tagged_union), meaning that the set of possible values in that pattern match is endless.

The second problem is the default branch. We are assuming that, in case `R` is not a `Future`, then we are dealing with a side effectful function that executes synchronously. So one of your colleagues comes along and does this:

```scala
import monix.eval.Task

guarantee {
  // Oh noes!
  Task {
    println("Executing!")
    1 + 1
  }
} {
  println("Done!")
}

//=> Done!
```

Oops again! Now we've got a bug.

## Type Classes to the rescue

Let us define a type class for discriminating between types at *compile-time*:

```scala
trait CanGuarantee[R] {
  def guarantee(f: => R)(finalizer: => Unit): R
}
```

Now our function can look like this:

```scala
def guarantee[R: CanGuarantee](f: => R)(finalizer: => Unit): R =
  implicitly[CanGuarantee[R]].guarantee(f)(finalizer)
```

To get the behavior of the original sample, we can define the default instances in the companion object like this:

```scala
object CanGuarantee  {
  // Future instance
  implicit def futureInstance[A]: CanGuarantee[Future[A]] =
    new CanGuarantee[Future[A]] {
      def guarantee(f: => Future[A])(finalizer: => Unit): Future[A] =
        Future(f).flatten.transform { r =>
          finalizer
          r
        }
    }

  // Default instance
  implicit def syncInstance[R]: CanGuarantee[R] =
    new CanGuarantee[R] {
      def guarantee(f: => R)(finalizer: => Unit): R =
        try f finally finalizer
    }
}
```

The upside is that now the mechanism is extensible, without modifying the original function:

```scala
final class Thunk[A](val run: () => A)

object Thunk {
  // Extending our logic with a new data type
  implicit def canGuarantee[A]: CanGuarantee[Thunk[A]] =
    new CanGuarantee[Thunk[A]] {
      def guarantee(f: => Thunk[A])(finalizer: => Unit): Thunk[A] =
        new Thunk(() => {
          try f.run() finally finalizer
        })
    }
}
```

## The problem with defaults

What happens in case you don't define `CanGuarantee[Thunk[A]]`?

```scala
guarantee {
  new Thunk { () =>
    println("Calculating!")
    1 + 1
  }
} {
  println("Done!")
}
```

The `syncInstance` that we defined above is incorrect for `Thunk`. This means that we can introduce silent bugs. What should happen here?

```scala
import java.util.concurrent.CompletableFuture

guarantee {
  CompletableFuture.runAsync { () =>
    println("Running!")
  }
} {
  println("Done!")
}
//=> Done!
//=> Running!
```

This is a bug waiting to happen.

Therefore one can make the case that the default instance, if it doesn't have the intended behavior for all data types, should not exist. But you can still provide a helper for creating one:

```scala
import scala.annotation.implicitNotFound

@implicitNotFound("""Cannot find implicit value for CanGuarantee[${R}].
If this value is synchronously calculated via an effectful function,
then use CanGuarantee.synchronous to create one.""")
trait CanGuarantee[R] {
  def guarantee(f: => R)(finalizer: => Unit): R
}

object CanGuarantee {
  // No longer implicit
  def synchronous[R]: CanGuarantee[R] =
    new CanGuarantee[R] {
      def guarantee(f: => R)(finalizer: => Unit): R =
        try f finally finalizer
    }

  // Future instance
  implicit def futureInstance[A]: CanGuarantee[Future[A]] =
    new CanGuarantee[Future[A]] {
      def guarantee(f: => Future[A])(finalizer: => Unit): Future[A] =
        Future(f).flatten.transform { r =>
          finalizer
          r
        }
    }
}
```

Notice the usage of Scala's [@implicitNotFound](https://www.scala-lang.org/api/current/scala/annotation/implicitNotFound.html) annotation for providing a nice error message.

Let's see what happens now when we try running the `CompletableFuture` code again:

```
error: Cannot find implicit value for CanGuarantee[CompletableFuture[Void]].
If this value is synchronously calculated via an effectful function,
then use CanGuarantee.synchronous to create one.
```

That's better. This now goes for `Unit` as well:

```
scala> guarantee { println("Executing!") } { println("Done!") }

error: Cannot find implicit value for CanGuarantee[Unit].
If this value is synchronously calculated via an effectful function,
then use CanGuarantee.synchronous[Unit] to create one.
       guarantee { println("Executing!") } { println("Done!") }
                                           ^
```

If you want to work with `Unit`, you have to create an instance for it, but notice how the error message tells you exactly what to do:

```scala
implicit val ev = CanGuarantee.synchronous[Unit]

guarantee { println("Executing!") } { println("Done!") }
```

## In conclusion

Friends don't let friends use `isInstanceOf` checks, because Scala has better ways of handling the related use cases.

Enjoy~