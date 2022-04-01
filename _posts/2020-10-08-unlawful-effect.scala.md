---
title: "Scala Snippet: Unlawful Effects"
image: /assets/media/snippets/unlawful-effect.png
image_hide_in_post: true
tags:
  - Cats Effect
  - Scala
  - Snippet
feed_guid: /snippets/2020/10/08/unlawful-effect.scala/
redirect_from:
  - /snippets/2020/10/08/unlawful-effect.scala/
  - /snippets/2020/10/08/unlawful-effect.scala.html
description: >
  Unlawful/independent version of `cats.effect.Effect`.
last_modified_at: 2022-04-01 16:36:39 +03:00
---

Unlawful/independent version of `cats.effect.Effect` from Cats Effect v2. Allows for converting (and executing) `IO`-like values to `scala.concurrent.Future`, being also good for a graceful migration to Cats Effect v3:

```scala
import cats.ApplicativeError
import cats.effect.{ Effect, IO }
import cats.implicits._
import simulacrum.typeclass
import scala.concurrent.{ Future, Promise }

/**
  * Type class defining an "unlawful" variant of `cats.effect.Effect`.
  *
  * This allows it to work with plain `Future`, which cannot implement `Effect`.
  * It also allows for a graceful migration to Cats Effect v3.
  *
  * NOTE: if the requirement is `F[_] : Sync : UnlawfulEffect` then this
  * is de facto equivalent with `Effect`, therefore `UnlawfulEffect` shouldn't
  * be used.
  */
@typeclass trait UnlawfulEffect[F[_]] {
  def unsafeToFuture[A](fa: F[A]): Future[A]
}

object UnlawfulEffect extends UnlawfulEffectLowLevelImplicits {
  /**
    * Standard `Future` instance, which couldn't be a lawful `Effect`.
    */
  implicit val forFuture: UnlawfulEffect[Future] =
    new UnlawfulEffect[Future] {
      override def unsafeToFuture[A](fa: Future[A]): Future[A] =
        fa
    }

  /**
    * Optimization for `cats.effect.IO`, even if this should be handled by
    * [[forAnyEffect]].
    */
  implicit val forIO: UnlawfulEffect[IO] =
    new UnlawfulEffect[IO] {
      override def unsafeToFuture[A](fa: IO[A]): Future[A] =
        fa.unsafeToFuture()
    }
}

trait UnlawfulEffectLowLevelImplicits { self: UnlawfulEffect.type =>
  /**
    * Converts from:
    * [[https://typelevel.org/cats-effect/typeclasses/effect.html]]
    */
  implicit def forAnyEffect[F[_]](implicit F: Effect[F]): UnlawfulEffect[F] =
    new UnlawfulEffect[F] {
      override def unsafeToFuture[A](fa: F[A]): Future[A] = {
        val p = Promise[A]()
        F.runAsync(fa) { result =>
          // Not really cool to not suspend side-effects here, but
          // we know the context in which we are in, and it's fine, this time;
          // Don't try this at home!
          p.complete(result.toTry)
          IO.unit
        }.unsafeRunSync()
        p.future
      }
    }
}
```

We can then interact with more impure APIs, that aren't IO-driven:

```scala
import akka.stream.scaladsl.Flow

implicit class FlowOps[In, Out, Mat](flow: Flow[In, Out, Mat]) 
  extends AnyVal {

  def mapEffect[F[_]: UnlawfulEffect, Out2](
    parallelism: Int
  )(fa: Out => F[Out2]): Flow[In, Out2, Mat] = {
    flow.mapAsync(parallelism)(out => UnlawfulEffect.unsafeToFuture(fa(out)))
  }
}
```

Sample:

```scala
import cats.effect.IO

Flow[Int].mapEffect { num =>
  IO {
    println(s"Received: $num")
    num.toString
  }
}
```

This is similar to usage of [TaskLike](https://monix.io/api/current/monix/eval/TaskLike.html) in [Monix](https://monix.io).
