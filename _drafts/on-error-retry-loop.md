# Error Handling with Cats and Scala

In the face of errors, we could interrupt what we are doing and log the incident for debugging purposes. Some errors however are temporary, for example network connection errors, the web service becoming unavailable for whatever reason, etc, in which case it might be appropriate to do one or multiple retries.

Here's how ...

- [Naive Implementation](#naive-implementation)

## Naive Implementation

The [ApplicativeError](https://github.com/typelevel/cats/blob/v2.1.1/core/src/main/scala/cats/ApplicativeError.scala) type class from Typelevel defines this function:

```scala
trait ApplicativeError[F[_], E] extends Applicative[F] {
  // ...
  def handleErrorWith[A](fa: F[A])(f: E => F[A]): F[A]
}
```

This works like a `flatMap` operation, but for errors. For the purpose of this tutorial we are going to use [cats.effect.IO](https://typelevel.org/cats-effect/datatypes/io.html).



....

There is one gotcha: the web server we're trying to communicate with might have become innaccessable due to being overwhelmed by traffic.
