---
title: "Cancellable HTTP requests via Scala's Tapir"
date: 2024-09-29T11:21:34+03:00
last_modified_at: 2024-09-29T12:26:11+03:00
tags:
  - Cats Effect
  - Programming
  - Scala
  - Snippet
description: >
  This sample shows an HTTP server and an HTTP client that can cleanly cancel requests. It's using Tapir and Sttp, with Netty and AsyncHttpClient backends, all powered by Cats-Effect.
---

<p class="intro">
  This sample shows an HTTP server and an HTTP client, that can cleanly cancel requests, both on the client-side and on the server-side. This is needed for safe disposal of resources. 
</p>

On the client-side, it's important to close or reuse the connection early, to avoid connection leaks. And on the server-side, the cancellation signal can be received when the client closes its connection, so the server may choose to cancel the processing of the request, since there's no longer a client waiting for the response.

This sample is using [Tapir](https://github.com/softwaremill/tapir) for describing HTTP endpoints. For the server backend, Tapir is configured to use Netty. And for the client making HTTP requests, it's using [Sttp](https://github.com/softwaremill/sttp), powered by the standard [async-http-client](https://github.com/AsyncHttpClient/async-http-client). And I'm also using [Cats-Effect](https://github.com/typelevel/cats-effect), as the effect system because it rocks, with its interruption model being best in class.

```scala
#!/usr/bin/env -S scala shebang

//> using scala "3.3.4"
//> using dep "com.softwaremill.sttp.tapir::tapir-netty-server-cats:1.11.5"
//> using dep "com.softwaremill.sttp.tapir::tapir-sttp-client:1.11.5"
//> using dep "com.softwaremill.sttp.client3::async-http-client-backend-cats:3.9.8"
//> using dep "org.typelevel::cats-effect:3.5.4"
//> using dep "org.slf4j:slf4j-nop:2.0.16"

import cats.effect.*
import cats.effect.std.Dispatcher
import sttp.tapir.*
import sttp.tapir.server.netty.cats.NettyCatsServer
import sttp.client3.*
import sttp.client3.asynchttpclient.cats.AsyncHttpClientCatsBackend
import sttp.tapir.client.sttp.SttpClientInterpreter
import scala.concurrent.duration.*
import scala.concurrent.TimeoutException

object Endpoints:
  type Type = Endpoint[Unit, Unit, Unit, String, Any]

  val slow: Type = endpoint.get
    .in("slow")
    .out(stringBody)

  val fast: Type = endpoint.get
    .in("fast")
    .out(stringBody)

def startServer: Resource[IO, Unit] =
  val fastEndpoint = Endpoints.fast.serverLogic: _ =>
    IO.pure(Right("fast response"))

  val slowEndpoint = Endpoints.slow.serverLogic: _ =>
    IO.monotonic.flatMap: startedAt =>
      val task =
        for
          _ <- IO.println("[Server] Received ping request!")
          _ <- IO.sleep(10.seconds)
        yield Right("slow response")

      task.onCancel:
        for
          now <- IO.monotonic
          elapsedSecs = (now - startedAt).toNanos / 1_000_000_000.0
          _ <- IO.println(
            f"[Server] Request cancelled after $elapsedSecs%.2f seconds!"
          )
        yield ()

  for
    d <- Dispatcher.parallel[IO]
    _ <- Resource
      .make:
        NettyCatsServer[IO](d)
          .port(8080)
          .addEndpoints(List(fastEndpoint, slowEndpoint))
          .start()
      .apply: s =>
        for
          _ <- IO.println("[Server] Shutting down...")
          _ <- s.stop()
          _ <- IO.println("[Server] Bye, bye 👋")
        yield ()
  yield ()

def makeRequest(e: Endpoints.Type, backend: SttpBackend[IO, Any]): IO[Unit] =
  val send = SttpClientInterpreter()
    .toRequest(e, Some(uri"http://localhost:8080"))
    .apply(())
    .response(asStringAlways)
    .send(backend)
    .flatMap: response =>
      IO.println(s"[Client] Response: ${response.body}")
    .timeout(1.second)
    .recoverWith:
      case _: TimeoutException =>
        IO(System.err.println("[Client] ERROR: Request timed out!"))
      case e =>
        IO.apply:
          System.err.println(s"[Client] ERROR Request failed!")
          e.printStackTrace()
  for
    _ <- IO.println(s"[Client] Sending request to ${e.show}")
    _ <- send
  yield ()

object Main extends IOApp.Simple:
  override def run: IO[Unit] =
    val resources =
      for
        _ <- startServer
        clientBackend <- AsyncHttpClientCatsBackend.resource[IO]()
      yield clientBackend

    resources.use: clientBackend =>
      for
        _ <- makeRequest(Endpoints.fast, clientBackend)
        _ <- makeRequest(Endpoints.slow, clientBackend)
      yield ()
```

To run this sample, you can use [Scala CLI](https://scala-cli.virtuslab.org/), which is the default `scala` launcher since Scala 3.5.0. For macOS:

```bash
# Installs the latest Scala via Homebrew
brew install scala

# Makes the above script executable
chmod +x ./tapir-client-server.scala

# Runs the above script
./tapir-client-server.scala
```
