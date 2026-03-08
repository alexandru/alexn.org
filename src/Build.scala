import cats.effect.{IO, ExitCode, Resource}
import cats.syntax.all.*
import laika.api.Transformer
import laika.format.{Markdown, HTML}
import laika.io.syntax.*
import laika.io.model.{InputTree, InputTreeBuilder}
import laika.io.api.TreeTransformer
import laika.ast.Path.Root
import extensions.CompatBundle

/** Main build pipeline orchestration.
  *
  * Commands:
  *   build  -- render all content to _site-laika/ (or --out <dir>)
  *   serve  -- start a local preview server (--port <n>, default 4000)
  *   verify -- compare selected Laika output against Jekyll baseline
  */
object Build {

  def run(args: List[String]): IO[ExitCode] = {
    args match {
      case "build" :: rest  => runBuild(parseOutDir(rest))
      case "serve" :: rest  => runServe(parsePort(rest))
      case "verify" :: _    => runVerify()
      case _                => printUsage *> IO.pure(ExitCode.Error)
    }
  }

  // ---------------------------------------------------------------------------
  // Argument helpers

  private def parseOutDir(args: List[String]): String = {
    val idx = args.indexOf("--out")
    if (idx >= 0 && idx + 1 < args.length) args(idx + 1)
    else "_site-laika"
  }

  private def parsePort(args: List[String]): Int = {
    val idx = args.indexOf("--port")
    if (idx >= 0 && idx + 1 < args.length)
      args(idx + 1).toIntOption.getOrElse(4000)
    else 4000
  }

  private val printUsage: IO[Unit] = IO.println(
    """|Usage:
       |  scala-cli run build.scala src/ -- build  [--out <dir>]
       |  scala-cli run build.scala src/ -- serve  [--port <port>]
       |  scala-cli run build.scala src/ -- verify""".stripMargin
  )

  // ---------------------------------------------------------------------------
  // Transformer

  /** Laika transformer with GitHub-flavoured Markdown and the site-specific
    * compatibility bundle.  Returned as a `Resource` so that the underlying
    * thread pool is properly released on completion or error.
    */
  def transformerResource: Resource[IO, TreeTransformer[IO]] = {
    Transformer
      .from(Markdown)
      .to(HTML)
      .using(Markdown.GitHubFlavor, CompatBundle)
      .parallel[IO]
      .build
  }

  // ---------------------------------------------------------------------------
  // Input tree

  /** Builds the virtual input tree by merging:
    *   - Static passthrough assets (assets/, robots.txt, manifest.webmanifest,
    *     crossdomain.xml, 404.html, CNAME)
    *   - Standalone pages under docs/
    *
    * Blog posts (_posts/) and wiki pages (_wiki/) will be wired in W2 once
    * the permalink / front-matter compatibility layer is in place.
    */
  def inputTree: InputTreeBuilder[IO] = {
    InputTree[IO]
      // Static assets: preserve the assets/ prefix in the output tree
      .addDirectory("assets", Root / "assets")
      // Passthrough files expected at the root of the generated site
      .addFile("robots.txt", Root / "robots.txt")
      .addFile("manifest.webmanifest", Root / "manifest.webmanifest")
      .addFile("crossdomain.xml", Root / "crossdomain.xml")
      .addFile("404.html", Root / "404.html")
      .addFile("CNAME", Root / "CNAME")
      // Static HTML/markdown pages under docs/
      .addDirectory("docs", Root / "docs")
  }

  // ---------------------------------------------------------------------------
  // Commands

  def runBuild(outDir: String): IO[ExitCode] = {
    transformerResource.use { transformer =>
      transformer
        .fromInput(inputTree)
        .toDirectory(outDir)
        .transform
        .as(ExitCode.Success)
    }
  }

  def runServe(port: Int): IO[ExitCode] = {
    // Preview server via laika.preview.ServerBuilder will be wired in a
    // later workstream once the full input tree is stable.
    IO.println(
      s"Preview server on port $port is not yet implemented. " +
        "Use 'bundle exec jekyll serve' in the meantime."
    ) *> IO.pure(ExitCode.Error)
  }

  def runVerify(): IO[ExitCode] = {
    // Parity comparison against Jekyll baseline will be implemented in W11.
    IO.println(
      "Verify: side-by-side Jekyll vs Laika comparison not yet implemented."
    ) *> IO.pure(ExitCode.Success)
  }
}
