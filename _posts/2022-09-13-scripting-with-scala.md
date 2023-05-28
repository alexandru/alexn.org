---
title: "Scripting with Scala"
image: /assets/media/articles/2022-09-scala-cli.png
tags:
  - CLI
  - Scala
  - Shell
  - Snippet
date: 2022-09-13 12:00:00 +03:00
last_modified_at: 2022-09-21 23:22:19 +03:00
description: >
  Unix has a long tradition with scripting — small programs represented as text files that can be inspected, modified, and executed. Scala can be used for scripting too.
---

<p class="intro">
  Unix has a long tradition with scripting — small programs represented as text files that can be inspected, modified, and executed. Scala can be used for scripting too.
</p>

Scala is a compiled language, your average project has quite a complicated build setup, but we have 2 tools that makes scripting possible and quite pleasant:

- [Ammonite](https://ammonite.io/#ScalaScripts);
- [Scala CLI](https://scala-cli.virtuslab.org/), which is newer, does more, and can embed Ammonite;

For this sample **I'm going to use Scala CLI**.

First step, install `scala-cli`. I'm on macOS, using [Homebrew](https://brew.sh/), for other operating systems refer to [its documentation](https://scala-cli.virtuslab.org/docs/overview#installation):

```sh
brew install Virtuslab/scala-cli/scala-cli
```

We are going to create a command-line utility that tells us how much time has passed since some timestamp in the past. It's usage and output will look like this:

```sh
$ time-since.sc 2022-01-01

Since:   Sat, 1 Jan 2022 00:00:00 +0200
Until:   Tue, 13 Sep 2022 14:06:15 +0300

Elapsed: 255 days, 13 hours, 6 minutes, 15 seconds

Years:          0.70
Months:         8.40
Weeks:         36.51
Days:         255.55
Hours:       6133.10
Minutes:   367986.26
```

Create a text file in `$HOME/bin/time-since.sc` (or somewhere else that's on your system `$PATH`):

```scala
#!/usr/bin/env -S scala-cli shebang -q

//> using scala "2.13.8"
//> using lib "com.github.scopt::scopt::4.1.0"

import scopt.{OParser, Read}
import java.time.format.DateTimeFormatter
import java.time._
import java.util.concurrent.TimeUnit
import scala.util.Try

case class Args(
  since: LocalDateTime,
  until: Option[LocalDateTime],
  zoneId: ZoneId,
)

val parsedArgs = {
  val builder = OParser.builder[Args]
  import builder._

  implicit val readsTime: Read[LocalDateTime] =
    implicitly[Read[String]].map { dt =>
      Try(LocalDateTime.parse(dt, DateTimeFormatter.ISO_LOCAL_DATE_TIME))
        .orElse {
          Try(LocalDate.parse(dt, DateTimeFormatter.ISO_LOCAL_DATE))
            .map(_.atTime(LocalTime.of(0, 0, 0, 0)))
        }
        .getOrElse(
          throw new IllegalArgumentException(
            s"Not a valid timestamp, correct format is `yyyy-mm-dd` OR `yyyy-mm-ddTHH:MM:SS`."
          ))
    }

  implicit val readsZoneId: Read[ZoneId] =
    implicitly[Read[String]].map { id =>
      Try(ZoneId.of(id))
        .getOrElse(throw new IllegalArgumentException(s"'$id' is not a valid timezone id"))
    }

  val parser = OParser.sequence(
    programName("time-since.sc"),
    head("time-since", "1.x"),
    arg[LocalDateTime]("<timestamp>")
      .text("Format: `yyyy-mm-dd` or `yyyy-mm-ddTHH:MM:SS`.")
      .action((ts, args) => args.copy(since = ts)),
    opt[LocalDateTime]('u', "until")
      .text("Format: `yyyy-mm-dd` or `yyyy-mm-ddTHH:MM:SS`. Defaults to NOW.")
      .action { (ts, args) => args.copy(until = Some(ts)) },
    opt[ZoneId]('z', "zone-id")
      .text("Example: Europe/Bucharest")
      .action { (id, args) => args.copy(zoneId = id) },
  )
  OParser
    .parse(parser, args, Args(null, None, ZoneId.systemDefault()))
    .getOrElse {
      System.exit(1)
      throw new RuntimeException()
    }
}

val since = parsedArgs.since.atZone(parsedArgs.zoneId)
val until = parsedArgs.until.fold(ZonedDateTime.now(parsedArgs.zoneId))(_.atZone(parsedArgs.zoneId))
val sinceTs = since.toInstant.toEpochMilli
val untilTs = until.toInstant.toEpochMilli

println()
println(s"Since:   ${since.format(DateTimeFormatter.RFC_1123_DATE_TIME)}")
println(s"Until:   ${until.format(DateTimeFormatter.RFC_1123_DATE_TIME)}")

val totalMs = untilTs - sinceTs
val days = TimeUnit.MILLISECONDS.toDays(totalMs)
val rem1 = totalMs - TimeUnit.DAYS.toMillis(days)
val hours = TimeUnit.MILLISECONDS.toHours(rem1)
val rem2 = rem1 - TimeUnit.HOURS.toMillis(hours)
val minutes = TimeUnit.MILLISECONDS.toMinutes(rem2)
val rem3 = rem2 - TimeUnit.MINUTES.toMillis(minutes)
val seconds = TimeUnit.MILLISECONDS.toSeconds(rem3)

println()
println(s"Elapsed: $days days, $hours hours, $minutes minutes, $seconds seconds")
println()

println(f"Years:   ${(untilTs - sinceTs) / (1000.0 * 60 * 60 * 24 * 365.24)}%11.2f")
println(f"Months:  ${(untilTs - sinceTs) / (1000.0 * 60 * 60 * 24 * 30.417)}%11.2f")
println(f"Weeks:   ${(untilTs - sinceTs) / (1000.0 * 60 * 60 * 24 * 7)}%11.2f")
println(f"Days:    ${(untilTs - sinceTs) / (1000.0 * 60 * 60 * 24)}%11.2f")
println(f"Hours:   ${(untilTs - sinceTs) / (1000.0 * 60 * 60)}%11.2f")
println(f"Minutes: ${(untilTs - sinceTs) / (1000.0 * 60)}%11.2f")
println()
```

This script has what's called a [shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)) declaration, which tells your shell (Bash, Zsh) how to interpret your script:

```sh
#!/usr/bin/env -S scala-cli shebang -q
```

Also, note the dependencies — we can specify the Scala version, and any library dependencies we require, in this case [scopt](https://github.com/scopt/scopt), a library that helps us parse command line arguments:

```scala
//> using scala "2.13.8"
//> using lib "com.github.scopt::scopt::4.1.0"
```

I usually build such scripts in Python or Ruby. These are good choices because they can be installed everywhere easily, and have "batteries included", but extra functionality is hard to import. Scala-CLI (Ammonite too) allows us to import any dependency from Maven Central, and that's awesome! ❤️

Make this script executable:

```sh
$ chmod +x ~/bin/time-since.sc
```

Let's execute it, and see what happens:

```sh
$ time-since.sc

Error: Missing argument <timestamp>
time-since 1.x
Usage: time-since.sc [options] <timestamp>

  <timestamp>            Format: `yyyy-mm-dd` or `yyyy-mm-ddTHH:MM:SS`.
  -u, --until <value>    Format: `yyyy-mm-dd` or `yyyy-mm-ddTHH:MM:SS`. Defaults to NOW.
  -z, --zone-id <value>  Example: Europe/Bucharest

$ time-since.sc 2022-03-01

Since:   Tue, 1 Mar 2022 00:00:00 +0200
Until:   Tue, 13 Sep 2022 14:06:37 +0300

Elapsed: 196 days, 13 hours, 6 minutes, 37 seconds

Years:          0.54
Months:         6.46
Weeks:         28.08
Days:         196.55
Hours:       4717.11
Minutes:   283026.63
```

Note that you can edit this script in [IntelliJ IDEA](https://www.jetbrains.com/idea/), with auto-completion and everything. See [the documentation](https://scala-cli.virtuslab.org/docs/cookbooks/intellij).

A disadvantage of working with Scala-CLI is that it's not available everywhere, as for example, on Ubuntu/Debian I prefer `.deb` packages via official repositories. But Java is available everywhere, and you can always [package scripts in JARs](https://scala-cli.virtuslab.org/docs/cookbooks/scala-package).

The startup time is not ideal either, being that of any Java app:

```sh
$ time time-since.sc
...
time-since.sc  0.51s user 0.13s system 99% cpu 0.645 total
```

So, the startup cost is half a second. It's not that bad though. ~~And I hope some out-of-the-box integration with [GraalVM's Native Image](https://www.graalvm.org/native-image/) will happen.~~

You can package the script using [GraalVM's Native Image](https://www.graalvm.org/native-image/) to speed things up, see [the documentation](https://scala-cli.virtuslab.org/docs/cookbooks/native-images):

```sh
cd $HOME/bin

scala-cli package --native-image ./time-since.sc -o ./time-since -- --no-fallback
```

<p class="warn-bubble" markdown="1">
GraalVM's native image only has partial support for libraries using reflection, and needs to know about them ahead of time. This sample was easy, but depending on your dependencies, other scripts may require some tweaking.
</p>

The startup time is now much better:

```sh
$ time ./time-since 2022-01-01 1>/dev/null

...  0.01s user 0.01s system 36% cpu 0.034 total
```

I'm in love! 😍
