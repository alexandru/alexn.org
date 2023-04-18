---
title: "Integrating Akka with Cats-Effect 3"
image: /assets/media/articles/2023-akka-plus-cats-effect.png
date: 2023-04-17 11:05:29 +03:00
last_modified_at: 2023-04-18 12:48:22 +03:00
generate_toc: true
tags:
  - Cats Effect
  - FP
  - Programming
  - Scala
description: >
  We are using a combination of Akka and Cats-Effect (ver. 3) for building payment processors. This post describes some solutions we’ve discovered.
---

<p class="intro withcap" markdown=1>
  We are using a combination of [Akka](https://akka.io/) and [Cats-Effect](https://typelevel.org/cats-effect/) (ver. 3) for building payment processors. Integrating them isn't without challenges. This post describes some solutions we've discovered.
</p>

We've been using Akka because [Akka Cluster](https://doc.akka.io/docs/akka/2.6.20/typed/index-cluster.html) and [Akka Persistence](https://doc.akka.io/docs/akka/2.6.20/typed/persistence.html) fitted our needs for data persistence. We're also using [Akka Stream](https://doc.akka.io/docs/akka/2.6.20/stream/index.html), because our flows are complicated graphs, even though at times it felt overkill and [fs2](https://fs2.io/) might have been a better fit. Note that [Akka has gone proprietary](./2022-09-07-akka-is-moving-away-from-open-source.md), and we're still on the last FOSS version (`2.6.20`). We might pay up to upgrade to the proprietary license, although I'm rooting for [Apache Pekko](https://pekko.apache.org/) to become stable.

## Starting Actor Systems as a Resource

Cats-Effect's [Resource](https://typelevel.org/cats-effect/docs/std/resource) is one of the secret weapons of Scala. When you have Cats-Effect in your project, it's best to manage the lifecycle of resources via `Resource`. Akka also provides its own [coordinated-shutdown](https://doc.akka.io/docs/akka/current/coordinated-shutdown.html) mechanism, but I recommend going with `Resource`, due to the ease of use, and the reasoning capabilities.

First, let's get the dependencies out of the way:

```scala
// sbt syntax
libraryDependencies ++= Seq(
  "com.typesafe.akka" %% "akka-actor" % "2.6.20",
  "com.typesafe.akka" %% "akka-actor-typed" % "2.6.20",
  "ch.qos.logback" % "logback-classic" % "1.4.6",
  // FP awesomeness!!!
  "org.typelevel" %% "cats-effect" % "3.4.9",
)
```

And the imports:

```scala
import akka.Done
import akka.actor.{CoordinatedShutdown, ActorSystem => UntypedActorSystem}
import cats.effect.kernel.Resource
import cats.effect.std.Dispatcher
import cats.effect.{Deferred, IO}
import cats.syntax.all._
import com.typesafe.config.Config
import org.slf4j.LoggerFactory
import scala.concurrent.TimeoutException
import scala.concurrent.duration._
```

To create an actor system in the context of a `Resource`, a naive approach would be this:

```scala
// Version 1 of 3: DO NOT USE THIS
def startActorSystemUntyped(
  systemName: String,
  config: Option[Config],
): Resource[IO, UntypedActorSystem] =
  Resource(IO {
    val system = UntypedActorSystem(
      systemName.trim.replaceAll("\\W+", "-"),
      config = config
    )
    // Here, system.terminate() returns a `Future[Terminated]`
    val cancel = IO.fromFuture(IO(system.terminate())).void
    (system, cancel)
  })
```

The first problem with this approach is that both Akka and Cats-Effect 3 are creating their own thread-pool. Having too many thread-pools meant for CPU-bound tasks can decrease performance and make problems harder to investigate. Cats-Effect's thread-pool is optimized for `IO` and it would be a pity if we wouldn't use it. Akka's thread-pool is the old and reliable `ForkJoinPool`, that's also used by Scala's `global`, but CE's thread-pool is perfectly adequate for use with Akka as well, due to properly implementing [BlockContext](https://www.scala-lang.org/api/2.13.10/scala/concurrent/BlockContext.html).

Note that it's best if this would be configurable. So here's version 2:

```scala
// Version 2 out of 3: DO NOT USE THIS
def startActorSystemUntyped(
  systemName: String,
  config: Option[Config],
  useIOExecutionContext: Boolean,
): Resource[IO, UntypedActorSystem] =
  Resource(
    for {
      // Fishing IO's `ExecutionContext`
      ec <- Option
        .when(useIOExecutionContext) { IO.executionContext }
        .sequence
      system <- IO {
        UntypedActorSystem(
          systemName.trim.replaceAll("\\W+", "-"),
          config = config,
          defaultExecutionContext = ec,
        )
      }
    } yield {
      // Here, system.terminate() returns a `Future[Terminated]`
      val cancel = IO.fromFuture(IO(system.terminate())).void
      (system, cancel)
    }
  )
```

There is one more problem, best described as a setting that you'll often see in an `application.conf` file:

```hocon
akka.coordinated-shutdown.exit-jvm = on
```

This setting tells Akka to forcefully stop the JVM as part of the coordinated shutdown process. And *this setting is good*, you should have this on. And that's because **Akka can decide to shut down on its own**, and afterward it's probably best to shut down the process, too. One example is when using Akka Cluster, with a [split-brain resolver](https://doc.akka.io/docs/akka-enhancements/current/split-brain-resolver.html), in which case Akka should shut down the application in case the node is removed from the cluster. If it doesn't, then the app could be left in a zombie state.

Both Akka and Cats-Effect can add a shut-down hook to the JVM, via [Runtime.addShutdownHook](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/lang/Runtime.html#addShutdownHook(java.lang.Thread)). Cats-Effect can do it via its `IOApp` implementation. Akka can do it via its `akka.coordinated-shutdown.exit-jvm` setting. This triggers the disposal process on `System.exit`, no matter the reason it happened. And one problem is that both will start to dispose of resources, concurrently. In other words, Akka can shut down the actor system before Cats-Effect has had a chance to shut down all resources depending on that actor system. Which is usually bad.

Another problem I discovered in testing is that in certain scenarios, Akka, on `system.terminate()`, seems to return a `Future[Done]` that never completes. Seems to be some sort of race condition, and it's bad, as it can indefinitely block Cats-Effect's resource disposal process. In my testing, this seemed to be alleviated if I first waited on a promise completed via a task registered with Akka's coordinated-shutdown (see below). I don't know if this code solves it or not, but a "timeout" on `system.whenTerminated` seems to be a good idea.

```scala
// Version 3 out of 3: USE THIS

/** Starts an (untyped) Akka actor system in the
  * context of a Cats-Effect `Resource`, and integrating
  * with its cancellation abilities.
  *
  * HINT: for apps (in `main`), it's best if
  * `akka.coordinated-shutdown.exit-jvm` is set to `on`,
  * because Akka can decide to shutdown on its own. And
  * having this setting interacts well with Cats-Effect.
  *
  * @param systemName is the identifying name of the system.
  * @param config is an optional, parsed HOCON configuration;
  *        if None, then Akka will read its own, possibly
  *        from `application.conf`; this parameter is
  *        provided in order to control the source of
  *        the application's configuration.
  * @param useIOExecutionContext if true, then Cats-Effect's
  *        default thread-pool will get used by Akka, as well.
  *        This is needed in order to avoid having too many
  *        thread-pools.
  * @param timeoutAwaitCatsEffect is the maximum amount of time
  *        Akka's coordinated-shutdown is allowed to wait for
  *        Cats-Effect to finish. This is needed, as Cats-Effect
  *        could have a faulty stack of disposables, or because
  *        Akka could decide to shutdown on its own.
  * @param timeoutAwaitAkkaTermination is the maximum amount of
  *        time to wait for the actor system to terminate, after
  *        `terminate()` was called. We need the timeout, because
  *        `terminate()` proved to return a `Future` that never
  *        completes in certain scenarios (could be a bug, or a
  *        race condition).
  */
def startActorSystemUntyped(
  systemName: String,
  config: Option[Config],
  useIOExecutionContext: Boolean,
  timeoutAwaitCatsEffect: Duration,
  timeoutAwaitAkkaTermination: Duration,
): Resource[IO, UntypedActorSystem] = {
  // Needed to turn IO into Future
  // https://typelevel.org/cats-effect/docs/std/dispatcher
  Dispatcher.parallel[IO](await = true).flatMap { dispatcher =>
    Resource[IO, UntypedActorSystem](
      for {
        // Fishing IO's `ExecutionContext`
        ec <- Option
          .when(useIOExecutionContext)(IO.executionContext)
          .sequence
        // For synchronizing Cats-Effect with Akka
        awaitCancel <- Deferred[IO, Unit]
        // For awaiting termination via coordinated-shutdown,
        // needed as `terminate()` is unreliable
        awaitTermination <- Deferred[IO, Unit]
        logger = LoggerFactory.getLogger(getClass)
        system <- IO {
          logger.info("Creating actor system...")
          val system = UntypedActorSystem(
            systemName.trim.replaceAll("\\W+", "-"),
            config = config,
            defaultExecutionContext = ec,
          )
          // Registering task in Akka's CoordinatedShutdown
          // that will wait for Cats-Effect to catch up,
          // blocking Akka from terminating, see:
          // https://doc.akka.io/docs/akka/current/coordinated-shutdown.html
          CoordinatedShutdown(system).addTask(
            CoordinatedShutdown.PhaseBeforeServiceUnbind,
            "sync-with-cats-effect",
          ) { () =>
            dispatcher.unsafeToFuture(
              // WARN: this may not happen, if Akka decided
              // to terminate, and `coordinated-shutdown.exit-jvm`
              // isn't `on`, hence the timeout:
              awaitCancel.get
                .timeout(timeoutAwaitCatsEffect)
                .recoverWith {
                  case ex: TimeoutException =>
                    IO(logger.error(
                      "Timed out waiting for Cats-Effect to catch up! " +
                        "This might indicate either a non-terminating " +
                        "cancellation logic, or a misconfiguration of Akka."
                    ))
                }
                .as(Done)
            )
          }
          CoordinatedShutdown(system).addTask(
            CoordinatedShutdown.PhaseActorSystemTerminate,
            "signal-actor-system-terminated",
          ) { () =>
            dispatcher.unsafeToFuture(
              awaitTermination.complete(()).as(Done)
            )
          }
          system
        }
      } yield {
        val cancel =
          for {
            // Signals that Cats-Effect has caught up with Akka
            _ <- awaitCancel.complete(())
            _ <- IO(logger.warn("Shutting down actor system!"))
            // Shuts down Akka, and waits for its termination
            // Here, system.terminate() returns a `Future[Terminated]`,
            // but we are ignoring it, as it could be non-terminating
            _ <- IO(system.terminate())
            // Waiting for Akka to terminate via coordinated-shutdown
            _ <- awaitTermination.get
            // WARN: `whenTerminated` is unreliable, hence the timeout
            _ <- IO.fromFuture(IO(system.whenTerminated))
              .void
              .timeoutAndForget(timeoutAwaitAkkaTermination)
              .handleErrorWith(_ =>
                IO(logger.warn(
                  "Timed-out waiting for Akka to terminate!"
                ))
              )
          } yield ()
        (system, cancel)
      }
    )
  }
}
```

Note that the correctness of complicated apps relies on `akka.coordinated-shutdown.exit-jvm` being set to `on` in `application.conf`. If you feel uneasy about this, note that this can be accomplished programmatically, by doing a manual `System.exit` in that `CoordinateShutdown` task:

```scala
// NOT NEEDED, prefer to use `application.conf`
CoordinatedShutdown(system).addTask(
  CoordinatedShutdown.PhaseBeforeServiceUnbind,
  "shutdown-actor-system",
) { () =>
  // System.exit will block the thread, so best to
  // run it async, in a fire-and-forget fashion
  val triggerShutdown =
    IO.blocking(System.exit(255))
      .start
      .void

  dispatcher.unsafeToFuture(
    (triggerShutdown *> awaitCancel.get)
      .timeout(timoutAwaitCatsEffect)
      .recoverWith { ... }
      .as(Done)
  )
}
```

If you do this, it will work OK, as both Cats-Effect and Akka install shutdown hooks. But I feel that this is duplicating the functionality of `akka.coordinated-shutdown.exit-jvm`, making behavior unclear for those familiar with Akka and its configuration.

On a final note, you can work with Akka's [typed actor systems](https://doc.akka.io/docs/akka/2.6.20/typed/from-classic.html), it's the same thing. For simplicity, you could initialize it as a classic actor system (like we are doing above), and then convert it into a typed one:

```scala
import akka.actor.typed.scaladsl.adapter.ClassicActorSystemOps
system.toTyped
```

## Using IO with Akka Stream

For this section we need to depend on [Akka Stream](https://doc.akka.io/docs/akka/2.6.20/stream/index.html):

```scala
// sbt syntax
libraryDependencies ++= Seq(
  "com.typesafe.akka" %% "akka-stream" % "2.6.20",
  "com.typesafe.akka" %% "akka-stream-typed" % "2.6.20",
)
```

### Turning an IO into a Flow

An obvious solution for working with `IO` in Akka Stream is via
[mapAsync](https://doc.akka.io/docs/akka/2.6.20/stream/operators/Source-or-Flow/mapAsync.html):

```scala
import akka.NotUsed
import akka.stream.scaladsl.Flow
import cats.effect.IO
import cats.effect.std.Dispatcher

def uncancelableIOToFlow[A, B](parallelism: Int)(
  f: A => IO[B]
)(implicit d: Dispatcher[IO]): Flow[A, B, NotUsed] =
  Flow[A].mapAsync(parallelism)(a => d.unsafeToFuture(f(a)))
```

We need a [Dispatcher](https://typelevel.org/cats-effect/docs/std/dispatcher) for turning `IO` values into `Future` values, as `mapAsync` works with `Future`. 

There is one glaring problem: `Future` isn't cancelable, and these `IO` tasks may be long-running ones. And the code above will not cancel the running `IO` when the stream is getting cancelled. Most often this isn't a problem, and can be in fact desirable.

In the context of Akka Stream, to execute `IO` tasks as cancelable tasks, we need to work with `Publisher` from the [Reactive Streams](https://github.com/reactive-streams/reactive-streams-jvm) specification. Implementation is low-level, as it has to synchronize concurrent calls:

```scala
import org.reactivestreams.{Publisher, Subscriber, Subscription}

/** Converts a Cats-Effect `IO` into a Reactive Streams `Publisher`.
  *
  * [[https://github.com/reactive-streams/reactive-streams-jvm]]
  */
def toPublisher[A](io: IO[A])(implicit d: Dispatcher[IO]): Publisher[A] =
  (s: Subscriber[_ >: A]) => s.onSubscribe(new Subscription {
    type CancelToken = () => Future[Unit]

    private[this] val NOT_STARTED: Null = null
    private[this] val LOCKED = Left(false)
    private[this] val COMPLETED = Left(true)

    // State machine for managing the active subscription
    private[this] val ref =
      new AtomicReference[Either[Boolean, CancelToken]](NOT_STARTED)

    override def request(n: Long): Unit =
      ref.get() match {
        case NOT_STARTED =>
          if (n <= 0) {
            if (ref.compareAndSet(NOT_STARTED, COMPLETED))
              s.onError(new IllegalArgumentException(
                "non-positive request signals are illegal"
              ))
          } else {
            if (ref.compareAndSet(NOT_STARTED, LOCKED)) {
              val cancelToken = d.unsafeRunCancelable(
                io.attempt.flatMap { r =>
                  IO {
                    r match {
                      case Right(value) =>
                        s.onNext(value)
                        s.onComplete()
                      case Left(e) =>
                        s.onError(e)
                    }
                    // GC purposes
                    ref.lazySet(COMPLETED)
                  }
                }
              )
              // Race condition with lazySet(COMPLETED), but it's fine
              ref.set(Right(cancelToken))
            }
          }
        case Right(_) | Left(_) =>
          // Already active, or completed
          ()
      }

    @tailrec
    override def cancel(): Unit =
      ref.get() match {
        case NOT_STARTED =>
          if (!ref.compareAndSet(NOT_STARTED, COMPLETED))
            cancel() // retry
        case LOCKED =>
          Thread.onSpinWait()
          cancel() // retry
        case Left(_) =>
          ()
        case current@Right(token) =>
          // No retries necessary; if state changes from Right(token),
          // it means that the stream is already completed or canceled
          if (ref.compareAndSet(current, COMPLETED))
            token()
      }
  })
```

And we can turn `Publisher` into a `Source`:

```scala
import akka.stream.scaladsl.Source

def toSource[A](io: IO[A])(implicit d: Dispatcher[IO]): Source[A, NotUsed] =
  Source.fromPublisher(toPublisher(io))
```

And finally, we can use [flatMapMerge](https://doc.akka.io/docs/akka/2.6.20/stream/operators/Source-or-Flow/flatMapMerge.html) to get the desired behavior of having a `Flow` that executes cancelable `IO` tasks:

```scala
import akka.stream.scaladsl.Flow

def cancelableIOToFlow[A, B](parallelism: Int)(
  f: A => IO[B]
)(implicit d: Dispatcher[IO]): Flow[A, B, NotUsed] =
  Flow[A].flatMapMerge(
    breadth = parallelism,
    a => toSource(f(a))
  )
```

<p class="warn-bubble" markdown="1">
  <strong>Warning:</strong> `mapAsync` is much more efficient than `flatMapMerge` or `flatMapConcat`. Unfortunately, Akka Stream isn't optimized for flat-mapping on streams that emit a single event. Also, depending on how your streams are structured, you may actually want uncancelable execution. Apply good judgement!
</p>

### Repeated execution (fixed delay)

Your challenge, should you choose to accept it, is to turn this into a stream:

```scala
def tryPoll: IO[Option[Result]]
```

So we want to describe a function that turns that into a stream, which is a common pattern:

```scala
def poll0[A](
  tryPoll: IO[Option[A]],
  sleepDelay: FiniteDuration,
)(implicit d: Dispatcher[IO]): Source[A, NotUsed] = {
  val logger = LoggerFactory.getLogger(getClass)
  Source.repeat(())
    .via(cancelableIOToFlow(1) { _ =>
      tryPoll.handleError { e =>
        logger.error("Unhandled error in poll", e)
        None
      }.flatTap {
        case None => IO.sleep(sleepDelay)
        case Some(_) => IO.unit
      }
    })
    .collect { case Some(a) => a }
}
```

The sleep itself could be managed by Akka Stream. At some point, our function looked like this:

```scala
def poll1[A](
  tryPoll: IO[Option[A]],
  interval: FiniteDuration,
)(implicit d: Dispatcher[IO]): Source[A, NotUsed] = {
  val logger = LoggerFactory.getLogger(getClass)
  // Notice the `takeWhile`. This is a child stream that gets
  // composed via `flatMapConcat`.
  val drain =
    Source.repeat(())
      .via(uncancelableIOToFlow(1) { _ =>
        tryPoll.handleError { e =>
          logger.error("Unhandled error in poll", e)
          None
        }
      })
      .takeWhile(_.nonEmpty)
      .collect { case Some(a) => a }
  // Main stream, managing the sleep intervals
  Source
    .tick(initialDelay = Duration.Zero, interval = interval, tick = ())
    .flatMapConcat(_ => drain)
    .mapMaterializedValue(_ => NotUsed)
}
```

This has the virtue of being fast, since the sleep is managed by Akka, and for draining our queue, we can manage to work with `mapAsync` (and thus, uncancellable IO tasks). However, this had awkward behavior due to the buffering, and isn't flexible enough. For instance, we wanted to specify a custom sleep duration for when exceptions are being thrown.

Last, but not least, in this particular case you can simply use [fs2](https://fs2.io/). This has the downside of introducing yet another dependency, and thus the area for potential issues is bigger. Extra dependencies on the classpath add risk. On the other hand, fs2 is designed to work with streams of IO tasks, being meant for precisely this use-case. And you can convert an `fs2.Stream` via the Reactive Streams interoperability.

You'll need these dependencies:

```scala
// sbt syntax
libraryDependencies ++= Seq(
  "co.fs2" %% "fs2-core" % "3.6.1",
  "co.fs2" %% "fs2-reactive-streams" % "3.6.1",
)
```

And the implementation:

```scala
def poll2[A](
  tryPoll: IO[Option[A]],
  interval: FiniteDuration,
)(implicit d: Dispatcher[IO]): Source[A, NotUsed] = {
  val logger = LoggerFactory.getLogger(getClass)
  val repeatedTask = tryPoll.handleError { e =>
    logger.error("Unhandled error in poll", e)
    None
  }.flatTap {
    case None => IO.sleep(interval)
    case Some(_) => IO.unit
  }

  val stream = fs2.Stream
    .repeatEval(repeatedTask)
    .collect { case Some(a) => a }

  import fs2.interop.reactivestreams._
  Source.fromPublisher(new StreamUnicastPublisher(stream, d))
}
```

Note, however, that using `fs2` for use-cases like this isn't without peril. For example, the cancellation model of Cats-Effect (and that of fs2) is incompatible with the Reactive Streams API when managing resources. You can't turn a `Resource` into a `Publisher`. You can turn a `Resource` into an `fs2.Stream`, and if you then try to turn that `fs2.Stream` into a `Publisher`, you'll end up with a `Publisher` that doesn't manage the resource correctly. Simply put, an `fs2.Stream` is more powerful than a `Publisher` (from the Reactive Streams spec), and so the conversion from fs2 to Reactive Streams can be problematic.

## Akka Stream Graphs

When running graphs with Akka Stream, if the processing of individual events is critical (like in our case), the question is what happens when the process is being shut down, as there will be some transactions that will be in-flight, with a process shutdown interrupting them.

We want to wait (with a timeout) for the processing of in-flight transactions, before the process is terminated. To achieve that, there are 2 elements to it:

1. The use of [kill switches](https://doc.akka.io/docs/akka/2.6.20/stream/stream-dynamic.html#controlling-stream-completion-with-killswitch), to stop all inputs in your graph;
2. The detection of the completion signal, giving a chance for in-flight transactions to complete;

A `KillSwitch` can be managed via `Resource`, although, as you shall see, we may need to trigger the kill signal outside the context of this `Resource`:

```scala
import akka.stream.{SharedKillSwitch, KillSwitches}

def sharedKillSwitch(name: String): Resource[IO, SharedKillSwitch] =
  Resource(IO {
    val ks = KillSwitches.shared(name)
    (ks, IO(ks.shutdown()))
  })
```

Another piece of the puzzle is that we may like to add logic to Cats-Effect's cancellations stack:

```scala
def resourceFinalizer(effect: IO[Unit]): Resource[IO, Unit] =
  Resource(IO { ((), effect) })
```

The method for starting the processing graph can look like this, and note that `IO[Done]` should signal when the processing is complete (all inputs are completed):

```scala
def startProcessor(
  killSwitch: SharedKillSwitch
)(implicit
  system: ActorSystem[_], 
): Resource[IO, IO[Done]]
```

We can then use the `KillSwitch` to kill all inputs, and then wait for processing to complete:

```scala
for {
  ks <- sharedKillSwitch("my-kill-switch")
  // We want to wait for `Done` during cancellation (below)
  awaitDone <- startProcessor(ks)(system)
  // The magic we've been waiting for
  _ <- resourceFinalizer(
    for {
      // Kill all inputs first
      _ <- IO(ks.shutdown())
      // Waits for processor to stop before proceeding;
      // Timeout is required, or this could be non-terminating
      _ <- awaitDone.timeoutAndForget(10.seconds)
    } yield ()
  )
} yield awaitDone
```

If we have this on our hands, we can easily describe a reusable app logic meant for executing Akka Stream graphs, which can take care of most things. And we base it on [IOApp](https://typelevel.org/cats-effect/api/3.x/cats/effect/IOApp.html):

```scala
trait ProcessorApp extends IOApp {
  /** Abstract method to implement... */
  def startProcessor(
    killSwitch: SharedKillSwitch
  )(implicit
    system: ActorSystem[_],
    dispatcher: Dispatcher[IO]
  ): Resource[IO, IO[Done]]

  override final def run(args: List[String]): IO[ExitCode] = {
    val startWithResources = for {
      d <- Dispatcher.parallel[IO]
      system <- startActorSystemTyped(
        systemName = "my-actor-system",
        config = None,
        useIOExecutionContext = true,
        timeoutAwaitCatsEffect = 10.seconds,
        timeoutAwaitAkkaTermination = 10.seconds,
      )
      killSwitch <- sharedKillSwitch("my-kill-switch")
      awaitDone <- startProcessor(killSwitch)(system, d)
      _ <- resourceFinalizer(
        for {
          // Kill all inputs
          _ <- IO(killSwitch.shutdown())
          // Waits the for processor to stop before proceeding;
          // Timeout is required, or this could be non-terminating
          _ <- awaitDone.timeoutAndForget(10.seconds)
          _ <- IO(logger.info(
            "Awaited processor to stop, proceeding with shutdown"
          ))
        } yield ()
      )
    } yield awaitDone

    startWithResources.use { awaitDone =>
      // Blocking on `awaitDone` makes sense, as the processor
      // could finish without the app receiving a termination signal
      awaitDone.as(ExitCode.Success)
    }
  }

  protected lazy val logger =
    LoggerFactory.getLogger(getClass)

  // It's a good idea to set a timeout on shutdown;
  // we need to take faulty cancellation logic into account
  override protected def runtimeConfig =
    super.runtimeConfig.copy(
      shutdownHookTimeout = 30.seconds
    )

  // We want to log uncaught exceptions in the thread pool,
  // via slf4j, otherwise they'll go to STDERR
  override protected def reportFailure(err: Throwable) =
    IO(logger.error("Unexpected error in thread-pool", err))
}
```

<p class="warn-bubble" markdown="1">
**WARNING:** when waiting for things to shut down, it's important to have timeouts all over the place, to avoid non-terminating logic. The last thing you want is a zombie process that can't shut down without a `kill -9`, because that requires external monitoring and intervention (e.g., systemd, docker, monit), and you can't trust that to be correctly configured. The less you trust, the more reliable your process will be.
</p>

As mentioned before, that `IO[Done]` is the completion signal, which we'll use in our main logic. This is easily accomplished via a [Sink](https://doc.akka.io/api/akka/2.6/akka/stream/scaladsl/Sink.html):

```scala
import akka.stream.scaladsl.Sink

def ignoreSink[A]: Sink[A, IO[Done]] =
  Sink.ignore.mapMaterializedValue(f => IO.fromFuture(IO.pure(f)))
```

We can now give an actual `Main` as an example. When running it, try killing it via SIGHUP/SIGINT/SIGTERM, see how it waits for processing to stop before shutting down resources:

```scala
object Main extends ProcessorApp {
  override def startProcessor(killSwitch: SharedKillSwitch)(implicit
    system: ActorSystem[_],
    dispatcher: Dispatcher[IO]
  ): Resource[IO, IO[Done]] = {
    Resource.eval {
      for {
        mySource <- IO {
          val counter = new AtomicInteger(0)
          val tryPoll = IO {
            val cnt = counter.incrementAndGet()
            if (cnt % 2 == 0) Some(cnt) else None
          }
          poll0(tryPoll, 1.second)
            // Installing killSwitch on this source
            .via(killSwitch.flow)
        }
        awaitDone <- IO {
          val sink = ignoreSink[Any]
          val graph = RunnableGraph.fromGraph(
            GraphDSL.createGraph(sink) { implicit builder => s =>
              import GraphDSL.Implicits._

              val ints = builder.add(mySource)
              val logEvents = builder.add(
                Flow[Int].map(i => logger.info(s"Received event: $i"))
              )
              
              // w00t, here's our very complicated graph! 
              ints ~> logEvents ~> s
              ClosedShape
            }
          )
          graph.run()
        }
      } yield awaitDone
    }
  }
}
```

## Full Example (Scala CLI)

The full example below can be executed directly via [Scala CLI](https://scala-cli.virtuslab.org/). On macOS you can install it with:

```sh
brew install Virtuslab/scala-cli/scala-cli
```

And then you can run it:

```sh
scala-cli run ./sample.scala

# Or make the script executable; works due to the included 'shebang'
# (https://en.wikipedia.org/wiki/Shebang_(Unix))
chmod +x ./sample.scala

# And then run it directly
./sample.scala
```

Copy/paste this script into `sample.scala`:

```scala
#!/usr/bin/env -S scala-cli shebang -q

//> using scala "2.13.10"
//> using lib "ch.qos.logback:logback-classic:1.4.6"
//> using lib "co.fs2::fs2-core::3.6.1"
//> using lib "co.fs2::fs2-reactive-streams::3.6.1"
//> using lib "com.typesafe.akka::akka-actor-typed::2.6.20"
//> using lib "com.typesafe.akka::akka-actor::2.6.20"
//> using lib "com.typesafe.akka::akka-stream-typed::2.6.20"
//> using lib "com.typesafe.akka::akka-stream::2.6.20"
//> using lib "org.typelevel::cats-effect::3.4.9"

import akka.actor.typed.ActorSystem
import akka.actor.typed.{ActorSystem => TypedActorSystem}
import akka.actor.{CoordinatedShutdown, ActorSystem => UntypedActorSystem}
import akka.stream.scaladsl.{Flow, GraphDSL, RunnableGraph}
import akka.stream.scaladsl.{Flow, Sink, Source}
import akka.stream.{ClosedShape, KillSwitches, SharedKillSwitch}
import akka.{Done, NotUsed}
import cats.effect.kernel.Resource
import cats.effect.std.Dispatcher
import cats.effect.{Deferred, ExitCode, IO, IOApp}
import cats.syntax.all._
import com.typesafe.config.Config
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference
import org.reactivestreams.{Publisher, Subscriber, Subscription}
import org.slf4j.LoggerFactory
import scala.annotation.tailrec
import scala.concurrent.duration._
import scala.concurrent.{Future, TimeoutException}

object Main extends ProcessorApp {
  import AkkaUtils._

  override def startProcessor(killSwitch: SharedKillSwitch)(implicit
    system: ActorSystem[_],
    dispatcher: Dispatcher[IO]
  ): Resource[IO, IO[Done]] = {
    Resource.eval {
      for {
        mySource <- IO {
          val counter = new AtomicInteger(0)
          val tryPoll = IO {
            val cnt = counter.incrementAndGet()
            if (cnt % 2 == 0) Some(cnt) else None
          }
          poll0(tryPoll, 1.second)
            // Installing killSwitch on this source
            .via(killSwitch.flow)
        }
        awaitDone <- IO {
          val sink = ignoreSink[Any]
          val graph = RunnableGraph.fromGraph(
            GraphDSL.createGraph(sink) { implicit builder => s =>
              import GraphDSL.Implicits._

              val ints = builder.add(mySource)
              val logEvents = builder.add(
                Flow[Int].map(i => logger.info(s"Received event: $i"))
              )
              
              // w00t, here's our very complicated graph! 
              ints ~> logEvents ~> s
              ClosedShape
            }
          )
          graph.run()
        }
      } yield awaitDone
    }
  }
}

trait ProcessorApp extends IOApp {
  import AkkaUtils._

  /** Abstract method to implement... */
  def startProcessor(killSwitch: SharedKillSwitch)(implicit
    system: ActorSystem[_],
    dispatcher: Dispatcher[IO]
  ): Resource[IO, IO[Done]]

  override final def run(args: List[String]): IO[ExitCode] = {
    val startWithResources = for {
      d <- Dispatcher.parallel[IO]
      system <- startActorSystemTyped(
        systemName = "my-actor-system",
        config = None,
        useIOExecutionContext = true,
        timeoutAwaitCatsEffect = 10.seconds,
        timeoutAwaitAkkaTermination = 10.seconds,
      )
      killSwitch <- sharedKillSwitch("my-kill-switch")
      awaitDone <- startProcessor(killSwitch)(system, d)
      _ <- resourceFinalizer(
        for {
          // Kill all inputs
          _ <- IO(killSwitch.shutdown())
          // Waits the for processor to stop before proceeding;
          // Timeout is required, or this could be non-terminating
          _ <- awaitDone.timeoutAndForget(10.seconds)
          _ <- IO(logger.info("Awaited processor to stop, proceeding with shutdown"))
        } yield ()
      )
    } yield awaitDone

    startWithResources.use { awaitDone =>
      // Blocking on `awaitDone` makes sense, as the processor
      // could finish without the app receiving a termination signal
      awaitDone.as(ExitCode.Success)
    }
  }

  protected lazy val logger =
    LoggerFactory.getLogger(getClass)

  // It's a good idea to set a timeout on shutdown;
  // we need to take faulty cancellation logic into account
  override protected def runtimeConfig =
    super.runtimeConfig.copy(
      shutdownHookTimeout = 30.seconds
    )

  // We want to log uncaught exceptions in the thread pool,
  // via slf4j, otherwise they'll go to STDERR
  override protected def reportFailure(err: Throwable) =
    IO(logger.error("Unexpected error in thread-pool", err))
}

object AkkaUtils {
  /** Starts an (untyped) Akka actor system in the
    * context of a Cats-Effect `Resource`, and integrating
    * with its cancellation abilities.
    *
    * HINT: for apps (in `main`), it's best if
    * `akka.coordinated-shutdown.exit-jvm` is set to `on`,
    * because Akka can decide to shutdown on its own. And
    * having this setting interacts well with Cats-Effect.
    *
    * @param systemName is the identifying name of the system.
    * @param config is an optional, parsed HOCON configuration;
    *        if None, then Akka will read its own, possibly
    *        from `application.conf`; this parameter is
    *        provided in order to control the source of
    *        the application's configuration.
    * @param useIOExecutionContext if true, then Cats-Effect's
    *        default thread-pool will get used by Akka, as well.
    *        This is needed in order to avoid having too many
    *        thread-pools.
    * @param timeoutAwaitCatsEffect is the maximum amount of time
    *        Akka's coordinated-shutdown is allowed to wait for
    *        Cats-Effect to finish. This is needed, as Cats-Effect
    *        could have a faulty stack of disposables, or because
    *        Akka could decide to shutdown on its own.
    * @param timeoutAwaitAkkaTermination is the maximum amount of
    *        time to wait for the actor system to terminate, after
    *        `terminate()` was called. We need the timeout, because
    *        `terminate()` proved to return a `Future` that never
    *        completes in certain scenarios (could be a bug, or a
    *        race condition).
    */
  def startActorSystemUntyped(
    systemName: String,
    config: Option[Config],
    useIOExecutionContext: Boolean,
    timeoutAwaitCatsEffect: Duration,
    timeoutAwaitAkkaTermination: Duration,
  ): Resource[IO, UntypedActorSystem] = {
    // Needed to turn IO into Future
    // https://typelevel.org/cats-effect/docs/std/dispatcher
    Dispatcher.parallel[IO](await = true).flatMap { dispatcher =>
      Resource[IO, UntypedActorSystem](
        for {
          // Fishing IO's `ExecutionContext`
          ec <- Option
            .when(useIOExecutionContext)(IO.executionContext)
            .sequence
          // For synchronizing Cats-Effect with Akka
          awaitCancel <- Deferred[IO, Unit]
          // For awaiting termination, as `terminate()` is unreliable
          awaitTermination <- Deferred[IO, Unit]
          logger = LoggerFactory.getLogger(getClass)
          system <- IO {
            logger.info("Creating actor system...")
            val system = UntypedActorSystem(
              systemName.trim.replaceAll("\\W+", "-"),
              config = config,
              defaultExecutionContext = ec,
            )
            // Registering task in Akka's CoordinatedShutdown
            // that will wait for Cats-Effect to catch up,
            // blocking Akka from terminating, see:
            // https://doc.akka.io/docs/akka/current/coordinated-shutdown.html
            CoordinatedShutdown(system).addTask(
              CoordinatedShutdown.PhaseBeforeServiceUnbind,
              "sync-with-cats-effect",
            ) { () =>
              dispatcher.unsafeToFuture(
                // WARN: this may not happen, if Akka decided
                // to terminate, and `coordinated-shutdown.exit-jvm`
                // isn't `on`, hence the timeout:
                awaitCancel.get
                  .timeout(timeoutAwaitCatsEffect)
                  .recoverWith {
                    case ex: TimeoutException =>
                      IO(logger.error(
                        "Timed out waiting for Cats-Effect to catch up! " +
                          "This might indicate either a non-terminating " +
                          "cancellation logic, or a misconfiguration of Akka."
                      ))
                  }
                  .as(Done)
              )
            }
            CoordinatedShutdown(system).addTask(
              CoordinatedShutdown.PhaseActorSystemTerminate,
              "signal-terminated",
            ) { () =>
              dispatcher.unsafeToFuture(
                awaitTermination.complete(()).as(Done)
              )
            }
            system
          }
        } yield {
          val cancel =
            for {
              // Signals that Cats-Effect has caught up with Akka
              _ <- awaitCancel.complete(())
              _ <- IO(logger.warn("Shutting down actor system!"))
              // Shuts down Akka, and waits for its termination
              // Here, system.terminate() returns a `Future[Terminated]`,
              // but we are ignoring it, as it could be non-terminating
              _ <- IO(system.terminate())
              // Waiting for Akka to terminate via its CoordinatedShutdown
              _ <- awaitTermination.get
              // WARN: `whenTerminated` is unreliable
              _ <- IO.fromFuture(IO(system.whenTerminated)).void
                .timeoutAndForget(timeoutAwaitAkkaTermination)
                .handleErrorWith(_ =>
                  IO(logger.warn(
                    "Timed-out waiting for Akka to terminate!"
                  ))
                )
            } yield ()
          (system, cancel)
        }
      )
    }
  }

  /** Starts a (typed) Akka actor system.
    *
    * @see [[startActorSystemUntyped]] for more details on params.
    */
  def startActorSystemTyped(
    systemName: String,
    config: Option[Config],
    useIOExecutionContext: Boolean,
    timeoutAwaitCatsEffect: FiniteDuration,
    timeoutAwaitAkkaTermination: FiniteDuration,
  ): Resource[IO, TypedActorSystem[Nothing]] =
    startActorSystemUntyped(
      systemName,
      config,
      useIOExecutionContext,
      timeoutAwaitCatsEffect,
      timeoutAwaitAkkaTermination,
    ).map { system =>
      import akka.actor.typed.scaladsl.adapter.ClassicActorSystemOps
      system.toTyped
    }

  /** Converts a Cats-Effect `IO` into a Reactive Streams `Publisher`.
    *
    * [[https://github.com/reactive-streams/reactive-streams-jvm]]
    */
  def toPublisher[A](io: IO[A])(implicit d: Dispatcher[IO]): Publisher[A] =
    (s: Subscriber[_ >: A]) => s.onSubscribe(new Subscription {
      type CancelToken = () => Future[Unit]

      private[this] val NOT_STARTED: Null = null
      private[this] val LOCKED = Left(false)
      private[this] val COMPLETED = Left(true)

      // State machine for managing the active subscription
      private[this] val ref =
        new AtomicReference[Either[Boolean, CancelToken]](NOT_STARTED)

      override def request(n: Long): Unit =
        ref.get() match {
          case NOT_STARTED =>
            if (n <= 0) {
              if (ref.compareAndSet(NOT_STARTED, COMPLETED))
                s.onError(new IllegalArgumentException(
                  "non-positive request signals are illegal"
                ))
            } else {
              if (ref.compareAndSet(NOT_STARTED, LOCKED)) {
                val cancelToken = d.unsafeRunCancelable(
                  io.attempt.flatMap { r =>
                    IO {
                      r match {
                        case Right(value) =>
                          s.onNext(value)
                          s.onComplete()
                        case Left(e) =>
                          s.onError(e)
                      }
                      // GC purposes
                      ref.lazySet(COMPLETED)
                    }
                  }
                )
                // Race condition with lazySet(COMPLETED), but it's fine
                ref.set(Right(cancelToken))
              }
            }
          case Right(_) | Left(_) =>
            // Already active, or completed
            ()
        }

      @tailrec
      override def cancel(): Unit =
        ref.get() match {
          case NOT_STARTED =>
            if (!ref.compareAndSet(NOT_STARTED, COMPLETED))
              cancel() // retry
          case LOCKED =>
            Thread.onSpinWait()
            cancel() // retry
          case Left(_) =>
            ()
          case current@Right(token) =>
            // No retries necessary; if state changes from Right(token),
            // it means that the stream is already completed or canceled
            if (ref.compareAndSet(current, COMPLETED))
              token()
        }
    })

  def toSource[A](io: IO[A])(implicit d: Dispatcher[IO]): Source[A, NotUsed] =
    Source.fromPublisher(toPublisher(io))

  def uncancelableIOToFlow[A, B](parallelism: Int)(
    f: A => IO[B]
  )(implicit d: Dispatcher[IO]): Flow[A, B, NotUsed] =
    Flow[A].mapAsync(parallelism)(a => d.unsafeToFuture(f(a)))


  def cancelableIOToFlow[A, B](parallelism: Int)(
    f: A => IO[B]
  )(implicit d: Dispatcher[IO]): Flow[A, B, NotUsed] =
    Flow[A].flatMapMerge(
      breadth = parallelism,
      a => toSource(f(a))
    )

  def poll0[A](
    tryPoll: IO[Option[A]],
    interval: FiniteDuration,
  )(implicit d: Dispatcher[IO]): Source[A, NotUsed] = {
    val logger = LoggerFactory.getLogger(getClass)
    Source.repeat(())
      .via(cancelableIOToFlow(1) { _ =>
        tryPoll.handleError { e =>
          logger.error("Unhandled error in poll", e)
          None
        }.flatTap {
          case None => IO.sleep(interval)
          case Some(_) => IO.unit
        }
      })
      .collect { case Some(a) => a }
  }

  def poll1[A](
    tryPoll: IO[Option[A]],
    interval: FiniteDuration,
  )(implicit d: Dispatcher[IO]): Source[A, NotUsed] = {
    val logger = LoggerFactory.getLogger(getClass)
    // Notice the `takeWhile`. This is a child stream that gets
    // composed via `flatMapConcat`.
    val drain =
    Source.repeat(())
      .via(uncancelableIOToFlow(1) { _ =>
        tryPoll.handleError { e =>
          logger.error("Unhandled error in poll", e)
          None
        }
      })
      .takeWhile(_.nonEmpty)
      .collect { case Some(a) => a }

    Source
      .tick(initialDelay = Duration.Zero, interval = interval, tick = ())
      .flatMapConcat(_ => drain)
      .mapMaterializedValue(_ => NotUsed)
  }

  def poll2[A](
    tryPoll: IO[Option[A]],
    interval: FiniteDuration,
  )(implicit d: Dispatcher[IO]): Source[A, NotUsed] = {
    val logger = LoggerFactory.getLogger(getClass)
    val repeatedTask = tryPoll.handleError { e =>
      logger.error("Unhandled error in poll", e)
      None
    }.flatTap {
      case None => IO.sleep(interval)
      case Some(_) => IO.unit
    }

    val stream = fs2.Stream
      .repeatEval(repeatedTask)
      .collect { case Some(a) => a }

    import fs2.interop.reactivestreams._
    Source.fromPublisher(new StreamUnicastPublisher(stream, d))
  }

  def ignoreSink[A]: Sink[A, IO[Done]] =
    Sink.ignore.mapMaterializedValue(f => IO.fromFuture(IO.pure(f)))

  def sharedKillSwitch(name: String): Resource[IO, SharedKillSwitch] =
    Resource(IO {
      val ks = KillSwitches.shared(name)
      (ks, IO(ks.shutdown()))
    })

  def resourceFinalizer(effect: IO[Unit]): Resource[IO, Unit] =
    Resource(IO {
      ((), effect)
    })
}
```

Enjoy!
