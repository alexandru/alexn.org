/** Site-wide metadata, mirroring the values from Jekyll's _config.yml. */
object SiteConfig {

  val title: String = "Alexandru Nedelcu"
  val description: String = "On programming and personal projects"
  val domain: String = "alexn.org"
  val url: String = "https://alexn.org"
  val baseUrl: String = ""

  object Author {
    val name: String = "Alexandru Nedelcu"
    val github: String = "alexandru"
    val linkedin: String = "alexelcu"
    val mastodon: String = "https://mastodon.social/@alexelcu"
    val bluesky: String = "https://bsky.app/profile/alexn.org"
  }

  object RepoEdit {
    val base: String = "https://github.com/alexandru/alexn.org/blob/main/"
  }

  val navigation: List[(String, String)] = List(
    "Blog"      -> "/blog/",
    "Wiki"      -> "/wiki/",
    "About"     -> "/about/",
    "Subscribe" -> "/subscribe/"
  )
}
