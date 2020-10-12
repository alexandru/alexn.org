---
image: /assets/media/snippets/on-error-retry-loop.png
tags:
  - Cats Effect
  - Scala
---

```scala
import java.io._
import java.nio.charset.CharacterCodingException

import cats.{ ApplicativeError, Defer, MonadError }
import cats.effect._
import cats.implicits._
import com.typesafe.scalalogging.LazyLogging

import scala.concurrent.duration._

/**
  * Configuration for retry logic, could be read from a config file, via
  * something like [[https://github.com/pureconfig/pureconfig PureConfig]].
  */
final case class RetryConfig(
  maxRetries: Int,
  initialDelay: FiniteDuration,
  maxDelay: FiniteDuration,
  backoffFactor: Double,
  private val evolvedDelay: Option[FiniteDuration] = None,
) {
  def canRetry: Boolean = maxRetries > 0

  def delay: FiniteDuration =
    evolvedDelay.getOrElse(initialDelay)

  def evolve: RetryConfig =
    copy(
      maxRetries = math.max(maxRetries - 1, 0),
      evolvedDelay = Some {
        val nextDelay = evolvedDelay.getOrElse(initialDelay) * backoffFactor
        maxDelay.min(nextDelay) match {
          case ref: FiniteDuration => ref
          case _: Duration.Infinite => maxDelay
        }
      }
    )
}

/**
  * Signaling desired outcomes via Boolean is very confusing,
  * having our own ADT for this is better.
  */
sealed trait RetryOutcome

object RetryOutcome {
  case object Next extends RetryOutcome
  case object Raise extends RetryOutcome
}

/** Module grouping our retry helpers. */
object OnErrorRetry {
  def loop[F[_], A, S](
    fa: F[A],
    initial: S
  )(
    f: (Throwable, S, S => F[A]) => F[A]
  )(implicit F: ApplicativeError[F, Throwable], D: Defer[F]): F[A] = {
    fa.handleErrorWith { err =>
      f(err, initial, state => D.defer(loop(fa, state)(f)))
    }
  }

  def withBackoff[F[_], A](fa: F[A], config: RetryConfig)(
    p: Throwable => F[RetryOutcome]
  )(implicit
    F: MonadError[F, Throwable],
    D: Defer[F],
    timer: Timer[F]
  ): F[A] = {
    OnErrorRetry.loop(fa, config) { (error, state, retry) =>
      if (state.canRetry)
        p(error).flatMap {
          case RetryOutcome.Next =>
            timer.sleep(state.delay) *> retry(state.evolve)
          case RetryOutcome.Raise =>
            // Cannot recover from error
            F.raiseError(error)
        }
      else
        // No retries left
        F.raiseError(error)
    }
  }
}

object Playground extends LazyLogging with IOApp {
  // Motivating example, not very good, but go with it
  def readTextFromFile(file: File, charset: String): IO[String] =
    IO {
      val in = new BufferedReader(new InputStreamReader(new FileInputStream(file), charset))
      val builder = new StringBuilder()

      var line: String = null
      do {
        line = in.readLine()
        if (line != null)
          builder.append(line).append("\n")
      } while (line != null)

      builder.toString
    }

  override def run(args: List[String]): IO[ExitCode] = {
    val config = RetryConfig(
      maxRetries = 10,
      initialDelay = 10.millis,
      maxDelay = 2.seconds,
      backoffFactor = 1.5
    )
    val task = IO.suspend {
      val path = args.headOption.getOrElse(
        throw new IllegalArgumentException("File path expected in main's args")
      )
      readTextFromFile(new File(path), "UTF-8")
    }
    val text = OnErrorRetry.withBackoff(task, config) {
      case _: CharacterCodingException | _: IllegalArgumentException =>
        IO.pure(RetryOutcome.Raise)
      case e =>
        IO(logger.warn("Unexpected error, retrying", e))
          .as(RetryOutcome.Next)
    }
    for {
      t <- text
      _ <- IO(println(t))
    } yield ExitCode.Success
  }
}
```