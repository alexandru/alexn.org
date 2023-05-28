---
title: "Immutable Collections should be Your Default"
redirect_from:
  - /blog/2022/10/27/things-i-love-about-scala/
image: /assets/media/articles/2022-immutable-collections.png
image_hide_in_post: true
date: 2022-10-27 15:34:46 +03:00
last_modified_at: 2022-12-05 00:02:50 +02:00
generate_toc: true
tags:
  - FP
  - Java
  - Scala
description: >
  Mutable collection types should only be used strategically, with purpose, otherwise for correctness/safety purposes, the default should be immutable collection types, aka persistent data structures.
---

<p class="intro" markdown=1>
Mutable collection types should only be used strategically, with purpose, otherwise for correctness/safety purposes, the default should be immutable collection types, aka [persistent data structures](https://en.wikipedia.org/wiki/Persistent_data_structure).
</p>

## Available options

For working with immutable collections:

- Java's standard library has utilities for [creating unmodifiable copies](https://docs.oracle.com/en/java/javase/11/core/creating-immutable-lists-sets-and-maps.html), which are better than nothing;
- [VAVR](https://www.vavr.io/) works well for Java;
- [Guava](https://github.com/google/guava/wiki/ImmutableCollectionsExplained) is also a standard recommendation for Java;
- [kotlinx.collections.immutable](https://github.com/Kotlin/kotlinx.collections.immutable) works well for Kotlin;
- In Scala and Clojure, the default collection implementations are immutable by default, a wise design choice for JVM languages that provide their own (maximal) standard library;
- [Immutable.js](https://github.com/immutable-js/immutable-js/) works well for JavaScript;

## Motivation

Immutable collections are much like `String`. You don't need `String` to be mutable, whenever you build a bigger `String`, you just do `ref += nextLine` or you work with a `StringBuilder`. And `String` being immutable helps with sharing it safely across threads, or with using it in `HashMap` implementations. Java's Strings are surprisingly sane, compared with other implementations, people should take note. So why shouldn't collections also be immutable by default, just like `String`?

Mutable collections may have a performance advantage, even when used in a concurrent context. Java's `ConcurrentLinkedQueue` for example will perform better than an `AtomicReference(immutable.Queue())`. Or an `ArrayList` will perform better than an immutable/persistent `List` (which is actually a stack). But performance optimizations are often unnecessary, and safety should be the default.

*Performance is a currency*, and whenever you can afford it (most of the time), what better way to spend such a currency than on correctness?

## Sample: Simple Sharing

Sharing of mutable data structures is bad, and demonstrating it is easy:

```java
// Java code

record class ProjectConfig(
  List<String> availableTimezones,
  //...
) {}

//... later ...
config.availableTimezones().add("Mars/SpaceXFirst");
```

This is bad because it modifies that configuration for all call sites. Even if a project-wide configuration change was your intent, this is a pretty bad way to model configuration updates in your code, because then your components need to be notified of such configuration changes. For the call-site, this is bad too, because the user doesn't really know if doing this is safe or not. The users may end up thinking that they received their own copy, so this is safe.

And note, it's acceptable to use Java's way of handling this — by wrapping that list into something that throws an `UnsupportedOperationException` when you try to `add()` or `remove()`. But it would be even better if you used some type that makes the immutability clear, e.g., `ImmutableList`.

## Sample: Concurrent Data Structures

Just this week I stumbled on the following Java declaration:

```java
// Java code
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

//...
Map<String, List<String>> dns = new ConcurrentHashMap<>();
```

You should immediately notice that something is wrong, because the type of `ConcurrentHashMap` is hidden, which means that its methods specifically meant for dealing with concurrent updates aren't used. Then, I stumbled on gems like:

```java
// All unsynchronized of course
var value = "another value"
var list = dns.get("key");
if (list != null) {
  list.add(value);
} else {
  list = new ArrayList<>();
  list.add(value);
  dns.put("key", newList);
}
```

I mean, yikes! The developer that wrote this code felt that multi-threading synchronization was needed. But rubbing some `ConcurrentHashMap` on your code won't help, if you don't treat those values as being immutable. By extracting a `List` from that `ConcurrentHashMap`, then modifying it, that code is thread unsafe. Also, that `get` followed by `put` is not atomic. Such concurrency issues lead to overridden updates (lost values), or even to corrupted data structures. This could have all been avoided with proper use of an immutable `List` in those values, combined with good use of `ConcurrentHashMap`'s API (e.g., [compute](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/concurrent/ConcurrentHashMap.html#compute(K,java.util.function.BiFunction))).

So, the result was a hard to trace bug in our project, coming from a (proprietary) library that we can't fix.

In Scala, even if we use `ConcurrentHashMap`, we'd use it in combination with a Scala immutable `List`, which is available by default, no import necessary:

```scala
// Scala code
import java.util.concurrent.ConcurrentHashMap

//..
val dns = new ConcurrentHashMap[String, List[String]]()

//..
dns.compute("key", (k, v) => {
  val current = if (v != null) v else Nil
  current.prepended("new-value")
})
```

You can do this with Java's mutable `ArrayList`, of course, but:

1. you need to remember to not modify the extracted values — this means creating a clone, and adding values to that clone;
2. creating clones of mutable data structures can cost more than using specialized implementations of persistent/immutable collection types (e.g., Scala's `List`, `Queue`, `Vector`, `Map`, `Set`);

Immutable collection types can also be transformed into concurrent collections, very cheaply, by wrapping them into an `AtomicReference`. Which is actually a neat trick used by many libraries handling concurrency.

```scala
// Scala 3 code, making use of "Explicit Nulls"
// Needs the -Yexplicit-nulls compiler option to see it in action
import java.util.concurrent.atomic.AtomicReference
import scala.collection.immutable.Queue
import scala.collection.mutable.ListBuffer

final class ConcurrentQueue[V]() {
  private val ref = new AtomicReference(Queue.empty[V])

  def enqueue(value: V): Unit = {
    var continue = true
    while (continue) {
      val current = ref.get().nn
      val update = current.enqueue(value)
      continue = !ref.compareAndSet(current, update)
    }
  }

  def dequeue(): Option[V] = {
    // A legitimate case when Option's None doesn't mean Null 🙂
    var result: Option[V] | Null = null
    while (result == null) {
      val current = ref.get().nn
      current.dequeueOption match {
        case None =>
          result = None
        case Some((v, update)) =>
          if (ref.compareAndSet(current, update)) {
            result = Some(v)
          }
      }
    }
    result.nn
  }

  def dequeueAll(): List[V] = {
    val buffer = ListBuffer.empty[V]
    var continue = true
    while (continue) {
      dequeue() match {
        case None =>
          continue = false
        case Some(v) =>
          buffer.append(v)
      }
    }
    buffer.toList
  }
}
```

And usage:

```scala
// Scala code
val queue = new ConcurrentQueue[String]()
queue.enqueue("Hello")
queue.enqueue("World")

for (value <- queue.dequeueAll()) {
  println(value)
}
```


<p class="warn-bubble" markdown="1">
**WARN:** your `AtomicReference` or your `ConcurrentHashMap` references won't work for managing concurrent access, if the values you put in them aren't immutable (or at least treated as such)!
</p>

If you're ever tempted to do this, remember, THIS IS A BUG:

```java
// Java code
final AtomicReference<List<String>> ref =
  new AtomicReference<>(new ArrayList<>());

// BUG!!!
ref.get().add("value")
```

Note that instead of atomic references, or other concurrent and mutable data structures, you could use intrinsic locks via `synchronize` blocks and a `mutable.Queue`, of course, but by using atomic references the algorithm is [lock-free](https://en.wikipedia.org/wiki/Non-blocking_algorithm), and for example, with virtual threads in Java 19 (Project Loom) by using `synchronize` blocks you can still have OS/platform threads blocked (pinned), whereas if you work this way, you can avoid that.

As a fair warning, the algorithm may be non-blocking, but it is not "wait-free", and might not do well on high contention. So for performance reasons, when you need concurrent queues, you're better off using Java's `ConcurrentLinkedQueue` or specialized implementations, such as those in [JCTools](https://github.com/JCTools/JCTools) (which are awesome!🌞). However, you can put any immutable data structure in an `AtomicReference`, and then claim that you're working with [STM](https://en.wikipedia.org/wiki/Software_transactional_memory) (or at least something close) 😎.

## Epilogue

Immutable collections being used by default is one of the biggest wins people get when adopting "functional programming", or when adopting alternative JVM languages, like Scala or Clojure. Nothing else comes close.

Even when working with Java, you can adopt immutable collection types by default, as a best practice. You can do this either by:

1. Wrapping them in "unmodifiable" collections, using the standard library — but this won't bring all possible benefits;
2. Adopting libraries such as Vavr or Guava.

Now go forth and convince your team to adopt this best practice 🎤🎶😎
