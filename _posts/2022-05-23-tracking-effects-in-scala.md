---
title: "Tracking Side Effects in Scala"
image: /assets/media/articles/scala3-unsafe-io.png
tags: 
  - FP
  - Monix
  - Scala
description: >
  What if we'd use Scala's type system for tracking side-effects in impure code, too? In the Scala/FP community we use and love effect systems, such as Cats Effect, with its IO data type. "Suspending side-effects" in IO is great, but in Scala it's either `IO` or forgoing any kind of type-safety for side-effects, and that's bad.
---

<p class="intro withcap" markdown="1">
What if we'd use Scala's type system for tracking side-effects in impure code, too? In the Scala/FP community we use and love effect systems, such as [Cats Effect](https://typelevel.org/cats-effect/) with its `IO` data type. *"Suspending side-effects"* in `IO` is great, but in Scala it's either `IO` or forgoing any kind of type-safety for side-effects, and that's bad.
</p>

In spite of our wishes to the contrary, integration code or low-level code in Scala is inevitable. Also, there are instances in which impure/imperative code is actually clearer. I still have the feeling that Cats-Effect's `Ref` is harder to understand in practice than `AtomicReference`, for example, in spite of all benefits of referential transparency or the decoupling that happens between the declarations of expressions and their evaluation. And software-transactional memory can be worse than `Ref`, which is probably why in Scala it never took off, in spite of decent implementations available.

**For impure code**, I'd still like to notice the side effects, visually, via types, and I still want the compiler to protect me from leaks. Scala 3 makes this easier, via [Context Functions](https://docs.scala-lang.org/scala3/reference/contextual/context-functions.html).

```scala
// SCALA 3

import scala.io.StdIn
// https://dotty.epfl.ch/docs/reference/experimental/erased-defs
// import scala.language.experimental.erasedDefinitions

/*erased*/ class CanSideEffect
/*erased*/ class CanBlockThreads extends CanSideEffect

type UnsafeIO[+A] = CanSideEffect ?=> A

type UnsafeBlockingIO[+A] = CanBlockThreads ?=> A

def unsafePerformIO[A](f: UnsafeIO[A]): A =
  f(using new CanSideEffect)

def unsafePerformBlockingIO[A](f: UnsafeBlockingIO[A]): A =
  f(using new CanBlockThreads)

//-------

object Console {
  def writeLine(msg: String): UnsafeBlockingIO[Unit] =
    println(msg)
  
  def readLine: UnsafeBlockingIO[String] =
    StdIn.readLine
}

@main def main(): Unit = {
  unsafePerformBlockingIO {
    Console.writeLine("Enter your name:")
    val name = Console.readLine
    Console.writeLine(s"Hello, $name!")
  }
}
```

We might also make use of [erased definitions](https://docs.scala-lang.org/scala3/reference/experimental/erased-defs.html), to eliminate any overhead, but this is an experimental feature that's only available in nightly builds.

Note that this is possible to do in Scala 2, but less nice, although in libraries we might think of developing for the future, without leaving users of Scala 2 in the dust.

```scala
// SCALA 2

class CanSideEffect
class CanBlockThreads extends CanSideEffect

type UnsafeIO[+A] = CanSideEffect => A

type UnsafeBlockingIO[+A] = CanBlockThreads => A

def unsafePerformIO[A](f: UnsafeIO[A]): A =
  f(new CanSideEffect)

def unsafePerformBlockingIO[A](f: UnsafeBlockingIO[A]): A =
  f(new CanBlockThreads)

//-------

object Console {
  def writeLine(msg: String)(implicit permit: CanBlockThreads): Unit =
    println(msg)
  
  def readLine(implicit permit: CanBlockThreads): String =
    StdIn.readLine
}

object Main extends App {
  unsafePerformBlockingIO { implicit permit =>
    Console.writeLine("Enter your name:")
    val name = Console.readLine
    Console.writeLine(s"Hello, $name!")
  }
}
```

Scala 3 also introduced an experimental feature for dealing with *"checked exceptions"* that makes use of this mechanism, see the ["safer exceptions" PR](https://github.com/lampepfl/dotty/pull/11721)

There is precedent in Scala 2 for using implicits like this. For example, the `Await` utilities that we use for `Future`:

```scala
import scala.concurrent._
import scala.concurrent.duration._

//...
Await.result(future, 10.seconds)
```

The implementation of `result` is this one:

```scala
object Await {
  // ...
  def result[T](awaitable: Awaitable[T], atMost: Duration): T = 
    blocking(awaitable.result(atMost)(AwaitPermission))
}
```

This is making use of Scala's ["blocking context"](https://docs.scala-lang.org/overviews/core/futures.html#blocking), being decoupled from Scala's `Future` implementation via this interface:

```scala
trait Awaitable[+T] {
  //...
  def result(atMost: Duration)(implicit permit: CanAwait): T
}
```

In other words, the implementation forces the use of `Await.result` via a `CanAwait` implicit (which can't be instantiated from user code). This is also how Monix [disallows blocking I/O](https://github.com/monix/monix/blob/346352380c4b2b12a66f83cf7ca416dbebde357b/monix-execution/js/src/main/scala/monix/execution/schedulers/CanBlock.scala#L78) methods to run on top of JavaScript (such as [Task.runSyncUnsafe](https://github.com/monix/monix/blob/346352380c4b2b12a66f83cf7ca416dbebde357b/monix-eval/shared/src/main/scala/monix/eval/Task.scala#L1064)) 😉

Another API that I can remember is [Scala-STM](https://web.archive.org/web/20220523184153/https://nbronson.github.io/scala-stm/quick_start.html), a project that I used back in the day, and that looks like this:

```scala
def addLast(elem: Int): Unit =
  atomic { implicit txn =>
    val p = header.prev()
    val newNode = new Node(elem, p, header)
    p.next() = newNode
    header.prev() = newNode
  }
```

The implementation is keeping track of the current transaction, at compile-time, via that implicit parameter. Although, in this case the implicit isn't just a "compile-time proof", but rather something that affects the runtime too.

I think I'm being inspired by Martin Odersky's presentation:

{% include youtube.html id="YXDm3WHZT5g" caption="Plain Functional Programming by Martin Odersky" %}

Do you think tracking side effects like this would be useful in libraries? Monix, for example, also contains impure parts, and could make use of it.

Would you like it? Any prior art that I'm not aware of?
