---
tags:
  - sbt
  - Scala
---

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
