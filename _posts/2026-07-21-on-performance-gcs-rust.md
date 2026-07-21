---
title: "On Performance, GCs and Rust"
image: /assets/media/articles/2026-arrogant-thomas.jpg
image_caption: >
  Thomas, my cat, thinking about freeing himself from the shackles of GC.
tags:
  - Programming
  - Languages
  - Java
  - JVM
  - Rust
---

<p class="intro" markdown=1>
Consider this claim: _Rust programs have better performance than Java/Go/.NET programs._ Do you agree with it?
</p>

I don't agree. For one, because it's not defining what "performance" means. We need to be more specific.

Performance has at least two aspects, that are often at odds (sometimes you have to pick your poison):

- **Throughput.** Example: _How many transactions get processed per second?_
- **Latency.** Example: _Ensure that any transaction gets processed in at most 1 second._

<p class="info-bubble" markdown="1">
I will be talking more about Java, because it's what I'm most familiar with, but most of the points I'm making also apply to similar platforms, like dotNET, or Go.
</p>

Programming platforms like Java, .NET or Go use [tracing garbage collection](https://en.wikipedia.org/wiki/Tracing_garbage_collection). This is a form of automatic memory management that delays the deallocation of unused objects. When it comes to memory allocation, GC-managed languages can achieve excellent throughput, better actually than what your average C/C++ developer can achieve, especially if they use `malloc`.

Allocating heap memory via `malloc` in C/C++ can seriously affect the performance of your program because it's slow, and it leads to memory fragmentation, which further affects performance. In C++ (and in Rust) you end up relying a lot on stack allocation, which is very performant and predictable, due to the ability to automatically release objects when they go out of scope via its "destructor" (see [RAII](https://en.wikipedia.org/wiki/Resource_acquisition_is_initialization)). In C++, and in Rust, beginners often resort to copying entire data structures, which can be slow versus just passing around a reference. Or they resort to smart pointers that do [reference counting](https://en.wikipedia.org/wiki/Reference_counting), which is still technically GC, a technique that's more predictable (which is why it's used in languages meant for developing UIs, such as Swift), but also, less performant in many scenarios, trading throughput for latency. And for heap allocation, developers often rely on techniques such as the [object pool pattern](https://en.wikipedia.org/wiki/Object_pool_pattern), which aren't rookie-friendly.

Compare it with Java ... the JVM pre-allocates heap memory, this being one of its problems, because it's challenging to configure a JVM to release unused heap back to the OS. Allocating memory on the JVM is most often just incrementing a pointer, being thus as cheap as stack allocation. Releasing the memory occupied by objects with a short lifespan (the so-called young generation) happens in bulk, because the GC is "generational", as it groups objects in categories based on how long they survive. Java's GC also defragments memory.

One problem that Java has is indirection. Objects get allocated in heap memory, and traversing a data structure leads to a lot of indirection that invalidate the CPU's cache layers. JVM runtimes also use [escape analysis](https://en.wikipedia.org/wiki/Escape_analysis) to eliminate intrinsic locks or heap allocation; it's been limited in its ability to do that, although I hear GraalVM can do a good job. Which is why it's great that the [value classes](https://openjdk.org/projects/valhalla/value-objects) from [Project Valhalla](<https://en.wikipedia.org/wiki/Project_Valhalla_(Java_language)>) are coming. But note that people misunderstand its purpose ... Value Classes are not about stack allocation, but about allocating _contiguous memory regions_ (memory flattening). And also, this is a Java-specific issue that others don't have; for example, dotNET already has value classes.

Another problem that Java and similar platforms have (those based on tracing GC) are the _stop-the-world GC pauses_. Modern GCs try to do their work incrementally and concurrently, without affecting the program. But their ability is limited, falling back to a stop-the-world GC cycle that freezes the whole program, thus affecting _latency_. Also, the bigger the heap, the bigger the pause and thus older GC implementations could have stop-the-world pauses that lasted for seconds when talking of heap sizes measured in only tens of GBs, making the use of large heaps impractical.

More recent GCs, such as [ZGC](https://wiki.openjdk.org/spaces/zgc/pages/34668579/Main), are _"nearly pauseless"_, minimizing stop-the-world pauses, and also making their latency more predictable, such that managing large heaps is now possible. Better GCs also improve the development of [soft real-time systems](https://en.wikipedia.org/wiki/Real-time_computing#Criteria_for_real-time_computing) because latency is more predictable. And one thing I like about Java is that it provides choices, including commercial solutions, such as the [Azul C4](https://www.azul.com/products/components/pgc/).

Notice I only talked about memory allocation patterns. But aren't other things also affecting performance, such as all the runtime checks meant for preserving memory safety? Of course, runtime checks affect performance as well, but when it comes to the performance of your program, I/O dominates, and this includes (RAM) memory access patterns; and here we are talking about how memory gets allocated/released, or accessed, aspects of shared-memory concurrency included (how multiple threads synchronize access to the same memory locations). In other words, before worrying about array bounds checks costing CPU cycles, worry about the memory layout of the objects in that array.

You should be able to see the problem when talking about performance:

1. GC-managed systems can have **better _throughput_** than what your average developer is able to build in C++ or Rust.
2. GC-managed systems have **worse _latency_**, however, that latency is good enough for "soft real-time" systems.

In other words, **GC-managed systems trade _latency_ for _throughput_ and ease-of-use.**

<p class="info-bubble" markdown="1">
Tangent: GC makes certain paradigms easier, and here there are "safety" aspects that are more nuanced. For example, Rust programming is credited as having aspects of _"functional programming"_, a claim that's just marketing, not holding up to scrutiny. For actual FP (programming with math functions) you need cheap memory sharing, and that's a property of GC-managed systems, whereas Rust goes completely in the other direction, making sharing difficult on purpose; e.g., working with persistent data structures or with closures in Rust is hard. Why do you think people complain about "Async Rust" so much? Turns out relying on GC makes certain things a lot easier.
</p>

But I don't want to diminish the advantages that languages like C++ or Rust have over GC-managed languages:

- For programming many embedded systems, having a GC is a dealbreaker.
- For hard real-time systems, too, having a GC is a dealbreaker. Imagine the braking system of a car, imagine what it would mean for a GC pause to happen right when you're pressing the break; in which case any extra latency is simply not tolerable.
- GC-managed programs will use more RAM, simply because generational GCs will pre-allocate more RAM. And Java in particular is memory hungry, having been optimized for servers with plenty of memory. This is quite significant. For instance an HTTP server I've built in Rust and able to use only 5 MB of RAM would require 50 MB when built with Java (and this with optimizations to remove standard library modules from the classpath).
- GC-managed programs tend to have a slower startup (again, latency suffers).
- Optimizing memory-access patterns in languages with manual memory management is much easier.

When speaking of performance, that last point is the most important: when you have the expertise, optimizing memory access patterns is much easier in languages like C++ and Rust, because you have more freedom. Doing the same in Java is not impossible, as projects like Reactor demonstrate, but it's a PITA nonetheless.

The trade-off that Rust makes is one of ease-of-use, in preference for performance with predictable latency and safety. IMO, it's the only good alternative to C++ right now. But if you dislike its ergonomics, but still want memory safety, well, the alternative is definitely a GC-managed language.

As a conclusion, your average program is better off with a GC-managed language. But the ceiling with Rust or C++ for what you can build is significantly higher, assuming you have the expertise and the need.