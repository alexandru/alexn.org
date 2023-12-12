---
title: "December Adventure update, thoughts on Rust"
image: /assets/media/articles/2023-december-adventure-2.png
date: 2023-12-12 12:00:00 +02:00
last_modified_at: 2023-12-12 15:53:13 +02:00
tags:
  - Programming
  - Languages
  - Rust
  - Scala
social_description: >
  This is an update to my december adventure, in which I took it upon myself to learn the Rust programming langauge.
---

<p class="intro" markdown=1>
  This is an update to my [december adventure](./2023-12-04-december-adventure.md), in which I took it upon myself to learn the Rust programming langauge.
</p>

First, I've participated in the [Advent of Code](https://adventofcode.com/) for the first 10 days, solving problems in Scala, then translating them to Rust. Unfortunately, [day 10](https://adventofcode.com/2023/day/10) got too complicated. I solved part 2 via "ray casting," an idea that I got early in my thinking, but detecting line intersections is easier said than done. What happened is that I had to detect patterns in the map's corners, in order to do correct counting, and this happened by debugging on the large input file, which is very impractical. This isn't unlike other days in which the full specs or corner cases are visible only in the large input file, with the problems being underspecified. Day 10 took 4 hours of my time, and because the problems are increasing in difficulty, I'm finding it harder and harder to find time for a Scala to Rust translation.

My December Adventure, to learn Rust, is progressing well. I've made little progress on the books, but solving AoC issues turbocharged my learning for simple tasks related to data structures. Translating AoC solutions made me somewhat familiar with vectors, iterators, hash-maps, plus some useful small libraries, like [regex](https://docs.rs/regex/latest/regex/) or [itertools](https://docs.rs/itertools/latest/itertools/). I also got a recommendation to use [rust-clippy](https://github.com/rust-lang/rust-clippy), a linter for Rust that can make some very useful recommendations. I wish we had something like it for Scala, too.

## More impressions on Rust

Compared with Scala, Rust has been annoying to work with, the former being more productive for AoC's problems. However, the point of reference for Rust aren't garbage collected languages like Scala, but rather C/C++. From that point of view, Rust seems surprisingly productive. It's not a managed language, and that's what makes it interesting.

Rust is not an FP language, either. One source of confusion is that Rust's immutability is a (transitive) property of variables, not of data structures. You can mutate any data structure in Rust by taking ownership. E.g., strings can be mutated, even ones that were previously owned by immutable variables. This is very unlike (impure) FP languages like Scala, F#, OCaml, others, where `var` or `let mutable` doesn't allow you to change the stored data structure. A string in these languages is immutable, regardless of what the variable holding it says. This is required for correctness, as mutability of strings would break the implementation of hash-maps & others.

Rust is a language built for mutability. The borrow checker makes mutation much safer, by disallowing read-only references to exist while the data structure is being mutated. For instance, you're not allowed to mutate a string while it's being used as a key in a hash-map. But that's all there is to its supposed “immutability by default”, a way to control who has read and write access.

Persistent/immutable collections, in Rust, don't make much sense, for example. Sharing structure, to avoid cloning, is inefficient without a good garbage collector (as you basically have to work with reference counting), and it's also not in the language's character.

I do wonder how productive Rust is for real projects. For now, I don't have any good ideas of where to apply it. I still have much to learn for building simple web services, as that requires async stuff, plus I'd like some problems for which Rust is particularly good at. Maybe I'll start with some basic CLI tools.
