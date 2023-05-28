---
title: "The case against Effect Systems (e.g., the IO data type)"
image: /assets/media/articles/2022-effect-systems.png
tags:
  - FP
  - FSharp
  - Java
  - Kotlin
  - Scala
date: 2022-10-13 12:00:00 +03:00
last_modified_at: 2023-05-28 09:39:22 +03:00
generate_toc: true
description: >
  As Scala developers and fans of the functional programming promoted by Haskell, how do we justify the use of `IO` to newbies coming from Java? It's been a fun ride, but the truth is that Java 19 is changing everything.
---

<p class="intro" markdown=1>
As Scala developers and fans of the functional programming promoted by Haskell, how do we justify the use of `IO` to newbies coming from Java? It's been a fun ride, but the truth is that [Java 19](./2022-09-21-java-19.md) is changing everything.
</p>

`IO` has been great, with libraries like [Cats-Effect](https://typelevel.org/cats-effect/) and [fs2](https://fs2.io/) taking functional programming on the JVM to new levels, and using these libraries has been a super-power. But here I'm going to argue that the problem hasn't been imperative programming, and this IO-driven style of static FP has an identity crisis on its hands, due to the introduction of Virtual Threads ([JEP 425](https://openjdk.org/jeps/425)), and the adoption of "[structured concurrency](https://en.wikipedia.org/wiki/Structured_concurrency)" concepts ([JEP 428](https://openjdk.org/jeps/428)), first popularized in [Kotlin](https://kotlinlang.org/docs/coroutines-overview.html).

## How IO shines

When you have the time, you should watch Daniel Spiewak's presentation:

{% include youtube.html id="qgfCmQ-2tW0" caption="The Case For Effect Systems — Daniel Spiewak" %}

I loved it, and I've long been a proponent of `IO`, having exactly these arguments. And yet ...

## A history of asynchrony

I once wrote an article on [asynchronous programming](./2017-01-30-asynchronous-programming-scala.md), in which I explained the progression from callbacks to monads. Here's the TL;DR ...

If we are to describe asynchronous computations with a type, it would go something like this:

```scala
type Callback[-A] = (A) => Unit

type Async[+A] = (Callback[A]) => Unit
```

So, an async computation is something that executes *somewhere else*, other than the current thread, so it could be on another thread, or another process, or on another machine on the network.

Now, imagine a classic sequence of synchronous function calls:

```scala
val x = foo();
val y = bar(x);
baz();
val z = qux(x, y);
return z
```

We can turn these into a callback-driven sequence, which is what would happen in JavaScript/Node.js land, before the advent of `Promise`:

```scala
def foo(): A = ???
// ...becomes...
def foo(): Async[A] = ???

//...
// Sequence becomes:
foo()(x =>
  bar(x)(y =>
    baz()(_ =>
      qux(x, y)(z => ???)
    )
  )
)
```

There are consequences for working like this:

1. callback hell, due to all the nesting;
2. the implementation is often stack-unsafe, so it can be hard and error-prone to express loops;
3. it invalidates standard language features (e.g., `try/catch/finally`);
4. it's very low level, so managing concurrency is tricky (e.g., waiting on 2 or more jobs running in parallel to finish);

In Scala, the answer has been the introduction of `Future`/`Promise`, which is a "monadic" type, implementing a `flatMap`:

```scala
// Scala code

def foo(): Future[A] = ???
//...

foo().flatMap { x =>
  bar(x).flatMap { y =>
    baz().flatMap(_ => qux(x, y))
  }
}
// ...or...
for {
  x <- foo()
  y <- bar(x)
  _ <- baz()
  r <- qux(x, y)
} yield r
```

Which kind of looks like our original, imperative, synchronous program. But, here be dragons — what happens if we invoke Future-driven functions outside that for-expression?

```scala
// Scala code
val b = baz()
for {
  x <- foo()
  y <- bar(x)
  _ <- b
  r <- qux(x, y)
} yield r
```

The non-obvious answer is *concurrent execution* happens — this is no longer a sequence of steps, and it wasn't necessarily what we wanted, leading to bugs, as the logic may access shared mutable state that may be broken by concurrent access. This is invalidating our common sense, because when we see `val b = baz()` in code, we do not expect concurrent execution, as it's not how our brains have been trained in these imperative programming languages. This here invalidates our mental model for how things behave.

Note that we were careful waiting on the result of `baz()`. What happens if we forget about it?

```scala
// Scala code
val b = baz()
for {
  x <- foo()
  y <- bar(x)
  r <- qux(x, y)
} yield r
```

Well, this is triggering a "fire and forget" job, and if it wasn't intended, we may now have a leak 🙀

## Imperative programming, the devil we know

"Imperative programming" is a paradigm that focuses on describing a program *step by step*, via a sequence of instructions that modify state. And I'm going to make this statement:

> **Imperative programming is extraordinarily intuitive!**

In imperative programming `;` is a separator between instructions, or statements. Imperative programming tends to be statement-oriented. But `;` simply denotes *sequencing* of steps. We can think of it as being an operator:

```
A ; B ; C
```

The above simply means statement `A` gets executed before statement `B`, which gets executed before statement `C`.

We can follow sequential steps towards achieving something. For example a vast majority of humans can cook, including many children. We may be bad cooks, we may only know simple recipes, given access to a stove we may hurt ourselves, but give people the raw ingredients and the cookware, and they won't starve. Children understand cooking too, being a sequence of steps, not rocket science.

My CS teacher from high school introduced us to algorithms with a recipe for pancakes. I don't remember the specifics, and it's been years since I cooked pancakes, so my memory is hazy, but I imagine the recipe went something like this:

```scala
// As an introductory lesson, he was completely ignoring resource safety, ofc:
val fryingPan = takeFryingPan(); // 1
val batter = mix(eggs, milk, flour, sugar, bakingPowder, salt); // 2
fryingPan.pour(oil); // 3
fryingPan.preHeat(2.minutes); // 4
fryingPan.pour(batter); // 5

while (!fryingPan.check(isContentsBrown)) { // 6
 sleep(30.seconds); // 7
 fryingPan.scoop(); // 8
}

fryingPan.pull(); // 9
```

Our `IO`-driven programming is still a sequence of steps. We may try to describe pure data structures that get interpreted later, but that seldom happens. In our FP programs, what actually happens in practice is still imperative in nature:

```scala
// Scala code
for {
  fryingPan <- takeFryingPan()
  batter <- mix(eggs, milk, flour, sugar, bakingPowder, salt)
  _ <- fryingPan.pour(oil)
  _ <- fryingPan.preHeat(2.minutes)
  _ <- fryingPan.pour(batter)
  _ <- {
    def loop(): IO[Unit] =
      fryingPan.check(isBrown).flatMap {
        case true =>
          IO.unit
        case false =>
          IO.sleep(30.seconds).flatMap(_ => loop())
      }
    loop()
  }
  r <- fryingPan.pull()
} yield r
```

In Haskell, and in the Scala FP community, the semicolon (`;`) gets replaced with `flatMap` (AKA `bind`, `>>=`, `SelectMany`, etc.).

```scala
A ; B ; C;

// becomes...

A.flatMap(_ => B).flatMap(_ => C)
```

This is made digestible via syntactic sugar. In Haskell that's the [do-notation](https://en.wikibooks.org/wiki/Haskell/do_notation), in Scala we have the [for comprehensions](https://docs.scala-lang.org/tour/for-comprehensions.html), and in F# we have [computation expressions](https://learn.microsoft.com/en-us/dotnet/fsharp/language-reference/computation-expressions).

So our Scala programs can look like this:

```scala
// Scala code
for {
  x <- foo()
  y <- bar(x)
  _ <- baz()
  z <- qux(x, y)
} yield z
```

This is similar to what we did with `Future`. In Scala this syntactic sugar is more generic, driven by monadic types, because in languages such as C# or TypeScript/JavaScript, we have special `async`/`await` syntax that only works with `Future`/`Promise`/`Task` data types and that looks like this:

```typescript
// JavaScript code
async function doStuff() {
  const x = await foo()
  const y = await bar(x)
  await baz() // better not forget the `await` 😉
  const z = await qux(x, y)
  return z
}
```

Call-sites of functions returning `IO`, however, are [referentially transparent](https://en.wikipedia.org/wiki/Referential_transparency). And it's important to contrast with `Future/Promise`. Take for example this program:

```scala
// Scala code
for {
  x <- fireRocketsToMars()
  y <- fireRocketsToMars()
} yield x + y

// ... versus ...

val r = fireRocketsToMars()
for {
  x <- r
  y <- r
} yield x + y

// ... versus ...

val rx = fireRocketsToMars()
val ry = fireRocketsToMars()
for {
  x <- rx
  y <- ry
} yield x + y
```

What's the difference of behavior between `IO` and `Future` in this case?

```scala
// Scala code

def fireRocketsToMars(): IO[Int]
// ... versus ...
def fireRocketsToMars(): Future[Int]
```

Well, with `IO` the behavior of the program is the same, in all 3 cases, whereas with `Future` the behavior changes. With `Future` we can talk of 3 different programs with wildly different behavior. And that's not good, as it can be counter-intuitive, being a source of bugs.  `IO` in this case behaves as it should, although in the context of Scala, `IO` isn't without fault either.

```scala
// Scala code

// No concurrent execution here, but we never use this value,
// so this is a hard to trace no-op:
val bazJob = baz()
for {
  x <- foo()
  y <- bar(x)
  z <- qux(x, y)
} yield z
```

Speaking of, I am asking questions on this difference of behavior in interviews. Surprisingly, many people get this wrong, in spite of having experience with real-world `IO` usage. And that's not their fault. The fault lies with the Scala language, because:

1. `Future` is a broken abstraction, completely beyond redemption, not much better than the callback hell it improves on, and the `async`/`await` syntactic sugar is only an ineffective band-aid — `async` doesn't help, as the default evaluation model should never be concurrent execution, you shouldn't need to mention an explicit`await` to force sequencing;
2. Scala, here, suffers from a severe case of [TIMTOWTDI](https://en.wikipedia.org/wiki/There's_more_than_one_way_to_do_it), because it's a strict language, and has multiple ways of expressing the sequencing of instructions, and it's no wonder that beginners are getting confused;

More on that later, but first a rant on math 😎

### Math is not intuitive

Math is abstraction, and it takes maturity to learn math abstraction. Some people never do. My high-school teacher used to say that there are two kinds of students, those that understand the formal definitions of limits (with the epsilon notation), and those that don't. I always thought that's just a language problem, use better communication and more people will understand, but it's without doubt that children need to develop the necessary cognitive abilities before understanding abstraction.

This is important to realize, because, while `IO`-driven programs are very much imperative in nature, laziness brings us closer to math. It's why languages like Haskell may never be in top 5, or why Scala can have a lot of accidental complexity. In [Curse of the Excluded Middle](https://queue.acm.org/detail.cfm?id=2611829), Erik Meijer argues just that ... in imperative, strictly-evaluated languages, lazy behavior is surprising, and that's bad.

I'd argue that laziness can be surprising in general, even if you're working in a non-strict language, such as Haskell. Haskell's non-strict evaluation keeps people honest. You can always call `unsafePerformIO` to trigger side effects that aren't tracked by the type system, but it's tricky getting the runtime to actually evaluate it, esp if you don't need the returned result. This means that shortcuts meant for debugging are hard (e.g., logging), and this can surprise people. And no sufficiently smart compiler or runtime has been invented yet to solve efficiency issues, which are a problem, because performance is hard to reason about when thunks get lazily evaluated, even in terms of big-O complexity. Data structures, at least, are meant to be already evaluated and inspectable. When that doesn't happen (e.g., streams), that's "codata", it takes (runtime) effort to inspect such values, and Haskell seriously blurs the lines between them.

<p class="info-bubble" markdown="1">
For Haskell developers out there that disagree, I have a question — in your programs, are you using `String`, or are you using `Text`?
</p>

There are many things I like about doing FP in Scala, and having strict evaluation as the default is one of them.

## Future is bad because asynchrony is bad

When I say that `Future` is broken, the reason is that its usage is prone to accidents. `Future` is an honest representation of asynchronous computations, and that's not the fault of imperative programming.

To wit, we started from this:

```scala
// Scala code

def fireRocketsToMars(): IO[Int]
// ... versus ...
def fireRocketsToMars(): Future[Int]
```

But there is a third option that we did not take into account, which is blocking I/O:

```scala
def fireRocketsToMars(): Int
```

With blocking I/O expressed like this, we have no need for `flatMap` or for special sequencing syntax, as it's pretty damn clear what's going on — at least in terms of sequencing of steps. It's not all rosy, my problem being that the signature is lying, as it doesn't make it clear that there are dangerous side effects going on (but in Scala [this could be fixed](./2022-05-23-tracking-effects-in-scala.md)).

```scala
val x = fireRocketsToMars();
val y = fireRocketsToMars();
x + y
```

It's important to realize the virtues of doing this:

1. if everything becomes synchronous/blocking by default, there are no accidents related to accidental concurrent execution;
2. the distinction between data and codata (i.e., data structures versus computations) becomes clear as day;
3. standard language constructs still work (e.g., for/while loops, `try-catch-finally`, `try-with-resources` or Java's checked exceptions);

Here's the other sample, again:

```scala
val x = foo();
val y = bar(x);
baz();
val z = qux(x, y);
return z
```

I'd argue that there is no meaningful difference between this, and the equivalent IO-driven program, at least in terms of accidents that can happen. If this were `Future`-driven, a lot of things could go wrong because all of those invocations could be concurrent, by accident. But we are not using `Future` here.

There can be no accidents here, because once the execution returns from a function invocation, that function is done. And having this mental model is awesome.

## Java: what's old is new again

Blocking I/O has always been the norm in Java land. Java was built for using threads, and for blocking those threads. Java's memory model, the ease of working with threads, was one of its main innovations.

This is why Java's standard library is filled with concurrency primitives that block, such as `BlockingQueue`, `Semaphore`, `ReadWriteLock` or `ReentrantLock`, with no async equivalents. It's why Java has a [Future](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/concurrent/Future.html) interface whose only means of getting its result is a blocking `.get()` call.

The newer [CompletableFuture](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/concurrent/CompletableFuture.html) happened in Java 8. Java 8 also introduced lambda expressions, so you can feel that was about the time asynchronous programming APIs took off, as a sort of detour from the official way of doing things.

And this is because Java does "[1:1 kernel-level threading](https://en.wikipedia.org/wiki/Thread_(computing)#Threading_models)", meaning that all Java threads are OS/platform threads, and platform threads are super expensive. This is because:

1. each thread has its own call-stack, thus consuming memory;
2. the kernel does "preemptive multithreading", so it does its best to execute many threads on few CPU cores — to do this, the kernel assigns time slots, pausing running threads, resuming previously paused threads, in a process called "context switching" — during which the memory used by a thread needs to be reloaded in a CPU's cache hierarchy, which consumes a lot of CPU;
3. due to consumption of both memory and CPU, there's a low limit on how many threads you can use;

The answer in Java land has been to work with thread-pools, to reuse available threads as much as possible, and to limit the maximum number of threads that can be started. Thread-pools are problematic as well, because:

1. `ThreadLocal` values can now leak, and thread interruption is very unsafe if you don't own the thread;
2. Complicated libraries tend to start their own thread-pool, and you can assess the maturity of Java projects by the number of thread-pools active at the same time;
3. Blocking I/O makes limiting threads hard, because you can end up with thread-starvation, a type of deadlock, a situation in which threads are unable to make progress due to hard limits on the thread-pool;

And managing threads and thread-pools being low level, the community evolved towards using "reactive"/fluent APIs, such as [RxJava](https://github.com/ReactiveX/RxJava), [Project Reactor](https://projectreactor.io/), [Akka](https://akka.io/), and others. Which are essentially libraries meant to recreate "M:N threading" on top of the JVM, i.e., multiplexing many jobs on few OS/platform threads.

Java 19 introduces "virtual threads", bringing M:N threading support at the runtime level, which makes threads, and blocking I/O cheap. It's not perfect, as the JVM can still block OS threads, generating "pinned" events in "flight recorder", which I'm sure will be the new bread and butter of profilers everywhere. But everything in the language and the standard library starts making sense again. All those APIs built for blocking suddenly become much cheaper to use, effectively obsoleting the `Future` data types.

## Structured concurrency

Thus far we've seen that sequential / synchronous execution is intuitive and should probably be the default, in order to prevent concurrency accidents (in our general purpose programming languages, not talking of domain-specific ones). But what if we need concurrency?

"Structured concurrency", as a concept, is similar to that of [structured programming](https://en.wikipedia.org/wiki/Structured_programming). Back in the day, when GOTO-driven languages were still used, introductory CS lessons included an incursion into structured programming and why it is needed.

<figure>
  <img src="{% link assets/media/articles/2022-structured-programming.png %}" alt="" class="transparency-fix" />
  <figcaption>
    Old-school structured programming diagram, showing Euclid's algorithm for the "greatest common divisor".
  </figcaption>
</figure>

The problem with GOTO statements is that they create a fork in the road, the program's flow becoming very hard to follow, leading to unmaintainable code. Edsger Dijkstra called GOTO statements harmful, because it complicates program analysis, verifying the correctness of algorithms becoming difficult, particularly the correctness of loops.

In the context of concurrency, this should sound very familiar. With classical Java, concurrent execution would look like this:

```java
// Java code
final var mixJob =
  ec.submit(() ->
    mix(eggs, milk, flour, sugar, bakingPowder, salt)
  );

final var prepareFryingPanJob =
  ec.submit(() -> {
    final var fryingPan = takeFryingPan();
    fryingPan.pour(oil);
    fryingPan.preHeat(Duration.ofMinutes(2));
    return fryingPan;
  });

final var fryingPan = prepareFryingPanJob.get();
final var batter = mixJob.get();
//...
```

We now have concurrent execution, making more efficient use of our resources. But therein lie problems:

1. if `prepareFryingPanJob.get()` throws an exception, the execution of `mixJob` won't get cancelled, thus creating a leak;
2. if the current thread gets interrupted, the interruption signal doesn't propagate to the started concurrent tasks;
3. if `prepareFryingPanJob` takes a long time to execute, but `mixJob` fails immediately, we won't see that failure until `prepareFryingPanJob` finishes;

Kotlin's coroutines did not introduce the notion of "structured concurrency", but I think it popularized it. The basic idea is this:

1. Concurrent jobs should be cancellable;
2. Concurrent jobs get started in a "scope", and that scope can't finish until all started concurrent jobs finish or get cancelled;
3. On error, all running concurrent jobs get cancelled;

This is similar to the idea behind C++'s [RAII](https://en.wikipedia.org/wiki/Resource_acquisition_is_initialization).

```kotlin
// Kotlin code
coroutineScope {
  val mixJob = async {
    mix(eggs, milk, flour, sugar, bakingPowder, salt)
  }
  val prepareFryingPanJob = async {
    val fryingPan = takeFryingPan()
    fryingPan.pour(oil)
    fryingPan.preHeat(2.minutes)
    fryingPan
  }

  val fryingPan = prepareFryingPanJob.await()
  val mix = mixJob.await()
  //...
}
```

In Kotlin, if the code of such a `coroutineScope` throws an error, all its concurrent jobs gets cancelled. The scope also awaits all concurrent jobs to finish, before it can finish, so there can be no accidental "fire and forget" jobs. And if any of the concurrent jobs throws an exception, then the other concurrent job gets cancelled.

Java 19 also introduced very experimental extensions for doing the same, in [JEP 428](https://openjdk.org/jeps/428):

```java
// Java code
try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
  final var mixJob =
    scope.submit(() ->
      mix(eggs, milk, flour, sugar, bakingPowder, salt)
    );

  final var prepareFryingPanJob =
    scope.submit(() -> {
      final var fryingPan = takeFryingPan();
      fryingPan.pour(oil);
      fryingPan.preHeat(Duration.ofMinutes(2));
      return fryingPan;
    });

  scope.join();
  scope.throwIfFailed();

  final var fryingPan = prepareFryingPanJob.resultNow();
  final var batter = mixJob.resultNow();
  //...
}
```

This API is currently "incubating" and looks clumsy, but the concept is the same, and its efficient use is made possible due to blocking I/O becoming cheap.

What would we do in Scala with Cats-Effect's `IO`?

```scala
// Scala code

// No-op
val mixJob =
  mix(eggs, milk, flour, sugar, bakingPowder, salt)

// No-op
val prepareFryingPanJob =
  for {
    fryingPan <- takeFryingPan
    _ <- fryingPan.pour(oil)
    _ <- fryingPan.preHeat(2.minutes)
  } yield fryingPan

(mixJob, prepareFryingPanJob).parMapN { (mx, fryingPan) =>
  //...
}
```

With Cats-Effect `IO` concurrency/parallel execution must be made explicit. Here we are using the `parMapN` operator from the [Parallel](https://typelevel.org/cats/typeclasses/parallel.html) type class. The creation of those tasks is lazy. Nothing gets executed then and there. This makes it a little clumsy, so you'd better turn your linter to warn against unused values.

But this raises important questions — in this context, what does `IO` buy us? I'm finding this question increasingly difficult to answer. I used to say that `IO` is very explicit about how things get evaluated (e.g., in parallel or sequential), so there can be no accidents, but `IO` isn't the only way for achieving that. And due to its laziness, it introduces some accidental complexity of its own.

`IO` is very composable. You can, for example, combine it with `Either`, via `EitherT`. Or you can bake `EitherT` in, like what ZIO did.

But with blocking I/O, in Java, you can make use of checked exceptions again. And for Kotlin, checkout [Arrow](https://arrow-kt.io/), see their article on [why `suspend () -> A` instead of `IO<A>`](https://arrow-kt.io/docs/effects/io/). If typed exceptions is your cup of team, here's how that sample would look like:

```kotlin
// Kotlin code
suspend fun makePancakes(): Either<SomeError, Pancakes> =
  either {
    val fryingPan = takeFryingPan().bind()
    val batter = mix(eggs, milk, flour, sugar, bakingPowder, salt).bind()
    fryingPan.pour(oil).bind()
    fryingPan.preHeat(2.minutes).bind()
    fryingPan.pour(batter).bind()
    //...
  }
```

For another more real use-case, here's a snippet from my own [personal project](https://github.com/alexandru/github-webhook-listener/blob/v2.1.2/src/main/kotlin/org/alexn/hook/Server.kt#L85):

```kotlin
// Kotlin code
either {
    val project = Either
        .fromNullable(config.projects[projectKey])
        .mapLeft { RequestError.NotFound("Project `$projectKey` does not exist") }
        .bind()
    val signature = call.request.header("X-Hub-Signature-256")
        ?: call.request.header("X-Hub-Signature")

    val body = call.receiveText()
    EventPayload
        .authenticateRequest(body, project.secret, signature)
        .bind()

    val parsed =
        EventPayload.parse(call.request.contentType(), body).bind()
    val result = if (parsed.shouldProcess(project)) {
        commandTriggerService.triggerCommand(projectKey)
    } else {
        RequestError.Skipped("Nothing to do for project `$projectKey`").left()
    }
    result.bind()
}
```

This isn't different from what was tried in Scala via attempts like [Monadless](https://github.com/monadless/monadless), a use-case that Kotlin's coroutines makes comfortable. In my opinion, if Scala continues to embrace `flatMap`, then it should expand the syntax of "for comprehensions" to be more ergonomic. F#'s "computation expressions" look more like imperative programming, going beyond `flatMap` and blending better within F#'s syntax, and that's good.

## In closing

Functions working with monadic types, such as `IO`, are referentially transparent, following the substitution model of evaluation, and facilitate algebraic reasoning. But showing what that is good for can be a challenge, especially in light of the TIMTOWTDI.

`IO` is awesome, but its existence in strictly-evaluated languages is increasingly questionable. Even in Scala land, many developers don't believe that monads are the only or the best way to deal with effects, even if (I bet) the community's opinion is increasingly biased, due to the natural churn that happens (people that like monads may stick around more than those that don't). I'm happy that proposals for alternatives still happen (even if they may go nowhere), checkout: [PRE-SIP: Suspended functions and continuations](https://contributors.scala-lang.org/t/pre-sip-suspended-functions-and-continuations/5801).

`IO` (and monads in general) on the JVM can have a bright future, but need better stories to tell.
