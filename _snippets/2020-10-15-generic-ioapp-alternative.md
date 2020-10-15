---
title: "Generic IOApp alternative"
date: 2020-10-15 10:05:19+0300
image: /assets/media/links/pureapp.png
tags:
  - Cats Effect
  - FP
  - Scala
---

This is a simple and generic [IOApp](https://typelevel.org/cats-effect/datatypes/ioapp.html) replacement. For those instances in which you want to work with `F[_]` and not `IO`, even in `main` apps.

Requirements:

- [EffectRuntime](./2020-10-12-effect-runtime.md) (snippet); or if not in the mood for that, replace it with the basic [cats.effect.ContextShift](https://typelevel.org/cats-effect/datatypes/contextshift.html)
- [Monix Catnap](https://monix.io/docs/3x/#monix-catnap)

```scala
import cats.effect._
import monix.catnap.SchedulerEffect

abstract class PureApp[F[_]](implicit protected val F: Async[F]) { self =>
  protected def runtime: Resource[SyncIO, EffectRuntime[F]]
  protected def effect(implicit r: EffectRuntime[F]): ConcurrentEffect[F]
  protected implicit def timer(implicit F: Concurrent[F], r: EffectRuntime[F]): Timer[F] = r.timer

  def run(args: List[String])(implicit
    F: ConcurrentEffect[F],
    r: EffectRuntime[F]
  ): F[ExitCode]

  final def main(args: Array[String]): Unit = {
    val (res, cancel) = runtime.allocated.unsafeRunSync()
    implicit val r = res
    try {
      new CustomIOApp()(effect(r), r).main(args)
    } finally {
      cancel.unsafeRunSync()
    }
  }

  private final class CustomIOApp(implicit F: ConcurrentEffect[F], runtime: EffectRuntime[F])
    extends IOApp {

    override protected implicit def contextShift: ContextShift[IO] =
      SchedulerEffect.contextShift[IO](runtime.unsafe.scheduler)(IO.ioEffect)
    override protected implicit def timer: Timer[IO] =
      SchedulerEffect.timerLiftIO[IO](runtime.unsafe.scheduler)(IO.ioEffect)
    override def run(args: List[String]): IO[ExitCode] =
      F.toIO(self.run(args))
  }
}

object PureApp {
  abstract class ForIO extends PureApp[IO] {
    override final def effect(implicit r: EffectRuntime[IO]): ConcurrentEffect[IO] =
      IO.ioConcurrentEffect(r)
  }
}
```

Sample:

```scala
abstract class MyGenericApp[F[_]: Async] extends PureApp[F] {
  
  def run(args: List[String])(implicit
    F: ConcurrentEffect[F],
    r: EffectRuntime[F]
  ): F[ExitCode] = {

    for {
      name <- Sync[F].delay(scala.io.StdIn.readLine())
      _ <- Sync[F].delay(println(s"Hello, $name"))
    } yield {
      ExitCode.Success
    }
  }
}

/**
 * Actual main implementation that the JVM can recognize.
 */
object MyApp extends MyGenericApp[IO] {
  override def runtime: Resource[SyncIO, EffectRuntime[F]] = 
    ???
  override def effect(implicit r: EffectRuntime[F]) = 
    IO.ioConcurrentEffect(r)
}
```
