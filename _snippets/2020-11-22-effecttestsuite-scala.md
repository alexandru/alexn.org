---
title: "EffectTestSuite[F].scala"
date: 2020-11-22 12:41:11+0200
image: /assets/media/snippets/test-effect-suite.png
tags:
  - Cats Effect
  - FP
  - Programming
  - Scala
---

Helpers for [ScalaTest](https://www.scalatest.org/) for testing effects (e.g. `cats.effect.IO`, `monix.eval.Task`). This is similar to [PureApp]({% link _snippets/2020-10-15-generic-ioapp-alternative.md %}).

**Requirement:** [EffectRuntime]({% link _snippets/2020-10-12-effect-runtime.md %}) (snippet)

Usage:

```scala
object Fns {
  def fireMissiles[F[_]: Sync]: F[Int] =
    Sync[F].delay {
      println("Firing missiles...")
      Random.nextInt(100) + 1
    }
}

class MyTestSuite extends EffectTestSuite.ForIO {
  testEffect("fire missiles") {
    for {
      count <- Fns.fireMissiles
    } yield {
      assert(count > 0)
    }
  }
}
```

Implementation:

```scala
import cats.effect._
import org.scalactic.source
import org.scalatest.compatible.Assertion
import org.scalatest.funsuite.AsyncFunSuiteLike
import org.scalatest.{ BeforeAndAfterAll, Tag }
import scala.concurrent.Promise
import scala.concurrent.duration._

trait EffectTestSuite[F[_]] extends AsyncFunSuiteLike {
  protected def effectTimeout: FiniteDuration = 30.seconds

  protected def testEffect(testName: String, testTags: Tag*)(
    testFun: => F[Assertion]
  )(implicit F: ConcurrentEffect[F], timer: Timer[F], pos: source.Position): Unit = {
    test(testName, testTags: _*) {
      val task = Concurrent.timeout(testFun, effectTimeout)
      val p = Promise[Assertion]()
      F.runAsync(task)(r => F.delay { p.complete(r.toTry); () }
      p.future
    }
  }
}

object EffectTestSuite {
  /** For working with `cats.effect.IO`
    */
  trait ForIO extends EffectTestSuite[IO] with BeforeAndAfterAll {
    protected def runtimeFactory: Resource[SyncIO, EffectRuntime[IO]] = {
      // This should be a concrete implementation
      ???
    }

    protected final lazy val (runtimeRef, runtimeCancel) = {
      runtimeFactory
        .allocated
        .unsafeRunSync()
    }

    override protected def beforeAll(): Unit = {
      super.beforeAll()
      // forces initialization
      runtimeRef; ()
    }

    override protected def afterAll(): Unit = {
      super.afterAll()
      runtimeCancel.unsafeRunSync()
    }

    protected implicit lazy val contextShift: EffectRuntime[IO] =
      runtimeRef

    protected implicit lazy val F: ConcurrentEffect[IO] =
      IO.ioConcurrentEffect(contextShift)

    protected implicit lazy val timer: Timer[IO] =
      runtimeRef.timer(F)
  }
}
```
