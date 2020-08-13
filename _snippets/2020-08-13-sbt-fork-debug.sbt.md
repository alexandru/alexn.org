```scala
fork := true

javaOptions ++= {
  sys.env.get("JVM_DEBUG") match {
    case Some("true") =>
      Seq("-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005")
    case Some(value) =>
      Seq(s"-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=$port")
    case None =>
      Seq.empty
  }
}
```