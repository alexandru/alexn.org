---
title: "Effect Runtime"
date: 2020-10-12 17:17:42+0300
image: /assets/media/snippets/effect-runtime.png
tags:
  - Cats Effect
  - FP
  - Scala
---

Defining an `EffectRuntime` that is used to run effects. This would be a replacement for `cats.effect.ContextShift`, with an integrated `Logger`, [Scheduler](https://monix.io/docs/current/execution/scheduler.html), and utilities for monitoring.

The `UnsafeLogger` / `SafeLogger` and `UnsafeMonitoring` interfaces are left as an exercise for the reader.

```scala
import cats.effect._
import cats.implicits._
import monix.catnap.SchedulerEffect
import monix.execution._
import scala.concurrent.duration._
import scala.concurrent.{ ExecutionContext, Future, TimeoutException }
// ...

/**
  * Slice of [[EffectRuntime]], to be used only when a dependency on
  * [[logging.UnsafeLogger]] is needed.
  */
trait UnsafeRuntimeLogger {
  def unsafe: UnsafeLoggerRef

  trait UnsafeLoggerRef {
    def logger: UnsafeLogger
  }
}

/**
  * Slice of [[EffectRuntime]], to be used only when a dependency on
  * `ExecutionContext` / `monix.execution.Scheduler` is needed.
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
  * Slice of [[EffectRuntime]], to be used only in an "unsafe" context
  * (where side effects are not suspended in `F[_]`).
  */
trait UnsafeRuntime
  extends UnsafeRuntimeLogger
  with UnsafeRuntimeScheduler
  with UnsafeRuntimeMonitoring {

  def unsafe: Unsafe

  trait Unsafe extends UnsafeLoggerRef with UnsafeSchedulerRef with UnsafeMonitoringRef
}

/**
  * Slice of [[EffectRuntime]], to be used only when a reference
  * to [[logging.SafeLogger]] is needed.
  */
trait EffectRuntimeLogger[F[_]] extends UnsafeRuntimeLogger {
  protected implicit def F: Sync[F]
  def logger: SafeLogger[F]
}

/**
  * Our evolved `cats.effect.ContextShift` that has everything we need in it
  * to execute effects.
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
