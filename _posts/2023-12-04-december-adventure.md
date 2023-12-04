---
title: "December Adventure: Learning Rust"
image: /assets/media/articles/2023-december.jpg
image_caption: >
  Postcard by publisher Brück & Sohn in Meißen.
date: 2023-12-04 13:04:09 +02:00
last_modified_at: 2023-12-04 18:59:29 +02:00
tags:
  - Blogging
  - Books
  - Languages
  - Personal
  - Programming
  - Rust
  - Scala
social_description: >
  This December I'm off to a great personal adventure in programming.
---

<p class="intro" markdown=1>
  This December I'm off to a great personal adventure in programming. Everyone can have their own fun [December Adventure](https://eli.li/december-adventure). You pick something you want to do, or maybe learn, and you do a little of it everyday, as long as it involves some coding.
</p>

The idea is related to the [Advent of Code (AoC)](https://adventofcode.com/), which can be a bit much for many. You can, instead, have your own adventure. [I am participating in AoC](https://github.com/alexandru/advent-of-code) this year, for now, as long as it is easy, mostly because it feels like good fun. And doing it as a group, with the [Scala community on Discord](https://discord.gg/scala), helps. But my real goal for December is **to learn Rust**.

## Why Rust?

Rust is an interesting programming language. It will never replace Scala for me, because it's not as productive, but the truth is, managed languages (with a heap managed by a garbage collector) will never replace C/C++, and that's the niche Rust falls into:

1. Cross-language reusable libraries. C is king here, due to its stable ABI, e.g., libraries for cryptography, a field for which wheel reinvention is a terrible idea. C is also the secret to Python's popularity, since many libraries have parts implemented with C under the hood (e.g., Numpy/Scipy).
2. Real-time systems; the JVM is great at throughput, but like all GC platforms, it can have unpredictable pauses that make it unsuitable for real-time systems (despite the awesome low-latency GC implementations, like ZGC); you probably don't want a GC-managed language for operating the brakes on your car, and even soft-real-time systems, like high-frequency trading or game engines, may be better served by C/C++/Rust.
3. High-performance CLI utilities. We'll probably not see projects like [ripgrep](https://github.com/BurntSushi/ripgrep) built on top of the JVM, due to the binary size and the startup time. I also bumped into [Helix](https://helix-editor.com/), a really cool vim replacement. This may change, with GraalVM or Scala/Kotlin Native, but Rust is already used for some pretty kick-ass utilities, and it makes me want to also have some fun.
4. Projects like the Linux kernel, Firefox, or [Servo](https://github.com/servo); these projects are lower-level, and will never accept contributions in your favorite JVM language (or .NET or Go or OCaml) for obvious reasons.
5. Rust is seemingly embeddable everywhere, because it has the advantage of a small runtime and easy integration with C. For example, it's the first choice for WebAssembly, you can build [Node.js plugins](https://neon-bindings.com/) with it, the Godot game engine has [unofficial Rust bindings](https://godot-rust.github.io/), and it may not shine for building GUIs, but it does have usable [GTK](https://gtk-rs.org/) and [Cocoa](https://github.com/ryanmcgrath/cacao) bindings (beta quality, but active), which is more than Java can say (in fairness, JavaFX is pretty cool, and Swing is still a workhorse, but it always leaves something to be desired).
6. Rust has a blog dedicated to [building an operating-system](https://os.phil-opp.com/), as it's that kind of language, and I don't know what other use cases are cooler than that.
7. The community is seemingly very productive, with many fun projects, resembling that of Scala. For example, if a language doesn't have its own community-driven game engines, even if immature, it's not the kind of language that people use for fun. Fortunately, Rust passes (see [Amethyst](https://amethyst.rs/)).

This doesn't mean that I'm giving up on Scala. I predict that it will remain my favorite programming language, by far, but I've always been a polyglot, and I prefer not being tied down by the tools that I'm using.

## Dec 1-4

On Friday, we had a national holiday, so we had a prolonged weekend. In addition to visiting relatives, or participating in the first days of AoC challenges, I managed to sit down and go through the [official Rust book](https://doc.rust-lang.org/stable/book/). I'm now at Chapter 7, which gave me the confidence to solve Advent of Code exercises with it. What I'm doing is that I first use Scala, because I think well in it, then translate the code to Rust.

[My AoC repository](https://github.com/alexandru/advent-of-code) has both Scala and Rust samples, and it's interesting, because you can compare how my Scala looks and feels, compared with Rust. As an initial impression, Rust is more verbose and awkward. I still don't fully master its memory ownership system. And this language prefers (safe) mutation. Working with persistent data structures is not idiomatic or comfortable, you're better off embracing mutation where needed. But for a language with manual memory management, it's actually quite usable, high-level and safe.

I've also started reading ["Learn Rust with Entirely Too Many Linked Lists"](https://rust-unofficial.github.io/too-many-lists/index.html). I feel confident in saying that if I go through this book, I'll grok Rust's memory management. But, it gave me brain damage straight from the first chapter, so it doesn't look like an easy book for beginners.

## On Blogging

I want to write more on this blog, because I have thoughts, and social media is still bad. I want to publish at least once per week, preferably more. For example, I'm going to publish more articles about how my December adventure is going.

This means that I may publish articles that may be shorter, or lower quality.

Let the fun begin~
