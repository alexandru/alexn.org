---
title: "Retry Failing Tasks with Cats and Scala"
description:
  Retry actions ending in failure via simple functions and Typelevel Cats type-classes.
tags:
  - Scala
  - FP
  - Code
image: /assets/media/snippets/on-error-retry-loop.png
---

In the face of errors, we could interrupt what we are doing and log the incident for debugging purposes. Some errors are temporary, for example network connection errors, the web service becoming unavailable for whatever reason, etc, in which case it might be appropriate to do one or multiple retries.

There are libraries with DSLs for specifying complex retry logic, e.g. [cats-retry](https://github.com/cb372/cats-retry). In this article, I am not talking about such libraries, for one because implementing your functions is fun, is educational, and also because you might not need a library where a simple function could do just fine.

Here's how ...

- [Task Example](#task-example)
- [Naive Implementation](#naive-implementation)
- [Filtering and End Condition](#filtering-and-end-condition)
- [Building a Generic Retry Loop](#building-a-generic-retry-loop)
- [Exponential Backoff](#exponential-backoff)
- [TL;DR Full Code Sample](#tldr-full-code-sample)

## Task Example

We are going to use [cats.effect.IO](https://typelevel.org/cats-effect/datatypes/io.html) for exemplification, but this can work just as well with the [Monix Task](https://monix.io/docs/3x/eval/task.html), [Monix Coeval](https://monix.io/docs/3x/eval/coeval.html) or any data type that implements the Cats or Cats Effect type classes.

```scala
import cats.effect.IO
import java.io._

// Not very motivating example, but let's go with it
def readTextFromFile(file: File, charset: String): IO[String] =
  IO {
    val in = new BufferedReader(
      new InputStreamReader(
        new FileInputStream(file), charset
      ))

    val builder = new StringBuilder()
    var line: String = null
    do {
      line = in.readLine()
      if (line != null) 
        builder.append(line).append("\n")
    } while (line != null)

    builder.toString
  }
```

This operation is doing I/O, the file we are looking for could be missing, but only temporarily, or we might have an IOPS capacity problem. In some cases, we might want to keep retrying the task.

## Naive Implementation

The [ApplicativeError](https://github.com/typelevel/cats/blob/v2.1.1/core/src/main/scala/cats/ApplicativeError.scala) type class from Typelevel Cats defines this function:

```scala
trait ApplicativeError[F[_], E] extends Applicative[F] {
  // ...
  def handleErrorWith[A](fa: F[A])(f: E => F[A]): F[A]
}
```

The `handleErrorWith` function works like a `flatMap` operation, but for errors. 

```scala
import cats.implicits._
import cats.{ApplicativeError, Defer}

object OnErrorRetry {
  // WARN: not OK, because we don't have an end condition!
  def loop[F[_], E, A](fa: F[A])
    (implicit F: ApplicativeError[F, E], D: Defer[F]): F[A] = {

    fa.handleErrorWith { _ =>
      // Recursive call
      D.defer(loop(fa))
    }
  }
}

//...
OnErrorRetry.loop(readTextFromFile(file))
```

Note the usage of `ApplicativeError` and `Defer` type classes, added as restrictions for our `F[_]`.

<p class='info-bubble' markdown='1'>
  There's a caveat with the way we're using <code>handleErrorWith</code> in such recursive loops. The type we use might not have a <em>memory safe</em> implementation, which is always a concern in Scala, due to the JVM lacking TCO. The data types that can throw errors, errors based on runtime conditions that can be retried, usually implement a memory-safe <code>handleErrorWith</code>, but it's better if we can ensure this via type restrictions.
  <br/><br/>
  We use the <a href="https://typelevel.org/cats/api/cats/Defer.html">Defer</a> type class to force usage of memory safe (trampolined) implementations.
</p>

This sample has several problems that we'll have to address:

1. no end condition
2. no filtering of errors, since not all errors are recoverable
3. no protections, like "*exponential backoff*"

## Filtering and End Condition

We must only retry the task in situations in which it can be retried. For example if the task throws a [CharacterCodingException](https://docs.oracle.com/javase/8/docs/api/java/nio/charset/CharacterCodingException.html){:target="_blank"}, that's not a task that can be retried, that's a bug. It's not always clear when the task can be retried or not, but we can try our best.

And we want to retry, but not forever. So there has to be an end condition in that loop.

```scala
/** 
  * Signaling desired outcomes via Boolean is very confusing,
  * having our own ADT for this is better.
  */
sealed trait RetryOutcome

object RetryOutcome {
  case object Next extends RetryOutcome
  case object Raise extends RetryOutcome
}

/** Module grouping our retry helpers. */
object OnErrorRetry {

  def withConfig[F[_], E, A](fa: F[A], maxRetries: Int)
    (p: E => RetryOutcome)
    (implicit F: ApplicativeError[F, E], D: Defer[F]): F[A] = {

    fa.handleErrorWith { error =>
      if (maxRetries > 0)
        p(error) match {
          case RetryOutcome.Next =>
            // Recursive call
            D.defer(withConfig(fa, maxRetries)(p))
          case RetryOutcome.Raise =>
            // Cannot recover from error
            F.raiseError(e)
        }
      else
        // Maximum retries reached, triggering error
        F.raiseError(e)
    }
  } 
}
```

And usage:

```scala
OnErrorRetry.withConfig(readTextFromFile(file), maxRetries = 10) {
  case _: CharacterCodingException =>
    RetryOutcome.Throw
  case _ =>
    RetryOutcome.Next
}
```

## Building a Generic Retry Loop

Inspired by Monix's [onErrorRestartLoop](https://github.com/monix/monix/pull/507), we can describe this function in a generic fashion:

```scala
object OnErrorRetry {
  /** 
    * Saves us from describing recursive functions that accumulate state.
    */
  def loop[F[_], A, S](
    fa: F[A],
    initial: S
  )(
    f: (Throwable, S, S => F[A]) => F[A]
  )(implicit F: ApplicativeError[F, Throwable], D: Defer[F]): F[A] = {
    fa.handleErrorWith { err =>
      f(err, initial, state => D.defer(loop(fa, state)(f)))
    }
  }
}

// Retrying 10 times at most
OnErrorRetry.loop(readTextFromFile(file), 10) {  (e, retriesLeft, retry) =>
  val canRetry = e match {
    case _: CharacterCodingException =>
      RetryOutcome.Throw
    case _ =>
      RetryOutcome.Next
  }
  if (canRetry && retriesLeft > 0)
    retry(retriesLeft - 1) // again
  else
    IO.raiseError(e)  
}
```

## Exponential Backoff

We might also want to introduce [exponential backoff](https://en.wikipedia.org/wiki/Exponential_backoff), because if the resource is busy, the last thing we want to do is to overwhelm it with retry requests. And we are are going to use [Timer](https://typelevel.org/cats-effect/datatypes/timer.html) for introducing delays.

At this point, the state and the configuration are more complicated, so let's introduce a reusable data structure too, that should be self-explanatory:

```scala
import scala.concurrent.duration._

/**
  * Configuration for retry logic, could be read from a config file, via
  * something like [[https://github.com/pureconfig/pureconfig PureConfig]].
  */
final case class RetryConfig(
  maxRetries: Int,
  initialDelay: FiniteDuration,
  maxDelay: FiniteDuration,
  backoffFactor: Double,
  private val evolvedDelay: Option[FiniteDuration] = None,
) {
  def canRetry: Boolean = maxRetries > 0

  def delay: FiniteDuration =
    evolvedDelay.getOrElse(initialDelay)

  def evolve: RetryConfig =
    copy(
      maxRetries = math.max(maxRetries - 1, 0),
      evolvedDelay = Some {
        val nextDelay = evolvedDelay.getOrElse(initialDelay) * backoffFactor
        maxDelay.min(nextDelay) match {
          case ref: FiniteDuration => ref
          case _: Duration.Infinite => maxDelay
        }
      }
    )
}
```

All together now:

```scala
object OnErrorRetry {
  def loop[F[_], A, S](
    fa: F[A],
    initial: S
  )(
    f: (Throwable, S, S => F[A]) => F[A]
  )(implicit F: ApplicativeError[F, Throwable], D: Defer[F]): F[A] = {
    fa.handleErrorWith { err =>
      f(err, initial, state => D.defer(loop(fa, state)(f)))
    }
  }

  def withConfig[F[_], A](fa: F[A], retry: RetryConfig)(
    p: Throwable => F[RetryOutcome]
  )(implicit 
    F: MonadError[F, Throwable], 
    D: Defer[F], 
    timer: Timer[F]
  ): F[A] = {
    loop(fa, retry) { (error, state, retry) =>
      if (state.canRetry)
        p(error).flatMap {
          case RetryOutcome.Next =>
            timer.sleep(state.delay) *> retry(state.evolve)
          case RetryOutcome.Raise =>
            F.raiseError(error)
        }
      else
        F.raiseError(error)
    }
  }
}
```

In our predicate we take an `F[RetryOutcome]` instead of a `RetryOutcome`. That's because we might want to trigger additional side effects, like logging.

So to build our final sample, let's introduce a dependency on [typesafe-config](https://github.com/lightbend/config) in `build.sbt`, which you probably have anyway:

```scala
libraryDependencies += "com.typesafe" % "config" % "1.4.0"
```

And usage:

```scala
object Playground extends LazyLogging with IOApp {
  // Motivating example
  def readTextFromFile(file: File, charset: String): IO[String] = ???

  override def run(args: List[String]): IO[ExitCode] = {
    val config = RetryConfig(
      maxRetries = 10,
      initialDelay = 10.millis,
      maxDelay = 2.seconds,
      backoffFactor = 1.5
    )
    val text = OnErrorRetry.withConfig(
      readTextFromFile(new File(args.head), "UTF-8"),
      config
    ) {
      case _: CharacterCodingException =>
        IO.pure(RetryOutcome.Raise)
      case e =>
        IO(logger.warn("Unexpected error, retrying", e))
          .as(RetryOutcome.Next)
    }
    for {
      t <- text
      _ <- IO(println(t))
    } yield ExitCode.Success
  }
}
```

## TL;DR Full Code Sample

See here for the full code sample:<br/>
[on-error-retry-loop.scala]({% link _snippets/2020-08-03-on-error-retry-loop.scala.md %})

Enjoy~
