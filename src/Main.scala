package alexn.build

import cats.effect.ExitCode
import cats.effect.IO
import cats.effect.IOApp
import cats.syntax.all.*
import com.monovore.decline.Command
import com.monovore.decline.Opts

import java.nio.file.Path

object Main extends IOApp {
  private final case class Settings(command: CommandKind, outputDirectory: Path, port: Int)

  private sealed trait CommandKind
  private object CommandKind {
    case object Build extends CommandKind
    case object Serve extends CommandKind
    case object Verify extends CommandKind
  }

  private val outputDirectoryOpt =
    Opts
      .option[String]("out", help = "Output directory for generated site files")
      .withDefault("_site-laika")
      .map(Path.of(_))

  private val portOpt =
    Opts
      .option[Int]("port", help = "Port for the local preview server")
      .withDefault(4000)
      .validate("Port must be greater than 0")(_ > 0)

  private val buildCommand =
    Command("build", "Build the Laika scaffold output") {
      outputDirectoryOpt.map(Settings(CommandKind.Build, _, 4000))
    }

  private val serveCommand =
    Command("serve", "Build and serve the Laika scaffold locally") {
      (outputDirectoryOpt, portOpt).mapN(Settings(CommandKind.Serve, _, _))
    }

  private val verifyCommand =
    Command("verify", "Build the Laika scaffold and verify expected output files") {
      outputDirectoryOpt.map(Settings(CommandKind.Verify, _, 4000))
    }

  private val command =
    Command("alexn-build", "Scala-CLI entrypoint for the alexn.org Laika migration scaffold") {
      Opts.subcommands(buildCommand, List(serveCommand, verifyCommand))
    }

  def run(args: List[String]): IO[ExitCode] = {
    command.parse(args) match {
      case Left(help) =>
        IO.println(help.toString).as(ExitCode.Error)
      case Right(settings) =>
        execute(settings).as(ExitCode.Success)
    }
  }

  private def execute(settings: Settings): IO[Unit] = {
    settings.command match {
      case CommandKind.Build =>
        SiteBuilder.build(settings.outputDirectory) *>
          IO.println(s"Built Laika scaffold into ${settings.outputDirectory.toAbsolutePath.normalize()}")
      case CommandKind.Serve =>
        SiteBuilder.build(settings.outputDirectory) *>
          PreviewServer
            .serve(settings.outputDirectory, settings.port)
            .use { boundPort =>
              IO.println(s"Serving ${settings.outputDirectory.toAbsolutePath.normalize()} at http://127.0.0.1:$boundPort") *>
                IO.never
            }
      case CommandKind.Verify =>
        SiteBuilder.build(settings.outputDirectory) *>
          SiteVerifier.verify(settings.outputDirectory) *>
          IO.println(s"Verified Laika scaffold output in ${settings.outputDirectory.toAbsolutePath.normalize()}")
    }
  }
}
