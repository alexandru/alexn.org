---
title: "Scala Snippet: Cats-Effect Resource to Reactive Streams"
tags:
  - Akka
  - Cats Effect
  - Reactive Streams
  - Scala
  - Snippet
description:
  Cats-Effect's Resource can't be converted directly into a Reactive Streams Publisher. Beware!
feed_guid: /snippets/2020/07/30/from-resource-to-reactivestreams.scala/
redirect_from:
  - /snippets/2020/07/30/from-resource-to-reactivestreams.scala/
  - /snippets/2020/07/30/from-resource-to-reactivestreams.scala.html
last_modified_at: 2022-04-01 17:13:37 +03:00
---

Cats-Effect's Resource can't be converted directly into a Reactive Streams Publisher. Beware!

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
