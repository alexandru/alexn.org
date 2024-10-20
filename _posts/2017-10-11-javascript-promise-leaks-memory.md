---
title: "JavaScript's Promise Leaks Memory"
redirect_from:
  - /blog/2017/10/11/javascript-promise-memory-unsafe.html
description:
  JavaScript's Promise leaks memory in recursive loops and what you can do about it.
tags:
  - Concurrency
  - FP
  - JavaScript
image: /assets/media/articles/js-then.png
image_hide_in_post: true
generate_toc: true
---

## Introduction

This piece of code will leak memory and eventually crash your Node.js
process or browser:

```typescript
// Tested on Node.js 7.10, Firefox 57 and Chrome 61
//
// Usage of `setImmediate` is to prove that we have
// async boundaries, can be removed for browsers
// not supporting it.

function signal(i) {
  return new Promise(cb => setImmediate(() => cb(i)))
}

function loop(n) {
  return signal(n).then(i => {
    if (i % 1000 == 0) console.log(i)
    return loop(n + 1)
  })
}

loop(0).catch(console.error)
```

<a href="/assets/html/js-promise-leak.html" target="_blank"><b>→ Load Sample for Browser</b></a>

It takes a while to fill GBs of heap, plus Node is less conservative, the GC eventually
freezing the process trying to recover memory, so give it a few seconds.

This is equivalent with this `async` function:

```typescript
async function loop(n) {
  const i = await signal(n)
  if (i % 1000 == 0) console.log(i)

  // Recursive call
  return loop(n + 1)
}
```

Of course, if this loop would be synchronous, not using `Promise` or `async` / `await`,
then the process would blow up with a stack overflow error because
at the moment of writing JavaScript does not do
[tail calls optimizations](https://en.wikipedia.org/wiki/Tail_call)
(until everybody implements ECMAScript 6 fully at least).

But before you jump to conclusions, this has nothing to do with JavaScript's
lack of TCO support. This is because in our recursive function it's
not JavaScript's [call stack](https://en.wikipedia.org/wiki/Call_stack)
that's managing that loop, but rather the `Promise` implementation.
That recursive call is asynchronous and so it does not abuse the call stack
by definition.

Unfortunately, just like a regular function using the call stack for those
recursive calls, the `Promise` implementation is abusing the heap memory,
not chaining `then` calls correctly. And that sample should not leak,
the `Promise` implementation should be able to do the equivalent of TCO
and in such a case eliminate frames in the `then` chain being created.

## The Spec is The Problem

<figure>
  <a href="https://promisesaplus.com/">
    <img src="{% link /assets/media/articles/js-then.png %}" />
  </a>
</figure>

We're talking of the [Promise/A+ specification](https://promisesaplus.com/).
Relevant links to known issues on GitHub, explaining why:

1. Node.js issue, now closed:
   **[node/#6673](https://github.com/nodejs/node/issues/6673)**
2. Promise/A+ spec issue, open since 2014:
   **[promises-spec/#179](https://github.com/promises-aplus/promises-spec/issues/179)**

As you'll see, there are some reasonable arguments for why the `Promise`
implementation is allowed to leak memory. But I can't agree.

## The Non-leaky Solution

The solution, if you insist on using JavaScript's `Promise`, is to work
with non-recursive functions:

```typescript
async function loop(n) {
  let i = 0

  while (true) {
    i = await signal(i + 1)
    if (i % 1000 == 0) console.log(i)
  }
}
```

But at this point any semblance of functional programming, if you ever had
any, goes out the window, see below.

## Common Objections

Gathering feedback from people, here are the common objections:

### 1. This is Normal

No, if you judge this implementation, relative to other `Promise` / `Future`
implementations in the industry, which are setting expectations.

Here are the implementations that I know about that DO NOT leak memory:

1. [Bluebird](http://bluebirdjs.com/docs/getting-started.html), probably
   the most popular non-standard `Promise` implementation for JavaScript
2. [Scala](https://www.scala-lang.org/)'s standard
   [Future](http://www.scala-lang.org/api/2.12.3/scala/concurrent/Future.html),
   in the wild since 2013; the fix for the leaky `flatMap`
   chains was added by [Rich Dougherty](https://x.com/richdougherty)
   in [this PR](https://github.com/scala/scala/pull/2674), inspired
   by Twitter's `Future` implementation
3. Twitter's [Future](https://twitter.github.io/util/docs/com/twitter/util/Future.html),
   which is used in all of Twitter's backend infrastructure, being integrated
   in [Finagle](https://twitter.github.io/finagle/)
4. [Trane.io](http://trane.io/), a Java Future implementation providing a `TailRec`
   builder meant precissely for this use-case
5. My very own Funfix [Future](https://funfix.org/api/exec/classes/future.html)
   and Monix [CancelableFuture](https://monix.io/api/3.0/monix/execution/CancelableFuture.html)

Interestingly, complaints for Scala's `Future` happened due to usage of
Play's [Iteratees](https://www.playframework.com/documentation/2.6.x/Iteratees),
with which people have been modeling stream processing.

### 2. But It Does Unlimited Chaining of Promises

Yes, that's why it's leaking memory.

No, the implementation should not chain promises like that and an
alternative implementation is possible and well known, as evidenced by
the implementations mentioned that don't leak.

The fault lies with the standard `Promise` implementation, not with
the shown sample, being a legitimate use-case.

### 3. That Sample Does Not Use the Return Value

The sample is kept simple for didactic purposes, however:

1. you can easily imagine a loop that processes a very long stream of data,
   aggregating information along the way, returning a result later
2. the script does do error handling and without that inner
   `return`, the `.catch(console.error)` would have no effect

### 4. That's the Equivalent of a Stack Overflow

Yes, I've mentioned this above, but just to set your mind at rest on this point,
proper Tail-Calls Optimizations are coming for normal call sites, being part of
ECMAScript, see:

- [ECMAScript specification](http://www.ecma-international.org/ecma-262/6.0/#sec-tail-position-calls)
- [ECMAScript 6 Proper Tail Calls in WebKit](https://webkit.org/blog/6240/ecmascript-6-proper-tail-calls-in-webkit/)

You can't rely on it yet, but you can rest assured that in the future
if that sample would be synchronous, it would not trigger a stack overflow.

Therefore, given that asynchronous calls are by definition processes / events
happening independently of the current call stack / run loop, this behavior
is actually surprising, since one of the reasons to go async is to escape
the limitations of the call stack.

### 5. You Don't Understand How Promises Work

I've been told that I don't understand promises. So I apologize for the
appeal to authority that I'm about to make.

Data types for dealing with *asynchrony* have been a hobby of mine since
2012 and I've been authoring several projects in which I implemented
Promise-like data types:

- [Monix](https://monix.io/), which implements `Task`, one of the best ports
  of Haskell's `IO`, along with a complementary `CancelableFuture` and
  what I think is the best back-pressured Rx `Observable` implementations
  in existence
- [Funfix](https://github.com/funfix/funfix), a JavaScript library for FP,
  delivering a `Future` and an `IO` implementation, see below
- have contributed to [cats-effect](https://github.com/typelevel/cats-effect),
  a more conservative `IO` port

<p class='info-bubble' markdown='1'>
Bonus — see my [presentation from Scala Days](https://www.youtube.com/watch?v=wi97X8_JQUk)!
</p>

My work, good or bad, has followed a certain pattern, which is why I do
understand promises, I do understand at least two solutions to this, hence
this article.

### 6. No Use-cases, This is a Niche

Functional programming might be a niche, however more and more projects,
including at big companies such as Facebook, are now using an
[actual FP style]({% link _posts/2017-10-15-functional-programming.md %}).

You cannot describe any functional programming algorithm involving loops
without tail recursions. If folds are used, then folds are described with
tail recursions as well. That's because:

1. any loop can be described with a tail recursion
2. you can't have immutability of the state you're evolving without it

An example of a use-case is the processing of really long / infinite streams of
events, for which it's really natural to describe algorithms using tail recursions
and for which you can't really work with imperative, mutation-based loops.

Imagine reading chunks of data from a file and describing them with a data
structure like this:

```typescript
interface List<A>

class Next<A> implements List<A> {
  constructor(
    public readonly head: A,
    public readonly next: () => Promise<List<A>>
  ) {}
}

class Halt implements List<A> {
  constructor(public readonly error?: any) {}
}
```

Sample is using TypeScript (could be Flow) for making it clear what the types are.
You can work with plain JavaScript of course.

This structure is really cheap and effective, being a lazy, asynchronous,
referentially transparent stream. And in fact it's really similar to JavaScript
implementations of async iterators, so yes, you are going to work with
something like this in the future, even if you don't like it ;-)

And describing transformation functions like this one is really fun too:

```typescript
function map<A, B>(list: List<A>, f: (a: A) => B): List<B> {
  if (list instanceof Next) {
    try {
      const cons = list as Next<A>
      return new Next(f(cons.head), () => cons.next().then(xs => map(xs, f)))
    } catch (e) {
      return new Halt(e)
    }
  } else {
    return list
  }
}
```

Alas, with the `Promise` implementation leaking, this doesn't work ;-)

## Alternatives

### Fluture

Project Page: [github.com/fluture-js/Fluture](https://github.com/fluture-js/Fluture)

This is the most popular `Promise` alternative that I know of.

It isn't a direct replacement however because it has lazy behavior, being meant for suspending side effects. This is more like an `IO` data type. Which is cool, you should use something like it, but it's also apples vs oranges.

I don't have enough experience with it, making this recommendation solely based on its popularity and I double checked that it indeed preserves stack safety.

### Funfix

I've been building a new project, [Funfix](https://funfix.org/),
a JavaScript library for functional programming (capital FP), supporting
[TypeScript](https://www.typescriptlang.org/) and [Flow](https://flow.org/)
types out of the box.

Funfix exposes [Future&lt;A&gt;](https://funfix.org/api/exec/classes/future.html), an
eager `Promise` alternative that's safe, cancellable and filled with goodies,
along with [IO&lt;A&gt;](https://funfix.org/api/effect/classes/io.html), a lazy, lawful,
cancellable data type for handling all kinds of side effects, inspired by Haskell,
the two being complementary.

This piece of code powered by `Future` does not leak:

```typescript
import { Future } from "funfix"

function loop(n) {
  return Future.of(() => n).flatMap(i => {
    if (i % 1000 == 0) console.log(i)
    return loop(n + 1)
  })
}

loop(0).recover(console.error)
```

And neither does this one, powered by `IO`:

```typescript
import { IO } from "funfix"

function loop(n) {
  return IO.of(() => n).flatMap(i => {
    if (i % 1000 == 0) console.log(i)
    return loop(n + 1)
  })
}

loop(0).run().recover(console.error)
```

This `IO` is a port of [Monix](https://monix.io/)'s
[Task](https://monix.io/docs/2x/eval/task.html), being a better
`IO` than Haskell's `IO` due to its cancellable nature ;-)

In [this PR](https://github.com/funfix/funfix/pull/57) I've also
fixed the memory leak for `Future`, doing the same tricks that
Scala's [Future](http://www.scala-lang.org/api/2.12.3/scala/concurrent/Future.html)
is doing. Now released in [v6.2.0](https://github.com/funfix/funfix/releases/tag/v6.2.0).

And note that this is harder to do for Funfix's `Future` due to also
having to deal with chains of `Cancelable` references, which can
also leak.

<p class='info-bubble' markdown='1'>
**Author's Rant —** in response to this article I've been called a scumbag
for "*shameless self promotion*".<br><br>
I'm building stuff that I share with the world and I like talking about
it on my personal blog. I'm not going to apologize for it.
</p>

## Final Words

That the current JavaScript `Promise` implementation has this leak
is a big problem, because tail-recursive calls are the cornerstone
of functional programming.

Yes, it's true that `Promise` is not a useful monadic type for doing FP,
since it does not suspend side effects (which is why you should
use [IO](https://funfix.org/api/effect/classes/io.html)), but that's
beside the point, plus for the FP purists out there, you can always
suspend it in a thunk, assuming that it doesn't leak in `then` chains.

This is also why I fear standardization by committee in general. Along with
the totally awkward `then` signature that can't be safely described with
TypeScript's or Flow's types, this is another example of how standard
solutions can be harmful, because by being pushed as a standard, it makes
it hard for alternatives to exist, since most people are just going to
use the standard implementation, especially in JavaScript's ecosystem
where people are afraid to take on dependencies.
