---
tags:
  - Akka
  - Cats Effect
  - Reactive Streams
  - Scala
---

# Flow/Processor to Effect

Possibly broken implementation, take it with a grain of salt:

```scala
import akka.actor.ActorSystem
import akka.stream.Materializer
import akka.stream.scaladsl.Flow
import cats.effect.{ ContextShift, IO, Resource }
import cats.implicits._
import monix.execution.AsyncSemaphore
import monix.execution.atomic.Atomic
import org.reactivestreams.{ Processor, Publisher, Subscriber, Subscription }

import scala.annotation.{ nowarn, tailrec }
import scala.concurrent.duration.Duration
import scala.concurrent.{ Await, ExecutionContext, Future, Promise }

final class FlowToEffect[In, Out] private (
  processor: Processor[In, Out]
)(implicit
  cs: ContextShift[IO],
  ec: ExecutionContext
) {
  private[this] val (producer: Publisher[Out], subscriber: Subscriber[In]) =
    (processor, processor)

  private[this] val awaitCallLatch = AsyncSemaphore(1)
  private[this] var publisherResponsePromise: Promise[Out] = _
  private[this] val requested =
    Atomic(Left(Promise()): Either[Promise[Unit], Long])

  private[this] val connectionClosed = Promise[Unit]()

  subscriber.onSubscribe(new Subscription {
    // Called by Akka Streams
    @tailrec
    override def request(n: Long): Unit = {
      assert(n >= 0)
      if (n == 0) return
      val update =
        if (n - 1 > 0) Right(n - 1)
        else Left(Promise[Unit]())

      requested.get() match {
        case current @ Left(promise) =>
          if (!requested.compareAndSet(current, update))
            request(n)
          else
            promise.success(())

        case current @ Right(n0) =>
          if (!requested.compareAndSet(current, Right(n + n0)))
            request(n)
      }
    }

    // Called by Akka Streams
    override def cancel(): Unit =
      throw new IllegalStateException()
  })

  producer.subscribe(new Subscriber[Out] {
    private[this] var sub: Subscription = _

    override def onSubscribe(s: Subscription): Unit = {
      sub = s
      connectionClosed.future.onComplete { _ =>
        println("Cancelling connection")
        sub.cancel()
      }
      sub.request(1)
    }

    override def onNext(t: Out): Unit = {
      publisherResponsePromise.success(t)
      sub.request(1)
      awaitCallLatch.release()
    }

    override def onError(t: Throwable): Unit = {
      publisherResponsePromise.failure(t)
      // TODO: signal future requests that stream ended in error
      awaitCallLatch.release()
    }

    override def onComplete(): Unit = ()
  })

  private val cancelIO: IO[Unit] =
    IO {
      connectionClosed.success(())
      ()
    }

  @nowarn("cat=deprecation")
  def pushEvent(in: In): IO[Out] =
    IO.fromFuture(IO {
      awaitCallLatch.acquire().flatMap {
        _ =>
          val promise = Promise[Out]()
          publisherResponsePromise = promise

          val backpressurePermission =
            requested.transformAndExtract {
              case Right(n) =>
                if (n > 1)
                  (Future.successful(()), Right(n - 1))
                else
                  (Future.successful(()), Left(Promise()))

              case current @ Left(promise) =>
                (promise.future, current)
            }

          backpressurePermission.flatMap { _ =>
            subscriber.onNext(in)
            promise.future
          }
      }
    })
}

object FlowToEffect {
  def apply[I, O](
    f: IO[Processor[I, O]]
  )(implicit
    cs: ContextShift[IO],
    ec: ExecutionContext
  ): Resource[IO, FlowToEffect[I, O]] = {
    Resource(f.map { processor =>
      val ref = new FlowToEffect(processor)
      (ref, ref.cancelIO)
    })
  }

  def apply[I, O, Mat](
    flow: Flow[I, O, Mat]
  )(implicit
    cs: ContextShift[IO],
    m: Materializer,
    ec: ExecutionContext
  ): Resource[IO, FlowToEffect[I, O]] = {
    val res = Resource.liftF(IO {
      flow.toProcessor.run()
    })
    res.flatMap(proc => apply(IO.pure(proc)))
  }

  def main(args: Array[String]): Unit = {
    import ExecutionContext.Implicits.global
    implicit val as = ActorSystem("test")
    implicit val cs = IO.contextShift(global)

    val flow = Flow.fromFunction[Int, String] { int =>
      show"Received number: $int"
    }

    val (res, cancelRes) = FlowToEffect(flow).allocated.unsafeRunSync()
    try {
      val f1 = res.pushEvent(1).unsafeToFuture()
      val f2 = res.pushEvent(2).unsafeToFuture()
      val f3 = res.pushEvent(3).unsafeToFuture()

      val r1 = Await.result(f1, Duration.Inf)
      println(show"Received: $r1")
      val r2 = Await.result(f2, Duration.Inf)
      println(show"Received: $r2")
      val r3 = Await.result(f3, Duration.Inf)
      println(show"Received: $r3")
    } finally {
      cancelRes.unsafeRunSync()
      Await.result(as.terminate(), Duration.Inf)
      ()
    }
  }
}
```