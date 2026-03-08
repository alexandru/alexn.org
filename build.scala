//> using scala "3.8.2"
//> using options "-no-indent" "-rewrite"
//> using dep "org.typelevel::laika-io:1.3.2"
//> using dep "org.typelevel::cats-effect:3.6.3"
//> using dep "com.monovore::decline-effect:2.6.0"
//> using dep "org.slf4j:slf4j-nop:2.0.17"

import com.monovore.decline.effect.CommandIOApp
import com.monovore.decline.{Command, Opts}
import cats.effect.{IO, ExitCode}

/** Thin Scala-CLI command entrypoint for the Laika build.
  *
  * Run with:
  *   scala-cli run build.scala src/ -- build [--out <dir>]
  *   scala-cli run build.scala src/ -- serve [--port <port>]
  *   scala-cli run build.scala src/ -- verify
  */
object Main extends CommandIOApp(
  name    = "build",
  header  = "alexn.org site build tool (Laika)"
) {
  override def main: Opts[IO[ExitCode]] = {
    Build.command
  }
}
