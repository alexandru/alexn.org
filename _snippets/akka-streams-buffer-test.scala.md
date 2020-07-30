---
date: 2020-07-29
---

```scala
import akka.actor.ActorSystem
import akka.stream.Attributes
import akka.stream.scaladsl.Source
import monix.execution.rstreams.Subscription
import org.reactivestreams.{ Publisher, Subscriber }

import scala.concurrent.{ Await, ExecutionContext, Future }
import scala.concurrent.duration._

def repeated[A](x: A)(f: A => A)(implicit ec: ExecutionContext): Publisher[A] =
  new Publisher[A] {
    override def subscribe(s: Subscriber[_ >: A]): Unit =
      s.onSubscribe(new Subscription {
        private[this] var current = x
        private[this] var requestCount = 0

        override def cancel(): Unit = ()
        override def request(n: Long): Unit = {
          requestCount += 1
          println(s"Request ($requestCount): $n")

          ec.execute(() => {
            var i = 0L
            while (i < n) {
              val c = current
              current = f(c)
              s.onNext(c)
              i += 1
            }
          })
        }
      })
  }

def run(): Unit = {
  implicit val system = ActorSystem("test")
  implicit val ec = system.dispatcher
  try {
    val f = Source
      .fromPublisher(repeated(1)(_ + 1))
      .mapAsync(1) { x =>
        Future {
          Thread.sleep(2000)
          println(s"Received: $x")
        }
      }
      .withAttributes(Attributes.inputBuffer(0, 1))
      .take(5)
      .run()

    Await.result(f, Duration.Inf); ()
  } finally {
    Await.result(system.terminate(), 10.seconds); ()
  }
}
```