package alexn.build

final case class SiteLink(label: String, href: String)
final case class SitePage(title: String, outputPath: String, markdown: String)

object SiteConfig {
  val title = "Alexandru Nedelcu"
  val description = "On programming and personal projects"
  val domain = "https://alexn.org"

  val navigation = List(
    SiteLink("Blog", "/blog/"),
    SiteLink("Wiki", "/wiki/"),
    SiteLink("About", "/about/"),
    SiteLink("Subscribe", "/subscribe/")
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

  val pages = List(
    SitePage(
      title = "Home",
      outputPath = "index.html",
      markdown = s"""# $title
                    |
                    |$description
                    |
                    |The Laika migration is now bootstrapped in this repository. This scaffold keeps static assets available while the Jekyll layouts, collections, and feeds are ported incrementally.
                    |
                    |Use the navigation links above to preview the first generated pages.
                    |""".stripMargin
    ),
    SitePage(
      title = "Blog",
      outputPath = "blog/index.html",
      markdown = """# Blog
                    |
                    |Blog post ingestion from `_posts/` has not been ported yet.
                    |
                    |This placeholder page exists so the new Scala-CLI build has a stable route to validate in CI while the migration continues.
                    |""".stripMargin
    ),
    SitePage(
      title = "Wiki",
      outputPath = "wiki/index.html",
      markdown = """# Wiki
                    |
                    |Wiki ingestion from `_wiki/` is planned in the next migration slices.
                    |
                    |For now the Laika scaffold exposes the route and static assets needed for incremental work.
                    |""".stripMargin
    ),
    SitePage(
      title = "About",
      outputPath = "about/index.html",
      markdown = s"""# About
                    |
                    |$title is migrating this site from Jekyll to Laika in small verified steps.
                    |
                    |The existing published site remains powered by Jekyll until output parity checks pass.
                    |""".stripMargin
    ),
    SitePage(
      title = "Subscribe",
      outputPath = "subscribe/index.html",
      markdown = """# Subscribe
                    |
                    |Subscription flows have not been ported yet.
                    |
                    |This page is intentionally minimal while the migration scaffolding is being wired into CI.
                    |""".stripMargin
    ),
    SitePage(
      title = "Not Found",
      outputPath = "404.html",
      markdown = """# Page not found
                    |
                    |The requested path does not exist in the Laika scaffold output yet.
                    |
                    |Try returning to the [home page](/).
                    |""".stripMargin
    )
  )
}
