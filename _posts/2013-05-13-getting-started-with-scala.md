---
title: "Resources for Learning Scala"
tags:
  - Languages
  - FP
  - Scala
  - Books
image: /assets/media/articles/scala.png
---

<p class="intro withcap">
  Getting started with a new programming language shouldn't be hard,
  however navigating the web for resources on getting started with Scala
  can be a doubting experience, as many such resources are either out of
  date, or wrong, or both. This post is intended to reduce the noise for
  my colleagues and other people that are interested in Scala
  development.
</p>

<!-- read more -->

## 1. Tools of the Trade

All you need for getting started is the Scala interpreter and a good
text editor.

First, download the archive from
**[scala-lang.org/downloads](http://www.scala-lang.org/downloads)**,
uncompress it and place the `bin/` subdirectory on your local
`PATH`. Then start the "scala" interpreter and test if it works:

```
$ scala
Welcome to Scala version 2.10.1
Type in expressions to have them evaluated.
Type :help for more information.

scala> 1 + 1
res0: Int = 2
```

You also need a good and simple text editor that can do syntax
highlighting for Scala. Your choice should be done in this order:

* your existing favorite text editor, if you have one
* **[Sublime Text 2](https://www.sublimetext.com/)** for a good
  out-of-the-box experience, although for reasons I won't go into
  here, I really keep away from text-editors that aren't open-source    
* **[Vim](http://www.vim.org/)** or
  **[Emacs](http://www.gnu.org/software/emacs/)** (in combination with
  [scala-mode2](https://github.com/hvesalai/scala-mode2) and
  [yasnippet](https://github.com/capitaomorte/yasnippet)). These text
  editors are eternal and extremely productive, however if you're unfamiliar with neither of
  them, adding the overhead of learning them on top of learning Scala
  is a bit too much
  
Other tools you may need for *serious development* (TM), but not
necessarily for learning:

* **[SBT](http://www.scala-sbt.org/)** for building projects and
  managing dependencies, being much like Maven for Java, or Leiningen
  for Clojure, or Rake+Bundler for Ruby  
* **[IntelliJ IDEA](http://www.jetbrains.com/idea/)**, in combination
  with the [sbt-idea](https://github.com/mpeltonen/sbt-idea) plugin,
  if you need a good IDE, but seriously, when getting your feet wet,
  stay away from IDEs. The community edition is open-source and fit
  for Scala development  
* **[Typesafe Activator](http://typesafe.com/platform/getstarted)** is a
  pretty recent development if you want to play with the TypeSafe stack
  (which really means the
  [Play Framework](http://www.playframework.com/) and
  [Akka](http://akka.io/)). I haven't played with it, but it looks like
  a neat way to get some sample apps running quickly. It also includes SBT.

But really, for playing around, start with just the Scala compiler + a
text editor that does syntax highlighting for Scala. I can't stress
this enough.

## 2. Books

For getting started, at the moment (*May 2013*) ignore all books
(seriously) other than these 3:

<a href="http://www.amazon.com/gp/product/0321774094/ref=as_li_ss_il?ie=UTF8&camp=1789&creative=390957&creativeASIN=0321774094&linkCode=as2&tag=bionicspirit-20"><b>Scala for the Impatient</b></a>
by Cay S. Horstmann, is a good pragmatic book on Scala (not so much on
functional programming), but it's for developers experienced in other
languages, so it's fast-paced while not scaring you away with endless
discussions on types. The PDF for the first part (out of 3) is 
available from the 
[Typesafe website](http://typesafe.com/resources/free-books).

<div class="clear"></div>

<a href="http://www.amazon.com/gp/product/B004Z1FTXS/ref=as_li_ss_il?ie=UTF8&camp=1789&creative=390957&creativeASIN=B004Z1FTXS&linkCode=as2&tag=bionicspirit-20"><b>Programming in Scala</b></a> 
by Martin Odersky is a good book on programming, not just Scala - many
of the exercises in
[Structure and Interpretation of Computer Programs](http://mitpress.mit.edu/sicp/)
are also present in this book, giving you the Scala-approach for
solving those problems, which is good.

<div class="clear"></div>

<a href="http://www.amazon.com/gp/product/1935182706/ref=as_li_ss_il?ie=UTF8&camp=1789&creative=390957&creativeASIN=1935182706&linkCode=as2&tag=bionicspirit-20"><b>Scala in Depth</b></a>
by Joshua Suereth D. - this is an advanced book on Scala, with many
insights into how functional idioms work in it or advice on best practices. I've yet to finish it, 
as it's not really an easy lecture. But it's a good book. Get
the eBook straight from [Manning](http://www.manning.com/suereth/).

<div class="clear"></div>

*NOTE:* these are Amazon links (with my affiliate tag) placed here for
convenience and for reading other people's reviews, but if you want
the eBook version don't buy from Amazon, prefer buying directly from
the publisher, as you'll get both a DRM-free Kindle version and a PDF,
useful for desktops or iPads. 

## 3. Online Resources

An unspoken rule when searching for online resources about Scala is
that you should stay away from the *www.scala-lang.org* website,
because many links are outdated and the website is not properly
maintained, as most of the effort these days is going to the
documention project (mentioned below), which will probably become the
homepage for Scala at some point. 

**[Functional Programming Principles in Scala](https://www.coursera.org/course/progfun)**
is an excellent course provided by Coursera / EPFL, taught by Martin
Odersky. The course is almost over, so register right now if you want
access to the videos and assignments, or you'll probably have to wait
for the next iteration.

**[Scala Documentation Project](http://docs.scala-lang.org/)** -
definitely checkout this website, as they aggregate everything good
here. If you want to learn more about Scala's library, especially the
collections, this is the place to learn from. Checkout for instance
this **[Scala cheatsheet](http://docs.scala-lang.org/cheatsheets/)**.

**[Scala School](http://twitter.github.com/scala_school/)** - a freely
available online tutorial by Twitter, which is very friendly to
newbies. I've read it and it's pretty good.

**[Ninety-Nine Scala Problems](http://aperiodic.net/phil/scala/s-99/)**
- a collection of 99 problems to be solved with Scala. If you get
stuck, you can view a solution which is often idiomatic. See also this
[GitHub project](https://github.com/etorreborre/s99) that gives you a
complete test-suite, to spare you of the
effort. [Project Euler](http://projecteuler.net/) is also a pretty
cool source of problems to solve.

**[The Scala Overview at StackOverflow.com](http://stackoverflow.com/tags/scala/info)**
is a pretty cool aggregate of popular Scala questions. I don't know if
they are compiling this automatically, or by hand, but it almost feels
like an online book.

**[Online videos from nescala.org](http://nescala.org/)**. These
presentations are pure gold and a must see. At the moment, the
homepage features the videos from 2013, so start with the
[2012 archive](http://nescala.org/2012).

## 4. Whom to Follow

[The Typesafe Blog](http://typesafe.com/blog) usually contains news
regarding Scala adoptions in the enterprise, or release announcements
about Akka, Play, Scala-IDE, or whatever Typesafe is doing these days
and it's useful to follow their RSS feed.

[This Week in #Scala](http://www.cakesolutions.net/teamblogs/) is a
weekly-ish article series written by Chris Cundill of Cake Solutions,
aggregating the most interesting news happening in the Scala
community. I subscribed to their newsletter.

My Twitter and my RSS feed does have subscriptions to interesting
people from the Scala community, however following people tends to add
noise to your news stream. If you want to learn Scala, then following
people's blogs and tweats is a waist of time.

## 5. Seeking Help

For seeking help for language usage:

* [The Scala-User mailing-list](https://groups.google.com/forum/?fromgroups=#!forum/scala-user)
* [StackOverflow.com](http://stackoverflow.com/questions/tagged/scala),
  where I got some pretty cool answers on Scala-tagged questions
 
For seeking help related to usage of various Scala frameworks or
libraries, you may want to subscribe to their specific
mailing-list. For instance
[play-framework](https://groups.google.com/forum/?fromgroups=#!forum/play-framework)
for problems related to the Play framework.
