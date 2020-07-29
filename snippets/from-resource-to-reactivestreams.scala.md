---
image: /assets/media/snippets/from-resource-to-reactivestreams.png
---

```scala
import cats.effect.Resource
import org.reactivestreams.Publisher

type Ack[F] = F[Unit]

def fromResource[F[_], A](res: Resource[F, A]): F[Publisher[(A, Ack[F])]]
```
