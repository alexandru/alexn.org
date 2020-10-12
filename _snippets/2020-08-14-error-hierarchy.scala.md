---
image: /assets/media/snippets/error-hierarchy.png
tags:
  - Scala
---

<figure>
  <a href="{% link assets/media/snippets/error-hierarchy.svg %}" target="_blank">
    <img src="{% link assets/media/snippets/error-hierarchy.svg %}" 
      alt="Error hierarchy graph"
      title="Error hierarchy graph" 
      style="width:100%;" />
  </a>
</figure>

```scala
sealed abstract class KnownException(message: String, cause: Throwable)
  extends RuntimeException(message, cause)

sealed abstract class InputException(message: String, cause: Throwable)
  extends KnownException(message, cause)

object InputException {
  final case class Validation(message: String, cause: Throwable)
    extends InputException(message, cause)
    with ExceptionCaseClassEquality

  final case class BadInput(message: String, cause: Throwable)
    extends InputException(message, cause)
    with ExceptionCaseClassEquality

  final case class Forbidden(message: String, cause: Throwable)
    extends InputException(message, cause)
    with ExceptionCaseClassEquality

  final case class NotFound(message: String, cause: Throwable)
    extends InputException(message, cause)
    with ExceptionCaseClassEquality

  final case class Conflict(message: String, cause: Throwable)
    extends InputException(message, cause)
    with ExceptionCaseClassEquality
}

sealed abstract class OutputException(message: String, cause: Throwable)
  extends KnownException(message, cause)

object OutputException {
  final case class Timeout(message: String, cause: Throwable)
    extends OutputException(message, cause)
    with ExceptionCaseClassEquality

  final case class TooManyRequests(message: String, cause: Throwable)
    extends OutputException(message, cause)
    with ExceptionCaseClassEquality

  final case class ResourceUnavailable(message: String, cause: Throwable)
    extends OutputException(message, cause)
    with ExceptionCaseClassEquality

  final case class Unknown(message: String, cause: Throwable)
    extends OutputException(message, cause)
    with ExceptionCaseClassEquality
}

trait ExceptionCaseClassEquality { self: Throwable with Product =>
  override def equals(other: Any): Boolean = {
    other match {
      case refTh: Throwable =>
        refTh match {
          case refProd: Product =>
            productIterator.toSeq.equals(refProd.productIterator.toSeq) &&
              getStackTrace.toSeq.equals(refTh.getStackTrace.toSeq)
          case _ =>
            false
        }
      case _ =>
        false
    }
  }
}
```