package alexn.build

import cats.effect.IO
import cats.syntax.all.*

import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Path

object SiteVerifier {
  private val expectedStaticPaths = SiteConfig.staticInputs

  def verify(outputDirectory: Path): IO[Unit] = {
    val normalizedOutput = outputDirectory.toAbsolutePath.normalize()
    val repositoryRoot = Path.of(System.getProperty("user.dir")).toAbsolutePath.normalize()

    for {
      loadedContent <- ContentLoader.load(repositoryRoot)
      expectedPages = SiteConfig.staticPages ++ loadedContent.generatedPages
      _ <- requireExists(normalizedOutput, "output directory")
      _ <- expectedPages.traverse_(page =>
        requireExists(normalizedOutput.resolve(page.outputPath), s"generated page ${page.outputPath}")
      )
      _ <- expectedStaticPaths.traverse_(path =>
        requireExists(normalizedOutput.resolve(path), s"static path $path")
      )
      _ <- requireContains(
        normalizedOutput.resolve("blog/index.html"),
        "posts migrated from `_posts/`",
        "blog index summary"
      )
      _ <- requireContains(
        normalizedOutput.resolve("wiki/index.html"),
        "wiki pages migrated from `_wiki/`",
        "wiki index summary"
      )
      _ <- requireContains(
        normalizedOutput.resolve("blog/2020/10/20/block-comments-on-the-web/index.html"),
        "/assets/misc/block-lists/no-comments.txt",
        "resolved {% link %} in blog post"
      )
      _ <- requireContains(
        normalizedOutput.resolve("wiki/email/index.html"),
        "/blog/2020/03/18/send-mail.py/",
        "resolved wiki link into blog route"
      )
      _ <- requireNotContains(
        normalizedOutput.resolve("blog/2022/09/21/java-19/index.html"),
        "{% include youtube.html",
        "legacy YouTube include tag"
      )
      _ <- requireContains(
        normalizedOutput.resolve("blog/2022/09/21/java-19/index.html"),
        "youtube-play-link",
        "rendered YouTube compatibility markup"
      )
      _ <- requireContains(
        normalizedOutput.resolve("wiki/web-design/index.html"),
        "<h1 id=\"web-design\">Web Design</h1>",
        "wiki title derived from heading"
      )
    } yield ()
  }

  private def requireExists(path: Path, description: String): IO[Unit] = {
    val normalizedPath = path.toAbsolutePath.normalize()

    IO.blocking(Files.exists(normalizedPath)).flatMap { exists =>
      if exists then {
        IO.unit
      } else {
        IO.raiseError(
          new IllegalStateException(s"Missing expected $description at $normalizedPath")
        )
      }
    }
  }

  private def requireContains(path: Path, expected: String, description: String): IO[Unit] =
    readUtf8(path).flatMap { content =>
      if content.contains(expected) then {
        IO.unit
      } else {
        IO.raiseError(
          new IllegalStateException(s"Missing $description in ${path.toAbsolutePath.normalize()}")
        )
      }
    }

  private def requireNotContains(path: Path, forbidden: String, description: String): IO[Unit] =
    readUtf8(path).flatMap { content =>
      if content.contains(forbidden) then {
        IO.raiseError(
          new IllegalStateException(s"Found unexpected $description in ${path.toAbsolutePath.normalize()}")
        )
      } else {
        IO.unit
      }
    }

  private def readUtf8(path: Path): IO[String] =
    IO.blocking(Files.readString(path, StandardCharsets.UTF_8))
}
