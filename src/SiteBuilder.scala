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
      loadedContent <- ContentLoader.load(repositoryRoot)
      _ <- deleteIfExists(normalizedOutput)
      _ <- createDirectories(normalizedOutput)
      _ <- copyStaticInputs(repositoryRoot, normalizedOutput)
      _ <- (SiteConfig.staticPages ++ loadedContent.generatedPages).traverse_(writePage(normalizedOutput, _))
    } yield ()
  }

  private def writePage(outputDirectory: Path, page: SitePage): IO[Unit] = {
    for {
      body <- renderBody(page)
      content = renderShell(page, body)
      target = outputDirectory.resolve(page.outputPath)
      _ <- writeUtf8(target, content)
    } yield ()
  }

  private def renderBody(page: SitePage): IO[String] = {
    page.sourceFormat match {
      case SourceFormat.Markdown =>
        renderMarkdown(page)
      case SourceFormat.Html =>
        IO.pure(page.content)
    }
  }

  private def renderMarkdown(page: SitePage): IO[String] = {
    for {
      normalized <- expandMarkdownInHtmlBlocks(stripKramdownAttributes(page.content))
      rendered <- IO.fromEither(
        markdownTransformer.transform(normalized).leftMap { error =>
          new RuntimeException(s"Unable to render page '${page.title}' (${page.outputPath}): $error")
        }
      )
    } yield rendered
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
    val metadata = SiteConfig.metadata
    val title =
      if pageTitle == "Home" then {
        metadata.title
      } else {
        s"$pageTitle · ${metadata.title}"
      }
    val canonicalPath = page.canonicalPath.getOrElse(defaultCanonicalPath(page.outputPath))
    val metaDescription =
      page.description
        .orElse(page.frontMatter.text("social_description"))
        .orElse(page.frontMatter.text("description"))
        .getOrElse(metadata.description)
    val openGraphImage =
      page.frontMatter
        .text("image")
        .map(metadata.absoluteUrl)
        .orElse(
          page.frontMatter.text("youtube").map(id => s"https://img.youtube.com/vi/$id/hqdefault.jpg")
        )
    val navigation = SiteConfig.navigation
      .map(link => s"<a href=\"${escapeHtml(link.href)}\">${escapeHtml(link.label)}</a>")
      .mkString("\n          ")
    val authorLinks = SiteConfig.authorLinks
      .map(link =>
        s"<a rel=\"me noopener noreferrer\" href=\"${escapeHtml(link.href)}\">${escapeHtml(link.label)}</a>"
      )
      .mkString("\n          ")
    val openGraphImageTags = openGraphImage.fold("") { image =>
      s"""    <meta property="og:image" content="${escapeHtml(image)}" />
         |    <meta property="og:image:secure_url" content="${escapeHtml(image)}" />
         |    <meta name="twitter:image:src" content="${escapeHtml(image)}" />
         |""".stripMargin
    }
    val headMetadataBlock = renderArticleDates(page) + openGraphImageTags

    s"""<!DOCTYPE html>
       |<html lang="en">
       |  <head>
       |    <meta charset="utf-8" />
       |    <meta name="viewport" content="width=device-width, initial-scale=1" />
       |    <title>${escapeHtml(title)}</title>
       |    <meta name="description" content="${escapeHtml(metaDescription)}" />
       |    <meta property="og:site_name" content="${escapeHtml(metadata.title)}" />
       |    <meta property="og:title" content="${escapeHtml(pageTitle)}" />
       |    <meta property="og:description" content="${escapeHtml(metaDescription)}" />
       |    <meta property="og:url" content="${escapeHtml(metadata.absoluteUrl(canonicalPath))}" />
       |    <meta property="og:type" content="${if page.publishedAt.isDefined then "article" else "website"}" />
       |    <meta name="twitter:card" content="${if openGraphImage.isDefined then "summary_large_image" else "summary"}" />
       |    <meta name="twitter:title" content="${escapeHtml(pageTitle)}" />
       |    <meta name="twitter:description" content="${escapeHtml(metaDescription)}" />
       |$headMetadataBlock
       |    <link rel="canonical" href="${escapeHtml(metadata.absoluteUrl(canonicalPath))}" />
       |    <style>
       |      :root { color-scheme: light dark; }
       |      body { font-family: system-ui, sans-serif; margin: 0; padding: 0; line-height: 1.6; }
       |      header, main, footer { max-width: 56rem; margin: 0 auto; padding: 1.5rem; }
       |      header { padding-bottom: 0.5rem; }
       |      nav, .meta-nav { display: flex; flex-wrap: wrap; gap: 1rem; margin-top: 0.75rem; }
       |      a { color: inherit; }
       |      main { padding-top: 0; }
       |      .notice { border: 1px solid currentColor; border-radius: 0.5rem; padding: 1rem; }
       |      .document-list { padding-left: 1.25rem; }
       |      .document-list li { margin: 0 0 1rem; }
       |      .page-meta { color: color-mix(in srgb, currentColor 70%, transparent); font-size: 0.95rem; margin-bottom: 1rem; }
       |      code { font-family: ui-monospace, monospace; }
       |    </style>
       |  </head>
       |  <body>
       |    <header>
       |      <strong>${escapeHtml(metadata.title)}</strong>
       |      <nav>
       |        $navigation
       |      </nav>
       |    </header>
       |    <main>
       |      <div class="notice">
       |        ${renderPageMeta(page)}
       |        $body
       |      </div>
       |    </main>
       |    <footer>
       |      <small>Generated by the Scala-CLI Laika migration scaffold.</small>
       |      <div class="meta-nav">
       |        $authorLinks
       |      </div>
       |    </footer>
       |  </body>
       |</html>
       |""".stripMargin
  }

  private def renderPageMeta(page: SitePage): String = {
    val details = List(
      page.publishedAt.map(date => s"Published ${escapeHtml(date.toLocalDate.toString)}"),
      page.modifiedAt.map(date => s"Updated ${escapeHtml(date.toLocalDate.toString)}")
    ).flatten

    if details.isEmpty then {
      ""
    } else {
      s"""<p class="page-meta">${details.mkString(" · ")}</p>"""
    }
  }

  private def renderArticleDates(page: SitePage): String = {
    List(
      page.publishedAt.map(date =>
        s"""    <meta property="article:published_time" content="${escapeHtml(date.toString)}" />"""
      ),
      page.modifiedAt.map(date =>
        s"""    <meta property="article:modified_time" content="${escapeHtml(date.toString)}" />"""
      )
    ).flatten match {
      case Nil    => ""
      case values => values.mkString("", "\n", "\n")
    }
  }

  private def defaultCanonicalPath(outputPath: String): String = {
    if outputPath == "index.html" then {
      "/"
    } else if outputPath == "404.html" then {
      "/404.html"
    } else {
      s"/${outputPath.stripSuffix("index.html")}"
    }
  }

  private def stripKramdownAttributes(content: String): String =
    content.replaceAll("""(?m)(\))\{:\s*[^}]+\}""", "$1")

  private def expandMarkdownInHtmlBlocks(content: String): IO[String] = {
    val pattern = """(?s)<p([^>]*)\smarkdown=['"]1['"]([^>]*)>(.*?)</p>""".r
    val matches = pattern.findAllMatchIn(content).toList

    matches
      .foldLeft(IO.pure(List.empty[(scala.util.matching.Regex.Match, String)])) { (acc, matched) =>
        acc.flatMap { replacements =>
          renderInlineMarkdown(matched.group(3)).map { rendered =>
            val attributes = normalizeHtmlAttributes(matched.group(1), matched.group(2))
            val openTag =
              if attributes.isBlank then {
                "<p>"
              } else {
                s"<p $attributes>"
              }

            replacements :+ (matched -> s"$openTag$rendered</p>")
          }
        }
      }
      .map { replacements =>
        val builder = new StringBuilder
        var cursor = 0

        replacements.foreach { case (matched, replacement) =>
          builder.append(content.substring(cursor, matched.start))
          builder.append(replacement)
          cursor = matched.end
        }

        builder.append(content.substring(cursor))
        builder.result()
      }
  }

  private def renderInlineMarkdown(content: String): IO[String] = {
    IO.fromEither(
      markdownTransformer.transform(content.trim).leftMap(error =>
        new RuntimeException(s"Unable to render markdown-in-HTML block: $error")
      )
    ).map(stripOuterParagraph)
  }

  private def normalizeHtmlAttributes(left: String, right: String): String =
    s"$left $right".replaceAll("""\s+""", " ").trim

  private def stripOuterParagraph(content: String): String = {
    val trimmed = content.trim

    if trimmed.startsWith("<p>") && trimmed.endsWith("</p>") then {
      trimmed.stripPrefix("<p>").stripSuffix("</p>")
    } else {
      trimmed
    }
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
