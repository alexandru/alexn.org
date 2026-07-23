package alexn.build

import cats.effect.IO
import cats.syntax.all.*
import laika.api.Transformer
import laika.format.HTML
import laika.format.Markdown

import java.nio.charset.StandardCharsets
import java.nio.file.FileVisitResult
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.SimpleFileVisitor
import java.nio.file.StandardCopyOption
import java.nio.file.attribute.BasicFileAttributes

object SiteBuilder {
  private def markdownTransformer =
    Transformer
      .from(Markdown)
      .to(HTML)
      .using(Markdown.GitHubFlavor)
      .build

  def build(outputDirectory: Path): IO[Unit] = {
    val normalizedOutput = outputDirectory.toAbsolutePath.normalize()
    val repositoryRoot = Path.of(System.getProperty("user.dir")).toAbsolutePath.normalize()

    for {
      _ <- deleteIfExists(normalizedOutput)
      _ <- createDirectories(normalizedOutput)
      _ <- copyStaticInputs(repositoryRoot, normalizedOutput)
      _ <- SiteConfig.pages.traverse_(writePage(normalizedOutput, _))
    } yield ()
  }

  private def writePage(outputDirectory: Path, page: SitePage): IO[Unit] = {
    for {
      body <- renderMarkdown(page)
      content = renderShell(page, body)
      target = outputDirectory.resolve(page.outputPath)
      _ <- writeUtf8(target, content)
    } yield ()
  }

  private def renderMarkdown(page: SitePage): IO[String] = {
    IO.fromEither(
      markdownTransformer.transform(page.markdown).leftMap { error =>
        new RuntimeException(s"Unable to render page '${page.title}' (${page.outputPath}): $error")
      }
    )
  }

  private def copyStaticInputs(repositoryRoot: Path, outputDirectory: Path): IO[Unit] = {
    SiteConfig.staticInputs.traverse_ { input =>
      val source = repositoryRoot.resolve(input)
      val target = outputDirectory.resolve(input)

      pathExists(source).ifM(copyPath(source, target), IO.unit)
    }
  }

  private def pathExists(path: Path): IO[Boolean] = {
    IO.blocking(Files.exists(path))
  }

  private def createDirectories(path: Path): IO[Unit] = {
    IO.blocking(Files.createDirectories(path)).void
  }

  private def writeUtf8(path: Path, content: String): IO[Unit] = {
    IO.blocking {
      val parent = path.getParent
      if parent != null then {
        Files.createDirectories(parent)
      }
      Files.writeString(path, content, StandardCharsets.UTF_8)
    }.void
  }

  private def copyPath(source: Path, target: Path): IO[Unit] = {
    IO.blocking {
      if Files.isDirectory(source) then {
        Files.walkFileTree(
          source,
          new SimpleFileVisitor[Path] {
            override def preVisitDirectory(
                dir: Path,
                attrs: BasicFileAttributes
            ): FileVisitResult = {
              Files.createDirectories(target.resolve(source.relativize(dir)))
              FileVisitResult.CONTINUE
            }

            override def visitFile(file: Path, attrs: BasicFileAttributes): FileVisitResult = {
              Files.copy(
                file,
                target.resolve(source.relativize(file)),
                StandardCopyOption.REPLACE_EXISTING,
                StandardCopyOption.COPY_ATTRIBUTES
              )
              FileVisitResult.CONTINUE
            }
          }
        )
      } else {
        val parent = target.getParent
        if parent != null then {
          Files.createDirectories(parent)
        }
        Files.copy(
          source,
          target,
          StandardCopyOption.REPLACE_EXISTING,
          StandardCopyOption.COPY_ATTRIBUTES
        )
      }
    }.void
  }

  private def deleteIfExists(path: Path): IO[Unit] = {
    pathExists(path).ifM(
      IO.blocking {
        Files.walkFileTree(
          path,
          new SimpleFileVisitor[Path] {
            override def visitFile(file: Path, attrs: BasicFileAttributes): FileVisitResult = {
              Files.delete(file)
              FileVisitResult.CONTINUE
            }

            override def postVisitDirectory(
                dir: Path,
                exc: java.io.IOException
            ): FileVisitResult = {
              Files.delete(dir)
              FileVisitResult.CONTINUE
            }
          }
        )
      }.void,
      IO.unit
    )
  }

  private def renderShell(page: SitePage, body: String): String = {
    val pageTitle = page.title
    val title =
      if pageTitle == "Home" then {
        SiteConfig.title
      } else {
        s"$pageTitle · ${SiteConfig.title}"
      }

    val canonicalPath =
      if page.outputPath == "index.html" then {
        "/"
      } else if page.outputPath == "404.html" then {
        "/404.html"
      } else {
        s"/${page.outputPath.stripSuffix("index.html")}"
      }

    val navigation = SiteConfig.navigation
      .map(link => s"<a href=\"${escapeHtml(link.href)}\">${escapeHtml(link.label)}</a>")
      .mkString("\n          ")

    s"""<!DOCTYPE html>
       |<html lang="en">
       |  <head>
       |    <meta charset="utf-8" />
       |    <meta name="viewport" content="width=device-width, initial-scale=1" />
       |    <title>${escapeHtml(title)}</title>
       |    <meta name="description" content="${escapeHtml(SiteConfig.description)}" />
       |    <link rel="canonical" href="${escapeHtml(SiteConfig.domain + canonicalPath)}" />
       |    <style>
       |      :root { color-scheme: light dark; }
       |      body { font-family: system-ui, sans-serif; margin: 0; padding: 0; line-height: 1.6; }
       |      header, main, footer { max-width: 56rem; margin: 0 auto; padding: 1.5rem; }
       |      header { padding-bottom: 0.5rem; }
       |      nav { display: flex; flex-wrap: wrap; gap: 1rem; margin-top: 0.75rem; }
       |      a { color: inherit; }
       |      main { padding-top: 0; }
       |      .notice { border: 1px solid currentColor; border-radius: 0.5rem; padding: 1rem; }
       |      code { font-family: ui-monospace, monospace; }
       |    </style>
       |  </head>
       |  <body>
       |    <header>
       |      <strong>${escapeHtml(SiteConfig.title)}</strong>
       |      <nav>
       |        $navigation
       |      </nav>
       |    </header>
       |    <main>
       |      <div class="notice">
       |        $body
       |      </div>
       |    </main>
       |    <footer>
       |      <small>Generated by the Scala-CLI Laika migration scaffold.</small>
       |    </footer>
       |  </body>
       |</html>
       |""".stripMargin
  }

  private def escapeHtml(value: String): String = {
    value
      .replace("&", "&amp;")
      .replace("<", "&lt;")
      .replace(">", "&gt;")
      .replace("\"", "&quot;")
      .replace("'", "&#39;")
  }
}
