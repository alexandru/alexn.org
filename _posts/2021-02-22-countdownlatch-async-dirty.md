---
title: "Implementing a CountDownLatch (async and dirty)"
date: 2021-02-22 15:39:35+0200
image: /assets/media/articles/countdownlatch-async-dirty.png
image_hide_in_post: true
description: Yo dawg, I heard you liked concurrency primitives. Let's implement our own asynchronous, dirty CountDownLatch.
tags: 
  - Concurrency
  - Multithreading
  - Programming
  - Scala
  - JVM
---

{% include youtube.html id="R6pl91IRVaI" image="/assets/media/articles/countdownlatch-async-dirty.png" %}

Yo dawg, I heard you liked concurrency primitives. Let's implement our own asynchronous, dirty [CountDownLatch](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/CountDownLatch.html).

Just to be clear, what we are implementing here is probably not production ready (please do some testing first, as I didn't 😅). Also this is not functional programming, and it's not using [Monix](https://monix.io) or [Cats-Effect](https://typelevel.org/cats-effect/), or any other libraries that might have helped. This is implemented using just the standard library.

Also, you might want the classic `java.util.concurrent.CountDownLatch`, which is pretty awesome, and it might be exactly what you need, although this one is useful too.

Why implement one? Because we can 💪

1. Watch the [YouTube video](https://www.youtube.com/watch?v=R6pl91IRVaI&autoplay=1){:target="_blank"} for full explanations
2. Checkout the following code for digesting it at your own pace
3. See the usage examples at the end

## The Code

```scala
import java.util.concurrent.{Executors, RejectedExecutionException}
import java.util.concurrent.atomic.AtomicReference
import scala.annotation.tailrec
import scala.concurrent.duration.{Duration, FiniteDuration}
import scala.concurrent.{ExecutionContext, Future, Promise, TimeoutException}

final class AsyncCountDownLatch(count: Int)(implicit ec: ExecutionContext)
  extends AutoCloseable {

  // Shared mutable state, managed by my favorite
  // synchronization primitive
  private[this] val state = new AtomicReference(State(count, Set.empty))
  private final case class State(
    count: Int,
    tasks: Set[Promise[Unit]]
  )

  /**
    * INTERNAL — scheduler for managing timeouts, must be destroyed
    * internally too. Note that this isn't the only possible design,
    * we could of course take this as a parameter in the class's
    * constructor, or use a globally shared one 🤷‍
    *
    * One cool alternative is to use Monix's `Scheduler` instead of
    * `ExecutionContext` (`monix.execution.Scheduler`).
    */
  private[this] val scheduler =
    Executors.newSingleThreadScheduledExecutor((r: Runnable) => {
      val th = new Thread(r)
      th.setDaemon(true)
      th.setName(s"countdownlatch-${hashCode()}")
      th
    })

  /**
    * INTERNAL — Given a `Promise`, install a timeout for it.
    */
  private def installTimeout(p: Promise[Unit], timeout: FiniteDuration): Unit = {
    // Removing the promise from our internal `state` is necessary to avoid leaks.
    @tailrec def removePromise(): Unit =
      state.get() match {
        case current @ State(_, tasks) =>
          val update = current.copy(tasks = tasks - p)
          if (!state.compareAndSet(current, update))
            removePromise()
        case null =>
          () // countDown reached zero
      }
    // Keeping this as a value in order to avoid duplicate work
    val ex = new TimeoutException(
      s"AsyncCountDownLatch.await($timeout)"
    )
    val timeoutTask: Runnable = () => {
      // Timeout won, get rid of promise from our state
      removePromise()
      p.tryFailure(ex)
    }
    try {
      // Finally, installing our timeout, w00t!
      val cancelToken = scheduler.schedule(
        timeoutTask, 
        timeout.length, 
        timeout.unit
      )
      // Canceling our timeout task, if primary completes first
      p.future.onComplete { r =>
        // Avoiding duplicate work
        if (r.fold(_ != ex, _ => true))
          cancelToken.cancel(false)
      }
    } catch {
      case _: RejectedExecutionException =>
        // This exception can happen due to a race condition:
        // When countDown() reaches zero, the scheduler is being
        // shut down, however while that happens we may be in
        // the process of installing a timeout — but this is no
        // longer necessary, since the promise will be completed;
        // NOTE — for extra-safety, we might want to check the
        // promise's state, to ensure that it is complete, and
        // a happens-before relationship probably exists (TBD)
        ()
    }
  }

  override def close(): Unit = {
    state.lazySet(null) // GC purposes
    scheduler.shutdown()
  }

  /**
    * Decrements the count of the latch, releasing all waiting
    * consumers if the count reaches zero.
    *
    * If the current count is already zero, then nothing happens.
    */
  @tailrec def countDown(): Unit =
    state.get() match {
      case current @ State(count, tasks) if count > 0 =>
        val update = State(count - 1, tasks)
        if (!state.compareAndSet(current, update))
          countDown() // retry
        else if (update.count == 0) {
          // Deferring execution to another thread, as it might 
          // be expensive (TBD if this is a good idea or not)
          ec.execute(() => {
            for (r <- tasks) r.trySuccess(())
            // Releasing resources
            close()
          })
        }
      case _ =>
        ()
    }

  /**
    * Causes the consumer to wait until the latch has counted down 
    * to zero, or the specified waiting time elapses.
    *
    * If the timeout gets triggered, then the returned `Future`
    * will complete with a `TimeoutException`.
    */
  @tailrec def await(timeout: Duration): Future[Unit] =
    state.get() match {
      case current @ State(count, tasks) if count > 0 =>
        val p = Promise[Unit]()
        val update = State(count, tasks + p)
        timeout match {
          case d: FiniteDuration => installTimeout(p, d)
          case _ => ()
        }
        if (!state.compareAndSet(current, update))
          await(timeout) // retry
        else
          p.future
      case _ =>
        Future.unit
    }
}
```

Usage sample of the classic `java.util.concurrent.CountDownLatch` that we're trying to mimic:

```scala
import java.util.concurrent.CountDownLatch
import scala.concurrent.ExecutionContext.Implicits.global

val threadCount = 4
val iterations = 10000
var results = Map.empty[Int, Int]

for (_ <- 0 until iterations) {
  val consumersStarted = new CountDownLatch(threadCount)
  val mainThreadProceed = new CountDownLatch(1)
  val consumersFinished = new CountDownLatch(threadCount)
  var sharedState = 0

  for (_ <- 0 until threadCount)
    global.execute(() => {
      consumersStarted.countDown()
      mainThreadProceed.await()
      sharedState += 1
      consumersFinished.countDown()
    })

  consumersStarted.await()
  mainThreadProceed.countDown()
  consumersFinished.await()

  results = results.updated(sharedState, results.getOrElse(sharedState, 0) + 1)
}

println("Done ... ")
println(results)
```

Usage sample of our `AsyncCountDownLatch`, again, testing faulty concurrent update:

```scala
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.{Await, Future, TimeoutException}
import scala.concurrent.duration._

val threadCount = 4
val iterations = 100000
var results = Map.empty[Int, Int]

for (_ <- 0 until iterations) {
  val consumersStarted = new AsyncCountDownLatch(threadCount)
  val mainThreadProceed = new AsyncCountDownLatch(1)
  val consumersFinished = new AsyncCountDownLatch(threadCount)
  var sharedState = 0

  for (_ <- 0 until threadCount) {
    for {
      _ <- Future.unit
      _ = consumersStarted.countDown()
      _ <- mainThreadProceed.await(Duration.Inf)
    } yield {
      sharedState += 1
      consumersFinished.countDown()
    }
  }

  val await = for {
    _ <- consumersStarted.await(Duration.Inf)
    _ = mainThreadProceed.countDown()
    _ <- consumersFinished.await(1.millis)
  } yield {
    results = results.updated(sharedState, results.getOrElse(sharedState, 0) + 1)
  }
  Await.result(await, Duration.Inf)
}

println("Done ... ")
println(results)
```
