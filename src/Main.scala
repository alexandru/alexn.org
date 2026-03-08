package alexn.build

import cats.effect.ExitCode
import cats.effect.IO
import cats.effect.IOApp
import cats.syntax.all.*
import com.monovore.decline.Command
import com.monovore.decline.Opts

import java.nio.file.Path

object Main extends IOApp {
  private val defaultPort = 4000

  private sealed trait AppCommand {
    def outputDirectory: Path
  }
  private object AppCommand {
    final case class Build(outputDirectory: Path) extends AppCommand
    final case class Serve(outputDirectory: Path, port: Int) extends AppCommand
    final case class Verify(outputDirectory: Path) extends AppCommand
  }

  private val outputDirectoryOpt =
    Opts
      .option[String]("out", help = "Output directory for generated site files")
      .withDefault("_site-laika")
      .map(Path.of(_))

  private val portOpt =
    Opts
      .option[Int]("port", help = "Port for the local preview server")
      .withDefault(defaultPort)
      .validate("Port must be greater than 0")(_ > 0)

  private val buildCommand: Command[AppCommand] =
    Command("build", "Build the Laika scaffold output") {
      outputDirectoryOpt.map[AppCommand](AppCommand.Build(_))
    }

  private val serveCommand: Command[AppCommand] =
    Command("serve", "Build and serve the Laika scaffold locally") {
      (outputDirectoryOpt, portOpt).mapN[AppCommand](AppCommand.Serve(_, _))
    }

  private val verifyCommand: Command[AppCommand] =
    Command("verify", "Build the Laika scaffold and verify expected output files") {
      outputDirectoryOpt.map[AppCommand](AppCommand.Verify(_))
    }

  private val command =
    Command("alexn.org", "Scala-CLI entrypoint for the alexn.org Laika migration scaffold") {
      Opts.subcommands(
        buildCommand, 
        serveCommand, 
        verifyCommand
      )
    }

  def run(args: List[String]): IO[ExitCode] = {
    command.parse(args) match {
      case Left(help) =>
        IO.println(help.toString).as(ExitCode.Error)
      case Right(settings) =>
        execute(settings).as(ExitCode.Success)
    }
  }

  private def execute(command: AppCommand): IO[Unit] = {
    command match {
      case AppCommand.Build(outputDirectory) =>
        SiteBuilder.build(outputDirectory) *>
          IO.println(s"Built Laika scaffold into ${outputDirectory.toAbsolutePath.normalize()}")
      case AppCommand.Serve(outputDirectory, port) =>
        SiteBuilder.build(outputDirectory) *>
          PreviewServer
            .serve(outputDirectory, port)
            .use { boundPort =>
              IO.println(s"Serving ${outputDirectory.toAbsolutePath.normalize()} at http://127.0.0.1:$boundPort") *>
                IO.never
            }
      case AppCommand.Verify(outputDirectory) =>
        SiteBuilder.build(outputDirectory) *>
          SiteVerifier.verify(outputDirectory) *>
          IO.println(s"Verified Laika scaffold output in ${outputDirectory.toAbsolutePath.normalize()}")
    }
  }
}
