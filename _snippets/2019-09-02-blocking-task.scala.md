---
tags:
  - Async
  - Monix
  - Scala
---

Imported from [gist.github.com](https://gist.github.com/alexandru/d04c23e3ebd918c6144b5ad33c69f48f).

WARN: not sure if this code is correct.

```scala
import monix.eval._
import monix.execution.atomic.Atomic
import scala.util.control.NonFatal

def blocking[A](f: => A): Task[A] =
  Task.cancelable0 { (scheduler, cb) =>
    // For capturing the executing thread
    val thread = Atomic(None : Option[Thread])
    // For synchronizing cancellation, ensuring the
    // interrupted flag is reset, in case it is our fault
    val wasInterrupted = Atomic(false)

    // Executing on top of thread-pool
    scheduler.execute(new Runnable {
      def run() = {
        val th = Thread.currentThread()
        val update = Some(th)
        var started = false

        try {
          if (thread.compareAndSet(None, update)) {
            started = true
            scala.concurrent.blocking {
              cb.onSuccess(f)
            }
          }
        } catch {
          case e: InterruptedException =>
            ()
          case NonFatal(e) =>
            cb.onError(e)
        } finally {
          // If true, then cancellation logic is guaranteed to
          // interrupt or to have interrupted current thread
          if (started && !thread.compareAndSet(update, null)) {
            // Waits for cancellation logic to finish
            while (!wasInterrupted.get) {
              // Thread.onSpinWait() on Java 9
              Thread.`yield`()
            }
            // Clear interruption flag
            Thread.interrupted()
          }
        }
      }
    })

    // Cancellation logic
    Task {
      thread.getAndSet(null) match {
        case None | null => ()
        case Some(th) =>
          th.interrupt()
          wasInterrupted.set(true)
      }
    }
  }
```