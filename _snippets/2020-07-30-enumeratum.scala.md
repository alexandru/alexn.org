---
tags:
  - Scala
---

```scala
/**
  * Imported from Gist:
  * [[https://gist.github.com/alexandru/3df8116f1c85f69612143b3b1884e1ed]]
  */

import enumeratum.{ CatsEnum, Enum, EnumEntry }

sealed abstract class AcknowledgeMode(override val entryName: String)
  extends Product
  with Serializable
  with EnumEntry

object AcknowledgeMode extends Enum[AcknowledgeMode] with CatsEnum[AcknowledgeMode] {
  val values = findValues

  case object Off extends AcknowledgeMode("off")

  case object Auto extends AcknowledgeMode("auto")

  case object Client extends AcknowledgeMode("client")

  case object DuplicatesOk extends AcknowledgeMode("duplicates-ok")

  case object Session extends AcknowledgeMode("session")
}
```
