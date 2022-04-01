---
title: 'ExecutionContext Must Be Stack-safe'
feed_guid: /snippets/2020/05/27/future-stack-overflow.scala/
redirect_from:
  - /snippets/2020/05/27/future-stack-overflow.scala/
  - /snippets/2020/05/27/future-stack-overflow.scala.html
tags:
  - Async
  - Scala
  - Snippet
description:
  Sample demonstrating that directly executing runnables in your
  `ExecutionContext` (with no stack-safety) is a really bad idea.
last_modified_at: 2022-04-01 15:47:40 +03:00
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
