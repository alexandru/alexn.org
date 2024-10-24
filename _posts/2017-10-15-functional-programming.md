---
title: "What is Functional Programming?"
description:
  FP is programming with (mathematical) functions, there's no room for interpretation.
tags:
  - Best Of
  - FP
  - Haskell
  - Scala
  - JavaScript
image: /assets/media/articles/functions.png
generate_toc: true
created_at: 2017-10-15 08:40:38 +03:00
last_modified_at: 2023-09-29 08:51:11 +03:00
---

<p class="intro" markdown='1'>Functional Programming (FP) is programming with *functions*. [Mathematical functions](https://goo.gl/q8dToC).</p>

There's no other definition that's correct, unless it's equivalent
to this one. There's no other definition that matters.

## Background

I first read the rigorous definition of a mathematical function
in my first year of high-school, the 9-th grade. A *function*
represents a unique association between elements of a domain
(the input set) to the elements of a codomain (the output
set). This means that applying the function to some input, you always
get the same output.

My 9-th grade self actually read this in a high-school math manual:

```
Given f: A → B, ∀ x,y ∈ A
If f(x) ≠ f(y) then x ≠ y
```

And in my young mind this condition seemed obvious and redundant, but
that's what you get with mathematical rigorosity, which in our
profession is sorely needed.

<p class='info-bubble' markdown='1'>
Given that I'm from Romania, being exposed to an education centered
on rote learning, influenced by the French and the Russian / Soviet
educational systems, I'm now pretty sure that I have an atypical background,
compared to my U.S. peers. <br><br> For example we learned some
category theory in our 12-th grade, of which I'm grateful, being really
intriguing to me how some 6-figures Ivy League graduates can complain about
never hearing of the word `Monoid`, or having to learn the math material of
normal teenagers. And don't get me wrong, our educational system isn't great,
being in a continued decline.
</p>

If you want to get even more technical, functional programming has
at its foundation the
[Lambda Calculus](https://en.wikipedia.org/wiki/Lambda_calculus), a
system for expressing computations that is equivalent to Turing
machines, a universal model of computation built on function
abstraction and application.

<p class='info-bubble' markdown='1'>
Some languages like Haskell are actually compiled / reduced to
an intermediate language that's very close to Lambda Calculus,
which is cool to have as a theoretical foundation, because then you
can prove things about your language and have the ability to add new
features safely, e.g. without risking type unsoundness. As an aside, Scala
doesn't have that luxury because it's also an OOP language, so they are
developing [DOT calculus](http://lampwww.epfl.ch/%7Eamin/dot/soundness_oopsla16.pdf)
as an alternative. Interesting stuff.
</p>

## Why Functional Programming?

Many people are enamored with Functional Programming because it
gives us:

1. [Referential Transparency](https://en.wikipedia.org/wiki/Referential_transparency)
2. [Equational Reasoning](https://wiki.haskell.org/Equational_reasoning_examples)

Software has
[essential complexity](http://www.cs.nott.ac.uk/~pszcah/G51ISS/Documents/NoSilverBullet.html)
in it and it doesn't help that our tools also contribute a decent
amount of accidental complexity. If for example you think about
[asynchrony](https://en.wikipedia.org/wiki/Asynchrony_(computer_programming)) and
[concurrency](https://en.wikipedia.org/wiki/Concurrency_(computer_science)),
which often lead to
[non-determinism](https://en.wikipedia.org/wiki/Nondeterministic_algorithm),
the challenges involved have had tremendous cost for this industry.

Functional Programming keeps complexity at a manageable level because
FP components can be divorced from their surrounding context and
analysed independently. FP components can also be freely composed,
an insanely useful property in an industry where software projects
are seemingly built like houses of cards.

Memory locks for example don't compose. Two functions yielding
asynchronous results might or might not compose, depending on what
shared mutable state they access, or what condition they are waiting
on for completion.

There are a few alternatives to FP, like Rust's draconic borrow
checker, which essentially bans uncontrolled sharing. There are
advantages and disadvantages to both approaches, however if you ever
found it weird or frustrating to deal with pure functions, then
fighting Rust's borrow checker should be even more weird or
frustrating (mind you, I think Rust is awesome, but that's beside the
point).

If you no longer require purity, if you change the definition of what
kind of "*functions*" we can accept, then we are no longer talking of
Functional Programming, but about ...

## Procedural Programming

We wouldn't need the "*pure*" qualification if we, as programmers,
wouldn't overload terms.

Back in the day of assembly language and Turbo Pascal, we had perfectly
good terms for impure functions, such as:
[procedure, routine, subroutine](https://en.wikipedia.org/wiki/Subroutine),
these being blocks of code on which you jumped with the code pointer,
executed some side-effects, pushed some results on the stack, then
jumped back to where you were, with the contract being that such
subroutines had a single entry point and a single exit point.

We have had a perfectly good term for describing programming made of
procedures / subroutines: [Procedural Programming](https://en.wikipedia.org/wiki/Procedural_programming) 😉

### Impure is Uninteresting

Lately the trend is to classify code making use of "lambda expressions"
as functional programming and to classify programming languages that
have "first-class functions" as being functional programming languages.

<p class='info-bubble' markdown='1'>
"Lambda expressions" are anonymous functions that can capture the
variables in the scope they've been defined (implemented using closures).
</p>

Well, the problem is that:

1. The venerable [C language](https://goo.gl/wfmLG6) has had the
   ability to pass function pointers around since forever, I know
   of no mainstream language that doesn't allow you to pass function
   references, which makes functions "first class";
2. You don't actually need anonymous functions for doing functional
   programming, if you have an equivalent — for example Java had
   "anonymous classes" before Java 8, with the newer lambda expressions
   actually creating anonymous classes; take a look at this
   [Functional Java](http://www.functionaljava.org/) library, which was
   built before Java 8;
3. It's 2017 and most languages in use have usable lambda expressions, except
   for Python which has inherent limitations due to it being statement
   oriented and the developers refusing to introduce multi-line
   anonymous functions, which has led to a dozen or so non-orthogonal
   features to replace the need for it, under the mantra
   "*only one way of doing things*", which by now is surely some
   kind of joke.

If you reduce your "*functional programming*" qualifier
to usage of first class (impure) functions and lambda expressions,
I think the top 15 languages and their use on GitHub qualifies.

## Anti-intellectualism Phenomenon

For all the learning that we are doing, software developers are
a really conservative bunch, unwilling to accept new concepts easily
and in this context "*new*" is relative to what we've
learned either in university or at our first job. The vigor with which
we defend what we already know is proportional with the
time we've invested in our knowledge and whatever it is that we
are currently doing.

Many people advise against mentioning "*Monad*", because it will
strike fear in the hearts of the unfaithful, the advice being apparently
to either sidestep the issue, to rename it into something that can
be supposedly easier to understand, or to compare it with burritos.

Such efforts are like renaming "*Water*" into "*Drinkable*" —
which obviously makes no sense in certain contexts and deprives
people of the correct jargon for seeking help. Although I'll grant
that "*Monad*" is pretty awful if you'll look at its etymology,
but it doesn't matter, because it has evolved into a proper noun and has
been used by book authors and researchers.

Anyway, want to discredit an idea, opinion, fact, or tool?
Classify it as "*academic*", a term that now has negative connotations,
even though most interesting breakthroughs in computer science come
from academia.

## Can We do FP in Any Language?

Yes, although some programming languages are better than others.

Doing FP in a programming language like Java feels like
doing OOP in C with [GObject](https://en.wikipedia.org/wiki/GObject).
Doable, but it makes one think of switching professions in the long run.

But actually it's not the programming language that's the biggest
problem, because technical challenges can usually be worked around, but
the surrounding culture created by the community, along with the libraries
available, because as a developer you won't want to reinvent the wheel
and swim against the tide.

This is why in addition to Haskell and OCaml, which are the languages
that people refer to when speaking of FP,
[Scala](https://scala-lang.org/) also shines amongst them, because it
has managed to attract and retain talent to
work on [awesome libraries for FP](https://typelevel.org/projects/),
that don't have an equal outside of Haskell.

And for example, yes, you can do actual Functional Programming in
JavaScript and there have been libraries helping with that, including
really popular ones like
[RxJS](https://github.com/Reactive-Extensions/RxJS),
[React](https://reactjs.org/),
[Redux](http://redux.js.org/),
[Immutable.js](https://github.com/facebook/immutable-js/),
[Underscore.js](http://underscorejs.org/) amongst others,
which were partially inspired by the community's experience with
[ClojureScript](https://clojurescript.org/) and now
[ReasonML](https://github.com/reasonml),
[PureScript](http://www.purescript.org/) and others.
There are also community efforts, such as my own
[Funfix](https://funfix.org), plus a growing ecosystem around
[Fantasy Land](https://github.com/fantasyland/fantasy-land), etc.

But bring up a problem like
[JavaScript's Promise Leaks Memory]({% link _posts/2017-10-11-javascript-promise-leaks-memory.md %})
in `then` chains and dozens of developers will jump on you to
re-educate you on how promises work and to make you understand that
the concerns you have are a niche, functional programming be damned.

Which does highlight that if you want functional programming,
the communities of languages being bred for FP, like Haskell,
PureScript, OCaml, Scala, etc. are probably richer and bigger than
the FP sub-communities of the top mainstream languages, Java and
JavaScript included.

## Learning Resources

Don't believe the opinions of people on the Internet, mine included.
Learn some Functional Programming instead, the real stuff, not the
pop lambda-infused mumbo jumbo, then you can make up your own mind.
At the very least, it's fun, and you've got nothing to lose.

Thus far, I found these two books to be good as an introduction to FP:

- [Haskell Programming from First Principles](http://haskellbook.com/)
- [Functional Programming in Scala](https://www.manning.com/books/functional-programming-in-scala)

Learning Haskell first is not a bad idea, because Haskell is currently
the *lingua franca* of FP and most interesting research is happening in
Haskell or in Haskell-derived languages (e.g. Idris, PureScript, etc).
Even if you move on, you'll still refer to concepts you learned in
Haskell by name, you'll still be inspired by ideas from Haskell's
ecosystem, etc. But if you're into Scala already, then the "red book"
is pretty awesome.

After that, you might want to read
[Category Theory for Programmers](https://bartoszmilewski.com/2014/10/28/category-theory-for-programmers-the-preface/)
([PDF version](https://github.com/hmemcpy/milewski-ctfp-pdf)),
which should come only after you've gone through one of the above books
from cover to cover.

<p class='info-bubble' markdown='1'>
Note you don't need category theory for FP, but it's better if you
eventually learn the basics, since it's a formal language for talking
about *composition* and we want *composition* in our lives 😎 <br><br>
If you want motivation, remember that kids in Romania do it —
put that on your fridge 😜
</p>

More good books might be out there, but for learning FP, I'd advise
against going with anything that's dynamically typed or LISP based. For one
because dynamic languages tend to be more pragmatic, plus their limited
type system don't allow many of the useful abstractions that
we've discovered in the last decade, so you'd be depriving yourself
of many useful concepts and libraries. You should feel free to pick a
dynamic language once you have the knowledge to make an informed choice.

Also, [SICP](https://mitpress.mit.edu/sicp/full-text/book/book.html)
(see [modern PDF compilation](https://github.com/sarabander/sicp-pdf))
might have been good for its time and is still a good book,
but it's not that good for learning FP in 2017.

Now go forth and spread the true FP love 💘
