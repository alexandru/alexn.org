---
title: "On Scala 3's Optional Braces"
image: /assets/media/articles/2022-scala3-optional-braces.png
date: 2022-10-24 12:07:21 +03:00
last_modified_at: 2022-10-27 18:55:00 +03:00
generate_toc: true
tags:
  - Programming Rant
  - Scala
description: >
  I dislike Scala 3's significant whitespace syntax. At this point it's safe to say that I hate it, being (IMO) an unfortunate evolution of the language.
---

<p class="intro withcap">
I dislike Scala 3's significant whitespace syntax. At this point it's safe to say that I hate it 🤷‍♂️, being (IMO) an unfortunate evolution of the language.
</p>

As a disclaimer, this may well be a subjective opinion, so full disclosure: I have never liked working with languages that have significant whitespace syntax. On the list of languages I dislike most, CoffeeScript is in the top 3, with YAML being a close second, and I had hoped that CoffeeScript's failure will finally make the notion of significant whitespace unpopular. But significant whitespace is like a siren song that keeps coming back in language design, possibly propelled by the popularity of Python and of YAML, and I don't understand why.

<p class="warn-bubble" markdown="1">
This is a strongly worded article, using words such as "hate". I'm criticising ideas, not people, and I'm only criticising Scala's new developments because it's a language that I love. Since we don't do science, expressing feelings is perfectly adequate 😛
</p>

## Virtues of indentation-based syntax

There are some virtues of a syntax based on significant whitespace. For example, code like this is sometimes a bug:

```scala
if (x > 0)
  foo(x)
  bar(x)
```

But you can have code linters, or the compiler, to force that `{}` when `if` is used as a statement, and once you add the braces, it's much clearer what the code is supposed to do, no longer depending on whitespace. In my opinion, significant whitespace makes these instances harder to detect and solve by tooling. Think of all the copy/paste issues you can have.

```scala
if (x > 0) {
  foo(x)
}
bar(x)

// .. vs ..

if (x > 0) {
  foo(x)
  bar(x)
}
```

Also, which formatting style should you pick?

```scala
if (x > 0) {
  ...
} else if (x < 0) {
} else {
  ...
}
// ..vs ...
if (x > 0) {
  ...
} 
else if (x < 0) {
  ...
}
else {
  ...
}
```

But with tools such as Scalafmt, or `gofmt`, this is a nonissue. It's certainly not the kind of choice that has any impact on code quality, and it's not enough to require the changing of an entire language. Scala could have an official coding style, enforced via Scalafmt, and this conversation would be over.

Less boilerplate you say?

I'm one of those people that doesn't mind the `;` at the end of lines in Java. I don't miss it either, but it's trivial to automate via the IDE, and sometimes it can serve as a useful visual delimiter. Because in fact `;` separates imperative statements that are sequenced. And for `{}`, what I notice from my peers is that they often want more braces, not less. Don't you have colleagues that tend to do this?

```scala
something match {
  case Something => { // <- unnecessary, yet, desired

  }
}
```

Even though in this case the syntax is not ambiguous, some people would prefer those extra braces as a visual delimiter. It takes Scalafmt to enforce a common style, although I can never complain about extra chars meant to make the code less ambiguous.

## Scala is not Python

In Scala 3, I don't know what the motivation was, but the word is that the new syntax is supposed to make Scala 3 more appealing to Python developers. I'm going to focus on Python, since I'm assuming that few people actually like YAML. So, at the risk of building a straw-man, I want to dispel this notion that Scala can be attractive to Python developers.

First, *Python is popular in spite of its syntax*, because it's an interactive/dynamic language that's easy to learn, it comes installed by default on all Linux distributions, and it comes with useful libraries such as Numpy, Scipy, Matplotlib, and others, which makes it the de facto standard for certain domains. To try to copy Python's recipe for success, by making the syntax to have significant indentation, is shortsighted at best. I worked as a Python developer, and I can tell you that its syntax was my least favorite part.

Such cosmetic changes may look appealing, but any copied success recipe should start with Python striving to NOT be a [TIMTOWTDI](https://en.wikipedia.org/wiki/There's_more_than_one_way_to_do_it) language. And Scala 3 did, in fact, introduce even more ways to express yourself. The language that proudly allowed many ways to express yourself, such as [programming in the Klingon language](https://metacpan.org/pod/Lingua::tlhInganHol::yIghun), is Perl, which is Python's nemesis 😎. Even more, Python historically rejected multi-line anonymous functions. In [Language Design Is Not Just Solving Puzzles](https://www.artima.com/weblogs/viewpost.jsp?thread=147358), Guido van Rossum says about a proposal for multi-line lambdas:

> But such solutions often lack "Pythonicity" -- that elusive trait of a good Python feature. It's impossible to express Pythonicity as a hard constraint. Even the Zen of Python doesn't translate into a simple test of Pythonicity.
>
> ... And still that's not why I rejected this proposal. If the double colon is unpythonic, perhaps a solution could be found that uses a single colon and is still backwards compatible (the other big constraint looming big for Pythonic Puzzle solvers). I actually have one in mind: if there's text after the colon, it's a backwards-compatible expression lambda; if there's a newline, it's a multi-line lambda; the rest of the proposal can remain unchanged. Presto, QED, voilà, etcetera.
>
> But I'm rejecting that too, because in the end (and this is where I admit to unintentionally misleading the submitter) I find **any solution unacceptable that embeds an indentation-based block in the middle of an expression**. Since I find alternative syntax for statement grouping (e.g. braces or begin/end keywords) equally unacceptable, this pretty much makes a multi-line lambda an unsolvable puzzle.

I find this quote very interesting, as it says that in Python significant indentation is reserved for grouping statements, and is not for describing expressions. Guido certainly finds the distinction between groups of statements and expressions to be an important one. I think it's pretty clear that Scala's new (fewer-braces) syntax is not "pythonic":

```scala
xs.map: x =>
  val y = x - 1
  y * y
```

And I seriously fail to see how it improves on:

```scala
xs.map { x =>
  val y = x - 1
  y * y
}
```

Reading the [Zen of Python](https://peps.python.org/pep-0020/) should make it clear that Scala is, at this point, a very unpythonic language. Note that I always found it odd that Python has the "only one way to do it" mantra, since in practice that's very far from true, but at least it tries.

## New syntax is unclear

One thing that I really don't get is the `end` marker:

```scala
def largeMethod(...) =
  ...
  if ... then ...
  else
    ... // a large block
  end if
  ... // more code
end largeMethod
```

Python does not have an `end` marker, Ruby or Pascal do. You could say that Python has the virtue of forcing you to keep your functions short, since obviously, indentation-based syntax is problematic for big blocks of code. I never bought that, which is why an "end marker" makes sense, except that Scala has already had a perfectly usable syntax that made use of `{}` braces. And no matter how much more readable you find this new end marker to be, the ensuing TIMTOWTDI is just not worth it.

Braces were already optional in Scala, in the case of expressions. For example, method definitions could omit braces, in case the implementation was a single expression. If you needed multiple statements, or in case you needed a [lexical scope](https://en.wikipedia.org/wiki/Scope_(computer_science)), you added the braces. Braces are super useful for hiding implementation details in the local scope:

```scala
val y = something()
val x = {
  // `y` and `z` can shadow values in the enclosing scope
  // and are no longer visible after this scope ends
  val y = foo()
  val z = bar()
  y + z
}
```

This is such a beautiful syntax. IMO, lexical scopes need visual delimiters that are more significant than indentation. It may be important to mention that scoping in Python is at the "enclosing-function" level. You can't do what I just did here with Scala, unless you create a closure, and then execute it. Which kind of makes sense, since establishing the scope by the indentation level seems to be pretty ambiguous.

```python
# Python code
y = something()
# creating new lexical scope
def createX():
  y = foo() # shadowing
  z = bar()
  return y + z
x = createX()
```

In Scala 2, groups of statements needed braces, expressions didn't. What those braces meant (a group of statements, also creating a lexical scope) was simple to explain. In Scala 3 this now changes.

## Tooling is problematic

Another problem we have is one of **tooling**. Scala 3 is a language that's harder to parse than Scala 2. Syntax based on indentation is context-sensitive. IDEs, like IntelliJ IDEA or Metals, or tools like Scalafmt, now have to do more work. My own website isn't able to correctly do syntax highlighting for Scala 3 yet.

And simple things, like copy/pasting a piece of code, are a problem because the IDE now has to guess the correct indentation level.

## On backwards compatibility

Languages evolve, but there is such a thing as too much evolution, for the simple reason that backwards compatibility has to be provided, otherwise you're effectively talking about a new language, and nobody is going to adopt the new version. This is why Scala will have to support both the old and the new indentation-based syntaxes for a very, very long time. Which means that projects will have to depend on compiler options (e.g., `-no-indent`), or on tools, such as Scalafmt, to impose the blessed syntax rules. And, don't get me wrong, Scalafmt is great, but I considered it optional, whereas now it becomes mandatory. This is similar to introducing the [using/given syntax](./2022-05-11-implicit-vs-scala-3-given.md), which is nice, but the old `implicit` keyword is still there, so it leads to more complexity, not less.

Java's slow evolution makes a lot of sense. Love it or hate it, you can probably take a JAR compiled with Java 1.1, and it would still run on the latest JVM, and that Java 1.1 code probably compiles as well. There are some exceptions, but those are very few and far between. Java's devotion to backwards compatibility is what propelled it to be considered a platform you can depend on, being in the same league as POSIX. Developers may not like its generics, its boilerplate, or its culture of libraries doing runtime introspection to workaround language issues. But at least its syntax won't dramatically change overnight, and those Python developers probably learned Java in school, so they can always get back to it.

Scala 3 is succeeding in sending a message that it's not Java++, but it's not doing so in a way that I find appealing.

## In closing

What I expected from Scala 3 was a simplification of Scala 2. It does simplify in some ways, e.g., macros are better, the type system fixes some holes, I love untagged union types, etc. But it also introduces complexity of its own, and for no good reason that I can see.

I think it's too late to backtrack on these changes, significant-indentation syntax is probably here to stay (not in my projects), but one can hope.
