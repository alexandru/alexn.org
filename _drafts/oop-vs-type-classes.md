---
title: "OOP vs Type Classes"
image: /assets/media/articles/scala-oop-typeclasses.jpg
generate_toc: true
---

## Motivation

<img src="{% link assets/media/articles/scala-spiral.png %}" width="100" align="right" class="right hide-in-feed" />

Scala is a hybrid OOP+FP language. If you love OOP, Scala is one of the best static OOP languages. But Scala also exposes parametric polymorphism and can encode type classes.

Thus, developers can also choose to use parametric polymorphism restricted by type classes (aka ad hoc polymorphism). As if choosing when to use immutability versus object identity wasn't bad enough, developers are also faced with a difficult choice when expressing abstractions. Such choices create tension in teams, with the code style depending on the team leader or whoever does the code reviews.

Let's go through what is OOP, what is ad hoc polymorphism via type classes, how to design type classes, go through the pros and cons, and establish guidelines for what to pick, depending on the use case.

## Video Presentation

I gave a speech in 2021 at [Scala Love in the City](https://inthecity.scala.love/) on this same topic. If you're more into videos, rather than reading words, you can watch this as an alternative, although note this article has more details that couldn't fit in video form...

{% include youtube.html id="UT2K9c66xCU" ratio=56.25 %}

## Abstraction

We are gifted with a brain that's great at recognizing patterns. Take a look at these shapes, [which one doesn't belong?](https://www.goodreads.com/book/show/31243369-which-one-doesn-t-belong)

<img src="{% link assets/media/articles/which-one-doesnt-belong-1.png %}" 
    alt="A picture of 4 shapes (3 triangles, 2 triangles with a right angle, 2 isosceles triangles, 1 pentagon)" />

What's cool is that there is no right answer, you can point at any one of them, thus grouping the other 3 with some common characteristic. We have above:

- 3 triangles;
- 2 triangles with a right angle;
- 2 isosceles triangles;
- 3 shapes containing a right angle;

Here's another one:

<img src="{% link assets/media/articles/which-one-doesnt-belong-2.png %}" 
    alt="A picture of 4 shapes (3 squares, 1 regular quadrilateral)" />

We have:

- 3 squares, and 1 regular quadrilateral that's not a square;
- 1 red square, 3 blue;
- 1 big square, 3 small regular quadrilaterals;
- 1 square with a different orientation than the other 3;

What about standard Scala types, how can you group these?

<img src="{% link assets/media/articles/types-cloud.svg %}"
  alt="Names of Scala types: SortedSet, List, Array, Vector, Option, String, Future, Try, Long, Either, IO" />

Some clues:

- Which types have a type parameter?
- Which types implement `map` and `flatMap`?
- Which types implement `foreach`?
- Which types are collections?
- Which collection types can be indexed efficiently?
- Which collection types have an insertion order?
- Which types are meant for signaling errors?
- Which types are meant for managing side effects?
- Which types have a sum/concatenation operation?
- On which types is that sum/concatenation operation associative, transitive or commutative?
- Which types can define an "empty" value?

We're pretty good at observing similarities, right?

<p class="info-bubble" markdown="1">
  For these images, I'm plagiarizing Julie Moronuki's [The Unreasonable Effectiveness of Metaphor](https://argumatronic.com/posts/2018-09-02-effective-metaphor.html), a keynote and an article that I recommend.
</p>

So what is abstraction?

- "*to draw away, withdraw, remove*", from the Latin _abstractus_;
- "*to consider as a general object or idea without regard to matter*";
- "*the act of focusing on one characteristic of an object rather than the object as a whole group of characteristics; the act of separating said qualities from the object or ideas*" (late 16th century);
- "*a member of an idealized subgroup when contemplated according to the abstracted quality which defines the subgroup*";

In the context of _software development_, abstraction can mean:

- idealization, removing details that aren't relevant, working with idealized models that focus on what's important;
- generalization, looking at what objects or systems have in common that's of interest, such that we can transfer knowledge, recipes, proofs;

We do this in order to **_manage complexity_** because abstractions allow us to map the problem domain better, by focusing on the essential, and it also helps us to reuse code.

<img src="{% link assets/media/articles/man-juggling.jpg %}" alt="Picture of a man juggling" />

The complexity of software projects only grows over time and there's only so much we can juggle with in our heads.

### Black Box Abstraction

A black box is a device, system or object that can be viewed in terms of its inputs and outputs. This means that the input and output are well specified, such that we can form a useful [mental model](https://en.wikipedia.org/wiki/Mental_model#:~:text=A%20mental%20model%20is%20an,own%20acts%20and%20their%20consequences.) for how it works. Note that the mental model doesn't have to be correct, it just has to be useful, such that we can operate the system without breaking it open and taking a look at the implementation:

<figure>
  <img src="{% link assets/media/articles/black-box.svg %}" alt="Illustration of the black box concept" />
  <figcaption>The engineering black box ideal</figcaption>
</figure>

These can be simple functions, associating one output value to one input, but not necessarily. Examples of complicated black boxes:

- Web services
- Automobiles

The input for an automobile is going to be the steering wheel, the gas and brake pedals. Automobiles are complex machines, but we don't need to know how they work under the hood in order to drive a car from point A to point B.

And in software development, a common strategy is to build bigger and bigger systems out of black boxes:

<figure>
  <img src="{% link assets/media/articles/black-box-multi.svg %}" alt="Illustration of multiple black boxes connected" />
</figure>


No paradigm has a monopoly on composition. FP developers can talk about functions composing, OOP developers can talk about objects composing. FP has the advantage that composition is more automatic, being governed by common protocols that have laws:

<img src="{% link assets/media/articles/category-theory.svg %}" width="1400" class="transparency-fix"
  alt="Image illustrating category theory" />

If `f` and `g` are functions, it's easy to compose them in a bigger function, `g ∘ f`. Things get more complicated when the types involved don't align. For example when that `B` type is a `Future[_]` or an `IO[_]`. But we can come up with protocols such that we can keep this automatic composition.

So what are we talking about?

- OOP-driven design is best for building black boxes, connected via [design patterns](https://en.wikipedia.org/wiki/Design_Patterns) for ensuring decoupling (the arrows between the boxes);
- FP-driven design is usually more about white-boxes; and for composing boxes, static FP gives us features such as Type Classes, for describing those design patterns via the type system, maximizing correctness and reusability;

🎤 drop — just kidding 😄

## What is OOP?

I like asking this question in interviews, as it's a little confusing. Ask 10 people, and you'll probably get 10 different answers, being a question that can be attacked on multiple axes: theory, philosophy, implementation details, best practices and design patterns.

OOP is a paradigm based on the concept of "objects" and their interactions, objects that contain both data and the code for manipulating that data, objects that communicate via messages. And in terms of provided features, we can talk of:

- Subtype polymorphism, via [single (dynamic) dispatch](https://en.wikipedia.org/wiki/Dynamic_dispatch);
- Encapsulation (hiding implementation details);
- Inheritance of classes or prototypes;

If there's one defining feature that defines OOP, that's subtype polymorphism, everything else flowing from it.
Subtype polymorphism gives us the [Liskov subtitution principle](https://en.wikipedia.org/wiki/Liskov_substitution_principle):

> *if S is a subtype of T, then objects of type T may be replaced with objects of type S*

And note that OOP can be seen in the [actor model](https://en.wikipedia.org/wiki/Actor_model); what are actors if not objects capable of async communication? And of course, web services behave like OOP objects, because OOP does a great job at modeling black boxes.

A great example of an OOP interface:

```scala
trait Iterable[+A] {
  def iterator: Iterator[A]
}

trait Iterator[+A] {
  def hasNext: Boolean
  def next(): A
}
```

Implemented by most collection types. We'll come back to it, to contrast and compare with a Type Class approach.

### Are OOP and FP orthogonal? Can they mix?

FP is about working with [mathematical functions]({% link _posts/2017-10-15-functional-programming.md %}). Nothing stops objects from being "pure", with their methods being math functions. For one, objects can perfectly describe immutable data structures, although these are less interesting, since they are just "product types" with names, or records:

```scala
case class Customer(
  name: FullName,
  emailAddress: EmailAddress,
  pass: PasswordHash
)
```

When contrasted with FP, the notion of _object identity_ (aka mutability) comes up a lot:

> "*FP removes one important dimension of complexity — To understand a program part (a function), you need no longer account for the possible executions that can lead to that program part*" — Martin Odersky in [Simple Functional Programming](https://www.youtube.com/watch?v=YXDm3WHZT5g). 

However, this is false. Let's take a mutable interface:

```scala
trait Iterator[+A] {
  def hasNext: Boolean
  def next(): A
}
```

We can of course "purify" it via `IO`:

```scala
trait Iterator[+A] {
  def hasNext: IO[Boolean]
  def next: IO[A]
}
```

Is this not compatible with FP? How about this one?

```scala
final class Metrics(counter: AtomicLong) {
  def touch(): Long = counter.incrementAndGet()
}
// FP version
final class Metrics(ref: Ref[IO, Long]) {
  def touch: IO[Long] = ???
}
```

What's the difference between that, and this totally pure function:

```scala
object Metrics {
  // Note the internals are now exposed, but function output 
  // depends entirely on function input FTW /s
  def touch(ref: Ref[IO, Long]): IO[Long] = ???
}
```

Does that not have "identity" too? Of course, it does. Suspending side effects in `IO` is cool and useful, but in terms of divorcing a function from its context and history of invocations, that's easier said than done, and FP won't save you.

Classes are, after all, just *closures with names*.

<p class="info-bubble" markdown="1">
  In Scala almost every type definition is a class, and every value is an object, functions included. Interacting with objects happens only via method calls. Turtles all the way down. Scala's OOP facilities and type system are so powerful that they allow us to encode whatever we want, such as type classes or ML modules.
</p>

<p class="warn-bubble" markdown="1">
  OOP may be orthogonal with FP, but the ideologies behind them are often at odds!
  So the answer to the question is: yes, they are orthogonal, but with caveats.
</p>

## What are Type Classes?

In static FP we have parametric polymorphism. Witness the simplest function possible:

```scala
def identity[A](a: A): A = a

// Compare and contrast with this one — how
// many implementations can this have?
def foo(a: String): String
```

This `identity` function can only have one implementation (unless you use reflection or other runtime tricks). But it would be useful to specify capabilities for that `A` type:

```scala
def sum[A](list: List[A]): A = ???

// Should work for integers
sum(List(1, 2, 3)) //= 6
// Should work for BigDecimal
sum(List(BigDecimal(1.5), BigDecimal(2.5))) //= 4.0
// Should work for strings
sum(List("Hello, ", "World")) //= Hello, World
// Should work for empty lists
sum(List.empty[Int]) //= 0
sum(List.empty[String]) //= ""
```

Can Scala's or Java's standard library provide this OOP interface?

First try:

```scala
trait Combine {
  def combine(other: Combine): Combine
}
```

Yikes, that's not good. We can't combine any two objects inheriting from `Combine`. We can't sum up an `Int` and a `String`, as this isn't JavaScript 😊 Liskov's substitution principle actually sucks here, as we care about the type, and we don't want to lose type safety 🙂

```scala
trait Combine[Self] { self: Self =>
  def combine(other: Self): Self  
}

class String extends Combine[String] { ... }

def sum[A <: Combine[A]](list: List[A]): A = ???
```

We are making use of Scala's [self types](https://docs.scala-lang.org/tour/self-types.html), but as you can see, this barely works for `combine`, and we are missing an `empty`, the neutral element, "zero" for integers, or the empty string. Java/Scala OOP developers would give up at some point, and those stubborn enough would define this dictionary:

```scala
trait Combinable[A] {
  def combine(x1: A, x2: A): A
  def empty: A
}

def sum[A](list: List[A], fns: Combinable[A]): A =
  list.foldLeft(fns.empty)(fns.combine)
```

Notice that `Combinable` is more or less the shape of that [foldLeft](https://www.scala-lang.org/api/2.13.4/scala/collection/immutable/List.html#foldLeft[B](z:B)(op:(B,A)=%3EB):B) operation.

These dictionaries are defined **per type**, and not per **object instance**. But wouldn't it be cool if we also had *automatic discovery*? That's what *implicit parameters* in Scala are for:

```scala
// Oops, the jig is up
trait Monoid[A] {
  def combine(x1: A, x2: A): A
  def empty: A
}

object Monoid {
  // Visible globally.
  // WARN: multiple monoids are possible for integers ;-)
  implicit object intSumInstance extends Monoid[Int] {
    def combine(x1: Int, x2: Int) = x1 + x2
    def empty = 0
  }
}

///...
def sum[A](list: List[A])(implicit m: Monoid[A]): A =
  list.foldLeft(m.empty)(m.combine)
// Or with some syntactic sugar
def sum[A : Monoid](list: List[A]): A = ???
```

Behold Type Classes:

- dictionaries of functions, defined per type, plus
- a mechanism for the *global discovery* of defined instances, provided by the language

Type-classes can have laws too. Monoid here has the following laws:

- combine(x, combine(y, z)) = combine(combine(x, y), z)
- combine(x, empty) = combine(empty, x) = x

These are like a [TCK](https://en.wikipedia.org/wiki/Technology_Compatibility_Kit) for testing the compatibility of implementations. Some type classes are lawless, because the laws are hard to specify, or because the signature says it all. That's fine.

Let's go back to this signature:

```scala
def sum[A : Monoid](list: List[A]): A
```

Can you see how it describes precisely what the function does? It takes a `Monoid` and `List`. What can it do with those, other than to sum up the list? There aren't that many implementations possible.

> With parametric polymorphism, coupled with Type Classes, the types dictate the implementation — and this intuition, that the signature describes precisely what the implementation does, is what static FP developers call "_parametricity_"

And as we shall see, this gives rise to one of the biggest ideological clashes in computer programming.

## Ideological clash

OOP and FP are ideologies — sets of beliefs on how it's best to build programs and manage the ever growing complexity. This is much like the political ideologies, like the Left vs Right, Progressives vs Conservatives, Anarchism vs Statism, etc, etc... different sets of beliefs for solving the same problem, promoted by social movements.

<img src="{% link assets/media/articles/yin-yang.svg %}" alt="Symbol of Yin and Yang"
  width="1400" class="transparency-fix" />

I'm not using this word lightly, computer science is not advanced as a science (via the scientific method), because computer science is also about communication and collaboration, therefore computer science also involves social problems, much like mathematics, but worse, because we can't rely only on idealized models and logic. And investigating social issues via the scientific method is hard, therefore we basically rely a lot on philosophy, intuition, experience, and fashion.

Computer science is only self-correcting based on what fails or succeeds in the market, thus relying on free market competition. If a solution is popular, that means that it found *product/market fit*. The downside is that going against the tide is difficult, due to lack of credible scientific evidence. For example "*it's based on math*" doesn't cut it.

Two sides of the same metaphorical coin, both ideologies attack the problem of local reasoning and ever growing complexity, and both have been succeeding, but from two slightly different perspectives.

<figure>
  <img src="{% link assets/media/articles/fp-oop-procedural.png %}" alt="Meme on FP with OOP guys teaming up to attack the Procedural guy" />
  <figcaption>OOP is an evolution on procedural programming by encapsulating side effects, whereas FP shuns side effects.</figcaption>
</figure>

We should learn from both, and we should have some fun while doing it, preferably without anyone getting hurt in the process.

### OOP values

- **flexibility of implementation**, meaning that the provider of an API only exposes what they *can promise* to support, leaving the door open for *multiple implementations*
- **backwards compatibility**, think web services — if protocols change often, this is disruptive for teams having to do integration, new development often happens by *feature accretion* and not *breakage*, and in case of *breakage*, developers think of *versioning*, *migrations* and in-place updates of components such that disruption is minimal (on the downside, this also means web services exposing APIs with JSONs having a lot of nullable fields 🤕);
- **black boxes**, components being described in terms of their inputs and outputs, data being coupled with the interpretation of that data (see this [exchange between Alan Kay and Rich Hickey](https://news.ycombinator.com/item?id=11946935));
- **resource management**, in contrast with FP, which makes resource management the job of the runtime, in OOP languages like Scala we implement our own `IO`, our own `HashMap` and `ConcurrentQueue`, etc, and that's because we have good encapsulation capabilities, access to low-level platform intrinsics and we don't shy away from doing optimizations via all sorts of nasty side effects;

### Static FP values

<p class="info-bubble" markdown="1">
  I'm saying *static FP* because NOT ALL of these are values of the FP ideology as practiced in dynamic languages. I recommend watching [Spec-ulation (YouTube)](https://www.youtube.com/watch?v=oyLBGkS5ICk){:target="_blank",rel="nofollow"}, a keynote by Rich Hickey.
</p>

- **flexibility at the call site**, meaning that an implementation, like a function, should be able to work with as many types as possible, and this is often at odds with *flexibility of the implementation*, because it means restricting what the implementation can do via *type signatures* (a very subtle point, being a case of *pick your poison*);
- **correctness**, API signatures in static FP being very precise, correctness is awesome, but unfortunately this is at odds with *backwards compatibility*; correctness often means breakage in the API; static FP devs pride themselves with their language's ability for refactoring, but refactoring often means breakage by definition;
- **dumb data structures** — based on the creed that data lives more than the functions operating on it, and that data structures can be more reusable when they are dumb, with interpretation being a matter of the functions operating on it, which can add or remove restrictions as they like; but this is often at odds with *encapsulation* and *flexibility of implementation*;
  - OOP prefers **black boxes**, FP prefers **white boxes**;
- **dealing with data** — FP shines within the I/O boundaries set by the runtime (or by OOP), there's nothing simpler than a function that manipulates immutable data structures, and such functions can be easily divorced from their underlying context;
- **derivation of laws and implementations** — static typing is about proving correctness, and static FP languages give us tools for automatically deriving proofs and implementations from available ones; e.g. if you have an `Ordering[Int]` you can quickly derive an `Ordering[List[Int]]`, which isn't possible in classic OOP

### Degenerate cases

Compare the degenerate signature for OOP classes:

```scala
trait Actor {
  def send(message: Any): Unit
}
```

Versus the degenerate signature for parametric functions in static FP:

```scala
def identity[A](a: A): A
```

This is a spectrum of course. An `Actor` can implement literally anything, but dealing with it is very unsafe, that contract is useless and all reasoning enabled by static typing goes out the window. And `identity` works for any type, maximally usable and composable, but it does absolutely nothing, in practice its utility being only to play "Type Tetris", i.e succeeding in the invocations of other functions by making the types match. It's such a sad little function, in spite of being a star at FP conferences.

What we want is balance. "*It depends*" is boring, but true.

## Converting between styles

### OOP interfaces to Type Classes

In some cases it is easy to convert from OOP interfaces to Type Classes. Remember that OOP is doing a dispatch on `this`, which is always implied as the first parameter of a method. Thus we can transform `this` into a type parameter:

```scala
// OOP-style interface
trait JSONSerialization {
  def toJSON: JsValue
}

// Type-class
trait JSONSerialization[A] {
  def toJSON(a: A): JsValue
}
```

It's not always as simple. OOP classes that have identity (that keep internal state), when converted to Type Classes, must expose that internal state:

```scala
// OOP
trait Iterator[+A] {
  def hasNext: Boolean
  def next(): A
}

// Type Class
trait Iterator[F[_]] {
  type Cursor[_]
  
  def start[A](collection: F[A]): Cursor[A]
  def hasNext[A](cursor: Cursor[A]): Boolean
  def next(cursor: Cursor[A]): (A, Cursor[A])
}
```

Note that this won't be a 1:1 conversion. Signatures for the type class implies that the `Cursor` is a pure data structure, and it can be problematic, as we could be talking about a reference pointer that needs to be mutated for efficiency. Exposing something that does `IO` might be more suitable:

```scala
trait Iterator[F[_]] {
  type Cursor[A]
  
  def start[A](collection: F[A]): IO[Cursor[A]]
  def hasNext[A](cursor: State[A]): IO[Boolean]
  def next(cursor: State[A]): IO[A]
}

// Perfectly equivalent to this OOP class:
trait Iterator[+A] {
  def hasNext: IO[Boolean]
  def next(): IO[A]
}
```

Observations:

- in some cases the Type Class approach exposes internals wide open, whereas the OOP version does not
- Type Classes introduce the need to have [Higher-Kinded Types](https://typelevel.org/blog/2016/08/21/hkts-moving-forward.html) (the `F[_]` type parameter in our samples), which means extra _expressivity_, extra _type safety_, but also extra complexity in the compiler's implementation, and extra learning curve (compromises, heh?)

### Type Classes to OOP interfaces

Not all OOP interfaces can be turned to Type Classes, even if you wanted to, it's not possible. Type Classes are simply more _expressive_, and the ability to express them in a programming language is pure gold. Let's try a sample of converting these familiar Type Classes to classic OOP interfaces:

```scala
trait FlatMap[F[_]] {
  def flatMap[A, B](fa: F[A])(f: A => F[B]): F[B]
}

trait Monad[F[_]] extends FlatMap[F] {
  def pure[A](a: A): F[A]
}
```

Well, `pure` is out, because we don't have a `this` instance that we can hold on to. How about just the `FlatMap` interface? A naive approach would be:

```scala
trait FlatMap[A] {
  def flatMap[B](f: A => FlatMap[B]): FlatMap[B]
}

// WRONG! We can't compose monadic types like this, for obvious reasons.
Option(1).flatMap(x => Future(x + 1))
```

This is a total fail, the Liskov substitution principle isn't our friend here. The type must be preserved. Scala is such a clever language, however, that it can work where other languages fail:

```scala
trait FlatMap[A, Self[_] <: FlatMap[A, Self]] { self: Self[_] =>
  def flatMap[B](f: A => Self[B]): Self[B]
}
```

This is called "*f-bound polymorphism*", and in truth it is only useful for *implementation inheritance* (used by Scala collections to share code), because if you ever want to use this in generic code, you will hate your life, and you might end up hating your life as a software engineer with just implementation inheritance. Just don't do it.

OOP developers from other languages can turn to design patterns for solace.

> A "design pattern" is usually a name for an abstraction that your programming language doesn't let you turn into a library.

Damn, that's a depressing thought.

## Best Practices

Getting down to the nitty-gritty ...

### Use Type Classes for expressing data constructors (factories)

Say we want to make the following function more generic, to work with any collection type, a classic problem solvable by [traverse](https://typelevel.org/cats/typeclasses/traverse.html):

```scala
def sequence(list: List[IO[A]]): IO[List[A]] = ???
```

We could attempt usage of `Iterable`, but that would mean we'd be losing the input type, and we'd have to replace it with something else, more concrete:

```scala
def sequence(list: Iterable[IO[A]]): IO[???]
```

In absence of `Traverse`, there's also Scala's [BuildFrom](https://www.scala-lang.org/api/current/scala/collection/BuildFrom.html), but let's attempt our own type class. We need:

- ability to create an empty buffer that can eventually build our final list
- ability to append items to this buffer
- ability to convert into our target type

```scala
import scala.collection.mutable.ListBuffer

trait CollectionBuilder[Coll[_]] {
  // Buffer is used for building the collection, 
  // it can be dirty / mutable
  type Buffer[A]
  // We need a way to iterate over the collection
  def iterable[A](coll: Coll[A]): Iterable[A]
  // Buffer data constructor
  def newBuffer[A]: Buffer[A]
  def append[A](buf: Buffer[A], elem: A): Buffer[A]
  def build[A](buf: Buffer[A]): Coll[A]
}

object CollectionBuilder {
  // Sample instance
  implicit object forList extends CollectionBuilder[List] {
    type Buffer[A] = ListBuffer[A]
    def iterable[A](coll: List[A]) = coll
    def newBuffer[A] = ListBuffer.empty[A]
    def append[A](buf: Buffer[A], elem: A) = buf += elem
    def build[A](buf: Buffer[A]) = buf.toList
  }
}

def sequence[Coll[_]](list: Coll[IO[A]])
  (implicit cb: CollectionBuilder[Coll]): IO[Coll[A]] =

  cb.iterable(list)
    .foldLeft(IO(cb.newBuffer[A]))(cb.append)
    .map(cb.build)
```

### Use Type Classes if you want reusability of dumb data structures

FP developers in general love to say that data survives more than the functions operating on it. Static FP developers love to reuse their data structures too. They also say that OOP is "complecting" data and methods operating on that data together, and that we shouldn't do that. I have objections to that statement, because *data implies some interpretation rules and logic*, even if minimal (otherwise we are dealing with bits), as we shall see, but sometimes it's a good idea.

When you can work with dumb, immutable data structures that need to be interpreted, type classes might be a good solution for reusing them. One such example is [monix.tail.Iterant](https://monix.io/api/current/monix/tail/Iterant.html). There's an [older presentation](https://www.youtube.com/watch?v=Ki4JvV66EbE) about it, but here's a summary ...

We start from the `Iterator` idea, described above as a pure trait, powered by `IO` for suspending side effects:

```scala
trait Iterator[+A] {
  def hasNext: IO[Boolean]
  def next: IO[A]
}
```

Well, this trait could be turned into a data structure:

```scala
sealed trait LazyList[A]

object LazyList {
  case class Next[A](head: A, tail: IO[LazyList[A]]) 
    extends LazyList[A]
  // Marks the end of the list, with an optional error
  case class Halt[A](e: Option[Throwable]) 
    extends LazyList[A]
}
```

But, why impose behavior on it via `IO`? Why is `IO` relevant at all?

```scala
sealed trait LazyList[F[_], A]

object LazyList {
  case class Next[F[_], A](head: A, tail: F[LazyList[F, A]]) 
    extends LazyList[F, A]
  case class Halt[F[_], A](e: Option[Throwable]) 
    extends LazyList[F, A]
}
```

And now, if we want to iterate this data structure, we can make it so :

```scala
def fold[F[_], A, S](list: LazyList[F, A])(seed: S)(f: (S, A) => S)
  (implicit F: MonadError[F, Throwable]): F[S] =
  // Using tailRecM for stack safety ;-)
  F.tailRecM((list, seed)) {
    case (Next(head, tail), state) =>
      tail.map { tail => Left((tail, f(state, head))) }
    case (Halt(None), state) =>
      F.pure(Right(state))
    case (Halt(Some(err)), _) =>
      F.raiseError(err)
  }
```

And now all we need is `MonadError`, which means this can work with more types than `IO`. 

#### Caveat: dumb data structures can be misleading

FP developers may love the reuse of data structures, but this isn't always such a good idea. 

> Sometimes invariants set by the used functions are important, and ignoring those invariants is dangerous.

Consider:

```scala
case class BinaryTree[+A](
  value: A,
  left: Option[BinaryTree[A]],
  right: Option[BinaryTree[A]]
)
```

Does this qualify as a dumb, reusable data-structure? It depends. This tree can be a [binary search tree (BST)](https://en.wikipedia.org/wiki/Binary_search_tree), and we could have this function for searching an element:

```scala
object SortedSet {
  def fromList[A: Ordering](list: List[A]): BinaryTree[A] = ???
  def contains[A: Ordering](set: BinaryTree[A], value: A): Boolean = ???
}

// Second variant
object InefficientSet {
  def fromList[A](list: List[A]): BinaryTree[A] = ???
  def contains(set: BinaryTree[A], value: A): Boolean
}
```

Here's the problem:

```scala
// Inefficient
InefficientSet.contains(
  SortedSet.fromList(???),
  111
)
// Malfunction
SortedSet.contains(
  InefficientSet.fromList(???),
  222
)
```

The invariant of the "binary search tree" is imposed by the `fromList` function. If you build that tree with any other function, then that `contains` of a BST will malfunction.

```scala
case class SortedSet[+A](tree: BinaryTree[A])

object SortedSet {
  def contains[A: Ordering](set: SortedSet[A], value: A): Boolean = ???
}
```

M'kay, that's better, but is this really reusability? Wouldn't it have been better to copy/paste and then add that restriction in the class constructor?

```scala
// Notice the Ordering restriction:
case class SortedSet[+A : Ordering](
  value: A,
  left: Option[SortedSet[A]],
  right: Option[SortedSet[A]]
)
```

But this is no longer a "dumb data structure", because it adds interpretation to its definition. As it should. The public data constructor is still risky 😉

### Type Class instances must be coherent (globally unique)

Type Class instances must be *globally unique*, as the logic making use of type classes usually depends on it, or in other words:

> In a fully compiled program, for any type(s) parameters, there is at most one instance resolution for a given type class.

Type Classes have many qualities, but the ability to redefine instances for existing types is not one of them. Scala cannot guard against this, we can define as many instances we want, and import them in scope as needed. Scala doesn't support type classes directly either, yet we encode them anyway.



### Type Classes must not keep state

### Use OOP for managing resources

### Use OOP for information hiding, aka Encapsulation

> "*Encapsulation is only useful for hiding optimizations*" — FP developer

### Use OOP for avoiding the "Sea of Parameters" effect

