package alexn.build

import cats.effect.IO
import cats.syntax.all.*

import java.nio.file.Files
import java.nio.file.Path

object SiteVerifier {
  private val expectedPages = SiteConfig.pages.map(_.outputPath)
  private val expectedStaticPaths = SiteConfig.staticInputs

  def verify(outputDirectory: Path): IO[Unit] = {
    val normalizedOutput = outputDirectory.toAbsolutePath.normalize()

    for {
      _ <- requireExists(normalizedOutput, "output directory")
      _ <- expectedPages.traverse_(path => requireExists(normalizedOutput.resolve(path), s"generated page $path"))
      _ <- expectedStaticPaths.traverse_(path => requireExists(normalizedOutput.resolve(path), s"static path $path"))
    } yield ()
  }

  private def requireExists(path: Path, description: String): IO[Unit] = {
    val normalizedPath = path.toAbsolutePath.normalize()

    IO.blocking(Files.exists(normalizedPath)).flatMap { exists =>
      if (exists) {
        IO.unit
      } else {
        IO.raiseError(new IllegalStateException(s"Missing expected $description at $normalizedPath"))
      }
    }
  }
}
