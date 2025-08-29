---
title: "Scala's Gamble with Direct Style"
image: /assets/media/articles/scala-stairs.jpg
image_caption: The staircase at EPFL that inspired Scala's logo.
date: 2025-08-29T08:33:16+03:00
last_modified_at: 2025-08-29T11:15:15+03:00
tags:
  - FP
  - Opinion
  - Programming Rant
  - Scala
  - Scala 3
description: >
  Scala does not move in the direction of more monadic IO, but rather in the direction of "direct style", preferring continuations to monads, but without providing support for continuations out of the box.
---

<p class="info-bubble" markdown="1">
  This is a more superficial article, i.e., an opinion piece. I'm making it my mission, again, to publish more thoughts on my own blog.
</p>

Scala has had a wide ecosystem for functional programming™️ directly inspired by Haskell and OCaml, due to its expressive type system and support for both type class encodings and OOP. As such it has inspired not one, but multiple runtimes for monadic IO, such as [Cats-Effect](https://typelevel.org/cats-effect/), [ZIO](https://zio.dev/), [Kyo](https://getkyo.io/). And these libraries served as an inspiration for others, see [Effect-TS](https://effect.website/).

Yet, Scala 3, the language, does not move in the direction of more monadic IO, but rather in the direction of "direct style", preferring continuations to monads, but without providing support for continuations out of the box. There are some attempts to fill that gap:

1. The [dotty-cps-async](https://github.com/dotty-cps-async/dotty-cps-async) approach is IMO the best bet, even for retrofitting monadic IO to direct style. But in my limited experience, it has edge cases, and in the projects making use of it, like [Cats-Effect](https://github.com/typelevel/cats-effect-cps) (possibly [ZIO](https://zio.dev/zio-direct/) or [Kyo](https://getkyo.io/#/?id=direct-syntax) as well), this support isn't used much. For example, one reason this happens is because the interruption model is different from that of the JVM, e.g., if you don't turn a cancellation into an `InterruptedException`, it won't blend well with the language's constructs, like `try-catch-finally`. But also, support not being part of the actual language, in this case, may mean the implementation is cursed to battle edge cases and bugs forever.
2. [gears](https://github.com/lampepfl/gears/) builds on top of virtual threads for the JVM, and it supports Scala Native as well. It can support WASM via [WASM JSPI](https://v8.dev/blog/jspi), possibly in the next release. So it builds on the runtime's support for either blocking threads or (one-shot) continuations. That's incredibly limiting. For example, it has no JavaScript support and blocking threads is still very taxing on JVM-like platforms that don't have virtual threads, such as Android. And obviously, execution cannot be fine-tuned, and you don't have the abilities of a user-space runtime such as that of Cats-Effect or ZIO.
3. [ox](https://github.com/softwaremill/ox) is a JVM library for blocking threads and doesn't make any attempts of supporting anything else but the JVM. If you work on the JVM, I guess that's fine, although the library will be somewhat less useful after [Structured Concurrency lands in Java 25](https://rockthejvm.com/articles/structured-concurrency-jdk-25). If we want to go back to blocking threads (with mostly the same caveats applying), I guess that's acceptable with the support for virtual threads since Java 21, but what about Scala Native, JS or Wasm? Ox is a cool library and may be right for a lot of projects, but for the ecosystem, if Scala doesn't escape the JVM, or at least JVM-isms, it's far less interesting than the next versions of Java (which will also have [type-classes](https://www.youtube.com/watch?v=Gz7Or9C0TpM) BTW).

Keep the above in mind and compare with Kotlin:

- [Kotlin Coroutines](https://github.com/Kotlin/kotlinx.coroutines) have multi-platform support, and this means — JVM, Android, iOS (Native), JS and WasmGC.
  - Watch [Structured concurrency](https://www.youtube.com/watch?v=Mj5P47F6nJg) by Roman Elizarov to get a sense of the design considerations that went into it. This isn't your grandpa's async/await.
  - Those coroutines, along with its support for context parameters, can be leveraged not just for I/O, but also for handling of resources in general, matching Scala's libraries such as Cats-Effect and ZIO (see [Arrow](https://arrow-kt.io/learn/coroutines/resource-safety/)).
- [Multiplatform](https://www.jetbrains.com/kotlin-multiplatform/) support is top-notch. It has a [growing ecosystem of libraries](https://klibs.io/), with [Compose Multiplatform](https://www.jetbrains.com/compose-multiplatform/) having stable iOS support and getting contributions from Google and others.
- It's a language that evolves as well. For instance, [context parameters](https://github.com/Kotlin/KEEP/blob/context-parameters/proposals/context-parameters.md) are almost here, [rich errors](https://www.youtube.com/watch?v=IUrA3mDSWZQ) as well, and it may even get better [immutability support](https://www.youtube.com/watch?v=qpM3_ymNkP8) before Scala.

Scala is still my preferred language by far, and it obviously relies more on community and less on commercial support. I actually loved that about Scala, but there's an elephant in the room that will have to be addressed...

Scala 2.x thrived due to making it saner to work with asynchronous I/O and concurrency. But the world isn't standing still. Scala could've taken the path of [F#'s computation expressions](https://learn.microsoft.com/en-us/dotnet/fsharp/language-reference/computation-expressions), thus improving the ergonomics of working with monadic IO. Scala could also include support for continuations out-of-the-box. Scala 3 does neither of those things, which means monadic IO is not getting the support it needs in order to be mainstream and the *"direct style"* approaches are currently in limbo.

In other words, Scala is alienating the part of the community that builds cutting-edge, user-space I/O runtimes that are the envy of the industry, while not providing the support required for making "direct style" work for the folks that would rather prefer that over monads. And I think that's bad, especially as alternatives exist, one of those alternatives being Java 25.

I still ❤️ Scala, it's a productive language, and I believe it will be even more awesome with [capture checking](https://nrinaudo.github.io/articles/capture_checking.html). But making programming safer is just one aspect of what makes or breaks a language. There are other aspects, such as the platforms and problem domains a language is able to target. Most problems we solve on a daily basis are I/O-related problems and without a consistent story that targets the mainstream, I fear for its future.
