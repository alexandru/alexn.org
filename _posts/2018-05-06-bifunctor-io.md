---
title: "On Bifunctor IO and Java's Checked Exceptions"
description:
  Bifunctor IO is a hot topic in the Scala community. Herein I'm expressing my dislike for it, as it shares the problems of Java's Checked Exceptions.
tags:
  - Best Of
  - FP
  - Haskell
  - OOP
  - Scala
  - Typelevel
image: /assets/media/articles/bio.png
generate_toc: true
---

<p class="intro" markdown="1">
  The Bifunctor `IO` data type is a hot topic in the Scala community. In this article however I'm expressing my dislike for it because it shares the same problems as Java's Checked Exceptions.
</p>

## What is IO?

Normally the `IO` data type is expressed as:

```scala
sealed trait IO[+A] {
  ???
}
```

What this means is that `IO` is like a thunk, like a function with
zero parameters, that upon execution will finally produce an `A`
value, if successful. The type also signals possible side effects that
might happen upon execution, but since it behaves like a function
(that hasn't been executed yet), when you are given an `IO` value you
can consider it as being pure (and the function producing it has
*referential transparency*). This means that `IO` can be used to
describe pure computations.

Modern `IO` implementations for JVM are also capable of describing
asynchronous processes, therefore you can also think of `IO` as being:

```scala
opaque type IO[+A] = () => Future[A]
```

If we had [opaque types](https://docs.scala-lang.org/sips/opaque-types.html)
this would work well ;-)

Available implementations are:

- [cats.effect.IO](https://typelevel.org/cats-effect/datatypes/io.html)
- [monix.eval.Task](https://monix.io/docs/3x/eval/task.html)
- [scalaz.concurrent.Task](https://github.com/scalaz/scalaz/blob/series/7.3.x/concurrent/src/main/scala/scalaz/concurrent/Task.scala)
  (in the 7.2.x and 7.3.x series)

Some cool presentations on this subject:

- [The Making of an IO](https://www.youtube.com/watch?v=g_jP47HFpWA) (ScalaIO FR, 2017)
- [What Referential Transparency can do for you](https://www.youtube.com/watch?v=X-cEGEJMx_4) (ScalaIO FR, 2017)
- [Monix Task: Lazy, Async and Awesome](https://monix.io/presentations/2016-task-flatmap-oslo.html) (flatMap(Oslo), 2016)

`IO[+A]` implements `MonadError[IO, Throwable]`. And if we're talking
of Cats-Effect or Monix, it also implements
[Sync](https://typelevel.org/cats-effect/typeclasses/sync.html) among
others.

This means that `IO[+A]` can terminate with error, it can terminate in
a `Throwable`, actually reflecting the capabilities of the Java
Runtime. This means that this code is legit:

```scala
import cats.effect.IO
import scala.util.Random

def genRandomPosInt(max: Int): IO[Int] =
  IO(Math.floorMod(Random.nextInt(), max))
```

The astute reader might notice that this isn't a total function, as it
could throw an `ArithmeticException`. An easy mistake to make.

## What's the Bifunctor IO?

I'm going to call this data type `BIO`, to differentiate it from `IO` above:

```scala
sealed trait BIO[E, A] {
  ???
}
```

Such a type parameterizes the error type in `E`. This is more or less like usage of
`Either` to express the error, but as you shall see below, they aren't exactly
equivalent:

```scala
opaque type BIO[E, A] = IO[Either[E, A]]
```

Or in case you're throwing `EitherT` in the mix to make that less awkward:

```scala
import cats.data.EitherT

type BIO[E, A] = EitherT[IO, E, A]
```

Exposing the error type would allow one to be very explicit at compile time
about the error:

```scala
def openFile(file: File): BIO[FileNotFoundException, BufferedReader] =
  // Made up API
  BIO.delayE {
    try Right(new BufferedReader(new FileReader(file)))
    catch { case e: FileNotFoundException => Left(e) }
  }

def genRandomInt: BIO[Nothing, Int] =
  BIO.delayE(Right(Random.nextInt()))
```

You can see in the first function that we are very explicit about
`FileNotFoundException` being an error that could happen, instructing readers
that they should probably do error recovery.

And in the second function we could use `Nothing` as the error type to
signal that this operation can in fact produce no error (not really, but
let's go with it 😉).

Available implementations:

- [scalaz/ioeffect](https://github.com/scalaz/ioeffect), the Scalaz 8 `IO`,
  available as a backport for Scalaz 7, by John A. De Goes and other Scalaz contributors
- [cats-bio](https://github.com/LukaJCB/cats-bio) by Luka Jacobowitz, inspired
  by Scalaz 8's `IO`, he took Cats-Effect's `IO` and changed `Throwable` to `E`
  as a proof of concept
- Worthy to mention is also [Unexceptional IO](https://github.com/LukaJCB/cats-uio),
  Luka's precursor to his BIO implementation, inspired by Haskell's
  [UIO](https://hackage.haskell.org/package/unexceptionalio) I think

Some articles on this subject:

- [No More Transformers: High-Performance Effects in Scalaz 8](http://degoes.net/articles/effects-without-transformers),
  by John A. De Goes
- [Rethinking MonadError](https://typelevel.org/blog/2018/04/13/rethinking-monaderror.html),
  by Luka Jacobowitz

The premise of these articles is that:

1. our type system should stop us from being able to write nonsensical error handling
   code and give us a way to show anyone reading the code that we’ve already handled errors
2. the performance of `EitherT` is bad and usage more awkward

Naturally, I disagree with the first assertion and I don't think the second assertion is a problem 😀

## The Problems of Java's Checked Exceptions

While I think that the Bifunctor IO is a cool implementation, that's pretty useful
for certain people, or certain use cases, I believe that ultimately it's not a good
default implementation, as it shares the same problems as Java's Checked Exceptions.
Or in other words, it's ignoring decades of experience with exceptions, since
their introduction in LISP and then in C++, Java, C# and other mainstream languages.

The web is littered with articles on why checked exceptions were a bad idea and many
of those reasons are also very relevant for an `IO[E, A]`. Here's just two such
interesting articles:

- [Checked exceptions I love you, but you have to go](https://testing.googleblog.com/2009/09/checked-exceptions-i-love-you-but-you.html)
- [The Trouble with Checked Exceptions](https://www.artima.com/intv/handcuffs.html), an interview with Anders Hejlsberg

But let me explain in more detail ...

### 1. Composition Destroys Specific Error Types

Let's go with a more serious example:

```scala
import java.io._

def openFile(file: File): BIO[FileNotFoundException, BufferedReader] =
  // Made up API
  BIO.delayE {
    try Right(new BufferedReader(new FileReader(file)))
    catch { case e: FileNotFoundException => Left(e) }
  }

def readLine(in: BufferedReader): BIO[IOException, String] =
  BIO.delayE {
    try Right(in.readLine())
    catch { case e: IOException => Left(e) }
    finally in.close()
  }

def convertToNumber(nr: String): BIO[NumberFormatException, Long] =
  BIO.delayE {
    try Right(nr.toLong)
    catch { case e: NumberFormatException => Left(e) }
  }
```

What would be the type of a composition of multiple `IO` values like this?

```scala
for {
  buffer <- openFile(file)
  line <- readLine(buffer)
  num <- convertToNumber(line)
} yield num
```

That's right, you'll have a `Throwable` on your hands. And this is
assuming that we've got a `flatMap` that widens the result to the most
specific super-type, otherwise you'll have to take care of conversions
manually, at each step. Also note that our usage of `Throwable` is
irrelevant for the problem at hand. You could come up with your own
error type, but `Throwable` is actually more practical, because we can
simply cast it.

So assuming a `flatMap` that doesn't automatically widen the error
type of the result, what you'll have to deal with is actually worse:

```scala
for {
  buffer <- openFile(file).leftWiden[Throwable]
  line <- readLine(buffer).leftWiden[Throwable]
  num <- convertToNumber(line).leftWiden[Throwable]
} yield num
```

Not sure how people feel about this, but to me this isn't an
improvement over the status quo, far from it, this is just noise
polluting the code. And before you say anything in its defence, make
sure the argument doesn't also apply to Java and everything you
dislike about it 😉

### 2. You Don't Recover From Errors Often

Imagine a piece of code like this:

```scala
for {
  r1 <- op1
  r2 <- op2
  r3 <- op3
} yield r1 + r2 + r3
```

So we are executing 3 operations in sequence and each of them can fail,
we don't know which or how.

Does it matter? Most of the time, you don't care. Most of the time it is
irrelevant. Most of the time you can't even recover until later.

Due to this uncertainty about which operations trigger errors and
which don't, the premise of a Bifunctor `IO` is that we're forced to
do `attempt` (error recovery) everywhere, but that is not a correct
premise. The way exceptions work and why they were introduced in LISP
and later in C++, is that you only catch exceptions at the point were
you can actually do something about it, otherwise it's fine to live in
blissful ignorance.

Empirical evidence suggests that most checked exceptions in Java are
either ignored or re-thrown, forcing people to write catch blocks that
are meaningless and even error prone.

You can even find some studies on handling of checked exceptions in
Java projects, although I'm unsure about how good they are. For
example there's
[Analysis of Exception Handling Patterns in Java Projects](https://ieeexplore.ieee.org/document/7832935/),
which states that:

> *"Results of this study indicate that most programmers ignore checked exceptions and
> leave them unnoticed. Additionally, it is observed that classes higher in the exception
> class hierarchy are more frequently used as compared to specific exception subclasses."*

Consider that in case of a web server the recovery might be something
as simple as showing the user an HTTP 500 status. HTTP 500 statuses are
a problem, but only if they happen and when they start to show up,
you can then go back and fix what needs to be fixed.

Also remember the `FileNotFoundException` we mentioned above?
Well, in most cases there's not much you can do about it. It's not like
you've got much choice in the knowledge that the file is missing,
most of the time the important bit being that an error, any error,
happened.

To quote Anders Hejlsberg, the original designer of C#:

> *"It is funny how people think that the important thing about
> exceptions is handling them. That is not the important thing about
> exceptions. In a well-written application there's a ratio of ten to
> one, in my opinion, of try/finally to try/catch. Or in C#, `using`
> statements, which are like try/finally."*

In other words the most important part of exceptions are the finalizers,
recovery being less frequent.

### 3. The Error Type is an Encapsulation Leak

Lets say that we have this function:

```scala
def foo(param: A): BIO[FileNotFoundException, B]
```

By saying that it can end with a `FileNotFoundException`, we are instructing
all callers, at all call sites, to handle this error as part of the exposed API.

It's pretty obvious that `FileNotFoundException` can happen due to trying to
open a file on disk that is missing. It's a very specific error, isn't it,
the kind of error we're supposed to like if we're fans of `EitherT` or of the
Bifunctor `IO`.

Well, what happens if we change `foo` to make an HTTP request instead, or
maybe we turn it into something that reads a memory location. Now all of a sudden
`FileNotFoundException` is no longer a possibility.


```scala
def foo(param: A): BIO[Unit, B]
```

This then bubbles down to all call sites, effectively breaking backwards compatibility,
so all that depend on your `foo` will have to upgrade and recompile. And as the author
of `foo` you'll be faced with two choices:

1. break compatibility
2. keep lying to your users that `foo` can end with a `FileNotFoundException` and
   thus leave them with _unreachable code_ - which is something that some Java
   libraries are known to have done

NOTE: there are cases in which *you want* to break binary compatibility in
case the error type changes.  That is precisely the use case for which the
Bifunctor IO or `EitherT` are recommended.

### 4. It Pushes Complexity to the User

On utility I deeply understand the need to parameterize all things. But the question is,
what else could we parameterize and why aren't we doing it?

- we could have a type parameter that says whether the operation is blocking-IO bound,
  or CPU bound and  in this way we could avoid running an `IO` that's CPU-bound on a
  thread-pool meant for blocking I/O or vice-versa
- we could add a type parameter for the execution model — is it synchronous or asynchronous?
- we could describe the side effect with a type parameter — i.e. is it doing PostgreSQL queries,
  or ElasticSearch inserts and in this way the type becomes more transparent and you could
  come up with rules for what's safe to execute in parallel or what not
- add your own pet peeve ...

I'm fairly sure that people have attempted these. I'm fairly sure that
there might even be libraries around that are useful in certain
specific instances. But they are not mainstream.

We aren't doing it because adding type parameters to the types we are
using leads to the death of the compiler, not to mention our own
understanding of the types involved, plus usage becomes that much
harder, because by introducing type parameters, values with different
type arguments no longer compose without explicit conversion /
widening, pushing a lot of complexity to the user.

This is why `EitherT` is cool, even with all of its problems. It's cool
because it can be bolted on, when you need it, adding that complexity
only when necessary.

The Bifunctor `IO[E, A]` looks cool, but what happens downstream to
the types using it? Monix's `Iterant` for example is
`Iterant[F[_], A]`. Should it be `Iterant[F[_], E, A]`? Or maybe
`Iterant[F[Throwable, _], A]`? Or `Iterant[F[_, _], E, A]`?

If I parameterize the error in `Iterant`, how could it keep on working with
the current `IO` that doesn't have a `E` parameter? And if `Iterant` works with
`IO[Throwable, _]`, then what's the point of `IO[E, A]` anyway?

Note that having multiple type parameters is a problem in Haskell too.
Martin Odersky already expressed his dislike for type classes of multiple type
parameters, such as `MonadError` and it's pretty telling that type classes with
multiple type parameters are not part of standard Haskell.

### 5. The Bifunctor IO Doesn't Reflect the Runtime

I gave this piece of code above and I'm fairly sure that you missed the
bug in it:

```scala
def readLine(in: BufferedReader): BIO[IOException, String] =
  BIO.delayE {
    try Right(in.readLine())
    catch { case e: IOException => Left(e) }
    finally in.close()
  }
```

The bug is that `in.close()` can throw exceptions as well. Actually on top of the JVM
even pure, total functions can throw `InterruptedException` for example.

So what happens next?

Well the Bifunctor `IO` cannot represent just any `Throwable`. By making `E` generic,
it means that handling of `Throwable` is out. So at this point there are about 3 possibilities:

1. crash the process, which would be the default, naive implementation
2. your thread crashes without making a sound, logging to a stderr that gets redirected to `/dev/null`
3. use something like a custom Java
   [Thread.UncaughtExceptionHandler](https://docs.oracle.com/javase/7/docs/api/java/lang/Thread.UncaughtExceptionHandler.html),
   or Scalaz's specific "fiber" error reporter to report such errors somewhere

Also the astute reader should notice that by replacing the `MonadError` handling and recovery
by a simple reporter there's no way to do *back-pressured retries*. The nature of bugs is that
many bugs are non-deterministic. Maybe you're doing an HTTP request and you're expecting a
number in return, but it gives you an unexpected response - maybe it has a maximum limit
of concurrent connections or something.

When making requests to web services, wouldn't it be better to give them some slack?
Wouldn't it be better to do retries with [exponential backoff](https://en.wikipedia.org/wiki/Exponential_backoff)
a couple of times before crashing? Or maybe use utilities such as
[TaskCircuitBreaker](https://monix.io/docs/3x/eval/circuit-breaker.html)? Of course it is. And in
the environments I worked on, such instances are very frequent and the processes have to be really
resilient to failure and resiliency is built-in only when having the assumption that
*everything can fail for unknown reasons*.


In the grand scheme of things, the reason for why this is a huge problem is because
`IO` should reflect the runtime, because `IO` effectively replaces Java's call-stack.
But the Bifunctor `IO` no longer does.

In the words of [Daniel Spiewak](https://x.com/djspiewak), who initiated
the Cats-Effect project:

<blockquote>
  <p><em>“
    The JVM runtime is typed to a first order. Which happens to be exactly what the type
    parameter of IO reflects. I'm not talking about code in general, just IO.
    IO is the runtime, the runtime is IO.
  ”</em></p>
  <p>
    <a href="https://x.com/djspiewak/status/983807277613236230">
      Source
    </a>
  </p>
  <p><em>“
    The whole purpose of IO as an abstraction is to control the runtime.
    If you pretend that the runtime has a property which it does not, then that
    control is weakened and can be corrupted (in this case, by uncontrolled crashes).
  ”</em></p>
  <p>
    <a href="https://x.com/djspiewak/status/983808880349073408">
      Source
    </a>
  </p>
  <p><em>“
    IO needs to reflect and describe the capabilities of the runtime, for good or for bad.
    All it takes is an "innocent" throw to turn it all into a lie, and you can't prevent that.
  ”</em></p>
  <p>
    <a href="https://x.com/djspiewak/status/983805298526699520">
      Source
    </a>
  </p>
</blockquote>

I agree with that and it shows which developers worked a lot in dynamic environments,
this great divide being between those that think types can prove correctness in all cases
and those that don't.

If you're in the former camp, I think [Hillel Wayne](https://x.com/Hillelogram)
is eager to [prove you wrong](https://hillelwayne.com/post/theorem-prover-showdown/) 😉

## IO Cannot Be an Alias of the Bifunctor IO

You might be temped to say that:

```scala
type IO[A] = BIO[Throwable, A]
```

This is not true and it gave birth to, what I like to call, the great
"_No True Functor_" debate and fallacy 😜

But details about it would take another article to explain.

So it's enough to say that `cats.effect.IO` and `monix.eval.Task` has got you
covered in all cases, whereas a Bifunctor `IO` needs to pretend that developers
on top of the JVM can work only with total functions, on top of an environment
that actively proves you wrong, thus applying the "*let it crash*" philosophy
on top of a runtime that makes this really expensive to do so
(i.e. the JVM is not Erlang).

This is another great divide in mentality, although I can see the merits of
the arguments on the other side. In such cases it's relevant by what kind
of problems you got burned or not in the past I guess.

## Final Words

I am not saying that the Bifunctor `IO[E, A]` is not useful.

I'm pretty sure it will prove useful for some use-cases, the same kind of use-cases
for which `EitherT` is useful, except with a less orthogonal design. Well you gain
some performance in that process, although when you're using `EitherT` it's debatable
whether it matters for those particular use cases.

What I am saying is that:

1. let's not ignore the two decades of experience we had with Java's checked exceptions,
   preceded by another two decades of experience with exceptions in other languages
2. `EitherT` is useful because it can be bolted on when the need arises, or otherwise
   it can be totally ignored by people like myself, so let's not throw the baby with the
   bath water

I do think that `IO[E, A]` will be a great addition to the ecosystem, as an option over
the current status quo. Scala is a great environment.

That's all.
