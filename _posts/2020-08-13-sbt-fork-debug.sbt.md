---
title: "Snippet: turn on JVM debugging in sbt"
tags:
  - sbt
  - Scala
  - Snippet
feed_guid: /snippets/2020/08/13/sbt-fork-debug.sbt/
redirect_from:
  - /snippets/2020/08/13/sbt-fork-debug.sbt/
  - /snippets/2020/08/13/sbt-fork-debug.sbt.html
description: >
  Remote debugging can be used to debug externally executed programs, useful to activate in `sbt` in order to keep using it while debugging with your favorite IDE.
last_modified_at: 2022-04-01 17:00:47 +03:00
---

Remote debugging can be used to debug externally executed programs, useful to activate in `sbt` in order to keep using it while debugging with your favorite IDE. See for example [IntelliJ IDEA's documentation](https://www.jetbrains.com/help/idea/tutorial-remote-debug.html):

**UPDATE:** there is now a `--jvm-debug <port>` parameter to the `sbt` executable ...

```bash
sbt --jvm-debug 5005
```

**OLD WAY:** — if the above is not suitable, you can do a manual config like this:

```scala
fork := true

javaOptions ++= {
  val Digits = "^(\\d+)$".r
  sys.env.get("JVM_DEBUG") match {
    case Some("true") =>
      Seq("-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005")
    case Some(Digits(port)) =>
      Seq(s"-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=$port")
    case _ =>
      Seq.empty
  }
}
```

And then set a `JVM_DEBUG` environment variable, before executing `sbt`:

```bash
JVM_DEBUG=5005 sbt
```
