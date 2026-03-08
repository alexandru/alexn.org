import cats.effect.{IO, ExitCode, Resource}
import cats.syntax.all.*
import com.monovore.decline.{Command, Opts}
import laika.api.Transformer
import laika.format.{Markdown, HTML}
import laika.io.syntax.*
import laika.io.model.{InputTree, InputTreeBuilder}
import laika.io.api.TreeTransformer
import laika.ast.Path.Root
import extensions.CompatBundle

/** Main build pipeline orchestration.
  *
  * Subcommands (wired via Decline):
  *   build  -- render all content to _site-laika/ (or --out <dir>)
  *   serve  -- start a local preview server (--port <n>, default 4000)
  *   verify -- compare selected Laika output against Jekyll baseline
  */
object Build {

  // ---------------------------------------------------------------------------
  // CLI model (Decline)

  private val buildCmd: Command[IO[ExitCode]] = {
    val outDir = Opts
      .option[String]("out", help = "Output directory (default: _site-laika)", short = "o")
      .withDefault("_site-laika")
    Command("build", "Render the site to an output directory") {
      outDir.map(runBuild)
    }
  }

  private val serveCmd: Command[IO[ExitCode]] = {
    val port = Opts
      .option[Int]("port", help = "Port for the preview server (default: 4000)", short = "p")
      .withDefault(4000)
    Command("serve", "Start a local preview server") {
      port.map(runServe)
    }
  }

  private val verifyCmd: Command[IO[ExitCode]] = {
    Command("verify", "Compare Laika output against Jekyll baseline") {
      Opts(runVerify())
    }
  }

  /** Top-level Decline command exposed to `Main` in `build.scala`. */
  val command: Opts[IO[ExitCode]] = {
    Opts.subcommands(buildCmd, serveCmd, verifyCmd)
  }

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

