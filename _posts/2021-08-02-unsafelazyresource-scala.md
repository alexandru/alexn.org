---
title: "Unsafe Lazy Resource.scala"
feed_guid: /snippets/2021/08/02/unsafelazyresource-scala/
redirect_from: 
  - /snippets/2021/08/02/unsafelazyresource-scala/
  - /snippets/2021/08/02/unsafelazyresource-scala.html
tags:
  - Scala
  - Snippet
image: /assets/media/snippets/unsafe-lazy-resource.png
image_hide_in_post: true
last_modified_at: 2022-04-01 15:42:12 +03:00
description: >
  Snippet for an impure way (no IO) to create a resource that can later be closed.
---

<blockquote class="twitter-tweet"><p lang="en" dir="ltr"><em>I need an impure way (no IO) to create a resource atomically only once and later be able to know if it was created or not, so I can close this resource safely. 🤔</em><br><br>Jules Ivanic (@guizmaii) ⬇️ <a href="https://twitter.com/guizmaii/status/1422111131556974592" target="_blank" rel="nofollow">August 2, 2021</a></p></blockquote>

```scala
import scala.util.control.NonFatal

/** Builds a "closeable" resource that's initialized on-demand.
  *
  * Works like a `lazy val`, except that the logic for closing
  * the resource only happens in case the resource was initialized.
  *
  * NOTE: it's called "unsafe" because it is side-effecting.
  * See homework.
  */
final class UnsafeLazyResource[A](
  initRef: () => A,
  closeRef: A => Unit,
) extends AutoCloseable {

  /** Internal state that works like a FSM:
    *  - `null` is for pre-initialization
    *  - `Some(_)` is an active resource
    *  - `None` is the final state, a closed resource
    */
  @volatile private[this] var ref: Option[A] = null
  
  /** 
    * Returns the active resources. Initializes it if necessary.
    *
    * @return `Some(resource)` in case the resource is available,
    *         or `None` in case [[close]] was triggered.
    */
  def get(): Option[A] =
    ref match {
      case null =>
        // https://en.wikipedia.org/wiki/Double-checked_locking
        this.synchronized {          
          if (ref == null) {
            try {
              ref = Some(initRef())
              ref
            } catch {
              case NonFatal(e) =>
                ref = None
                throw e
            }
          } else {
            ref
          }
        }
      case other =>
        other
    }
  
  override def close(): Unit =
    if (ref ne None) {
      val res = this.synchronized {
        val old = ref
        ref = None
        old
      }
      res match {
        case null | None => ()
        case Some(a) => closeRef(a)
      }  
    }
}
```

Example:

```scala
import java.io._

def openFile(path: File): UnsafeLazyResource[InputStream] =
  new UnsafeLazyResource(
    () => new FileInputStream(path),
    in => in.close()
  )

val lazyInput = openFile(new File("/tmp/file"))
// .. later
try {
  val in = lazyInput.get().getOrElse(
    throw new IllegalStateException("File already closed")
  )
  //...
} finally {
  lazyInput.close()
}
```

## Homework

1. Try using an [AtomicReference](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/atomic/AtomicReference.html){:target="_blank"} instead of synchronizing a `var` — not as obvious as you'd think — initialization needs protection, you'll need an indirection 😉
2. Try designing a pure API with Cats Effect's [Resource](https://typelevel.org/cats-effect/docs/std/resource){:target="_blank"} (you might need [Ref](https://typelevel.org/cats-effect/docs/std/ref){:target="_blank"} and [Deferred](https://typelevel.org/cats-effect/docs/std/deferred){:target="_blank"} for your internals too)
