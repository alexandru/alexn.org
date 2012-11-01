---
layout: post
title: "On Scala versus other languages"
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

I've fallen in love with both and I can't really pick a
favorite. However other developers tend to be grossly polarized on
this issue, with lots of inaccurate opinions flying around, so for
what is worth this is my analysis on why you should love Scala too.

A sequel on what makes Clojure great will follow when I have the time
for it.

## 1. Functional Programming for the Win

It's not a silver bullet, but on the whole it's awesome. You really
have to experience it, while leaving aside the preconceptions and
biases you've been building up by honing those imperative skills for
years. Students learn functional programing more easily, because they
are fresh, otherwise the learning experience is a little painful.

We need some definitions though. On functional programming:

* deals with computation by evaluating functions with
  [referential transparency](http://en.wikipedia.org/wiki/Referential_transparency_(computer_science))
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

### 1.1 - Polymorphism À la Carte

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
way - all of these use-cases are cumbersome.

Haskell deals with it through
[Type Classes](http://en.wikipedia.org/wiki/Type_class). Clojure deals
with this through
[multi-methods](http://en.wikipedia.org/wiki/Multiple_dispatch) and
protocols, protocols being the dynamic equivalent for type-classes for
a dynamic type-system.

### 1.2 - Yes Virginia, Scala has Type-Classes

So what's a type class? It's like an interface in Java, except that
you can make any existing type conform to it without modifying the
implementation of that type.

As an example, what if we wanted a generic function that can add
things up ... you know, like a `foldLeft()`, but rather than
specifying how to fold, you want for each type to know how to do that. 

There are several problems with doing this in Java:

- there is no interface defined for "`+`" on types that support addition
  (like integers, BigInteger, BigDecimal, floating-point numbers,
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

So what makes this interface a type-class? Let's look at how we'll
implement our `sum()` function that uses this:

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
define them in the companion object of trait `CanFold`, like this:

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

### 1.3 - Scala's Collections Library is Awesome

So what does the above buy you anyway. The following are some examples
from Scala's collections library.

You can sum things up in Lists, as long as you have an implementation
of type-class `Numeric[T]` in scope:

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
what happens when you do this:

{% highlight scala %}
BitSet(1,2,3,4).map(x => "number " + x.toString)
//=> Set[java.lang.String] = Set(number 1, number 2, number 3, number 4)
{% endhighlight %}

Again, it did the right thing, because you can't store Strings in a
BitSet, as BitSets are for integers. So it returned a plain Set of
strings. How is this possible, you may ask?

The answer is in the
[CanBuildFrom](http://www.scala-lang.org/api/current/scala/collection/generic/CanBuildFrom.html)
pattern. The signature of `map()` used above is this one:

{% highlight scala %}
def map[B, That](f: (A) => B)(implicit bf: CanBuildFrom[BitSet[A], B, That]): That
{% endhighlight %}

So, similar to my example with `CanFold`:

- the compiler takes types A and B from the mapping function `f: (A) => B` that's provided as an argument
- searches for an implicit in scope of type `CanBuildFrom[A, B, _]`
- the return type is established as the third type parameter of the implicit param that is used
- the actual building of the result is externalized; the BitSet does
  not need to know how to build Sets of Strings

What's great is that the provided implicits for `CanBuildFrom` can all
be overridden by your own implementations (type-classes biach).

(as a side note, Clojure cannot do this, even if the Seq protocol is awesome nonetheless)

### 1.4 - Is this complex?

I mentioned above that this stuff is not complex, it's just
hard. Scala does have complexities when it comes to really advanced
use-cases, as can be seen in this article:
[True Scala Complexity](http://yz.mit.edu/wp/true-scala-complexity/)

It's worth mentioning however that, as Martin Odersky noted in the
HackerNews thread of that article, the author tries to accomplish
something that's not possible in most languages out there, while a
solution is still possible in Scala (albeit with small limitations).

### 1.5 - Scala versus Haskell

Scala's static type-system is less expressive than that of Haskell. In
particular Haskell supports
[rank-2 polymorphism](https://en.wikibooks.org/wiki/Haskell/Polymorphism#Higher_rank_types),
while Scala only rank-1. So Scala does not win many points on Haskell,
but it definitely wins on this one:

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
library are more composable. It's also worth pointing out that Scala's
collections library is so awesome precisely because OOP plays a part
and there are cases where doing similar things in Haskell require
experimental GHC extensions.

### 1.6 - Scala versus F#/Ocaml

Type-classes in F#/Ocaml can only be manually implemented. These
languages are awesome too, however you really start wishing for an
ad-hoc polymorphism mechanism in which the types are open.

F# takes the crown as the ugly ducklin' as it follows the (really
screwed) C# conventions of defining "`+`" as static functions on
classes, so even if you know that a T is an Integer, you can't sum 2
Integers because the compiler cannot make the connection to `T + T`,
as OOP interfaces/subtyping only applies to instances, not classes
themselves. Take a look at the signature for `List.sum` in F#:

{% highlight ocaml %}
List.sum : ^T list -> ^T (requires 
  ^T with static member (+) and ^T with static member Zero)
{% endhighlight %}

First of all, this is bad from all perspectives, as it uses the
(really screwed) notion of "*static methods*" that should have never
happened in OOP, mixing it with the notion of OOP interfaces (so you
can't consider them as being plain functions anymore). This is fucked
up actually. It's also not a type-class as it is *not open* - you
cannot modify a built-in type to have the required static members,
being the same problem you get with classic OOP inheritance of
interfaces. You also cannot override the implementation, as you'd wish
in certain contexts.

The right way to do this in Ocaml/SML would be to explicitly pass a
dictionary of implementations around, as described here:
[Typeclass overloading and bounded polymorphism in ML](http://okmij.org/ftp/ML/ML.html#typeclass).

By contrast to F# in Scala there is no such thing as "*static
methods*", "`+`" operations being plain polymorphic instance
methods. You also do not have 2 type-systems in the same language, as
Scala follows the "*uniform access principle*". Type-classes and
algebraic data-types are still modeled by means of OOP classes and
objects. The code is indeed more verbose, but it reduces complexity a
lot because a big part of learning Ocaml is learning when OOP is
appropriate, or not, as you have to pick from the get-go and combining
approaches is very cumbersome. Granted Ocaml at the very least
improves on classic OOP by giving you *structural typing*.

Take for instance the definition of an immutable and persistent
List. A List can be defined as an algebraic data-type, being either an
Empty List, or a Tuple of 2 elements, the head and the tail, right?

{% highlight scala %}
sealed abstract class List[+T]
case class Pair[+t](head: T, tail: List[T]) extends List[T]
case object Nil extends List[Nothing]
{% endhighlight %}

One difference should immediately be noticeable, our `List` has
covariant behavior, meaning that a `List[Any]` is a supertype for
`List[String]`. Arrays in Java have the same behavior and this leads
to lots of gotchas, but if our List is immutable, then this is not a
problem. For instance this gives you polymorphic behavior without
needing type parameters or higher-kinded types:

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
  def length = 0
}

case class Pair[+T](head: T, tail: List[T]) extends List[T] {
  override val length = 1 + tail.length
}
{% endhighlight %}

Now, isn't that nice? It works for lazy lists too. You just have to
make the `length` definition a `lazy val` and presto. And you didn't
have to choose how to represent Lists, picking the design that makes
sense for the operation in question.

### 1.7 - On Static-type Systems

Static versus dynamic is what polarizes developers most in separate
camps. It's like a never-ending flamewar, with lots of religiosity
flying around.

At its core, a static type system helps you by providing proof at
compile-time that the types you're using behave as you expect them to
behave. This is good, because you need all the help you can get and
static typing can eliminate a lot of errors.

This is a doubly-edged sword though. By definition a static type
system will reject pieces of code that are perfectly correct. Also,
it's not a silver bullet, as Rich Hickey said in his excelent
[Simple Made Easy](http://www.infoq.com/presentations/Simple-Made-Easy)
talk (paraphrasing): "*What's the common thing that all bugs in the
wild share? They passed the type-checker, they passed all the
tests!*"

I've seen opinions that "*structural typing*" (Go, Scala) or
"*type-inference*" (Ocaml, Haskell, Scala), are as good as "*duck
typing*". That couldn't be further from the truth - the real power of
duck typing comes from the ability to create / modify types and
functions on the fly at runtime. In other words you can make shit up
and as long as it's correct, then it works. In contrast, a static type
system actively rejects pieces of code if it can't prove that the
types you're using support the computation you're trying to do, so no
matter how smart the type system is, you'll always end up in lots of
instances where you have to spoon-feed the compiler to allow you to do
what *you mean* (but not all compilers are equal here).

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
about exceptional state and deal with it.

Thinking of Scala versus Clojure and Haskell, in regards to its
static-type system Scala sits somewhere in the middle. This is both
good and bad. On one hand Scala does not have the same (static)
expressive capabilities of Haskell, being a poor substitute for it. On
the other hand you can drill holes in that static-type system to make
it do what you want, which I think is a good trade-off.

I personally lean towards dynamic type systems, however the tradeoffs
I end up making in Scala are worth it for the extra type safety it
brings. On the other hand with Clojure, because of its support for
multi-methods and protocols and macros, is a dynamic language that's
more expressive than most other dynamic languages, especially the
mainstream ones, like Python, Ruby, Perl, Javascript or PHP.

But more on that in the sequel on Clojure I promised.


