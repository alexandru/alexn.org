```scala
import java.util.concurrent.atomic.AtomicReference
import cats.effect.{ IO, Resource }
import com.ing.raptor.common.UnlawfulEffect
import org.reactivestreams.{ Publisher, Subscriber, Subscription }

/**
  * WARN: broken example, this cannot work, as it leaks, DO NOT USE!
  */
def resourceAsPublisher[A](r: Resource[IO, A]): Publisher[A] = {
  new Publisher[A] {
    override def subscribe(s: Subscriber[_ >: A]): Unit = {
      s.onSubscribe(new Subscription {
        private[this] var phase: Long = 2
        private[this] val cancelable = new AtomicReference(IO.unit)

        override def request(n: Long): Unit = {
          if (n <= 0) {
            s.onError(new IllegalArgumentException("n must be strictly positive"))
            return
          } else if (n > 1) {
            // Oops!!!
            s.onError(new IllegalArgumentException("resource will be closed immediately if buffered"))
            return
          }

          phase = math.max(phase - n, 0)
          phase match {
            case 1 =>
              r.allocated.flatMap {
                case (res, cancel) =>
                  if (!cancelable.compareAndSet(IO.unit, cancel)) {
                    cancel *> IO(s.onComplete())
                  } else {
                    IO(s.onNext(res))
                  }
              }.unsafeToFuture
            case 0 =>
              closeAndSignal.unsafeToFuture
          }
          ()
        }

        override def cancel(): Unit = {
          UnlawfulEffect.unsafeToFuture(closeAndSignal)
          ()
        }

        private[this] val closeAndSignal: IO[Unit] =
          IO.suspend {
            val cancel = cancelable.getAndSet(null)
            if (cancel != null) {
              cancel *> IO(s.onComplete())
            } else {
              IO.unit
            }
          }
      })
    }
  }
}
```