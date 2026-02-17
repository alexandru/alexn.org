---
title: "Hybrid IO-driven Promise (Scala snippet)"
date: 2026-02-17T14:03:04+02:00
last_modified_at: 2026-02-17T15:46:11+02:00
image: /assets/media/articles/2026-iopromise-snippet.png
tags:
  - Akka
  - Cats Effect
  - Concurrency
  - FP
  - Programming
  - Scala
  - Snippet
description: >
  Alternative to Scala's `Promise` and Cats-Effect's `Deferred`, exposing a hybrid API, useful for interoperability between imperative libraries (e.g., Akka/Pekko) and Cats-Effect.
---

<p class="intro" markdown=1>
Alternative to [Scala's Promise](https://www.scala-lang.org/api/current/scala/concurrent/Promise.html) and [Cats-Effect's Deferred](https://typelevel.org/cats-effect/docs/std/deferred), exposing a hybrid API, useful for interoperability between imperative libraries (e.g., Akka/Pekko) and Cats-Effect.
</p>

Compared with [Deferred](https://typelevel.org/cats-effect/docs/std/deferred), this `IOPromise` allows for completing the promise via `unsafeTryComplete`, which can be used in an imperative (non-`IO`) context, but it still exposes an `IO`-driven API.

Pros:
- The advantage of using this, instead of just wrapping `scala.concurrent.{ Promise, Future }` references in `cats.effect.IO` is that the `IO` value returned by `awaitOrGet` doesn't leak memory (being able to unregister its callback on cancellation).
- The advantage of using this, over `cats.effect.Deferred`, is that it allows for completing the promise in an imperative context, without needing to instantiate a [Dispatcher](https://typelevel.org/cats-effect/docs/std/dispatcher) or having to import [cats.effect.unsafe.global](https://typelevel.org/cats-effect/api/3.x/cats/effect/unsafe/IORuntime$.html#global:cats.effect.unsafe.IORuntime), thus being safer, more efficient and with a lighter API.


```scala
//> using dep "org.typelevel::cats-effect:3.6.3"
//> using scala "3.3.7"

import cats.effect.IO
import java.util.concurrent.atomic.AtomicReference
import scala.annotation.tailrec
import scala.collection.immutable.Queue
import scala.concurrent.ExecutionContext
import scala.concurrent.Future

/** This is a replacement for `scala.concurrent.Promise` and
  * `cats.effect.Deferred`, exposing a hybrid API, useful in 
  * interop scenarios.
  *
  * All methods exposed have both pure/safe and impure/unsafe variants:
  *   - [[tryComplete]] and [[unsafeTryComplete]]
  *   - [[awaitOrGet]] and [[unsafeAwaitOrGet]]
  */
final class IOPromise[A] private (ref: AtomicReference[IOPromise.State[A]]) {
  import IOPromise.*

  /** Attempts to complete the promise with the given result.
    *
    * It's UNSAFE, in the sense that it's side-effecting. This can be a feature,
    * as it can be used in a non-`IO` context.
    *
    * @return
    *   `true` if the promise was successfully completed with the given result,
    *   `false` if the promise was already completed by another
    *   thread/actor/fiber.
    */
  @tailrec
  def unsafeTryComplete(result: Either[Throwable, A]): Boolean = {
    val state = ref.get()
    state.tryComplete(result) match {
      case None => false
      case Some((task, newState)) =>
        if (ref.compareAndSet(state, newState)) {
          task.run()
          true
        } else {
          // Retry...
          unsafeTryComplete(result)
        }
    }
  }

  /** Variant of [[unsafeTryComplete]]. */
  def unsafeTrySuccess(value: A): Boolean =
    unsafeTryComplete(Right(value))

  /** Variant of [[unsafeTryComplete]]. */
  def unsafeTryFailure(ex: Throwable): Boolean =
    unsafeTryComplete(Left(ex))

  /** Safe (IO-driven) version of [[unsafeTryComplete]]. */
  def tryComplete(result: Either[Throwable, A]): IO[Boolean] =
    IO(unsafeTryComplete(result))

  /** Safe (IO-driven) version of [[unsafeTrySuccess]]. */
  def trySuccess(value: A): IO[Boolean] =
    tryComplete(Right(value))

  /** Safe (IO-driven) version of [[unsafeTryFailure]]. */
  def tryFailure(ex: Throwable): IO[Boolean] =
    tryComplete(Left(ex))

  /** Returns an `IO` that completes when the promise is completed.
    *
    * @see
    *   [[unsafeAwaitOrGet]] for the side-effecting version of this method.
    */
  def awaitOrGet: IO[A] = {
    def cancel(cb: Callback[A]): IO[Unit] =
      IO.defer {
        val current = ref.get()
        current.unregister(cb) match {
          case Some(update) if !ref.compareAndSet(current, update) =>
            cancel(cb) // retry
          case _ =>
            IO.unit
        }
      }

    @tailrec
    def tryCompleteOrEnqueue(cb: Callback[A]): Option[IO[Unit]] = {
      val state = ref.get()
      state.getResult(cb) match {
        case Right(newState) =>
          if (ref.compareAndSet(state, newState)) {
            Some(cancel(cb))
          } else {
            tryCompleteOrEnqueue(cb)
          }
        case Left(task) =>
          task.run()
          None
      }
    }

    IO.executionContext.flatMap { ec =>
      IO.async { cb =>
        IO(tryCompleteOrEnqueue((ec, cb)))
      }
    }
  }

  /** Awaits the completion of the promise, producing a result.
    *
    * It's UNSAFE because it's side-effecting, and `Future` itself has its own
    * warts.
    *
    * @see
    *   [[awaitOrGet]] for the safe (IO-driven) version of this method.
    * @return
    *   a `Future` that completes when the promise is completed.
    */
  def unsafeAwaitOrGet(using ec: ExecutionContext): Future[A] = {
    @tailrec
    def tryCompleteOrEnqueue(cb: Callback[A]): Unit = {
      val state = ref.get()
      state.getResult(cb) match {
        case Right(newState) =>
          if (!ref.compareAndSet(state, newState)) {
            tryCompleteOrEnqueue(cb)
          }
        case Left(task) =>
          task.run()
      }
    }

    val promise = scala.concurrent.Promise[A]()
    tryCompleteOrEnqueue((ec, r => promise.complete(r.toTry)))
    promise.future
  }
}

object IOPromise {
  /** Creates a new `IOPromise`.
    *
    * @see
    *   [[unsafe]] for the side-effecting version of this method.
    */
  def apply[A](): IO[IOPromise[A]] =
    IO(unsafe())

  /** Creates a new `IOPromise` in a side-effectful way.
    *
    * UNSAFE, because it's side-effecting, meaning that it allocates mutable
    * state.
    *
    * @see
    *   [[apply]] for the safe (IO-driven) version of this method.
    */
  def unsafe[A](): IOPromise[A] =
    new IOPromise(new AtomicReference(State.Pending(Queue.empty)))

  private type Callback[A] = (ExecutionContext, Either[Throwable, A] => Unit)

  sealed private trait State[A] extends Product with Serializable {
    /** @return
      *   either `Some((task, newState))`, in case the state was `Pending`, and
      *   we have to call all the registered callbacks. Or `None`, in case the
      *   state was already `Completed`, and the caller has nothing left to do.
      */
    def tryComplete(result: Either[Throwable, A]): Option[(Runnable, State[A])] =
      this match {
        case State.Pending(callbacks) =>
          val task: Runnable = () =>
            for ((ec, notify) <- callbacks)
              ec.execute(() => notify(result))
          Some((task, State.Completed(result)))
        case State.Completed(_) =>
          None
      }

    /** Attempts to register the given callback, if the state is still
      * `Pending`, returning the new state with the callback registered.
      *
      * If the state is already completed, then the callback isn't registered,
      * the caller returning a task that should be executed. Note that this
      * method is supposed to be pure, which is why we are not calling the
      * callback directly.
      */
    def getResult(cb: Callback[A]): Either[Runnable, State[A]] =
      this match {
        case State.Pending(callbacks) =>
          Right(State.Pending(callbacks.enqueue(cb)))
        case State.Completed(result) =>
          Left { () =>
            val (ec, notify) = cb
            ec.execute(() => notify(result))
          }
      }

    /** Removes a callback from the queue, used for cancellation. */
    def unregister(cb: Callback[A]): Option[State[A]] =
      this match {
        case State.Pending(callbacks) =>
          val filtered = callbacks.filterNot(_ == cb)
          Some(State.Pending(filtered))
        case State.Completed(_) =>
          None
      }
  }

  private object State {
    /** Represents a promise that is still pending, and has a queue of callbacks
      * waiting on completion.
      */
    final case class Pending[A](callbacks: Queue[Callback[A]]) extends State[A]

    /** Represents a promise that is already completed, with the result
      * memoized.
      */
    final case class Completed[A](result: Either[Throwable, A]) extends State[A]
  }
}
```

As a usage example, here's a [KillSwitch](https://pekko.apache.org/japi/pekko/snapshot/org/apache/pekko/stream/KillSwitch.html) implementation on which we can await the shutdown via `cats.effect.IO`, very useful for [Akka/Pekko+Cats-Effect interop](./2023-04-17-integrating-akka-with-cats-effect-3.md).

```scala
//> using dep "org.apache.pekko::pekko-stream-typed:1.4.0"

import cats.effect.kernel.Resource
import cats.effect.IO
import org.apache.pekko.stream.FlowShape
import org.apache.pekko.stream.Graph
import org.apache.pekko.stream.KillSwitch
import org.apache.pekko.stream.KillSwitches
import org.slf4j.LoggerFactory

/** Replacement for Akka/Pekko `SharedKillSwitch`.
  *
  * It's primary innovation is the [[awaitShutdown]] method.
  *
  * NOTE: the use of `SharedKillSwitch` in this project is now banned ;-)
  */
trait BetterKillSwitch extends KillSwitch {
  def flow[T]: Graph[FlowShape[T, T], BetterKillSwitch]
  def awaitShutdown: IO[KillSwitchOutcome]
}

object BetterKillSwitch {
  def unsafe(name: String): BetterKillSwitch = {
    val underlying = KillSwitches.shared(name)
    val promise = IOPromise.unsafe[KillSwitchOutcome]()
    new BetterKillSwitchEfficient(underlying, promise)
  }

  def apply(name: String): IO[BetterKillSwitch] =
    IO(unsafe(name))

  def resource(name: String): Resource[IO, BetterKillSwitch] =
    Resource(apply(name).map { ks =>
      (ks, IO(ks.shutdown()))
    })
}

final private class BetterKillSwitchEfficient(
  underlying: org.apache.pekko.stream.SharedKillSwitch,
  promise: IOPromise[KillSwitchOutcome]
) extends BetterKillSwitch {
  override def awaitShutdown: IO[KillSwitchOutcome] =
    promise.awaitOrGet

  override def shutdown(): Unit =
    try
      underlying.shutdown()
    finally {
      val _ = promise.unsafeTrySuccess(KillSwitchOutcome.Completed)
    }

  override def abort(ex: Throwable): Unit =
    try
      underlying.abort(ex)
    finally
      if (!promise.unsafeTrySuccess(KillSwitchOutcome.Errored(ex)))
        LoggerFactory.getLogger(getClass).error(
          "Kill switch was already shutdown when aborting with error",
          ex
        )

  override def flow[T]: Graph[FlowShape[T, T], BetterKillSwitch] =
    underlying.flow[T].mapMaterializedValue { it =>
      if (it == underlying) BetterKillSwitchEfficient.this
      else new BetterKillSwitchEfficient(it, promise)
    }
}

/** Kill-switches can be shutdown gracefully (i.e., by completing the stream),
  * or via an error.
  *
  * The effect on the downstream is not the same, as `onError` short-circuits
  * the stream, while `shutdown` allows the in-process messages to complete.
  *
  * This type is used to signal to shut down listener whenever the kill-switch
  * is shutdown gracefully or aborted via an error.
  */
enum KillSwitchOutcome {
  case Completed
  case Errored(e: Throwable)

  def toEither: Either[Throwable, Unit] =
    this match {
      case Completed => Right(())
      case Errored(e) => Left(e)
    }
}
```

Note that when using a [SharedKillSwitch](https://pekko.apache.org/japi/pekko/1.4/org/apache/pekko/stream/SharedKillSwitch.html) (the standard implementation provided by Akka/Pekko), we could already do something like the following, by leveraging Akka/Pekko streams, but it's definitely heavier, API-wise as well (notice the `Materializer` requirement):

```scala
import cats.effect.syntax.*
import org.apache.pekko.stream.Materializer
import org.apache.pekko.stream.SharedKillSwitch
import org.apache.pekko.stream.scaladsl.Source

def awaitShutdown(
  ref: SharedKillSwitch
)(using Materializer): IO[Either[Throwable, Unit]] = {
  val start = IO {
    val done = Source.never[Unit]
      .via(ref.flow)
      .run()
    (done, IO.unit)
  }
  IO.fromFutureCancelable(start)
    .void.attempt
}
```