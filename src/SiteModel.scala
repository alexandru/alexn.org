package alexn.build

import java.time.OffsetDateTime

enum SourceFormat {
  case Markdown
  case Html
}

sealed trait FrontMatterValue {
  def asText: Option[String]
  def asBoolean: Option[Boolean]
  def asTextList: List[String]
}

object FrontMatterValue {
  final case class Text(value: String) extends FrontMatterValue {
    def asText: Option[String] = Option(value)
    def asBoolean: Option[Boolean] =
      value.trim.toLowerCase match {
        case "true"  => Some(true)
        case "false" => Some(false)
        case _       => None
      }
    def asTextList: List[String] =
      asText.toList
  }

  final case class BooleanValue(value: Boolean) extends FrontMatterValue {
    def asText: Option[String] = Some(value.toString)
    def asBoolean: Option[Boolean] = Some(value)
    def asTextList: List[String] = List(value.toString)
  }

  final case class TextList(values: List[String]) extends FrontMatterValue {
    def asText: Option[String] =
      values match {
        case single :: Nil => Some(single)
        case _             => None
      }
    def asBoolean: Option[Boolean] = None
    def asTextList: List[String] = values
  }
}

final case class FrontMatter(values: Map[String, FrontMatterValue]) {
  def text(key: String): Option[String] =
    values.get(key).flatMap(_.asText)

  def bool(key: String): Option[Boolean] =
    values.get(key).flatMap(_.asBoolean)

  def textList(key: String): List[String] =
    values.get(key).map(_.asTextList).getOrElse(Nil)

  def merged(defaults: FrontMatter): FrontMatter =
    FrontMatter(defaults.values ++ values)
}

object FrontMatter {
  val empty = FrontMatter(Map.empty)
}

final case class SiteLink(label: String, href: String)

final case class SiteAuthor(
    name: String,
    github: String,
    linkedin: String,
    mastodon: String,
    bluesky: String
)

final case class SiteMetadata(
    title: String,
    description: String,
    domain: String,
    url: String,
    baseurl: String,
    author: SiteAuthor
) {
  def sitePath(path: String): String = {
    val normalizedBase =
      if baseurl.isBlank then {
        ""
      } else {
        s"/${baseurl.stripPrefix("/").stripSuffix("/")}"
      }
    val normalizedPath =
      if path.isBlank || path == "/" then {
        "/"
      } else {
        s"/${path.stripPrefix("/")}"
      }

    if normalizedPath == "/" then {
      s"$normalizedBase/"
    } else {
      s"$normalizedBase$normalizedPath"
    }
  }

  def absoluteUrl(path: String): String =
    s"$url${sitePath(path)}"
}

final case class SitePage(
    title: String,
    outputPath: String,
    content: String,
    sourceFormat: SourceFormat = SourceFormat.Markdown,
    description: Option[String] = None,
    canonicalPath: Option[String] = None,
    publishedAt: Option[OffsetDateTime] = None,
    modifiedAt: Option[OffsetDateTime] = None,
    frontMatter: FrontMatter = FrontMatter.empty
)
