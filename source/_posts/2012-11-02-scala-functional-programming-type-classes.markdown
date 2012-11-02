---
layout: post
title: "On Scala, Functional Programming and Type-Classes"
tags:
  - Languages
  - Scala
  - Clojure
  - Java  
---

I've been following the excelent Coursera course on
[Functional Programming Principles in Scala](https://www.coursera.org/course/progfun)
led by Martin Odersky. This was not my first encounter with Scala as
I've been using it including for my day job. In parallel, because I
felt the need for a Javascript replacement, I've been learning Clojure
too, because of the excelent ClojureScript.

I've fallen in love with both and I can't really pick a favorite. For
what is worth this document represents my (rookie) experience with
Scala, being complete yack shaving on my part, or you could call it
the intellectual masturbation of a fool.

UPDATE: as if the article wasn't long enough, I've added to it some
more stuff :-)

## 1. Functional Programming for the Win

It's not a silver bullet, but on the whole it's awesome. You really
have to experience it, while leaving aside the preconceptions and
biases you've been building up by honing those imperative skills for
years. Students learn functional programing more easily, fresh as they
are, otherwise the learning experience can be painful.

But we haven't evolved much in the last 200,000 years and so our brain
finds pleasure mostly in the things that appeal to our inner-animal,
being interested in the means to get laid, eat food, sleep and escape
wild beasts. Learning can be a pleasure, but not when you're venturing
to unfamiliar grounds, so if you start, hang in there.

We need some definitions though. Functional programming ...

* deals with computation by evaluating functions with
  [referential transparency](http://en.wikipedia.org/wiki/Referential_transparency_(computer_science)
  as a property (i.e. functions behave like mathematical functions,
  for the same input you must always get the same output)
* the final output of a computation is composed out of multiple
  transformations of your input data, instead of building that
  solution by mutating state
  
A functional programming language is one that:

* treats functions as first-class objects, meaning that dealing with
  higher-order functions is not only possible, but comfortable  
* gives you the tools needed for *composing* functions and types

By that definition languages like Ruby and Javascript can be
considered decent functional languages and they are. However I would
also add:

* has a rich collection of immutable/persistent data-structures (in
  general if you want to assess the viability of any programming
  language, disregarding the platform it runs on, it's perfectly
  characterized by its basic primitives and data-structures;
  e.g. think of C++, Java, or Javascript)  
* exposes a type-system that deals efficiently with the
  [expression problem](http://en.wikipedia.org/wiki/Expression_problem); 
  Rich Hickey calls this "*polymorphism a la carte*"
  
You can also go to the extreme of specifying that all side-effects
must be modeled with monadic types, but that's a little too much IMHO,
as only one mostly-mainstream language fits that bill (Haskell).

## 2. Is Scala a Functional Programming Language?

Yes it is. You only need to follow the excelent (I mentioned above)
[Coursera course](https://www.coursera.org/course/progfun) and solve
the assignments to realize that Scala is indeed a very functional
language. The course was a little short, but a follow-up is
planned. Now move along

## 3. Polymorphism À la Carte

This is a term that I've been hearing from Rich Hickey, when he talks
about open type-systems, referring primarily to Clojure's Protocols
and Haskell's Type-Classes.

These mechanisms for polymorphisms are good solutions for dealing with
the expression problem being in stark contrast with Object-Oriented
Programming as we've come to know it from Java and C++.

OOP is often a closed type-system, especially as used in static
languages. Adding new classes into an existing hierarchy, adding new
functions that operate on the whole hierarchy, adding new abstract
members to interfaces, making built-in types to behave in a certain
way - all of these cases are cumbersome.

Haskell deals with it through
[Type Classes](http://en.wikipedia.org/wiki/Type_class). Clojure deals
with this through
[Multi-Methods](http://en.wikipedia.org/wiki/Multiple_dispatch) and
protocols, protocols being the dynamic equivalent for type-classes in
a dynamic type-system.

## 4. Yes Virginia, Scala has Type-Classes

So what's a type class? It's like an interface in Java, except that
you can make any existing types conform to it without modifying the
implementation of that type.

As an example, what if we wanted a generic function that can add
things up ... you know, like a `foldLeft()` or a `sum()`, but rather
than specifying how to fold, you want the environment to know how to
do that for each particular type.

There are several problems with doing this in Java or C#:

- there is no interface defined for "`+`" on types that support addition
  (like Integers, BigInteger, BigDecimal, floating-point numbers,
  strings, etc...)
- we need to start from some *zero* (the list of elements you want to
  fold could be empty)
  
Well, you can define a type-class, like so:

{% highlight scala %}
trait CanFold[-T, R] {
  def sum(acc: R, elem: T): R
  def zero: R
}
{% endhighlight %}

But wait, isn't this just a simple Java-like interface? Well yes, yes
it is. That's the awesome thing about Scala - in Scala every instance
is an object and every type is a class.  

So what makes this interface a type-class?
[Objects in combination with implicit parameters](http://ropas.snu.ac.kr/~bruno/papers/TypeClasses.pdf)
of course. Let's look at how we'll implement our `sum()` function that
uses this:

{% highlight scala %}
def sum[A, B](list: Traversable[A])(implicit adder: CanFold[A, B]): B = 
  list.foldLeft(adder.zero)((acc,e) => adder.sum(acc, e))
{% endhighlight %}

So if the Scala compiler can find an implicit `CanFold` in scope
that's defined for type A, then it uses it to return a type B. This is
awesomeness on multiple levels:

- the implicit defined in scope for type A are establishing the return
  type B  
- you can define a CanFold for any type you want, integers, strings,
  lists, whatever

Implicits are also scoped so you have to import them. If you want
default implicits for certain types (globally available) you have to
define them in the companion object of the trait `CanFold`, like this:

{% highlight scala %}
object CanFold {
  // default implementation for integers
  
  implicit object CanFoldInts extends CanFold[Int, Long] {
    def sum(acc: Long, e: Int) = acc + e
    def zero = 0
  }
}
{% endhighlight %}

And usage is as expected:

{% highlight scala %}
// notice how the result of summing Integers is a Long
sum(1 :: 2 :: 3 :: Nil)
//=> Long = 6
{% endhighlight %}

I'm not going to lie to you as this stuff gets hard to learn and while
learning how to do this, you'll end-up pulling your hair out wishing
for dynamic typing where all of this is not a concern. However you
should distinguish between *hard* and *complex* (the former is
relative and subjective, the later is absolute and objective).

One issue with our implementation is when you want to provide a
default implementation for base types. That's why we've made the type
parameter T *contravariant* in the `CanFold[-T,R]` definition. What
contravariance means is precisely this:

{% highlight scala %}
if B inherits from A, as in B is a subtype of A (i.e. B <: A), then
CanFold[A, _] is a subtype of CanFold[B, _] 
(i.e. CanFold[A,_] <: CanFold[B,_])
{% endhighlight %}

This allows us to define a CanFold for any Traversable and it will
work for any Seq / Vector / List and so on.

{% highlight scala %}
implicit object CanFoldSeqs 
extends CanFold[Traversable[_], Traversable[_]] {
  def sum(x: Traversable[_], y: Traversable[_]) = x ++ y
  def zero = Traversable()
}
{% endhighlight %}

So this can sum up any kind of `Traversable`. The problem is that it
loses the type parameter in the process:

{% highlight scala %}
sum(List(1,2,3) :: List(4, 5) :: Nil)
//=> Traversable[Any] = List(1, 2, 3, 4, 5)
{% endhighlight %}

And the reason for why I mentioned this is hard is because after
pulling my hair out, I had to
[ask on StackOverflow](http://stackoverflow.com/questions/13176697/problems-with-contravariance-in-scala)
on how to get a `Traversable[Int]` back. So instead of a concrete
implicit object, you can provide an implicit `def` that can do the
right thing, helping the compiler to see the type embedded in that
container:

{% highlight scala %}
implicit def CanFoldSeqs[A] = new CanFold[Traversable[A], Traversable[A]] {
  def sum(x: Traversable[A], y: Traversable[A]) = x ++ y
  def zero = Traversable()
}

sum(List(1, 2, 3) :: List(4, 5) :: Nil)
//=> Traversable[Int] = List(1, 2, 3, 4, 5)
{% endhighlight %}

Implicits are even more flexible than meets the eye. Apparently the
compiler can also work with functions that return the instance you
want, instead of concrete instances. As a side-note, what I did above
is difficult to do, even in Haskell, because sub-typing is involved,
although doing it in Clojure is easy because you simply do not care
about the returned types.

**NOTE: the above code is not bullet-proof, as conflicts can happen**

Say in addition to a CanFold[Traversable,_] you also define something
for Sets (which are also traversable) ...

{% highlight scala %}
implicit def CanFoldSets[A] = new CanFold[Set[A], Set[A]] {
  def sum(x: Set[A], y: Set[A]) = x ++ y
  def zero = Set.empty[A]
}

sum(Set(1,2) :: Set(3,4) :: Nil)
{% endhighlight %}

This will generate a conflict error and I'm still looking for a
solution that makes the compiler use the most specific type it can
find, while still keeping that nice contra-variance we've got going
(hey, I'm just getting started). The error message looks like this:

{% highlight sh %}
both method CanFoldSeqs in object ...
and method CanFoldSets in object ...
match expected type CanFold[Set[Int], B]
{% endhighlight %}

That's not bad at all as far as error messages go. For now, you just
avoid being too general and in case you want to override the default
behavior in the current scope, you can shadow the conflicting
definitions:

{% highlight scala %}
{ 
  // shadowing the more general definition 
  // (notice the block, representing its own scope, 
  //  so shadowing is local)
  def CanFoldSeqs = null

  // this now works
  sum(Set(1,2) :: Set(3,4) :: Nil)
  //=> Set[Int] = Set(1, 2, 3, 4)
}
{% endhighlight %}

Another solution that `CanBuildFrom` uses is to define implicits on
multiple levels, such that some implicits take priority over others,
likes so:

{% highlight scala %}
trait LowLevelImplicits {
  implicit def CanFoldSeqs[A] = new CanFold[Traversable[A], Traversable[A]] {
    def sum(x: Traversable[A], y: Traversable[A]) = x ++ y
    def zero = Traversable()
  }
}

object CanFold extends LowLevelImplicits {
  // higher precedence over the above
  implicit def CanFoldSets[A] = new CanFold[Set[A], Set[A]] {
    def sum(x: Set[A], y: Set[A]) = x ++ y
    def zero = Set.empty[A]
  }
}
{% endhighlight %}

And yeah, it will do the right thing. A little ugly though. In
essence, this is heavy stuff already. Good design can make for
kick-ass libraries though.

## 5. Scala's Collections Library is Awesome

So what does the above buy you anyway? The following are some examples
from Scala's own collections library.

You can sum things up in sequences, as long as you have an
implementation of type-class `Numeric[T]` in scope:

{% highlight scala %}
List(1,2,3,4).sum
//=> Int = 10
{% endhighlight %}

You can sort things, as long as you have an implementation of
type-class `Ordering[T]` in scope:

{% highlight scala %}
List("d", "c", "e", "a", "b").sorted
//=> List[java.lang.String] = List(a, b, c, d, e)
{% endhighlight %}

A collection will always do the right thing, returning the same kind
of collection when doing a `map()` or a `flatMap()` or a `filter()`
over it. For instance to revert the keys and values of a Map:

{% highlight scala %}
Map(1 -> 2, 3 -> 4).map{ case (k,v) => (v,k) }
//=> scala.collection.immutable.Map[Int,Int] = Map(2 -> 1, 4 -> 3)
{% endhighlight %}

However, if the function you give to `map()` above does not return a
pair, then the result is converted to an iterable:

{% highlight scala %}
Map(1 -> 2, 3 -> 4).map{ case (k,v) => v * 2 }
//=> scala.collection.immutable.Iterable[Int] = List(4, 8)
{% endhighlight %}

Even more awesome than this, take for example the `BitSet` which is a
compressed `Set` of integers (so it's optimized for storing integers):

{% highlight scala %}
import collection.immutable.BitSet

BitSet(1,2,3,4).map(_ + 2)
//=> BitSet = BitSet(3, 4, 5, 6)
{% endhighlight %}

Mapping over it still returns a BitSet, as expected. However, look at
what happens when the mapping function returns Strings:

{% highlight scala %}
BitSet(1,2,3,4).map(x => "number " + x.toString)
//=> Set[java.lang.String] = Set(number 1, number 2, number 3, number 4)
{% endhighlight %}

Again, it did the right thing, because you can't store Strings in a
BitSet, as BitSets are for integers. So it returned a plain Set of
strings. How is this possible, you may ask?

The answer is in the
[CanBuildFrom](http://www.scala-lang.org/api/current/scala/collection/generic/CanBuildFrom.html)
pattern. The signature of `map()` used above is a bit of a mouthful:

{% highlight scala %}
def map[B, That](f: (Int) => B)(implicit bf: CanBuildFrom[BitSet, B, That]): That
{% endhighlight %}

So, similar to my example with `CanFold`:

- the compiler takes type B from the mapping function `f: (Int) => B` that's provided as an argument
- searches for an implicit in scope of type `CanBuildFrom[BitSet, B, _]`
- the return type is established as the third type parameter of the implicit that is used
- the actual building of the result is externalized; the BitSet does
  not need to know how to build Sets of Strings

So basically, if you define your own types like so:

{% highlight scala %}
class People extends Traversable[Person] { /* yada yada... */ }
case class Person(id: Int)
{% endhighlight %}

Then if you want the mapping (or flatMapping) of a BitSet to return a
`People` collection in case the function returns `Person`, then you
have to implement an implicit object of this type:

{% highlight scala %}
CanBuildFrom[BitSet, Person, People]
{% endhighlight %}

And then this will work:

{% highlight scala %}
BitSet(1,2,3,4).map(x => Person(x))
//=> People = People(Person(1), Person(2), Person(3), Person(4))
{% endhighlight %}

So what's great is that the provided implicits for `CanBuildFrom` can
be overridden by your own implementations and you can provide
CanBuildFrom implementations for your own types, etc...

(as a side note, Clojure cannot do conversions based on the given
mapping function, even if the Seq protocol is awesome nonetheless and
doing something akin to CanBuildFrom in Haskell is difficult from what
I've been told)

If you want a lazy
[Iterator](http://www.scala-lang.org/api/current/scala/collection/Iterator.html)
(like
[if you want to wrap JDBC result-sets](https://github.com/alexandru/shifter/blob/master/db/src/main/scala/shifter/db/Sql.scala#L83)),
you only need to wrap the JDBC result-set in an Iterator by
implementing `next()` and `hasNext`. You then get
`filter()`/`map()`/`flatMap()` for free, but with a twist - Iterators
are lazy and can only be traversed once. Applying filter/map/flatMap
will not traverse the Iterator, being lazy operations. To convert this
into a lazy sequence that also memoizes (stores) the results for
multiple traversals, you only need to do `iterator.toStream`, or to
get all the results at once `iterator.toList`.

[Streams](http://www.scala-lang.org/api/current/scala/collection/immutable/Stream.html)
in Scala are lazy sequences. You can easily implement infinite lists
of things, like Fibonacci numbers or the digits of PI or
something. But Streams are not the only lazy collections, Scala also has
[Views](http://www.scala-lang.org/docu/files/collections-api/collections_42.html)
and you can transform any collection into a corresponding view, including Maps. 

But that's not all. Scala also has implementations of collections that
do things in parallel. Here's how to calculate if a number is prime,
sequentially:

{% highlight scala %}
import math._

def isPrime(n: Int) = {
  val range = 2 to sqrt(abs(n)).toInt
  ! range.exists(x => n % x == 0)
}
{% endhighlight %}

If you have multiple cores around doing nothing, here's how to
calculate it by putting those extra cores at work:

{% highlight scala %}
def isPrime(n: Int) = {
  val range = 2 to sqrt(abs(n)).toInt
  ! range.par.exists(x => n % x == 0)
}
{% endhighlight %}

Notice the difference?

## 6. Is this complex?

I mentioned above that this stuff is not complex, it's just
hard. Scala does have complexities when it comes to really advanced
use-cases, as can be seen in this article:
[True Scala Complexity](http://yz.mit.edu/wp/true-scala-complexity/)

It's worth mentioning however that, as Martin Odersky noted in the
Hacker News thread of that article, the author tries to accomplish
something that's not possible in most languages out there, while a
solution is still possible in Scala (albeit with small limitations).

## 7. Are OOP Features Getting in the Way?

I happen to disagree and I actually love the blend of OOP with
functional features. Martin Odersky claims that OOP is orthogonal to
functional programming. But if you pay attention, you'll notice it's
not only orthogonal, but complementary in an elegant way.

I'm indicating below instances where I think OOP helps, but as a clear
example of what the combination can do, consider Scala's
[Set](http://www.scala-lang.org/api/current/scala/collection/immutable/Set.html). A
`Set[T]` can be viewed as a function that takes a parameter of type T
and returns either True if the value is in the Set, or False
otherwise. This means you can do this:

{% highlight scala %}
val primaryColors = Set("red", "green", "blue")

val colors = List("red", "purple", "yellow", "vanilla", "white", "black", "blue")

colors.filter(primaryColors)
{% endhighlight %}

This is possible because our set is in fact a subtype of
`Function1[Int, Boolean]`, so you can pass it to any higher-order
function that expects that signature.

But the similarity goes deeper than simple resemblance and syntactic
sugar. If you remember from school, mathematical Sets can be perfectly
described by what is called a
[characteristic function](http://en.wikipedia.org/wiki/Indicator_function),
so Sets are interchangeable with functions in mathematics.

This means operations on Sets like *unions*, *intersections*,
*complements*, *Cartesian products* and so on can be perfectly
described (or replaced) with operations on functions and that's
exactly what
[boolean algebra](http://en.wikipedia.org/wiki/Boolean_algebra) is
about.

And I don't know how Haskell handles this for `Data.Set`, or if it
handles it at all, but OOP subtyping seems like the easiest way to
model something like this in a static language ...

* for one, the hierarchy is simple to understand, simple to model -
  you just inherit from <br /> `Function1[-T, +R]` - done
* downcasting to a function is something OOP simply does - you just
  pass your object to something that expects a function - done  
* functions are *contravariant* in their parameters and *covariant* in
  their return type - this is not something easily done without OOP OR
  without the language being completely dynamic (such that
  co/contra-variance does not matter) - a Set is a bad example, as
  Sets in Scala are invariant, however you can probably think of
  useful usecases for where you'd want this for your own types that
  behave as functions

This is just a small and insignificant example of course, like most
examples I'm giving here, but to me properly done OOP (where every
type is modeled with classes and every value is some kind of object)
just feels right.

## 8. Scala versus Haskell

Scala's static type-system is sometimes less expressive than that of
Haskell. In particular Haskell supports
[rank-2 polymorphism](https://en.wikibooks.org/wiki/Haskell/Polymorphism#Higher_rank_types),
while Scala only rank-1. One point that Scala wins over Haskell is
definitely this one:

{% highlight scala %}
List(1,2,3,4,5).flatMap(x => Option(x))
//=> List[Int] = List(1, 2, 3, 4, 5)
{% endhighlight %}

Doing the above in Haskell (using the `bind` operator) triggers a
compile-time error, because the return type of the mapping function is
expected to be of type `List` and the `Maybe` type (the equivalent of
`Option`) is not a `List`.

`Option` in Scala is not a collection, but it is *viewable* as a
collection of either 0 or 1 elements. As a consequence, because of
good design decisions, the monadic types defined in Scala's collection
library are more composable. 

EDIT: this example is simple and shallow. As pointed out in the
comments, it's easy to make the conversion by yourself, however I'm
talking about the design choices of Scala's library and the
awesomeness of implicits. As a result, the standard monadic types
provided by Scala (all collections, Futures, Promises, everything that
has a filter/map/flatMap, etc...) are inherently more composable and
friendlier.

It's also worth pointing out that Scala's collections library is so
awesome precisely because OOP plays a part and there are cases where
doing similar things in Haskell require experimental GHC extensions.

For instance, all of the collections in Scala share code in one way or
another. If you want to build your own
[Traversable](http://www.scala-lang.org/api/current/scala/collection/Traversable.html)
you only have to implement that trait with the abstract `foreach()`,
but you get all other methods, including
`filter()`/`map()`/`flatMap()` for free. As a side-effect your
collection will be a monadic type by default.

Haskell is lazy by default. This is good for many problems. In Scala
lazyness is a choice. In Haskell this lazyness is awesome, but in my
experience while playing with it, it gets very hard to reason about
the resulting performance. Sometimes it's fast without you doing
anything, other times - well, profiling and fixing performance issues
in Haskell is not for mortals. Scala is more predictable, being strict
and lazy when needed. It also has at its disposal the awesome JVM
ecosystem for profiling and monitoring.

## 9. Scala versus F# / Ocaml

F# is good if you want to use C# 2020. But F# has rough edges
inherited from Ocaml, while it has not inherited all the benefits. F#
has nominative typing, instead of structural typing for OOP (as
Ocaml). And you really start wishing for an ad-hoc polymorphism
mechanism in which the types are open.

In regards to how one implements `CanFold` F# takes the crown as the
ugly ducklin' as it follows the (really screwed) C# conventions of
defining "`+`" as static functions on classes (a reminiscence of C++
btw), so even if you know that a T is an Integer, you can't sum 2
Integers based on the interface definition alone, because the compiler
cannot make the connection to `T + T`, as in OOP interfaces/subtyping
only applies to instances, not classes and "static members". This is
why they had to extend the language. Take a look at the signature for
`List.sum` in F#:

{% highlight ocaml %}
List.sum : ^T list -> ^T (requires 
  ^T with static member (+) and ^T with static member Zero)
{% endhighlight %}

First of all, this is bad from all perspectives, as it uses the
(really fucked up) notion of "*static members*" that should have never
happened in OOP. It's also not a type-class as it is *not open* - you
cannot modify a built-in type to have the required static members,
being the same problem you get with classic OOP inheritance of
interfaces. You also cannot override the implementation, as you'd wish
in certain contexts.

In Scala there is no such thing as "*static members*", "`+`"
operations being plain polymorphic instance methods.

The one thing I really like about
[F# are quotations](http://msdn.microsoft.com/en-us/library/dd233212.aspx),
which give you
[.NET LINQ](http://msdn.microsoft.com/en-us/library/bb308959.aspx),
with the difference that quotations in F# are more potent than what C#
can do. In simple words, quotations in F# give you the possibility of
repurposing/recompiling pieces of code at runtime (e.g. macros).

But [macros support](http://scalamacros.org/) is an upcoming feature
of Scala 2.10, which is already at RC1 and you can play around with
the up-coming [Scala version of LINQ](http://slick.typesafe.com/)
right now.

**Ocaml** goes a long way with its structural typing for OOP. Ocaml
has the most advanced type-inferencer out of the popular functional
languages, being more advanced than the one in Haskell. It's a potent
language, but sadly it has no equivalent for type-classes.

The right way to implement `CanFold` in Ocaml/SML would be to
explicitly pass a dictionary of pointers around, as described here:
[Typeclass overloading and bounded polymorphism in ML](http://okmij.org/ftp/ML/ML.html#typeclass).

Scala, unlike Ocaml and F#, does not have 2 type-systems in the same
language, as Scala follows the "*uniform access
principle*". Type-classes and algebraic data-types are still modeled
by means of OOP classes and objects.

Why does it matter? If you ever worked with C++ you can understand
this - if OOP is pervasive in your language and not just something
completely optional, then every type in the system should be
(*viewable* as being) polymorphic and extending from some Object,
otherwise you'll end up with lots and lots of pain. It's also a matter
of having to make choices.

In Scala the code is indeed more verbose, but it reduces complexity a
lot because a big part of learning Ocaml is learning when OOP is
appropriate, or not, as you have to pick from the get-go and combining
approaches is very cumbersome.

Take for instance the definition of an immutable and persistent
List. A List can be defined efficiently as an algebraic data-type,
being either an Empty List, or a Pair of 2 elements, the head and the
tail, right?

In Ocaml:

{% highlight ocaml %}
type 'a my_list = Nil | List of 'a * 'a my_list
{% endhighlight %}

Elegant and simple. And in Scala:

{% highlight scala %}
sealed abstract class List[+T]
case class Pair[+t](head: T, tail: List[T]) extends List[T]
case object Nil extends List[Nothing]
{% endhighlight %}

One difference should immediately be noticeable, our `List` has
covariant behavior, meaning that a `List[String]` is also a
`List[Any]`, or a `List[j.u.HashMap]` is also a
`List[j.u.AbstractMap]`. Arrays in Java have the same behavior and
this leads to lots of gotchas, but if our List is immutable, then this
is not a problem, but a bonus. For instance this gives you polymorphic
behavior without needing type parameters or higher-kinded types or
other mechanisms, just plain OOP subtyping relationships:

{% highlight scala %}
def length(list: List[Any]) = list match {
   case Pair(head, tail) = 1 + length(tail)
   case Nil => 0
}
{% endhighlight %}

However, that's not efficient. A much better approach is to make
`length()` polymorphic (in the OOP sense), after all `length()` is a
defining property of Lists, so there's no reason for why it shouldn't
be there:

{% highlight scala %}
sealed abstract class List[+T] {
  // abstract definition
  def length: Int
}

case class Pair[+T](head: T, tail: List[T]) extends List[T] {
  override val length = 1 + tail.length
}

final case object Nil extends List[Nothing] {
  override val length = 0
}
{% endhighlight %}

Now, isn't that nice? It works for lazy lists too. You just have to
make the `length()` definition on `Pair` a `lazy val` and presto. And
you didn't have to make choices for the internal representation of
Lists, picking the design that makes sense for the operation in
question.

Did I mention Scala also has structural typing if you want it? Yes it
can (albeit, without the awesome type-inferencing that Ocaml is
capable of):

{% highlight scala %}
type Closeable = { def close():Unit }

def using[A, B <: Closeable](closable: B)(f: B => A): A = 
  try {
    f(closable)
  }
  finally {
    closable.close()
  }
{% endhighlight %}

This comparisson isn't really fair btw, because I've been fixating on
issues that Scala does really well. Ocaml is great, however I
personally find it limiting and awkward at the edges of the 2 type
systems it contains. 

## 10. Static-type versus Dynamic-type Systems

Static versus dynamic is what polarizes developers most in separate
camps. It's like a never-ending flamewar, with healthy dosages of
religiosity.

At its core, a static type system helps you by providing proof at
compile-time that the types you're using behave as you expect them to
behave (note I'm speaking of types, not instances). This is good,
because you need all the help you can get and static typing can
eliminate a lot of errors.

This is a doubly-edged sword though. By definition a static type
system will reject pieces of code that are perfectly correct. Also,
it's not a silver bullet, as Rich Hickey said in his excelent
[Simple Made Easy](http://www.infoq.com/presentations/Simple-Made-Easy)
talk: "*What's the common thing that all bugs in the wild share? They
passed the type-checker, they passed all the tests!*"

I've seen opinions that "*structural typing*" or "*type-inference*"
are as good as "*duck typing*". That couldn't be further from the
truth - the real power of duck typing comes from the ability to create
/ modify types and functions on the fly at runtime. In other words you
can make shit up and as long as it's correct, then it works. In
contrast, a static type system actively rejects pieces of code if it
can't prove that the types you're using support the computation you're
trying to do, so no matter how smart the type system is, you'll always
end up in lots of instances where you have to spoon-feed the compiler
to allow you to do what *you mean* (n.b. not all compilers are equal).

This is not to say that static typing is bad. Well, it is bad in
languages where the type system is designed to help the IDE and not
the developer (e.g. Java, Delphi, Visual Basic). Otherwise, especially
in combination with referential transparency, it really eliminates a
whole class of errors.

Here we define *an error* as being an incorrect state of the
computation or corrupted output that takes the developers by
surprise. An exceptional state that's being controlled is not an
error. This is why Haskell makes such a big fuss out of dealing with
side-effects by means of monadic types - because it makes you think
about exceptional state and either deal with it, or make it somebody
else's problem.

Thinking of Scala versus Clojure and Haskell, in regards to its
static-type system Scala sits somewhere in the middle. This is both
good and bad. On one hand Scala does not have the same (static)
expressive capabilities of Haskell, being a poor substitute for it
when working with higher-kinded types. On the other hand you can
[drill holes](http://bionicspirit.com/blog/2012/07/02/love-scala.html)
in that static-type system to make it do what you want, which I think
is a good trade-off.

I personally lean towards dynamic type systems, however the tradeoffs
I end up making in Scala are worth it for the extra type safety it
brings. On the other hand Clojure, because of its support for
multi-methods and protocols and macros, is a dynamic language that's
more expressive than most other languages, including dynamic ones,
especially the mainstream, like Python, Ruby, Perl, Javascript or PHP.

## 11. Performance

I don't have any experience or proof on this, just personal feelings :-)

Scala runs on top of the JVM. When using closures or immutable
data-structures, it is wasteful. However there are a few things to
consider:

* Scala can be as low-level and as efficient as Java for the hot
  codepaths and low-level Scala code is still higher-level than Java
  (for instance the pimp-my-library pattern will have 0 overhead
  starting with Scala 2.10, while implicit parameters are
  compile-time)    
* the built-in immutable data-structures are optimized to be versioned
  / to reuse memory of prior states - just as when adding a new
  element to a List the old reference gets used as the tail, this
  also happens with Vectors and Maps - they are still less efficient
  than Java's collections, but it's a good tradeoff as these
  data-structures can be used without read-locks, so bye, bye
  lock-contention of threads  
* Scala creates lots of short lived objects. This can stress the
  garbage collector, but on the other hand the JVM has the most
  advanced garbage collectors available, so you shouldn't worry about
  it unless profiling tools tell you to ... for instance on the JVM
  heap allocation is as cheap as stack allocation, it can also do some
  escape analysis to get rid of some locks and to allocate some
  short-lived objects on the stack and deallocation of short-lived
  objects is cheap, because the GC is generational so it deallocates
  whole chucks of memory at once instead of individual references
  ... so why worry about it?
* the only instance to be concerned about is if you're building on top
  of Android, as Android does not have a JVM - but even there, Scala
  is workable (or so I've heard)

## 12. Tools of the Trade

I have a love/hate relationship with SBT, the defacto builds manager
for Scala, the replacement for Maven, the slayer of XML files.

The syntax is really weird and leads to cargo-culting. It broke
compatibility and so many examples available online are out of
date. When you're reading the
[Getting Started](http://www.scala-sbt.org/release/docs/Getting-Started/Welcome.html)
tome, it describes something about immutable data-structures, settings
options that are either lazy or strict, how to transform values with a
`~=` operator, something about another operator written as `<<=` and
so on.

Comparing this to how you work with Ruby Gems / Rake and Bundler is
simply not fun. Only a mother could love this syntax.

Then I've already had problems with its Ivy integration, not being
able to solve some dependencies. Thankfully I could find a fix.

On the other hand it's really pragmatic and I prefer it over Maven,
even if the Scala Maven plugin is in really good shape right now. Here
are some highlights of SBT:

* it can do cross-builds between multiple Scala versions; as is well
  known, major Scala versions are breaking binary compatibility, so if
  you want your library to support multiple Scala versions then SBT is
  a must, as it makes cross-building a breeze (it's almost too easy)  
* it's well integrated with ScalaTest, being able of continous
  compilation and testing, with output in colors - a really good tool
  for TDD  
* it makes it easy to deal with multiple sub-projects in the same root
  project, sub-projects that can be worked-on, tested or published
  individually or as a whole  
* all Scala projects have instructions for SBT first, Maven second and
  missing instructions for everything else - this is particularly
  painful if you're dealing with plugins (like doing precompilation of
  templates with Scalate or something)
  
I use Emacs. 

IDEs are not on the same level as Java. But I tried out
[IntelliJ IDEA's Scala plugin](http://blog.jetbrains.com/scala/) and
it's quite decent, with refactoring, intellisense and everything
nice. An Eclipse plugin is also available, developed now by TypeSafe,
however last time I tried, it was unstable.

So IDEs for Scala are in a worst shape than for Java, but on the other
hand these IDEs are functional and completely awesome when compared to
what you get by picking other functional languages, except maybe F#.

With Scala you can use all the profiling and monitoring tools and
classpath reloading tricks that you can use with Java. Nothing's
stopping you, as every tool meant for the JVM also works with Scala.

## 13. Concurrency and Parallelism

It's enough to say that Scala doesn't restrict you in any way:

* [Light-weight actors](http://akka.io/) that can process tons of messages (Erlang-style)
  and that work either on the same machine, in a single process, or
  distributed over a network
* [Futures and Promises](http://doc.akka.io/docs/akka/2.0.1/scala/futures.html),
  which in contrast to other languages (* cough * javascript / jquery * cough *) 
  are properly implemented as monadic types
* [Software transaction memory](http://nbronson.github.com/scala-stm/), as in Clojure
* [Parallel collections](http://docs.scala-lang.org/overviews/parallel-collections/overview.html)
* The awesome Java NIO, along with Netty, Mina and an entire ecosystem
  built around these libraries for async I/O (you don't know what
  pleasure feels like until you wrap Async-Http-Client in Akka
  Promises handled by an Akka Actor, then use responses in
  for-comprehensions)
* You can even do async/await as in C#, but it requires a compiler plugin

Basically Scala has it all. This may seem like a curse, but what other
languages define as built-in / hard to change / hard to evolve
features, Scala defines as libraries. So there are definitely upsides ;-)

## 14. Learning Resources

I've found the following to be good resources for learning Scala (note
that Amazon links have my affiliate tag, but if you want the eBook
version don't buy from Amazon, prefer buying directly from the
publisher, as you'll get both a DRM-free Kindle version and a PDF):

**[Functional Programming Principles in Scala](https://www.coursera.org/course/progfun)**,
already mentioned, is an excelent course provided by Coursera / EPFL,
taught by Martin Odersky. The course is almost over, but the material
will be left online, which means you can follow the lectures and do
the assignments and I'm pretty sure many students that attended will
remain on that forum for answering questions.

**[Scala School](http://twitter.github.com/scala_school/)** - a freely
available online tutorial by Twitter, which is very friendly to
newbies. I've read it and it's pretty good.

**[Scala Documentation Project](http://docs.scala-lang.org/)** -
definitely checkout this website, as they aggregate everything good
here. If you want to learn more about Scala's library, especially the
collections, this is the place to learn from.

**[Ninety-Nine Scala Problems](http://aperiodic.net/phil/scala/s-99/)**
- a collection of 99 problems to be solved with Scala. If you get
stuck, you can view a solution which is often idiomatic. See also this
[GitHub project](https://github.com/etorreborre/s99) that gives you a
complete test-suite, to spare you of the effort.

<a href="http://www.amazon.com/gp/product/B004Z1FTXS/ref=as_li_ss_il?ie=UTF8&camp=1789&creative=390957&creativeASIN=B004Z1FTXS&linkCode=as2&tag=bionicspirit-20"><img class="left" src="http://ws.assoc-amazon.com/widgets/q?_encoding=UTF8&ASIN=B004Z1FTXS&Format=_SL110_&ID=AsinImage&MarketPlace=US&ServiceVersion=20070822&WS=1&tag=alexanedel-20" /></a>
<a href="http://www.amazon.com/gp/product/B004Z1FTXS/ref=as_li_ss_il?ie=UTF8&camp=1789&creative=390957&creativeASIN=B004Z1FTXS&linkCode=as2&tag=bionicspirit-20"><b>Programming in Scala</b></a> 
by Martin Odersky is a good book on programming, not just Scala - many
of the exercises in
[Structure and Interpretation of Computer Programs](http://mitpress.mit.edu/sicp/)
are also present in this book, giving you the Scala-approach for
solving those problems, which is good.

<div class="clear"></div>

<a href="http://www.amazon.com/gp/product/0321774094/ref=as_li_ss_il?ie=UTF8&camp=1789&creative=390957&creativeASIN=0321774094&linkCode=as2&tag=bionicspirit-20"><img class="left" src="http://ws.assoc-amazon.com/widgets/q?_encoding=UTF8&ASIN=0321774094&Format=_SL110_&ID=AsinImage&MarketPlace=US&ServiceVersion=20070822&WS=1&tag=alexanedel-20" ></a>
<a href="http://www.amazon.com/gp/product/0321774094/ref=as_li_ss_il?ie=UTF8&camp=1789&creative=390957&creativeASIN=0321774094&linkCode=as2&tag=bionicspirit-20"><b>Scala for the Impatient</b></a>
by Cay S. Horstmann, is a good pragmatic book on Scala (not so much on
functional programming), but it's for developers experienced in other
languages, so it's fast-paced while not scaring you away with endless
discussions on types (like I just did). The PDF for the first part (out of 3) is 
available from the 
[Typesafe website](http://typesafe.com/resources/free-books).

<div class="clear"></div>

<a href="http://www.amazon.com/gp/product/1935182706/ref=as_li_ss_il?ie=UTF8&camp=1789&creative=390957&creativeASIN=1935182706&linkCode=as2&tag=bionicspirit-20"><img class="left" border="0" src="http://ws.assoc-amazon.com/widgets/q?_encoding=UTF8&ASIN=1935182706&Format=_SL110_&ID=AsinImage&MarketPlace=US&ServiceVersion=20070822&WS=1&tag=bionicspirit-20" ></a>
<a href="http://www.amazon.com/gp/product/1935182706/ref=as_li_ss_il?ie=UTF8&camp=1789&creative=390957&creativeASIN=1935182706&linkCode=as2&tag=bionicspirit-20"><b>Scala in Depth</b></a>
by Joshua Suereth D. - this is an advanced book on Scala, with many
insights into how functional idioms work in it. I've yet to finish
reading, as it's not really an easy lecture. But it's a good book. Get
the eBook straight from [Manning](http://www.manning.com/suereth/).

<div class="clear"></div>

## The End?

A sequel on what makes Clojure great will follow when I have the time
or patience for it (or once I finish reading the
[Joy of Clojure](http://joyofclojure.com/), great book btw).
