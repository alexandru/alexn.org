package alexn.build

import cats.effect.ExitCode
import cats.effect.IO
import cats.effect.IOApp

import java.nio.file.Path

object Main extends IOApp {
  private final case class Settings(command: Command, outputDirectory: Path, port: Int)

  private sealed trait Command
  private object Command {
    case object Build extends Command
    case object Serve extends Command
  }

  def run(args: List[String]): IO[ExitCode] = {
    parse(args) match {
      case Left(message) =>
        IO.println(message) *> IO.println(usage).as(ExitCode.Error)
      case Right(settings) =>
        execute(settings).as(ExitCode.Success)
    }
  }

  private def execute(settings: Settings): IO[Unit] = {
    settings.command match {
      case Command.Build =>
        SiteBuilder.build(settings.outputDirectory) *>
          IO.println(s"Built Laika scaffold into ${settings.outputDirectory.toAbsolutePath.normalize()}")
      case Command.Serve =>
        SiteBuilder.build(settings.outputDirectory) *>
          PreviewServer
            .serve(settings.outputDirectory, settings.port)
            .use { boundPort =>
              IO.println(s"Serving ${settings.outputDirectory.toAbsolutePath.normalize()} at http://127.0.0.1:$boundPort") *>
                IO.never
            }
    }
  }

  private def parse(args: List[String]): Either[String, Settings] = {
    args match {
      case Nil =>
        Left("Missing command.")
      case command :: tail =>
        val parsedCommand =
          command match {
            case "build" => Right(Command.Build)
            case "serve" => Right(Command.Serve)
            case other => Left(s"Unknown command: $other")
          }

        parsedCommand.flatMap { command =>
          parseFlags(tail, command, Path.of("_site-laika"), 4000)
        }
    }
  }

  private def parseFlags(
      args: List[String],
      command: Command,
      outputDirectory: Path,
      port: Int
  ): Either[String, Settings] = {
    args match {
      case Nil =>
        Right(Settings(command, outputDirectory, port))
      case "--out" :: value :: tail =>
        parseFlags(tail, command, Path.of(value), port)
      case "--port" :: value :: tail =>
        value.toIntOption match {
          case Some(parsed) if parsed > 0 => parseFlags(tail, command, outputDirectory, parsed)
          case _ => Left(s"Invalid port: $value")
        }
      case flag :: _ =>
        Left(s"Unknown or incomplete option: $flag")
    }
  }

  private val usage =
    "Usage: scala-cli run build.scala -- <build|serve> [--out <directory>] [--port <port>]"
}
