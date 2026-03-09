package alexn.build

object SiteConfig {
  val metadata = SiteMetadata(
    title = "Alexandru Nedelcu",
    description = "On programming and personal projects",
    domain = "alexn.org",
    url = "https://alexn.org",
    baseurl = "",
    author = SiteAuthor(
      name = "Alexandru Nedelcu",
      github = "https://github.com/alexandru",
      linkedin = "https://www.linkedin.com/in/alexelcu/",
      mastodon = "https://mastodon.social/@alexelcu",
      bluesky = "https://bsky.app/profile/alexn.org"
    )
  )

  val title = metadata.title
  val description = metadata.description
  val domain = metadata.domain

  val navigation = List(
    SiteLink("Blog", metadata.sitePath("/blog/")),
    SiteLink("Wiki", metadata.sitePath("/wiki/")),
    SiteLink("About", metadata.sitePath("/about/")),
    SiteLink("Subscribe", metadata.sitePath("/subscribe/"))
  )

  val authorLinks = List(
    SiteLink("GitHub", metadata.author.github),
    SiteLink("LinkedIn", metadata.author.linkedin),
    SiteLink("Mastodon", metadata.author.mastodon),
    SiteLink("Bluesky", metadata.author.bluesky)
  )

  val staticInputs = List(
    ".well-known",
    "assets",
    "CNAME",
    "crossdomain.xml",
    "favicon.ico",
    "manifest.webmanifest",
    "nginx.conf",
    "robots.txt",
    "_redirects"
  )

  val staticPages = List(
    SitePage(
      title = "Home",
      outputPath = "index.html",
      content = s"""# ${metadata.title}
                   |
                   |${metadata.description}
                   |
                   |The Laika migration now ingests the blog and wiki source trees directly from this repository while layout and feed parity continue in later milestones.
                   |
                   |Use the navigation links above to browse the generated blog and wiki indexes.
                   |""".stripMargin,
      description = Some(metadata.description)
    ),
    SitePage(
      title = "About",
      outputPath = "about/index.html",
      content = s"""# About
                   |
                   |${metadata.author.name} is migrating this site from Jekyll to Laika in small verified steps.
                   |
                   |The existing published site remains powered by Jekyll until output parity checks pass.
                   |""".stripMargin
    ),
    SitePage(
      title = "Subscribe",
      outputPath = "subscribe/index.html",
      content =
        """# Subscribe
          |
          |Subscription flows have not been ported yet.
          |
          |This page is intentionally minimal while the migration scaffolding is being wired into CI.
          |""".stripMargin
    ),
    SitePage(
      title = "Not Found",
      outputPath = "404.html",
      content = """# Page not found
                  |
                  |The requested path does not exist in the Laika scaffold output yet.
                  |
                  |Try returning to the [home page](/).
                  |""".stripMargin,
      canonicalPath = Some("/404.html")
    )
  )

  val postDefaults = FrontMatter(
    Map(
      "layout" -> FrontMatterValue.Text("post"),
      "has_contributions" -> FrontMatterValue.BooleanValue(true),
      "has_comments" -> FrontMatterValue.BooleanValue(true),
      "nav_id" -> FrontMatterValue.Text("/blog/")
    )
  )

  val wikiDefaults = FrontMatter(
    Map(
      "layout" -> FrontMatterValue.Text("wiki"),
      "has_contributions" -> FrontMatterValue.BooleanValue(true),
      "has_comments" -> FrontMatterValue.BooleanValue(true),
      "nav_id" -> FrontMatterValue.Text("/wiki/"),
      "description" -> FrontMatterValue.Text("Personal, volatile wiki documentation")
    )
  )
}
