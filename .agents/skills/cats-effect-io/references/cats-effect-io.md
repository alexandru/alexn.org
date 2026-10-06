# Cats Effect IO and Typeclasses (Scala)

Sources:
- https://typelevel.org/cats-effect/docs/tutorial
- https://typelevel.org/cats-effect/docs/concepts
- https://typelevel.org/cats-effect/docs/recipes
- https://typelevel.org/cats-effect/docs/faq
- https://typelevel.org/cats-effect/docs/core/test-runtime

## Table of Contents
- [Core ideas](#core-ideas)
- [Blocking and interruptibility](#blocking-and-interruptibility)
- [Resource safety](#resource-safety)
- [Execution boundary rules](#execution-boundary-rules)
- [Common recipes](#common-recipes)
- [API samples](#api-samples)
- [Testing guidance](#testing-guidance)
- [FAQ highlights](#faq-highlights)

## Core ideas
- **Effects as values**: `IO[A]` (or `F[A]`) describes side effects; nothing runs until the effect is evaluated.
- **Fibers** are lightweight threads; use structured concurrency (`parMapN`, `parTraverse`) instead of manual `start`/`join`.
- **Cancelation** is cooperative and always runs finalizers; use `Resource` to ensure cleanup under success, error, or cancel.
- **Asynchronous vs synchronous**: `IO.async` uses callbacks; `IO.delay`/`IO.blocking`/`IO.interruptible` use synchronous execution.

## Blocking and interruptibility
- `IO.blocking` (or `Sync[F].blocking`) moves blocking JVM calls onto the blocking pool.
- `IO.interruptible` allows cancelation via thread interruption when the underlying API supports it.
- Many `java.io` reads ignore interruption; use explicit cancelation protocols when available.

## Resource safety
- Prefer `Resource` over manual `try/finally` for acquisition/release.
- Use `Resource.fromAutoCloseable` for simple `AutoCloseable` lifecycles; use `Resource.make` when you need custom release handling.

## Execution boundary rules
- Treat `unsafeRun*` as a runtime-boundary operation only; application and test code should not call it.
- `import cats.effect.unsafe.implicits.global` is banned.
- Keep effect execution at framework boundaries (`IOApp`, http server runtimes, stream runtimes).
- To bridge non-Cats-Effect callback APIs, use `Dispatcher`.

## Common recipes
- **Dispatcher provisioning**: resource-scoped components may create and use their own `Dispatcher` inside that same `Resource`; otherwise require `Dispatcher` as a parameter (`using`/implicit is fine).
- **Background work**: use `Supervisor` for start-and-forget fibers with safe cleanup.
- **Effectful loops**: use `traverse`/`traverse_` and `parTraverse` for sequencing or parallelism.
- **Shared state**: use `Ref`, `Deferred`, and other std primitives (avoid mutable state).

## API samples

Side effects as values (IO vs F[_]):
```scala
import cats.effect.{IO, Sync}

def nowIO: IO[Long] = IO(java.time.Instant.now().toEpochMilli)

def nowF[F[_]: Sync]: F[Long] =
  Sync[F].delay(java.time.Instant.now().toEpochMilli)
```

Polymorphic side effects:
```scala
import cats.effect.Sync

def readEnv[F[_]: Sync](key: String): F[Option[String]] =
  Sync[F].delay(sys.env.get(key))
```

Blocking vs interruptible:
```scala
import cats.effect.{IO, Sync}

import java.io.FileInputStream

def readByteIO(path: String): IO[Int] =
  IO.blocking(new FileInputStream(path)).bracket { in =>
    IO.interruptible(in.read())
  } { in =>
    IO.blocking(in.close())
  }

val blockingCall: IO[Unit] = IO.blocking {
  java.nio.file.Files.list(java.nio.file.Paths.get("/tmp")).close()
}

def interruptibleSleep[F[_]: Sync]: F[Unit] =
  Sync[F].interruptible(Thread.sleep(250))
```

Resource usage:
```scala
import cats.effect.{IO, Resource}
import java.io.FileInputStream

def inputStream(path: String): Resource[IO, FileInputStream] =
  Resource.fromAutoCloseable(IO.blocking(new FileInputStream(path)))

def readFirstByte(path: String): IO[Int] =
  inputStream(path).use(in => IO.interruptible(in.read()))
```

Structured concurrency:
```scala
import cats.effect.{IO, IOApp}
import cats.syntax.all._

object ParallelExample extends IOApp.Simple {
  val run: IO[Unit] =
    (IO.println("A"), IO.println("B")).parTupled.void
}
```

Akka Streams interop with `mapAsync`:
```scala
import akka.stream.scaladsl.Source
import cats.effect.std.Dispatcher
import cats.effect.IO

/** Interop example showcasing a legitimate `unsafeToFuture` call. */
extension [A, Mat](self: Source[A, Mat])
  def mapIO[B](parallelism: Int)(f: A => IO[B])(using Dispatcher[IO]): Source[B, Mat] =
    self.mapAsync(parallelism) {
      a => summon[Dispatcher[IO]].unsafeToFuture(f(a))
    }
```

## Testing guidance
- Prefer test frameworks/modules that accept effectful tests (`IO[Assertion]`, `F[Assertion]`) instead of manual `unsafeRun*`.
- Avoid real sleeping in unit tests. Use virtual time with `TestControl` for deterministic scheduling.
- `SyncIO` can be lifted without running it: `val io: IO[A] = syncIo.to[IO]`.

Virtual-time test example:
```scala
import cats.effect.IO
import cats.effect.testkit.TestControl
import scala.concurrent.duration._

val test: IO[Int] =
  IO.sleep(1.second) *> IO.pure(42)

val result: IO[Int] =
  TestControl.executeEmbed(test)
```

## FAQ highlights
- If an `IO` is created but not composed, it does not run; compiler warnings can help catch this.
- `IO(...)` may run on a blocking thread in some optimized cases; this is normal.
- Starvation warnings often indicate accidental blocking without `IO.blocking`.
