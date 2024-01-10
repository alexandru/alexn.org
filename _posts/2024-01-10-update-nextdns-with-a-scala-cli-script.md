---
title: "Update NextDNS with a Scala CLI script"
image: /assets/media/articles/2014-scala-cli.png
image_hide_in_post: true
tags:
    - CLI
    - Scala
    - Shell
    - Snippet
date: 2024-01-10 13:14:14 +02:00
last_modified_at: 2024-01-10 18:04:09 +02:00
---

<p class="intro" markdown=1>
    Today I was reminded how awesome [Scala](https://www.scala-lang.org/) is for scripting, via [Scala CLI](https://scala-cli.virtuslab.org/). And it goes beyond having "batteries included".
</p>

**Problem:** I have a [NextDNS account](https://nextdns.io), as my DNS provider, for privacy and for blocking ads. My work computer has VPN software on it, that overrides the Wi-Fi's DNS servers in order to access internal company resources. But I still want to configure NextDNS in my browser, and the problem is that my Chromium browser doesn't fall back to the system DNS when I configure DNS-over-HTTPS.

**Solution:** a Scala script that updates the NextDNS configuration with overrides for the internal resources that I care about, as [NextDNS has an HTTP API](https://nextdns.github.io/api/) that I can use.

<p class="warn-bubble" markdown="1">
The following script uses [Scala 3](https://docs.scala-lang.org/scala3/book/introduction.html), with [4-spaces](./2023-11-08-in-scala-3-use-4-spaces-for-indentation.md) for [significant indentation](https://docs.scala-lang.org/scala3/reference/other-new-features/indentation.html). It's executable, and running it requires just having [Scala CLI installed](https://scala-cli.virtuslab.org/install).
</p>

```scala
#!/usr/bin/env -S scala-cli shebang

//> using scala "3.3.1"
//> using toolkit latest
//> using lib "com.monovore::decline:2.4.1"

import cats.syntax.all.given
import com.monovore.decline.*
import sttp.client4.quick.*
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

    lazy val getProfile =
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
            .body(upickle.default.write(
                Map(
                    "name" -> name,
                    "content" -> content
                )
            ))
            .send()

    def patch(id: String, name: String, content: String) =
        println(s"Updating $name (ip: $content)")
        if dryRun then quickRequest
            .patch(uri"https://api.nextdns.io/profiles/$profileId/rewrites/$id")
            .header("X-Api-Key", apiKey)
            .header("Content-Type", "application/json")
            .body(upickle.default.write(
                Map(
                    "content" -> content
                )
            ))
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

        getProfile.data.find: entry =>
            entry.get("name").contains(name)
        match
        case None =>
            post(name, ip)
        case Some(entry) if !entry.get("content").contains(ip) =>
            patch(entry("id"), name, ip)
        case Some(_) =>
            skip(name, ip)

    for domain <- domainsToCleanUp do
        val toDelete = getProfile.data.filter: entry =>
            entry.getOrElse("name", "").endsWith(domain) &&
            !toUpdate.contains(entry("name"))
        for entry <- toDelete do
            delete(entry("id"), entry("name"))

object Main extends CommandApp(
    name = "nextdns-vpn-update",
    header = "Update NextDNS's rewrites based on the current DNS (corporate VPN)",
    main =
        val apiKey = Opts
            .option[String]("api-key", help = "NextDNS API key")
            .orElse(Opts.env[String]("NEXTDNS_API_KEY", help = "NextDNS API key"))
        val profileId = Opts
            .option[String]("profile-id", help = "NextDNS profile ID")
            .orElse(Opts.env[String]("NEXTDNS_PROFILE_ID", help = "NextDNS profile ID"))
        val dryRun = Opts
            .flag("dry-run", help = "Dry run").orFalse

        (apiKey, profileId, dryRun).mapN(run)
)
```

Of note, the requirements for such a script:

- Doing HTTP requests;
- Composing and parsing JSON documents;
- Parsing command-line arguments.

My script depends on [Scala Toolkit](https://docs.scala-lang.org/toolkit/introduction.html), which is a set of libraries that can take care of doing HTTP requests (via [sttp](https://sttp.softwaremill.com/en/stable/)) and parsing JSON (via [upickle](https://github.com/com-lihaoyi/upickle)). The script also depends on [decline](https://github.com/bkirwi/decline), my favorite library for parsing command line arguments. I don't need to install these separately, as Scala CLI takes care of managing these dependencies (unlike some of the popular scripting languages).

The script can be executed directly, if you have [Scala CLI installed](https://scala-cli.virtuslab.org/install), as it includes a [shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)). Just paste the above in a file on your PATH, like `~/bin/nextdns-vpn-update.scala`. Then make it executable:

```scala
chmod +x ~/bin/nextdns-vpn-update.scala
```

And [Scala's Metals](https://scalameta.org/metals/), which I use with VS Code, is just wonderful for such scripts, with auto-completion, GH Copilot and everything. It took me at most 15 minutes to write and test this.

Python and Ruby are definitely dethroned for all my future scripting needs.
