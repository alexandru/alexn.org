---
title: "Scala OOFP Design Sample"
last_modified_at: 2022-04-18 20:43:15 +03:00
tags:
  - FP
  - OOP
  - Scala
image: /assets/media/articles/2022-04-oofp.png
generate_toc: true
description: >
  Scala is considered a multi-paradigm language, for better or worse, being one of the best OOP languages, which is why it's so versatile. Let's do a design exercise, going from OOP to static FP, and back. Let's understand the various techniques promoted in the community, and understand why the OOP design isn't just “idiomatic” for Scala, but can be superior to alternatives.
---

<p class="intro withcap">
Scala is considered a multi-paradigm language, for better or worse, being one of the best OOP languages, which is why it's so versatile. Let's do a design exercise, going from OOP to static FP, and back. Let's understand the various techniques promoted in the community, and understand why the OOP design isn't just “idiomatic” for Scala, but can be superior to alternatives.
</p>

## The design problem

**Design a *“queue of delayed messages.”***

Should you choose to accept this challenge, the queue should be similar to using a message broker like IBM-MQ, or a Kafka topic, but with the ability to schedule messages to be *delivered at exact timestamps in the future*. It also has to support an acknowledgement mechanism, with messages becoming invisible when pulled from the queue, and if the acknowledgement doesn’t happen, then messages have to reappear on the queue after a timeout.

As an underlying implementation, we could use a RDBMS database via JDBC — in our project (at $work) we use MS-SQL. But we could also have an in-memory implementation, which is actually super useful, and not just as a mock in tests. And we could migrate to a NoSQL database, such as MongoDB, or Redis, or maybe even Cassandra — anything that can do [atomic compare-and-swap operations](https://en.wikipedia.org/wiki/Compare-and-swap) (on keys) should work.

Using a real-world example can be boring, due to all the concerns involved, bear with me...

## Classic and impure OOP design

In classic OOP (e.g. Java) we could work with an interface like this:

```scala
import java.util.UUID
import java.time.Instant
import scala.concurrent.Future

trait DelayedQueue[A] {
  /** Schedules new messages on the queue. */
  def offer(m: OfferedMessage[A]): Future[OfferOutcome]
  /** Returns messages ready to be processed. */
  def tryPoll: Future[Option[ReceivedMessage[A]]]
  /** Deletes messages from the queue. */
  def discard(key: String): Future[Unit]
}

enum OfferOutcome { // Scala 3's tagged unions
  case Created
  case Updated
  case Ignored
}
  
final case class OfferedMessage[+A](
  key: String,
  payload: A,
  scheduleAt: Instant,
  canUpdate: Boolean,
)

final case class ReceivedMessage[+A](
  message: A,
  messageID: UUID,
  receivedAt: Instant,
  acknowledge: () => Future[Unit],
)
```

Using this API, to illustrate its usage for building consumers:

```scala
import scala.concurrent.ExecutionContext

def drain[A](queue: DelayedQueue[A])(using ExecutionContext): Future[Unit] =
  queue.tryPoll.flatMap {
    case None => Future.unit
    case Some(msg) =>
      println(s"Received: ${msg.message}")
      // Acknowledge it, or it will reappear after a timeout;
      msg.acknowledge()
        .flatMap(_ => drain(queue)) // process next
  }
```

There are many subtle design choices exposed by this API, which make it an acceptable one. Let’s enumerate …

1) Given the OOP context, we should already have an intuition that **this interface does I/O**, because there aren’t many good reasons for why open-world OOP interfaces are needed, the primary reason being that we need to abstract away implementation details that involve I/O;

2) We are using `Future`, so **the I/O can be asynchronous**. And `Future` can be completed with exceptions, so code should install generic exception handlers that do logging or whatever it is that you do with unexpected exceptions;

3) Messages get persisted based on a `key: String`, because when scheduling messages in advance, we may want to also get rid of them in advance; this “delayed queue” could then be used to trigger timeout exceptions for asynchronous operations that fail to yield a result; it’s why we have a `discard(key)` operation, which may seem redundant with `acknowledge` from `ReceivedMessage`, but isn’t;

4) The generic parameter in `DelayedQueue[A]` means **we are forced to have a queue per message-type**, which is a best practice, and avoids implementation leaks (more on that below);

5) **All actionable “error” conditions are expressed in the returned types** — in the case of `tryPoll` via the returned `Option`, and in the case of `offer` via the `OfferOutcome` union type; they don’t seem like errors, because they are *“designed away”*; in this sample we don’t need `Either` or Java’s checked exceptions (more on that below);

The interface does have flaws — for example, `tryPoll` is an operation that has to be repeated, in order to keep the channel open and ready to process messages. If we sleep between successive `tryPoll` operations, this might be an implementation detail as well. And it can be improved, but how we handle streaming isn't the purpose of this article.

### Beware: constraints can be implementation leaks

[Leaky abstractions](https://en.wikipedia.org/wiki/Leaky_abstraction) are common when designing abstract APIs. If you don’t have at least 2 very different implementations, the API isn’t really abstract. And in these abstract OOP interfaces, the constraints placed on parameter types lead to leaky abstractions. But let’s put this to the test…

Let’s say we don’t want `A` type parameter on the interface, so we could have it per method. But having it per method requires introducing a constraint for serialization/deserialization. Let’s design the type-class:

```scala
import monix.newtypes.TypeInfo

class ParsingException(message: String) extends RuntimeException(message)

/** 
  * Type-class for serializing and deserializing to and from `String`. 
  */
trait ValueCodec[A] {
  def kind: TypeInfo[A]
  def serialize(a: A): String
  def deserialize(s: String): Either[ParsingException, A]
}
```

Notes:

- [TypeInfo](https://newtypes.monix.io/api/monix/newtypes/TypeInfo.html) is from [monix-newtypes](https://github.com/monix/newtypes), but you can replace it with a plain `String` — we are making the *name of the type* be part of the persisted key, otherwise we can end up with conflicts when reusing the same database table / queue for multiple data types;
- Serialization should never return an error; but deserialization can end in error because we are losing information in the serialization process, thus we cannot force validations via the type system, and this error needs to be very explicitly modeled via the type system, as it’s not just an “exception”;

Based on this codec, our interface could become:

```scala
trait DelayedQueue {
  def offer[A: ValueCodec](m: OfferedMessage[A]): Future[OfferOutcome]
  def tryPoll[A: ValueCodec]: Future[Option[ReceivedMessage[A]]]
  def discard[A: ValueCodec](key: String): Future[Unit]
}
```

You can see how this sucks:

- We are encouraging the usage of a single queue for multiple message types;
- The call-sites of those methods are awkward;
- **Serialization method is an implementation leak;**

Serializing the values to string makes no sense for an in-memory implementation. It’s also restrictive, as your database might support a binary serialization format that’s more efficient than string (e.g. protocol buffers).

NOTE — our `ValueCodec` isn’t useless. We can still use it for our RDBMS implementation:

```scala
final class DelayedQueueJDBC[A: ValueCodec] private (
  connection: DataSource,
  //...
) extends DelayedQueue[A] {
  //...
}
```

Notice how the constraint is now part of the class’s *constructor*, and by being a constructor parameter, it doesn’t have to be part of the abstract interface.

## Suspending side effects

We can improve our interface by working with an `IO` datatype, such as that of [Cats Effect](https://typelevel.org/cats-effect/), replacing our usage of `Future`:

```scala
import cats.effect.IO

trait DelayedQueue[A] {
  def offer(m: OfferedMessage[A]): IO[OfferOutcome]
  def tryPoll: IO[Option[ReceivedMessage[A]]]
  def discard(key: String): IO[Unit]
}

final case class ReceivedMessage[+A](
  //...
  acknowledge: IO[Unit],
)
```

Our IO-driven API is definitely an improvement. Due to the usage of `IO`, it’s even more clear that we are modelling I/O operations with side effects involved. And the applications of these functions are [referentially transparent](https://en.wikipedia.org/wiki/Referential_transparency). We are now proudly making use of FP. For more details on how `IO` is better than `Future`, I recommend this presentation:

{% include youtube.html id="qgfCmQ-2tW0" %}

And, I would argue that usage of `IO` in this API can be the best you can do in Scala 😉

### Beware: IO in our API is a constraint!

By specifying `IO` we mean that *“implementations are free to launch rockets to Mars.”* And that’s good in the OOP sense, as we allow for flexibility of implementation, while keeping the protocol abstract enough that we can understand what’s going on.

Static FP proponents usually don’t like this (more details below), but I disagree.

## Tagless Final

`IO` can become a type parameter:

```scala
trait DelayedQueue[F[_], A] {
  def offer(m: OfferedMessage[A]): F[OfferOutcome]
  def tryPoll: F[Option[ReceivedMessage[F, A]]]
  def discard(key: String): F[Unit]
}

final case class ReceivedMessage[F[_], +A](
  //...
  acknowledge: F[Unit],
)
```

`F[_]` is a placeholder for what we call *“an effect”*. An effect in the context of FP isn’t a side effect — think of “effects” as anything other than returning the result of a computation.

`Option` and `Either` are modeling effects too. NOT side effects, but the main effects. In the English language, an effect is something that has a cause, and in our programming language we model causality via `flatMap`. So, as an incomplete and wrong intuition, effects in Scala are modeled via monadic data-types (types that implement a lawful `flatMap` and constructor pair, aka `Monad`).

By making `DelayedQueue` work with any `F[_]`:

1. we could use alternative `IO` data type implementations;
2. we could use monad stacks, e.g. `EitherT[IO, *]`;
3. we could use [cats.Id](https://typelevel.org/cats/datatypes/id.html) for really simple and pure tests;

And *“tagless final”* is a technique that’s equivalent to usage of OOP interfaces, except that the interfaces we get are parametrized by `F[_]`, aka the “effect type”.

<p class="info-bubble" markdown=1>
There are better places on the web that explain tagless final, and I'm likely doing a bad job. For those wanting to learn more about *tagless final* and its correspondence to object algebras, I recommend ["Extensibility for the Masses: Practical Extensibility with Object Algebras"](https://www.cs.utexas.edu/~wcook/projects/oa/oa.pdf) and ["From Object Algebras to Finally Tagless Interpreters"](https://oleksandrmanzyuk.wordpress.com/2014/06/18/from-object-algebras-to-finally-tagless-interpreters-2/).
</p>

In "tagless final" we define capabilities via OOP-like interfaces (also called "algebras"):

```scala
trait Logger[F[_]] {
  def info(message: String): F[Unit]
}
```

Then to model our consumer, we can combine multiple algebras:

```scala
import cats.Monad
import cats.syntax.all._

def drain[F[_], A](using // Scala 3's `implicit`
  Monad[F], 
  Logger[F], 
  DelayedQueue[F, A]
): F[Unit] =
  summon[DelayedQueue[F, A]].tryPoll.flatMap {
    case None => 
      Applicative[F].unit
    case Some(msg) =>
      summon[Logger[F]].info(s"Received: ${msg.message}")
        .flatMap(_ => msg.acknowledge) // deletes the message
        .flatMap(_ => drain[F, A]) // next please
  }
```

Let’s ignore the implementation and zoom in on this function’s signature:

```scala
def drain[F[_], A](using 
  Monad[F], 
  Logger[F], 
  DelayedQueue[F, A]
): F[Unit]
```

We are saying that we want `F[_]` to implement:

- `Monad`: which means a sequencing/chaining of steps is involved, via `flatMap`;
- `Logger`: which means we want to log something;
- `DelayedQueue`: our queuing capability;

This is what’s called *[“parametricity”](https://en.wikipedia.org/wiki/Parametricity)* in static FP circles: by looking at the function’s signature, we have a pretty good idea of what it does, because the function is so generic that it’s hard for it to do anything else.

And yet there’s something amiss for any seasoned OOP architect — let’s zoom back on the API:

```scala
trait DelayedQueue[F[_], A] {
  def offer(m: OfferedMessage[A]): F[OfferOutcome]
  def tryPoll: F[Option[ReceivedMessage[F, A]]]
  def discard(key: String): F[Unit]
}
```

In this example, we aren’t talking of any `F[_]` effect type. It’s ridiculous to think that we can use `Either` or `Option` here. If we use `Id`, we only use it for demonstrative purposes, with absolutely no value.

We say `F[_]` in this API, but as its authors, we know that we are talking of a data type that encapsulates / suspends side effects, but without saying so. This is the opposite of parametricity, and in this context usage of this style is not good API design, unless you really, really want tagless final in your project, and thus rely on conventions (e.g. whenever you see `F[_]`, you see `IO`). The danger being that readers of this code might not get a good mental model of using this API, because there's information missing, and that's bad.

To be clear — **this isn’t good API design because `F[_]` is left unspecified**.

To be fair, we could restrict `F[_]` to the [cats.effect.Concurrent](https://typelevel.org/cats-effect/docs/typeclasses/concurrent) type-class, but at that point we might as well work with `IO` directly. And if we’d revert to the IO-driven API, we could have:

```scala
def drain[A](logger: Logger, queue: DelayedQueue[A]): IO[Unit]
```

The big difference, in terms of “parametricity”, is that executing an `IO` could launch rockets to Mars for all we know, so we can’t really restrict the implementation of this function to depend entirely on its input. But this is Scala for you. On top of the JVM we can do anything, anywhere, anyway, relying somewhat on good practices and conventions for not triggering side effects, or using shared mutable state. And while using `F[_]` can make violations of parametricity harder, it doesn’t make it impossible, and those violations have the potential to be worse, since without `IO`, you definitely end up with unsuspended side effects.

There is also another difference ... implicit parameters mean that we are using only one instance in the whole project. We have only one `Logger` instance, and only one `DelayedQueue[A]` instance. This is a best practice. As another example, instances of type-classes need to be unique, because type-classes need *coherence*, i.e. if you can't rely on a single instance being available in the whole project, then the code can lead to bugs, due to function calls yielding different results for the same parameters, depending on the call-site.

Nothing stops you from converting to implicit parameters, even without `F[_]`. I think people abuse implicit parameters, I prefered to reserve use of implicit parameters for type-class instances, but that battle was lost, as with tagless final these "algebras" aren't necessarily type-classes anyway:

```scala
def drain[A](given logger: Logger, queue: DelayedQueue[A]): IO[Unit]
```

For me (*personal opinion warning!*), this version is pretty damn explicit about what it does, I don’t see much of a difference in my understanding of it, certainly not a difference that’s big enough to outweigh the cost of introducing higher-kinded types and type-classes. If you’ve been on any medium-sized project, a project that’s regularly looking for promising beginners, I’m pretty sure the concern did come up repeatedly – how in the world are beginners going to cope with learning the use of `F[_]` with type-classes and everything related? This on top of everything else, which can increase the barrier to entry significantly. And I think the experience of the job market varries based on the available talent.

## Monad Transformers, ZIO … are useless here

If we’d like to get fancy, we could work with a type that handles “dependency injection” and explicit errors, equivalent to Java’s “checked exceptions”:

```scala
type ZIO[-Env, +Error, +Result] = Env => IO[Either[Error, Result]]
```

We could work with this, but we have to be careful because the JVM doesn’t do tail-calls optimizations (TCO), so this could be memory unsafe. Also, we need `Monad` and other type-classes and utilities defined for it, so if using Cats, we could work with:

```scala
import cats.data.{EitherT, Kleisli}

type ZIO[Env, Error, Result] = 
  Kleisli[[A] =>> EitherT[IO, Error, A], Env, Result]
```

We are combining multiple [monad transformers](https://en.wikipedia.org/wiki/Monad_transformer), and so we have a *“monad transformers stack”*.

NOTE:

- the `Env` is the “environment”, which specifies what’s needed for the execution of the operation — for example, we might need a JDBC `DataSource` or a `Logger`;
- the `Error` type parameter is for signaling errors that must be handled;

This type is equivalent to [ZIO[R, E, A]](https://zio.dev/version-1.x/datatypes/core/zio). A data-type like `ZIO` is nicer if you use it everywhere, however I prefer the monad transformers from [Cats](https://typelevel.org/cats/), because they are more composable, and we only pay this price where needed … which in my case is almost never 🤷‍♂️

Can we have ...

1. An explicit environment that makes sense in an abstract API?
2. An explicit error type that signals currently unspecified error conditions?

The answer is NO and NO, because in both cases we are talking of [implementation leaks](https://en.wikipedia.org/wiki/Leaky_abstraction). It doesn’t prevent us from trying, though:

```scala
trait DelayedQueue[A] {
  def offer(m: OfferedMessage[A]): ZIO[DataSource, SQLException, OfferOutcome]
  def tryPoll: ZIO[DataSource, SQLException, Option[ReceivedMessage[F, A]]]
  def discard(key: String): ZIO[DataSource, SQLException, Unit]
}
```

`DataSource` or `SQLException` are only relevant for the JDBC-powered implementation, otherwise they are implementation leaks.

For one, I'm always amazed by the people's struggle to introduce various automated dependency injection techniques in their project, given we have OOP encapsulation and OOP constructors. Haskell's monad transformer stacks have always felt off, and it isn't just Scala's more limited type inference. Haskell is just not very good at encapsulation, as it's not a very good OOP language, most features and most of its culture conspiring against OOP-like encapsulation. In Scala, if you have dependencies that you'd like to avoid as explicit parameters, the first strategy is to give them as parameters in a class constructor that's only called once, then pass that object around. Anything else feels like a hack in Scala, IMO, even if constructor-based dependency injection has its drawbacks.

As for errors, one can argue that `SQLException` is important, and not declaring it in the output type is simply an unspecified error condition. But I’d argue that if it is important, then your API and your application’s design is probably screwed (with exceptions).

I'm repeating myself — we have no important error type that wasn’t already captured in the return types of our API:

- `Option` is an effect type that signals `None` in case there are no messages available; in which case you can stop, or you can retry later;
- `OfferOutcome` is a union data type that tells us if our offering has succeeded or not, taking into account other concurrent offerings;
  - But in most cases, it doesn't matter what this result even is, because after this call is executed, we know for a fact that there is a message scheduled with its corresponding key; so the result itself could be ignored;

In this context the usage of `ZIO`, to enhance the return types, would violate an important OOP principle:

> *“Program to an interface, not to an implementation.”*

This is the equivalent of *“parametricity”*, except it refers to encapsulating implementation details, and use flexible interfaces in your logic. Abstraction, as a general concept, is not just about observing groups of data types that can be operated in the same way. Abstraction is also about ignoring the non-essential, which is what OOP’s encapsulation and subtype polymorphism are doing.

There is nothing about this `ZIO` data type that improves our API in any way, quite the contrary, what it brings to the table is only going to obscure what we’re trying to express, as now we are forced to fill in those type parameters with something:

```scala
trait DelayedQueue[-Env, A]:
  def offer(m: OfferedMessage[A]): RIO[Env, Nothing, OfferOutcome]
  def tryPoll: RIO[Env, Nothing, Option[ReceivedMessage[F, A]]]
  def discard(key: String): RIO[Env, Nothing, Unit]
```

Note that `IO[A]` from Cats Effect is the equivalent of `ZIO[Any, Nothing, A]` (no, the explicit error type isn’t `Throwable`). So we have to parametrize the environment and ignore the error type. Or use both as parameters, but that’s just awful.

## Error Handling

As said multiple times, the important error conditions are already baked into the API. But that’s not entirely accurate — what we did was to design them away. Remember this good principle of software design:

> *“Design the errors out of existence.”*

An *“error”*, in the English language, means a mistake, an action which is inaccurate or incorrect. This can happen in our programming due to:

1. incomplete or incorrect input;
2. runtime conditions that are outside of our program’s control;
3. bugs;

Our programs mostly care about the happy path, but we have to treat errors too. *“Designing errors out of existence”* means that, if you care about an error, then it shouldn’t be an error. This means:

1. Model an output data type that expresses the "error" in a way that is hard to ignore — e.g. the result of a parsing function is either the parsed result, or some message that needs to be displayed; but this only works for input errors of functions whose result we depend on (i.e. we have a *data dependency*), otherwise …
2. Make the errors impossible, such that the caller of your API no longer has the responsibility of dealing with those errors;

**Question** — what can you do with an [SQLException](https://docs.oracle.com/javase/7/docs/api/java/sql/SQLException.html)?

**Answer: mostly nothing!** The right place to treat an `SQLException` is in the encapsulated implementation of your API. The lower-level it is, the better. Once you stream that to the client, it’s already too late to do anything about it.

Both Cats’ [EitherT](https://typelevel.org/cats/datatypes/eithert.html) and [ZIO](https://zio.dev/version-1.x/datatypes/core/zio) exist in order to make errors hard to ignore in instances in which they’d be easy to ignore:

```scala
def offer(m: OfferedMessage[A]): IO[Either[SQLException, OfferOutcome]]
```

In this case that `SQLException` can be easy to ignore, as we may not care about the `OfferOutcome`, so you can easily end up with this:

```scala
for {
  _ <- queue.offer(message) // oops!
  _ <- log("done")
} yield ()
```

As a band-aid you can make it more difficult to ignore such exceptions by usage of monad transformers, or related data types. The purpose here being to make that `flatMap` less forgiving:

```scala
// cats.EitherT
def offer(m: OfferedMessage[A]): EitherT[IO, SQLException, OfferOutcome]
// ZIO
def offer(m: OfferedMessage[A]): ZIO[Any, SQLException, OfferOutcome]
```

Except this is bad software design. Not only is `SQLException` an implementation leak, the bigger problem is that there are only 2 courses of action:

1. you can shrug and re-throw it like any other `Throwable`, such that the process can log it and do whatever it does for unknown exceptions;
2. you can retry the operation — and here’s the rub — a retry is best left as an implementation detail, because the retry logic depends on the resource type;

And to make matters worse, it’s really hard to parse an `SQLException`. Anyone that has ever done it knows that these exceptions aren’t standard at all, and sometimes we end up parsing its `message` in order to ascertain whether the transaction can be retried, or not. And there are multiple policies possible:

- in case a concurrent update happened, with the transaction failing, it’s often best for the retry to happen immediately, although it depends on the contention, and it’s good to keep in mind that RDBMS databases don’t do well with many concurrent updates hitting the same table;
- in case the connection is down, or in case of timeouts, using an [exponential backoff](https://en.wikipedia.org/wiki/Exponential_backoff) strategy might be wise;
- in case of an SQL syntax error, no retry is possible, of course, so you need to bail out as fast as possible;

Note that we probably have to parse `SQLException` in our implementation, in order to return a usable `OfferOutcome`. As an API author, if you take the time to parse `SQLException` such that you can discriminate between such cases, then why not take care of the retry logic yourself? Designing errors out of existence, in this case, means that the user of the API shouldn’t care.

If you’re designing a light-weight API that just wraps JDBC, by all means, expose `SQLException`, although I’ll be eternally grateful for any JDBC wrapper that avoids exposing `SQLException` and gives me something more usable, because it is goddamn awful.

## Epilogue

In application code, in a Scala project, I’d argue that nothing beats the clarity and flexibility of interfaces like this:

```scala
import cats.effect.IO

trait DelayedQueue[A] {
  def offer(m: OfferedMessage[A]): IO[OfferOutcome]
  
  def tryPoll: IO[Option[ReceivedMessage[A]]]
  
  def discard(key: String): IO[Unit]
}
```

For library code, using an `F[_]` type parameter for the effect type might be better, as it allows people to come up with their monad transformers stack, or a different `IO` implementation. Such library code allows for a "tagless final" approach, like we've seen here, and I admit, people have some good reasons for liking it. However, this doesn’t come without cost, a cost that needs to be balanced by great documentation.

Scala isn’t Haskell, and for me the *tagless final* approach (powered by implicit parameters / type-classes, or even monad transformers), or ZIO, both proved to be anti-OOP. An "idiomatic" Scala style should use its OOP features for OOP polymorphism, as that's the *"path of least resistance"*. And tagless final isn't incompatible with this approach, but I fear that usage of `F[_]` or of advanced language features end up obscuring the APIs exposed — compared to just passing IO-driven OOP interfaces around, as simple parameters.

These techniques and advanced features have their place in our toolbox, for sure, and the stronger the types, the better, but nothing beats good taste, or design that focuses on ease of use and the [user's mental model](https://en.wikipedia.org/wiki/The_Design_of_Everyday_Things), and such skills have less to do with static typing, or the application of math.

Designing good APIs requires empathy for the users of your API. Don't get me wrong, when you inflict pain on your users, it's better if that pain is strongly typed, but it would be much better to not inflict that pain at all.
