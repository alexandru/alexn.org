package alexn.build

import cats.effect.IO
import cats.syntax.all.*
import org.yaml.snakeyaml.LoaderOptions
import org.yaml.snakeyaml.Yaml
import org.yaml.snakeyaml.constructor.SafeConstructor

import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Path
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.OffsetDateTime
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeParseException
import scala.jdk.CollectionConverters.*
import scala.util.matching.Regex

object ContentLoader {
  final case class LoadedContent(blogPosts: List[SitePage], wikiPages: List[SitePage]) {
    val generatedPages: List[SitePage] =
      blogIndex :: wikiIndex :: blogPosts ::: wikiPages

    private def blogIndex: SitePage = {
      val body = blogPosts
        .sortBy(_.publishedAt.map(_.toInstant).map(_.toEpochMilli).getOrElse(0L))
        .reverse
        .map(renderBlogIndexItem)
        .mkString("\n")

      SitePage(
        title = "Blog",
        outputPath = "blog/index.html",
        content =
          s"""# Blog
             |
             |${blogPosts.size} posts migrated from `_posts/`.
             |
             |<ul class="document-list">
             |$body
             |</ul>
             |""".stripMargin,
        canonicalPath = Some("/blog/")
      )
    }

    private def wikiIndex: SitePage = {
      val body = wikiPages
        .sortBy(_.title.toLowerCase)
        .map(renderWikiIndexItem)
        .mkString("\n")

      SitePage(
        title = "Wiki",
        outputPath = "wiki/index.html",
        content =
          s"""# Wiki
             |
             |${wikiPages.size} wiki pages migrated from `_wiki/`.
             |
             |<ul class="document-list">
             |$body
             |</ul>
             |""".stripMargin,
        canonicalPath = Some("/wiki/"),
        description = Some("Personal, volatile wiki documentation")
      )
    }

    private def renderBlogIndexItem(page: SitePage): String = {
      val href = page.canonicalPath.getOrElse(s"/${page.outputPath.stripSuffix("index.html")}")
      val published = page.publishedAt.map(_.toLocalDate.toString).getOrElse("")
      val details = page.description.fold("")(value => s"<p>${escapeHtml(value)}</p>")

      s"""  <li>
         |    <a href="$href">${escapeHtml(page.title)}</a>
         |    <small>$published</small>
         |    $details
         |  </li>""".stripMargin
    }

    private def renderWikiIndexItem(page: SitePage): String = {
      val href = page.canonicalPath.getOrElse(s"/${page.outputPath.stripSuffix("index.html")}")
      val details = page.description.fold("")(value => s"<p>${escapeHtml(value)}</p>")

      s"""  <li>
         |    <a href="$href">${escapeHtml(page.title)}</a>
         |    $details
         |  </li>""".stripMargin
    }
  }

  private sealed trait DocumentKind {
    def directoryName: String
    def defaults: FrontMatter
  }
  private object DocumentKind {
    case object Blog extends DocumentKind {
      val directoryName = "_posts"
      val defaults = SiteConfig.postDefaults
    }

    case object Wiki extends DocumentKind {
      val directoryName = "_wiki"
      val defaults = SiteConfig.wikiDefaults
    }
  }

  private final case class RawDocument(
      kind: DocumentKind,
      sourcePath: Path,
      sourceRelativePath: String,
      sourceFormat: SourceFormat,
      slug: String,
      title: String,
      rawContent: String,
      frontMatter: FrontMatter,
      publishedAt: Option[OffsetDateTime],
      modifiedAt: Option[OffsetDateTime],
      canonicalPath: String,
      outputPath: String
  ) {
    def description: Option[String] =
      frontMatter.text("social_description").orElse(frontMatter.text("description"))

    def toSitePage(content: String): SitePage =
      SitePage(
        title = title,
        outputPath = outputPath,
        content = content,
        sourceFormat = sourceFormat,
        description = description,
        canonicalPath = Some(canonicalPath),
        publishedAt = publishedAt,
        modifiedAt = modifiedAt,
        frontMatter = frontMatter
      )
  }

  private final case class FrontMatterBlock(values: FrontMatter, rawValues: Map[String, String])

  private final case class LinkLookup(
      legacyLinks: Map[String, String],
      postUrls: Map[String, String]
  )

  private val frontMatterSeparator = "\n---\n"
  private val titleHeadingPattern = """(?m)^#\s+(.+?)\s*$""".r
  private val liquidLinkPattern = """\{%\s*link\s+(.+?)\s*%\}""".r
  private val postUrlPattern = """\{%\s*post_url\s+(.+?)\s*%\}""".r
  private val siteVariablePattern = """\{\{\s*site\.(url|domain|baseurl)\s*\}\}""".r
  private val nowDatePattern = """\??\{\{\s*'now'\s*\|\s*date:\s*['"][^'"]+['"]\s*\}\}""".r
  private val youtubeIncludePattern = """\{%\s*include\s+youtube\.html\s*([^%]*)%\}""".r

  def load(repositoryRoot: Path): IO[LoadedContent] = {
    for {
      blogPosts <- loadDocuments(repositoryRoot, DocumentKind.Blog)
      wikiPages <- loadDocuments(repositoryRoot, DocumentKind.Wiki)
      lookups = buildLookups(blogPosts, wikiPages)
      renderedBlogPosts <- blogPosts.traverse(renderDocument(_, lookups))
      renderedWikiPages <- wikiPages.traverse(renderDocument(_, lookups))
    } yield LoadedContent(
      blogPosts = renderedBlogPosts.sortBy(_.publishedAt.map(_.toInstant.toEpochMilli).getOrElse(0L)).reverse,
      wikiPages = renderedWikiPages.sortBy(_.title.toLowerCase)
    )
  }

  private def loadDocuments(repositoryRoot: Path, kind: DocumentKind): IO[List[RawDocument]] = {
    val sourceDirectory = repositoryRoot.resolve(kind.directoryName)

    for {
      sourceFiles <- listRegularFiles(sourceDirectory)
      documents <- sourceFiles.traverse(loadDocument(kind, sourceDirectory, _))
    } yield documents.sortBy(_.sourcePath.toString)
  }

  private def listRegularFiles(path: Path): IO[List[Path]] = {
    IO.blocking {
      if Files.isDirectory(path) then {
        val stream = Files.list(path)
        try {
          stream
            .iterator()
            .asScala
            .filter(Files.isRegularFile(_))
            .toList
        } finally {
          stream.close()
        }
      } else {
        Nil
      }
    }
  }

  private def loadDocument(kind: DocumentKind, sourceRoot: Path, sourcePath: Path): IO[RawDocument] = {
    for {
      text <- readUtf8(sourcePath)
      (frontMatterText, body) <- IO.fromEither(splitFrontMatter(sourcePath, text))
      frontMatterBlock <- parseFrontMatter(sourcePath, frontMatterText)
      document <- IO.fromEither(buildDocument(kind, sourceRoot, sourcePath, body, frontMatterBlock))
    } yield document
  }

  private def buildDocument(
      kind: DocumentKind,
      sourceRoot: Path,
      sourcePath: Path,
      body: String,
      frontMatterBlock: FrontMatterBlock
  ): Either[Throwable, RawDocument] = {
    val fileName = sourcePath.getFileName.toString
    val sourceFormat = detectSourceFormat(fileName)
    val mergedFrontMatter = frontMatterBlock.values.merged(kind.defaults)
    val slug = extractSlug(kind, fileName)
    val title =
      mergedFrontMatter
        .text("title")
        .orElse(extractHeadingTitle(body))
        .getOrElse(slug.replace('-', ' '))
    val publishedAt = parsePublishedAt(kind, fileName, frontMatterBlock.rawValues)
    val modifiedAt = parseDateField(sourcePath, "last_modified_at", frontMatterBlock.rawValues)
      .orElse(parseDateField(sourcePath, "created_at", frontMatterBlock.rawValues))
    val canonicalPath =
      kind match {
        case DocumentKind.Blog =>
          publishedAt match {
            case Some(value) =>
              f"/blog/${value.getYear}%04d/${value.getMonthValue}%02d/${value.getDayOfMonth}%02d/$slug/"
            case None =>
              return Left(
                new IllegalStateException(s"Blog post missing date information: $sourcePath")
              )
          }
        case DocumentKind.Wiki =>
          s"/wiki/$slug/"
      }
    val sourceRelativePath =
      sourceRoot.getParent.relativize(sourcePath).toString.replace('\\', '/')
    val outputPath =
      canonicalPath.stripPrefix("/").stripSuffix("/") match {
        case ""           => "index.html"
        case canonicalDir => s"$canonicalDir/index.html"
      }

    Right(
      RawDocument(
        kind = kind,
        sourcePath = sourcePath,
        sourceRelativePath = sourceRelativePath,
        sourceFormat = sourceFormat,
        slug = slug,
        title = title,
        rawContent = body,
        frontMatter = mergedFrontMatter,
        publishedAt = publishedAt,
        modifiedAt = modifiedAt,
        canonicalPath = canonicalPath,
        outputPath = outputPath
      )
    )
  }

  private def splitFrontMatter(sourcePath: Path, text: String): Either[Throwable, (String, String)] = {
    if !text.startsWith("---\n") then {
      Left(new IllegalStateException(s"Missing front matter separator in $sourcePath"))
    } else {
      val index = text.indexOf(frontMatterSeparator, 4)
      if index < 0 then {
        Left(new IllegalStateException(s"Unterminated front matter in $sourcePath"))
      } else {
        Right(text.substring(4, index) -> text.substring(index + frontMatterSeparator.length))
      }
    }
  }

  private def parseFrontMatter(sourcePath: Path, text: String): IO[FrontMatterBlock] = {
    IO.blocking {
      val loaderOptions = LoaderOptions()
      val yaml = Yaml(SafeConstructor(loaderOptions))
      val rawMap = Option(yaml.load[java.util.Map[String, Object]](text))
        .map(_.asScala.toMap)
        .getOrElse(Map.empty)

      val rawValues = extractRawValues(text)
      val values = rawMap.map { case (key, value) =>
        key -> normalizeYamlValue(key, value, rawValues)
      }

      FrontMatterBlock(FrontMatter(values), rawValues)
    }.handleErrorWith { error =>
      IO.raiseError(new IllegalStateException(s"Failed to parse front matter for $sourcePath", error))
    }
  }

  private def normalizeYamlValue(
      key: String,
      value: Object,
      rawValues: Map[String, String]
  ): FrontMatterValue = {
    value match {
      case null               => FrontMatterValue.Text("")
      case boolean: Boolean   => FrontMatterValue.BooleanValue(boolean)
      case list: java.util.List[?] =>
        FrontMatterValue.TextList(list.asScala.toList.map(renderYamlScalar(_, rawValues.get(key))))
      case _                  =>
        FrontMatterValue.Text(renderYamlScalar(value, rawValues.get(key)))
    }
  }

  private def renderYamlScalar(value: Any, rawValue: Option[String]): String = {
    value match {
      case null                 => ""
      case _: java.util.Date    => rawValue.getOrElse(value.toString)
      case other                => other.toString.trim
    }
  }

  private def extractRawValues(frontMatter: String): Map[String, String] = {
    frontMatter
      .linesIterator
      .filterNot(_.startsWith(" "))
      .flatMap { line =>
        line.indexOf(':') match {
          case -1    => None
          case index =>
            val key = line.substring(0, index).trim
            val value = line.substring(index + 1).trim
            Some(key -> value.stripPrefix("\"").stripSuffix("\""))
        }
      }
      .toMap
  }

  private def parsePublishedAt(
      kind: DocumentKind,
      fileName: String,
      rawValues: Map[String, String]
  ): Option[OffsetDateTime] = {
    kind match {
      case DocumentKind.Blog =>
        parseRawDate(rawValues.get("date"))
          .orElse(parseDateFromFileName(fileName))
      case DocumentKind.Wiki =>
        parseRawDate(rawValues.get("date"))
    }
  }

  private def parseDateField(
      sourcePath: Path,
      fieldName: String,
      rawValues: Map[String, String]
  ): Option[OffsetDateTime] = {
    rawValues.get(fieldName) match {
      case None        => None
      case some @ Some(value) =>
        parseRawDate(some).orElse {
          throw new IllegalStateException(s"Unsupported date '$value' for $fieldName in $sourcePath")
        }
    }
  }

  private def parseRawDate(rawValue: Option[String]): Option[OffsetDateTime] =
    rawValue.flatMap(parseDateValue)

  private def parseDateValue(value: String): Option[OffsetDateTime] = {
    val trimmed = value.trim
    val offsetFormats = List(
      DateTimeFormatter.ISO_OFFSET_DATE_TIME,
      DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss XXX"),
      DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ssXX"),
      DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ssXX")
    )
    val localDateTimeFormats = List(
      DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"),
      DateTimeFormatter.ISO_LOCAL_DATE_TIME
    )

    offsetFormats.view.flatMap(format => tryParseOffsetDateTime(trimmed, format)).headOption
      .orElse(localDateTimeFormats.view.flatMap(format => tryParseLocalDateTime(trimmed, format)).headOption)
      .orElse(tryParseLocalDate(trimmed))
  }

  private def tryParseOffsetDateTime(
      value: String,
      formatter: DateTimeFormatter
  ): Option[OffsetDateTime] = {
    try {
      Some(OffsetDateTime.parse(value, formatter))
    } catch {
      case _: DateTimeParseException => None
    }
  }

  private def tryParseLocalDateTime(
      value: String,
      formatter: DateTimeFormatter
  ): Option[OffsetDateTime] = {
    try {
      Some(LocalDateTime.parse(value, formatter).atOffset(ZoneOffset.UTC))
    } catch {
      case _: DateTimeParseException => None
    }
  }

  private def tryParseLocalDate(value: String): Option[OffsetDateTime] = {
    try {
      Some(LocalDate.parse(value, DateTimeFormatter.ISO_LOCAL_DATE).atTime(LocalTime.MIDNIGHT).atOffset(ZoneOffset.UTC))
    } catch {
      case _: DateTimeParseException => None
    }
  }

  private def parseDateFromFileName(fileName: String): Option[OffsetDateTime] = {
    val prefix = fileName.take(10)
    tryParseLocalDate(prefix)
  }

  private def detectSourceFormat(fileName: String): SourceFormat =
    if fileName.endsWith(".html") then SourceFormat.Html else SourceFormat.Markdown

  private def extractSlug(kind: DocumentKind, fileName: String): String = {
    kind match {
      case DocumentKind.Blog =>
        fileName.drop(11).replaceFirst("""\.[^.]+$""", "")
      case DocumentKind.Wiki =>
        fileName.replaceFirst("""\.[^.]+$""", "")
    }
  }

  private def extractHeadingTitle(body: String): Option[String] =
    titleHeadingPattern.findFirstMatchIn(body).map(_.group(1).trim)

  private def buildLookups(blogPosts: List[RawDocument], wikiPages: List[RawDocument]): LinkLookup = {
    val pages = blogPosts ::: wikiPages
    val legacyLinks = pages.flatMap { page =>
      val direct = page.sourceRelativePath -> page.canonicalPath
      val withLeadingSlash = s"/${page.sourceRelativePath}" -> page.canonicalPath
      List(direct, withLeadingSlash)
    }.toMap
    val postUrls = blogPosts.map { page =>
      val key = page.sourcePath.getFileName.toString.replaceFirst("""\.[^.]+$""", "")
      key -> page.canonicalPath
    }.toMap

    LinkLookup(legacyLinks = legacyLinks, postUrls = postUrls)
  }

  private def renderDocument(document: RawDocument, lookups: LinkLookup): IO[SitePage] = {
    val content =
      resolveYouTubeIncludes(
        resolveLegacyLinks(
          resolveSiteVariables(document.rawContent),
          lookups
        ),
        document.frontMatter
      )

    IO.pure(document.toSitePage(content))
  }

  private def resolveSiteVariables(content: String): String =
    siteVariablePattern.replaceAllIn(
      nowDatePattern.replaceAllIn(content, ""),
      matched =>
        matched.group(1) match {
          case "url"     => Regex.quoteReplacement(SiteConfig.metadata.url)
          case "domain"  => Regex.quoteReplacement(SiteConfig.metadata.domain)
          case "baseurl" => Regex.quoteReplacement(SiteConfig.metadata.baseurl)
          case _         => matched.matched
        }
    )

  private def resolveLegacyLinks(content: String, lookups: LinkLookup): String = {
    val linked = liquidLinkPattern.replaceAllIn(
      content,
      matched => Regex.quoteReplacement(resolveLinkTarget(matched.group(1).trim, lookups))
    )

    postUrlPattern.replaceAllIn(
      linked,
      matched => {
        val key = matched.group(1).trim
        val replacement = lookups.postUrls.getOrElse(key, s"/blog/$key/")
        Regex.quoteReplacement(replacement)
      }
    )
  }

  private def resolveLinkTarget(rawTarget: String, lookups: LinkLookup): String = {
    val normalized = rawTarget.trim

    lookups.legacyLinks
      .get(normalized)
      .orElse(lookups.legacyLinks.get(normalized.stripPrefix("/")))
      .getOrElse {
        val cleaned = normalized.stripPrefix("/")
        if cleaned.startsWith("_posts/") || cleaned.startsWith("_wiki/") then {
          lookups.legacyLinks.getOrElse(cleaned, s"/$cleaned")
        } else {
          s"/$cleaned"
        }
      }
  }

  private def resolveYouTubeIncludes(content: String, frontMatter: FrontMatter): String =
    youtubeIncludePattern.replaceAllIn(
      content,
      matched => Regex.quoteReplacement(renderYouTubeEmbed(parseAttributes(matched.group(1)), frontMatter))
    )

  private def parseAttributes(raw: String): Map[String, String] = {
    val attributePattern = """(\w+)=("([^"]*)"|'([^']*)'|([^\s]+))""".r

    attributePattern
      .findAllMatchIn(raw)
      .map { matched =>
        val value =
          Option(matched.group(3))
            .orElse(Option(matched.group(4)))
            .orElse(Option(matched.group(5)))
            .getOrElse("")
        matched.group(1) -> value
      }
      .toMap
  }

  private def renderYouTubeEmbed(attributes: Map[String, String], frontMatter: FrontMatter): String = {
    val id = attributes.get("id").orElse(frontMatter.text("youtube")).getOrElse("")
    val caption = attributes.get("caption").orElse(frontMatter.text("title")).getOrElse("Video link")
    val image =
      attributes
        .get("image")
        .orElse(frontMatter.text("image"))
        .getOrElse(s"https://img.youtube.com/vi/$id/hqdefault.jpg")
    val timeSuffix = attributes.get("time").fold("")(value => s"&t=$value")
    val link = s"https://www.youtube.com/watch?v=$id$timeSuffix&autoplay=1"
    val escapedLink = escapeHtml(link)
    val escapedImage = escapeHtml(image)
    val escapedCaption = escapeHtml(caption)

    s"""<figure class="video">
       |  <a href="$escapedLink" target="_blank" class="youtube-play-link" title="Go to YouTube video">
       |    <img src="$escapedImage" alt="" class="play-thumb" width="1280" height="720" />
       |  </a>
       |  <figcaption>
       |    <a href="$escapedLink" target="_blank">$escapedCaption (open on YouTube.com)</a>
       |  </figcaption>
       |</figure>""".stripMargin
  }

  private def readUtf8(path: Path): IO[String] =
    IO.blocking(Files.readString(path, StandardCharsets.UTF_8))

  private def escapeHtml(value: String): String = {
    value
      .replace("&", "&amp;")
      .replace("<", "&lt;")
      .replace(">", "&gt;")
      .replace("\"", "&quot;")
      .replace("'", "&#39;")
  }
}
