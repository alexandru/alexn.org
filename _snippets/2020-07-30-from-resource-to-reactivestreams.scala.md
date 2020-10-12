---
tags:
  - Akka
  - Cats Effect
  - Reactive Streams
  - Scala
---

```scala
import cats.effect.Resource
import org.reactivestreams.Publisher
import scala.concurrent.Future

type Ack[F] = () => F[Unit]

// This leaks
def fromResource[F[_], A](res: Resource[F, A]): F[Publisher[A]]

// Explicit acknowledgement logic is required
def fromResource[F[_], A](res: Resource[F, A]): F[Publisher[(A, Ack[F])]]

//-------------

// Similarly for concrete resources, this leaks!
def fromFile(file: File): Publisher[InputStream]

// Explicit acknowledgement logic is required
def fromFile(file: File): Publisher[(InputStream, Ack[Future])]
```
