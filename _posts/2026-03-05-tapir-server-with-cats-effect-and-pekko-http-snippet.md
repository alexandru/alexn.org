---
title: "Tapir Server with Cats-Effect and Pekko HTTP (snippet)"
image: /assets/media/articles/2026-tapir-cats-effect-akka-http.png
image_hide_in_post: true
date: 2026-03-05T14:27:35+02:00
last_modified_at: 2026-03-05T14:37:35+02:00
tags:
  - Akka
  - Cats Effect
  - Pekko
  - Programming
  - Scala
  - Snippet
description: >
  Simple snippet for using Tapir, with business logic driven by Cats-Effect, using Akka/Pekko HTTP as a backend.
---

At work, we have been using [Akka/Pekko HTTP](https://pekko.apache.org/docs/pekko-http/current/) for some servers, but one of the foundations is [Cats-Effect](https://typelevel.org/cats-effect/), and I wanted to use [Tapir](https://tapir.softwaremill.com/) for refactoring one of our microservices.

<p class="info-bubble" markdown="1">
As you may have noticed, I sometimes use this blog as a replacement for GitHub Gist.
</p>

Here's a simple snippet for using Tapir, with business logic driven by Cats-Effect, using Akka/Pekko HTTP as a backend:

```scala
#!/usr/bin/env -S scala shebang

//> using scala "3.8.2"
//> using dep com.softwaremill.sttp.tapir::tapir-core:1.13.10
//> using dep com.softwaremill.sttp.tapir::tapir-pekko-http-server:1.13.10
//> using dep org.typelevel::cats-effect:3.6.3
//> using dep org.apache.pekko::pekko-http:1.3.0
//> using dep org.apache.pekko::pekko-actor-typed:1.4.0

import cats.effect.*
import cats.effect.std.Dispatcher
import org.apache.pekko.actor.typed.ActorSystem
import org.apache.pekko.actor.typed.scaladsl.Behaviors
import org.apache.pekko.http.scaladsl.Http
import org.apache.pekko.http.scaladsl.server.Route
import scala.concurrent.ExecutionContext
import sttp.tapir.*
import sttp.tapir.server.pekkohttp.PekkoHttpServerInterpreter

object Main extends IOApp.Simple {

  // Endpoint definition (pure tapir, no effect type yet)
  val helloWorldEndpoint =
    endpoint.get
      .in("hello" / "world")
      .in(query[String]("name"))
      .out(stringBody)
      .errorOut(stringBody)

  // Business logic described via Cats Effect IO functions
  def greetLogic(name: String): IO[Either[String, String]] =
    IO.println(s"Saying hello to: $name")
      .as(Right(s"Hello, $name!"))

  // Bridge: IO logic → Future, as required by the Pekko HTTP interpreter
  def helloWorldRoute(using Dispatcher[IO], ExecutionContext): Route =
    PekkoHttpServerInterpreter().toRoute(
      helloWorldEndpoint.serverLogic(name => 
        summon[Dispatcher[IO]].unsafeToFuture(greetLogic(name))
      )
    )

  override def run: IO[Unit] = {
    val res =
      for {
        given Dispatcher[IO] <- Dispatcher.parallel[IO]
        given ExecutionContext <- Resource.eval(IO.executionContext)
        given ActorSystem[Nothing] <- Resource(IO {
          val system = ActorSystem(Behaviors.empty, "tapir-pekko-sample")
          val cancel = IO.fromFuture(IO {
            val f = system.whenTerminated
            system.terminate()
            f
          })
          (system, cancel.void)
        })
        _ <- Resource(IO {
          // Starts server
          val bound = Http().newServerAt("localhost", 8383)
            .bind(helloWorldRoute)
          val cancel =
            IO.fromFuture(IO {
              bound.flatMap(_.unbind())
            });
          (bound, cancel.void)
        })
      } yield ()

    res.use { _ =>
      for {
        _ <- IO.println(
          "Server running at http://localhost:8383 — press ENTER to stop"
        )
        _ <- IO.readLine.void
      } yield ()
    }
  }
}
```
