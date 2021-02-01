---
title: "I like Option.get"
date: 2020-11-12 20:02:46+0200
tags:
  - FP
  - Scala
  - TypeScript
description: We should strive to make illegal states unrepresentable. `Option.get` is a partial function that, according to many, shouldn't be in the standard library. Yet it doesn't bother me; the inability of Scala to make it safe is the problem.
image: /assets/media/articles/option.get.png
---

In strong, static, expressive FP languages, such as Scala, or Haskell, there's the ongoing drive to "*capture invariants in the type system*" and "*to make illegal states unrepresentable*". For a nice introduction, see [Parse, don't validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/) by Alexis King.

`Option.get` or `List.head` get such bad reps because these functions aren't total. To wit:

```scala
val value: Option[String] = None

value.get
//=> java.util.NoSuchElementException: None.get
//     at scala.None$.get(Option.scala:627)
```

This is indeed bad, because it fails at runtime. And if it fails at runtime, this means it can fail in production, in spite of all our unit tests and fancy CI setup.

In fairness, even with the current status quo, `option.get` is still better than usage of `null`, because developers are still aware that the value might be missing (by seeing the type, then having to call `.get`, at the very least), and even in absence of such mindfulness, at least the exception is clearer, as `NullPointerException` is often thrown due to faulty internals, and JVM initialization timing issues. At least you know it's your own fault 🙂

 If `get` wasn't available on `Option`, then you'd be forced to do this:

```scala
value match {
  case Some(v) => v
  case None => "unknown"
}
// Or this ...
value.getOrElse("unknown")
```

And if you'd miss a case, you'd get a warning (or an error, if you work with [fatal warnings](./2020-05-26-scala-fatal-warnings.md)):

```scala
value match { case Some(v) => v }
//=> warning: match may not be exhaustive.
//   It would fail on the following input: None
```

The compiler can thus force you to deal with `None` explicitly.

All of that aside however, in the following piece of code, what's wrong isn't the presence of `Option.get`, but rather the compiler's inability of seeing the `if` expression:

```scala
// This is correct and will never trigger runtime exceptions
if (option.nonEmpty)
  option.get // Like a boss 😎
else
  "unknown"
```

In other words, I'll blame Scala and Haskell, and not the availability of `Option.get`. I learned to expect more from my tools. It's not me, it's you, Scala.

We could say that in absence of compiler features to cope with this, then `.get` shouldn't exist. However, programming languages are general purpose, and often get used in contexts in which strong static guarantees are not only useless, but get in the way. I still [build my scripts in Ruby](./2020-11-11-organize-index-screenshots-ocr-macos.md), because the static languages that I love are really bad for scripting. I'd like to disable some static guarantees, whenever brevity is important, and not correctness. E.g. for my own throwaway scripts I couldn't care less that `Option.get` throws exceptions.

TypeScript has untagged unions, and under `--strict` this throws an error:

```ts
const sample: number | null = null

sample + 10
//=> error TS2531: Object is possibly 'null'.

// This works
if (sample !== null) {
  sample + 10
}
```

`Option` being boxed (tagged) provides us with benefits, like the ability to express `Option<Option<A>>` (without auto-flattening), or the ability to define monadic operations for it. Here's one way to express `Option` in TypeScript:

```ts
type None = {
  nonEmpty: false
}

type Some<A> = {
  nonEmpty: true
  value: A
}

type Option<A> = Some<A> | None

// ----------------------------------

const sample: Option<String> = 
  { nonEmpty: false } // None

sample.value
//=> error TS2339: Property 'value' does not exist on type 'Option<String>'.
//   Property 'value' does not exist on type 'None'.

// Compiles just fine
if (sample.nonEmpty) {
  console.log( sample.value )
}
```

This is called [Flow-sensitive typing](https://en.wikipedia.org/wiki/Flow-sensitive_typing). And minus some limitations and gotchas, it works just fine.

I hope Scala will evolve to do it too, because TypeScript, and Kotlin can already do this 🙂 and it would be a shame for Scala to not evolve such abilities, to go along with its brand new [untagged union types](https://dotty.epfl.ch/docs/reference/new-types/union-types.html).
