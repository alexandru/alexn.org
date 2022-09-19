---
title: "Avoid Javaisms: Mocks, Stubs, DI is Code Smell"
description:
  Such practices represent clear signals for code smell, meaning code
  that sucks as a symptom of a bigger problem, one of design. The
  lumping together of these practices is not an accident, as they are
  related.
tags:
  - FP
  - Scala
image: /assets/media/articles/skunk.jpg
---

<p class="intro withcap" markdown='1'>
  I'm a man of strong opinions and I truly believe that when we are
  doing
  [mocking, stubbing](http://www.martinfowler.com/articles/mocksArentStubs.html),
  [dependency injection](https://en.wikipedia.org/wiki/Dependency_injection)
  and integration testing, such practices represent clear signals for
  code smell, meaning code that sucks as a symptom of a bigger problem,
  one of design. The lumping together of these practices is not an
  accident, as they are related.
</p>

Let's take an example. Often in our components we've got dependencies,
other components only slightly related and on which we depend for
producing the desired effects. Things like database access, for both
reads and writes. In true Java spirit, lets build our noun:

```scala
trait DBService {
  def readItemConfig(uuid: UUID): Option[ItemConfig]
  def saveItemConfig(uuid: UUID, config: ItemConfig): Unit

  def readDatapoints(item: UUID, offset: Int, count: Int): Seq[Datapoint]
  def persistDatapoint(item: UUID, dp: Datapoint): Unit
}
```

This interface is reasonably abstract, meaning we aren't leaking too
many underlying storage details. Well, we are assuming synchronous
responses and the datapoints are read in batches instead of a nice
stream, but those are details that can be corrected and the interface
works for a text file, PostgreSQL, MongoDB or what have you. So now we
can depend on it:

```scala
class ItemActor(db: DBService) extends Actor {
  def receive = {
    case Init(uuid) =>
      for (cfg <- db.readItemConfig(uuid))
        context.become(active(cfg))
  }

  def active(cfg: ItemConfig): Receive = ???
}
```

Of course, if you've got masochistic tendencies, you might prefer
[the Cake pattern](https://github.com/alexandru/scala-best-practices/blob/master/sections/3-architecture.md#31-should-not-use-the-cake-pattern),
being the same thing, only much worse, because now you've got garbage
enhanced by global state and polymorphic superpowers, sucking as much
as Guice, only at compile-time:

```scala
trait ItemActorComponentImpl {
  self: DBServiceComponent =>

  class ItemActor extends Actor {
    def receive = {
      case Init(uuid) =>
        for (cfg <- dbService.readItemConfig(uuid))
          context.become(active(cfg))
    }

    def active(cfg: ItemConfig): Receive = ???
  }
}
```

I personally can't stand that, being the epitome of good intentions
gone wrong. But back to our point, if we want to test this actor, we'd
have to mock or stub our `DBService`, right?

Well, here's *the problem* mate: until now this actor only depends on
`DBService.readItemConfig`, yet we have to mock or stub the entire
interface of `DBService`. And having to mock or stub things unrelated
to testing this functionality should indicate that this code is too
*tightly coupled*. Right there your nose should reject the air
emanated from this code and it's common sense that often save us,
even though we often can't place our finger on the problem.

OK, OK, lets fix this somewhat using a common Java "best practice", by
splitting this interface into smaller modules. Our `DBService`
interface does too much, or so the popular wisdom would say.

```scala
trait ItemConfigsRepository {
  def read(uuid: UUID): Option[ItemConfig]
  def save(uuid: UUID, config: ItemConfig): Unit
}

trait DatapointsRepository {
  def readList(item: UUID, offset: Int, count: Int): Seq[Datapoint]
  def persist(item: UUID, dp: Datapoint): Unit
}
```

That feels better, right? By splitting functionality in smaller units
of finer-grained stuff, this should ameliorate our dependency
woes. Wrong! Now we've got two problems:

```scala
class ItemActor
  (icsRepo: ItemConfigsRepository, dpsRepo: DatapointsRepository)
  extends Actor {
  
  def receive = {
    case Init(uuid) =>
      for (cfg <- icsRepo.read(uuid))
        context.become(active(cfg, State.empty))
  }

  def active(cfg: ItemConfig, state: State): Receive = {
    case Signal(value) =>
      val newState = state.evolve(value)
      dpsRepo.persist(cfg.uuid, state.powerOutput)
      context.become(active(cfg, newState))
  }
}
```

BAM, more dependencies, more garbage, more mocks and stubs. Does this
ring a bell? Cake makes it worse btw. But anyway, now we can see that
our solution with `ItemConfigsRepository` doesn't work, as `readItem`
is often not used in the same place as `writeItem`, so our action had
an opposite effect of what we wanted.

How can this be, our interfaces are abstract and split in small units
according to best practices, yet what are we doing wrong?

Maybe this isn't so bad, right? I mean surely we can stub the
dependencies that aren't actually used and be done with it, everybody
else is doing it. And look, we've got dependency injection to deal
with all the constructor annoyances. Oh, except when you've got more
to add, things unrelated to the actual business logic, like persisting
more stuff:

```scala
  def active(cfg: ItemConfig, state: State): Receive = {
    case Signal(value) =>
      val newState = state.evolve(value)
      dpsRepo.persist(cfg.uuid, state.powerOutput)
      dpsRepo.persist(cfg.uuid, state.basepoint) // <-- here
      context.become(active(cfg, newState))
  }
```

So now with mocks, your tests are broken even though the business
logic hasn't changed, whereas with stubs that ignore those calls, both
of those calls might as well not exist. Both outcomes are wrong. 

Here we are having a side-effect, which is persisting values in the
database in response to that `State` being evolved when receiving
`Signal` values.

Yet we have a non-obvious *implementation leak*. From the point of
view of this actor, those persistence calls are just signals that a
state change happened and that we could do (but not necessarily)
something *in response*, but the actor should not care at all that
what we are doing is actual persistence in a database repository, or
sending values over an akka remoting connection, or over web-socket,
or dumping some logs on disk. These concerns should be totally outside
of our component and all we should be testing is if our component is
signaling stuff to the outside world. We tried fixing `DBService` but
in fact our Actor is broken.

Meet the famous and underused
[Observer pattern](https://en.wikipedia.org/wiki/Observer_pattern). And
its sibling on steroids [ReactiveX](http://reactivex.io/). Here's the
sample above using [Monifu](https://github.com/monifu/monifu):

```scala
class ItemActor(output: Channel[Signal])
  extends Actor {

  def receive = {
    case cfg: ItemConfig =>
      context.become(active(cfg, State.empty))
  }

  def active(cfg: ItemConfig, state: State): Receive = {
    case Signal(value) =>
      val newState = state.evolve(value)
      output.pushNext(newState)
      context.become(active(cfg, newState))
      
    case cfg: ItemConfig =>
      context.become(active(cfg, state))
  }
}

// ...
// in a galaxy far, far away

dbConfigSource.subscribe { config =>
  actor ! itemConfig
}

output.subscribe { signal =>
  dbService.persist(signal.uuid, signal.powerOutput)
  dbService.persist(signal.uuid, signal.basepoint)
}
```

OK, I know that Akka actors are cool and all, this is not about you
using or not Akka actors. So lets implement the Observer pattern on
top of Akka actors to see how that looks like:

```scala
class MyActor extends Actor {
  def receive = active(State.empty, Set.empty)

  def active(state: State, subscribers: Set[ActorRef]): Receive = {
    case "register" =>
      val ref = sender()
      if (!subscribers.contains(ref)) {
        context.watch(ref)
        context.become(active(state, subscribers + ref))
      }

    case Terminated(ref) =>
      context.unwatch(ref)
      context.become(active(state, subscribers - sender))

    case Signal(value) =>
      val newState = state.evolve(value)      
      for (subscriber <- subscribers) {
        for (event <- newState.events)
          subscriber ! event
      }

      context.become(active(newState, subscribers))
  }
}
```

It has been my general opinion that actors should
[mutate their state with context.become](https://github.com/alexandru/scala-best-practices/blob/master/sections/5-actors.md#52-should-mutate-state-in-actors-only-with-contextbecome)
and one reason is because that enables us to separate the business
logic from the actor and leave the actor to handle just the
communication side. Should the above actor be tested? Maybe, if you've
got time, but it really isn't a priority, because it doesn't contain
business logic. Let's go deeper. The business logic, exposed by
`newState = state.evolve` would be something like this:

```scala
case class Event(value: Int)

case class State
  (value: Int, lastEvent: Int, events: Seq[Event]) {

  def evolve(newValue: Int): State = {
    if (math.abs(newValue - lastEvent) > 100)
      State(newValue, newValue, Seq(Event(newValue)))
    else
      copy(value = newValue)
  }

  def popEvents: (Seq[Event], State) = 
    (events, copy(events = Seq.empty))
}

object State {
  val empty = State(0, 0, Seq.empty)
}
```

M'kay, so this does have business logic that would be valuable for
testing. AND we are modeling the side-effects in a pure way, by saying
on each `evolve` "*here's a bunch of signals to emit Bob, I don't care
how you do it or who reads them*".

Does this code have any dependencies whatsoever? No, it's pure and can
be tested in total isolation and for things that actually matter, you
know, unit testing. This is the essence of functional programming and
(I hope) of Scala. Because whenever you're using
[Mockito](http://mockito.org/) it means that you're not doing the
above.

In other words:

- dependency injection, mocking and stubbing is meant for hiding
  garbage under the rug
- for writes, you don't have to sprinkle your side-effecting calls all
  over the place, when you can decouple those concerns by implementing
  signaling by means of the Observer pattern
- for reads you can have components that *push* those configurations
  into your component and the actual wiring is very often not worth
  testing, because ...
- testing has diminishing returns: math formulas, the whiles and the
  ifs and the decision making are very important, but the interaction
  with external components or systems? Not so much, especially because
  you end up testing other people's libraries and frameworks,
  essentially duplicating functionality and generally not worth the
  trouble
- integration testing is like meat eating - it's not that meat eating
  is bad for you per se, but rather the fact that by eating meat
  you're not eating enough vegetables. You see, we have a finite
  budget and by doing integration testing it means that you're not
  doing something else. And people that do integration testing in
  their code are often the people that gave up on refactoring and unit
  testing their convoluted and tightly coupled code
- mocks and stubs are a definite sign that your components are too
  tightly coupled and that your business logic is mixed with
  side-effects of short term value involving third-party components
  and systems. It's usually a sign that you need to clean up your mess
- testing Akka actors is horrible because of their asynchronous nature
  and that's a good thing, because it makes you realize that actors
  are about communication and that you don't care about communication
  in your unit tests, so you'd better not have business logic in them ;-)
- your DBService can always fail for reasons outside of your control,
  so instead of testing DBService, your effort is much better spent in
  making your own component more resilient to failure and in improving
  logging, because when it comes to external systems, testing the
  happy path is worthless, being the edge cases that get you
- personally I dislike very much tests that pretend to test things,
  but have zero value - writing unit tests is just a means to an end,
  take time and have to be maintained, so don't burden your team with
  fragile tests that don't test anything of value, because that's not
  why you've been hired

Pain is good. Mocks, stubs, DI, integration tests are about avoiding
pain by fixing the symptoms rather than the disease. Don't treat the
symptoms, treat the disease.

Also see the list of
[best practices](https://github.com/alexandru/scala-best-practices) I
initiated that's free of Javaisms.

Cheers,
