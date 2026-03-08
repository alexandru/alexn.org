package alexn.build

import cats.effect.IO
import cats.effect.Resource
import cats.effect.std.Dispatcher
import com.sun.net.httpserver.HttpExchange
import com.sun.net.httpserver.HttpHandler
import com.sun.net.httpserver.HttpServer

import java.net.InetSocketAddress
import java.nio.file.Files
import java.nio.file.Path
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

object PreviewServer {
  def serve(rootDirectory: Path, port: Int): Resource[IO, Int] = {
    Dispatcher.parallel[IO].flatMap { dispatcher =>
      Resource.make(start(rootDirectory.toAbsolutePath.normalize(), port, dispatcher))(_.stop).map(_.port)
    }
  }

  private def start(rootDirectory: Path, port: Int, dispatcher: Dispatcher[IO]): IO[RunningServer] = {
    IO.blocking {
      val server = HttpServer.create(new InetSocketAddress(port), 0)
      val executor = Executors.newCachedThreadPool()
      server.setExecutor(executor)
      server.createContext(
        "/",
        new HttpHandler {
          override def handle(exchange: HttpExchange): Unit = {
            dispatcher.unsafeRunAndForget(handleRequest(rootDirectory, exchange))
          }
        }
      )
      server.start()
      RunningServer(server, executor, port)
    }
  }

  private def handleRequest(rootDirectory: Path, exchange: HttpExchange): IO[Unit] = {
    val requestPath = Option(exchange.getRequestURI.getPath).getOrElse("/")

    resolveTarget(rootDirectory, requestPath).flatMap {
      case Some((status, target)) =>
        for {
          bytes <- IO.blocking(Files.readAllBytes(target))
          _ <- IO.blocking(exchange.getResponseHeaders.set("Content-Type", contentType(target)))
          _ <- IO.blocking(exchange.sendResponseHeaders(status, bytes.length.toLong))
          _ <- IO.blocking {
            val output = exchange.getResponseBody
            try {
              output.write(bytes)
            } finally {
              output.close()
            }
          }
        } yield ()
      case None =>
        IO.blocking(exchange.sendResponseHeaders(404, -1)).void
    }.guarantee(IO.blocking(exchange.close()).void)
  }

  private def resolveTarget(rootDirectory: Path, requestPath: String): IO[Option[(Int, Path)]] = {
    val sanitized = requestPath.stripPrefix("/")
    val base = rootDirectory.resolve(sanitized).normalize()
    val nestedIndex =
      if (sanitized.isEmpty) {
        rootDirectory.resolve("index.html").normalize()
      } else {
        rootDirectory.resolve(sanitized).resolve("index.html").normalize()
      }
    val candidates = List(
      base,
      base.resolve("index.html"),
      nestedIndex,
      rootDirectory.resolve("404.html").normalize()
    ).distinct

    candidates.foldLeft(IO.pure(Option.empty[(Int, Path)])) { (acc, candidate) =>
      acc.flatMap {
        case some @ Some(_) => IO.pure(some)
        case None =>
          if (!candidate.startsWith(rootDirectory)) {
            IO.pure(None)
          } else {
            IO.blocking(Files.isRegularFile(candidate)).map { exists =>
              if (exists) {
                val status = if (candidate == rootDirectory.resolve("404.html")) 404 else 200
                Some(status -> candidate)
              } else {
                None
              }
            }
          }
      }
    }
  }

  private def contentType(path: Path): String = {
    val name = path.getFileName.toString

    if (name.endsWith(".html")) {
      "text/html; charset=utf-8"
    } else if (name.endsWith(".css")) {
      "text/css; charset=utf-8"
    } else if (name.endsWith(".js")) {
      "application/javascript; charset=utf-8"
    } else if (name.endsWith(".json") || name.endsWith(".webmanifest")) {
      "application/manifest+json; charset=utf-8"
    } else if (name.endsWith(".xml")) {
      "application/xml; charset=utf-8"
    } else if (name.endsWith(".svg")) {
      "image/svg+xml"
    } else if (name.endsWith(".png")) {
      "image/png"
    } else if (name.endsWith(".jpg") || name.endsWith(".jpeg")) {
      "image/jpeg"
    } else if (name.endsWith(".webp")) {
      "image/webp"
    } else if (name.endsWith(".ico")) {
      "image/x-icon"
    } else if (name.endsWith(".txt")) {
      "text/plain; charset=utf-8"
    } else {
      "application/octet-stream"
    }
  }

  private final case class RunningServer(server: HttpServer, executor: ExecutorService, port: Int) {
    def stop: IO[Unit] = {
      IO.blocking {
        server.stop(0)
        executor.shutdown()
      }.void
    }
  }
}
