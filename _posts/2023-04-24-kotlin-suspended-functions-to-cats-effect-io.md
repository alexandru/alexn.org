---
title: "Kotlin Coroutines to Cats-Effect"
image: /assets/media/articles/2023-kotlin-to-ce-3.png
image_hide_in_post: true
tags:
  - FP
  - Kotlin
  - Programming
  - Scala
  - Snippet
description:
  Kotlin Coroutines are usually integrated in Java code via Java’s CompletableFuture, but a tighter integration might be possible with Cats-Effect. 
---

<p class="intro withcap" markdown=1>
  Kotlin [Coroutines](https://kotlinlang.org/docs/coroutines-overview.html) are usually integrated in Java code via Java's `CompletableFuture`, but a tighter integration might be possible with [Cats-Effect](https://typelevel.org/cats-effect/). I played around to see if I can convert Kotlin's coroutines, built via suspended functions straight to `cats.effect.IO`. Turns out I could.
</p>


The following snippet is an executable script via [Scala-CLI](https://scala-cli.virtuslab.org/):

```scala
//#!/usr/bin/env -S scala-cli shebang -q

//> using scala "2.13.10"
//> using lib "org.typelevel::cats-effect::3.4.9"
//> using lib "org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4"

import cats.effect._
import kotlin.coroutines.{Continuation, CoroutineContext}
import kotlinx.coroutines.{Deferred, _}

import java.util.Collections
import java.util.concurrent.{AbstractExecutorService, CancellationException, TimeUnit}
import scala.concurrent.ExecutionContextExecutorService
import scala.concurrent.duration._
import scala.util.control.{NoStackTrace, NonFatal}

object Main extends IOApp {
  // Sleeping via Kotlin's coroutines
  def kotlinSleep(duration: FiniteDuration): IO[Unit] =
    KotlinCoroutines.runCancelable_ { (_, cont) =>
      // Kotlin suspended function calls...
      kotlinx.coroutines.DelayKt.delay(duration.toMillis, cont)
    }

  override def run(args: List[String]): IO[ExitCode] =
    for {
      _ <- IO.println("Running...")
      fiber <- kotlinSleep(10.seconds).start
      _ <- IO.sleep(1000.millis)
      _ <- fiber.cancel
      _ <- fiber.joinWithUnit
      _ <- IO.println("Done!")
    } yield ExitCode.Success
}

object KotlinCoroutines {
  def runCancelable_(
    block: (CoroutineScope, Continuation[_ >: kotlin.Unit]) => Any
  ): IO[Unit] = {
    runCancelable(block).void
  }

  def runCancelable[A](
    block: (CoroutineScope, Continuation[_ >: A]) => Any
  ): IO[A] = {
    coroutineToIOFactory[A](block, buildCancelToken)
  }

  private def dispatcher: IO[CoroutineDispatcher] =
    IO.executionContext.map { other =>
      kotlinx.coroutines.ExecutorsKt.from(
        new AbstractExecutorService with ExecutionContextExecutorService {
          override def isShutdown = false
          override def isTerminated = false
          override def shutdown() = ()
          override def shutdownNow() = Collections.emptyList[Runnable]
          override def execute(runnable: Runnable): Unit = other.execute(runnable)
          override def reportFailure(t: Throwable): Unit = other.reportFailure(t)
          override def awaitTermination(length: Long, unit: TimeUnit): Boolean = false
        }
      )
    }

  private def coroutineToIOFactory[A](
    block: (CoroutineScope, Continuation[_ >: A]) => Any,
    buildCancelToken: (Deferred[_], DisposableHandle) => Option[IO[Unit]]
  ): IO[A] = {
    dispatcher.flatMap { dispatcher =>
      IO.async[A] { cb =>
        IO {
          try {
            val context = CoroutineContextKt.newCoroutineContext(
              GlobalScope.INSTANCE,
              dispatcher.asInstanceOf[CoroutineContext],
            )
            val deferred = kotlinx.coroutines.BuildersKt.async(
              GlobalScope.INSTANCE,
              context,
              CoroutineStart.DEFAULT,
              (p1: CoroutineScope, p2: Continuation[_ >: A]) => block(p1, p2)
            )
            try {
              val dispose = deferred.invokeOnCompletion(
                (e: Throwable) => {
                  e match {
                    case e: Throwable => cb(Left(e))
                    case _ => cb(Right(deferred.getCompleted))
                  }
                  kotlin.Unit.INSTANCE
                })
              buildCancelToken(deferred, dispose)
            } catch {
              case NonFatal(e) =>
                deferred.cancel(null)
                throw e
            }
          } catch {
            case NonFatal(e) =>
              cb(Left(e))
              None
          }
        }
      }
    }.recoverWith {
      case PleaseCancel =>
        // This branch actually never happens, but it might
        // prevent leaks in case of a bug
        IO.canceled *> IO.never
    }
  }

  private def buildCancelToken(deferred: Deferred[_], dispose: DisposableHandle): Option[IO[Unit]] =
    Some(IO.defer {
      deferred.cancel(PleaseCancel)
      dispose.dispose()
      // Await for completion or cancellation
      coroutineToIOFactory[kotlin.Unit](
        (_, cont) => deferred.join(cont),
        (_, _) => None
      ).void
    })

  private object PleaseCancel
    extends CancellationException with NoStackTrace
}
```
