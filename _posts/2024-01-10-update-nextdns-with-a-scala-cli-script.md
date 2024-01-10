---
title: "Update NextDNS with a Scala CLI script"
image: /assets/media/articles/scala.png
image_hide_in_post: true
tags:
    - CLI
    - Scala
    - Shell
    - Snippet
date: 2024-01-10 13:14:14 +02:00
last_modified_at: 2024-01-10 13:33:55 +02:00
---

<p class="intro" markdown=1>
    Today I was reminded how awesome [Scala](https://www.scala-lang.org/) is for scripting, via [Scala CLI](https://scala-cli.virtuslab.org/). And it goes beyond having "batteries included".
</p>

**Problem:** I have a [NextDNS account](), as my DNS provider, for privacy and for blocking ads. My work computer has VPN software on it, that overrides the Wi-Fi's DNS servers in order to access internal company resources. But I still want to configure NextDNS in my browser, and the problem is that my Chromium browser doesn't fall back to the system DNS when I configure DNS-over-HTTPS.

**Solution:** a Scala script that updates the NextDNS configuration with overrides for the internal resources that I care about, as [NextDNS has an HTTP API](https://nextdns.github.io/api/) that I can use.

```scala
#!/usr/bin/env -S scala-cli shebang -q

//> using scala "3.3.1"
//> using toolkit latest
//> using lib "com.monovore::decline:2.4.1"

import cats.syntax.all.given
import com.monovore.decline._
import sttp.client4.quick.*
import sttp.client4.Response
import upickle.default.*
import java.net.InetAddress

val domainsToCleanUp = List(
    "corporate.net"
)

val toUpdate = List(
    "confluence.corporate.net",
    "kibana.corporate.net",
    "elk.corporate.net",
    "elk.uat.corporate.net",
    //...
)

def run(apiKey: String, profileId: String, dryRun: Boolean) =
    case class GetResponse(data: List[Map[String, String]])
        derives ReadWriter

    lazy val getAll =
        val resp = quickRequest
            .get(uri"https://api.nextdns.io/profiles/$profileId/rewrites")
            .header("X-Api-Key", apiKey)
            .send()
        upickle.default.read[GetResponse](resp.body.toString)

    def post(name: String, content: String) =
        println(s"Adding $name (ip: $content)")
        if (!dryRun) then quickRequest
            .post(uri"https://api.nextdns.io/profiles/$profileId/rewrites")
            .header("X-Api-Key", apiKey)
            .header("Content-Type", "application/json")
            .body(
                upickle.default.write(
                    Map(
                        "name" -> name,
                        "content" -> content
                    )
                )
            )
            .send()

    def patch(id: String, name: String, content: String) =
        println(s"Updating $name (ip: $content)")
        if dryRun then quickRequest
            .patch(uri"https://api.nextdns.io/profiles/$profileId/rewrites/$id")
            .header("X-Api-Key", apiKey)
            .header("Content-Type", "application/json")
            .body(
                upickle.default.write(
                    Map(
                        "content" -> content
                    )
                )
            )
            .send()

    def delete(id: String, name: String) =
        println(s"Deleting $name")
        if !dryRun then quickRequest
            .delete(uri"https://api.nextdns.io/profiles/$profileId/rewrites/$id")
            .header("X-Api-Key", apiKey)
            .send()

    def skip(name: String, content: String) =
        println(s"Skipping $name (ip: $content)")

    for name <- toUpdate do
        val address = InetAddress.getByName(name)
        val ip = address.getHostAddress.nn

        val entry = getAll.data.find: entry =>
            entry.get("name").contains(name)
        entry match
            case None =>
                post(name, ip)
            case Some(entry) if !entry.get("content").contains(ip) =>
                patch(entry("id"), name, ip)
            case Some(_) =>
                skip(name, ip)

    for domain <- domainsToCleanUp do
        val toDelete = getAll.data.filter: entry =>
            entry.getOrElse("name", "").endsWith(domain) &&
            !toUpdate.contains(entry("name"))
        for entry <- toDelete do
            delete(entry("id"), entry("name"))

object Main extends CommandApp(
    name = "nextdns-vpn-update",
    header = "Update NextDNS's rewrites based on the current DNS (corporate VPN)",
    main = {
        val apiKey = Opts
            .option[String]("api-key", help = "NextDNS API key")
            .orElse(Opts.env[String]("NEXTDNS_API_KEY", help = "NextDNS API key"))
        val profileId = Opts
            .option[String]("profile-id", help = "NextDNS profile ID")
            .orElse(Opts.env[String]("NEXTDNS_PROFILE_ID", help = "NextDNS profile ID"))
        val dryRun = Opts
            .flag("dry-run", help = "Dry run").orFalse

        (apiKey, profileId, dryRun).mapN(run)
   }
)
```

Of note, the requirements for such a script:

- Doing HTTP requests;
- Composing and parsing JSON documents;
- Parsing command-line arguments.

I depend on [Scala Toolkit](https://docs.scala-lang.org/toolkit/introduction.html), which is a set of libraries that can take care of HTTP requests (via [sttp](https://sttp.softwaremill.com/en/stable/)) and for parsing JSON (via [upickle](https://github.com/com-lihaoyi/upickle)). I also depend on [decline](https://github.com/bkirwi/decline) for parsing command line arguments.

The script can be executed directly, if you have Scala CLI installed, as it includes a shebang. Just paste the above in a file on your PATH, like `~/bin/nextdns-vpn-update.scala`. Then make it executable:

```scala
chmod +x ~/bin/nextdns-vpn-update.scala
```

And [Scala Metals](https://scalameta.org/metals/) is just wonderful for such scripts, with auto-completion, GH Copilot and everything. It took me at most 15 minutes to write and test this.

Python and Ruby are definitely dethroned for all my future scripting needs.
