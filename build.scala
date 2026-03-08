//> using scala "3.3.4"
//> using options "-no-indent", "-rewrite"
//> using dep "org.typelevel::laika-io:1.2.0"
//> using dep "org.typelevel::cats-effect:3.5.4"
//> using dep "org.slf4j:slf4j-nop:2.0.9"

import cats.effect.{IO, IOApp, ExitCode}

/** Thin Scala-CLI command entrypoint for the Laika build.
  *
  * Run with:
  *   scala-cli run build.scala src/ -- build [--out <dir>]
  *   scala-cli run build.scala src/ -- serve [--port <port>]
  *   scala-cli run build.scala src/ -- verify
  */
object Main extends IOApp {
  def run(args: List[String]): IO[ExitCode] = {
    Build.run(args)
  }
}
