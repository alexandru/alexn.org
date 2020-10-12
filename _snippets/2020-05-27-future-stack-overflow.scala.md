---
tags:
  - Async
  - Scala
---

```scala
// Demonstrating that directly executing runnables in your 
// ExecutionContext is a really bad idea

def trigger(cycles: Int): Future[Int] = {
  implicit val directEC =
    new ExecutionContext {
      def execute(r: Runnable) = r.run()
      def reportFailure(e: Throwable) = throw e
    }

  val p = Promise[Int]()
  val f = (0 until cycles).foldLeft(p.future)((f, _) => f.map(_ + 1))
  p.success(0)
  f
}

// Throws StackOverflowError
trigger(5000)
```