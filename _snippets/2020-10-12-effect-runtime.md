---
title: "Effect Runtime"
date: 2020-10-12 17:17:42+0300
image: /assets/media/snippets/effect-runtime.png
tags:
  - Cats Effect
  - FP
  - Scala
---

Defining an `EffectRuntime` that is used to build IO effects. This would be a replacement for [ContextShift](https://typelevel.org/cats-effect/datatypes/contextshift.html) (Cats Effect 2.x), with an integrated `Logger`, [Scheduler](https://monix.io/docs/current/execution/scheduler.html) (thus having access to [Timer](https://typelevel.org/cats-effect/datatypes/timer.html) too), and utilities for monitoring.

The `UnsafeLogger` / `SafeLogger` and `UnsafeMonitoring` interfaces are left as an exercise for the reader.

```scala
import cats.effect._
import cats.implicits._
import monix.execution._
// ...

/**
  * Slice of [[EffectRuntime]], to be used only when a dependency on
  * [[UnsafeLogger]] is needed.
  */
trait UnsafeRuntimeLogger {
  def unsafe: UnsafeLoggerRef

  trait UnsafeLoggerRef {
    def logger: UnsafeLogger
  }
}

/**
  * Slice of [[EffectRuntime]], to be used only when a dependency 
  * on `ExecutionContext` / `monix.execution.Scheduler` is needed.
  */
trait UnsafeRuntimeScheduler {
  def unsafe: UnsafeSchedulerRef

  trait UnsafeSchedulerRef {
    def scheduler: Scheduler
  }
}

/**
  * Slice of [[EffectRuntime]], to be used only when a reference
  * to [[UnsafeMonitoring]] is needed.
  */
trait UnsafeRuntimeMonitoring {
  def unsafe: UnsafeMonitoringRef

  trait UnsafeMonitoringRef {
    def monitoring: UnsafeMonitoring
  }
}

/**
  * Slice of [[EffectRuntime]], to be used only in an "unsafe"context
  * (where side effects are not suspended in `F[_]`).
  */
trait UnsafeRuntime
  extends UnsafeRuntimeLogger
  with UnsafeRuntimeScheduler
  with UnsafeRuntimeMonitoring {

  def unsafe: Unsafe

  trait Unsafe extends UnsafeLoggerRef 
    with UnsafeSchedulerRef 
    with UnsafeMonitoringRef
}

/**
  * Slice of [[EffectRuntime]], to be used only when a reference
  * to [[SafeLogger]] is needed.
  */
trait EffectRuntimeLogger[F[_]] extends UnsafeRuntimeLogger {
  protected implicit def F: Sync[F]
  def logger: SafeLogger[F]
}

/**
  * Our evolved `cats.effect.ContextShift` that has everything 
  * we need in it to build IO effects.
  */
abstract class EffectRuntime[F[_]]
  extends ContextShift[F]
  with EffectRuntimeLogger[F]
  with UnsafeRuntime { self =>

  protected implicit def F: Async[F]

  def logger: SafeLogger[F]
  def scheduler: F[Scheduler]
  def blocker: Blocker
  def timer(implicit F: Concurrent[F]): Timer[F]

  def deferAction[A](f: Scheduler => F[A]): F[A] =
    self.scheduler.flatMap(f)
}
```

Sample for wrapping a Future-based API:

```scala
import scala.concurrent._
import scala.concurrent.duration._

def unsafeGetRequest(req: Request)(
  implicit ec: ExecutionContext
): Future[Response] = {
  ???
}

def getRequest[F[_]: Concurrent](req: Request)(
  implicit r: EffectRuntime[F]
): F[Response] =
  r.deferAction { implicit ec =>
    for {
      _ <- r.logger.debug(s"Triggering request: $req")
      resp <- Async
        .fromFuture(Sync[F].delay(unsafeGetRequest(req)))
        .handleErrorWith { err =>
          r.logger.error("Unexpected error, retrying", err) >>
          r.timer[F].sleep(1.second) >>
          getRequest(req)
        }
    } yield {
      resp
    }
  }
```

WARN: the retry logic isn't a good one. For a better implementation,
see [Retry Failing Tasks with Cats and Scala](../_posts/2020-08-03-on-error-retry-loop.md).
