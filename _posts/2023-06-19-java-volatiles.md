---
title: "Java Volatiles"
image: /assets/media/articles/2023-java-volatiles.png
image_hide_in_post: true
date: 2023-06-19 13:57:50 +03:00
last_modified_at: 2023-06-20 08:31:48 +03:00
generate_toc: true
tags:
  - Programming
  - Concurrency
  - Java
  - Scala
  - JVM
description: >
  In Java and other JVM languages, "volatile" reads and writes are part of the concurrency toolbox. But adding `volatile` on variables can be a mistake. This is a poorly understood concept. Let's gain a better understanding.
---

<p class="intro" markdown=1>
In Java and other JVM languages, "volatile" reads and writes are part of the concurrency toolbox. But adding `volatile` on variables can be a mistake. This is a poorly understood concept. Let's gain a better understanding.
</p>

## Misconceptions

Some common ones:

- *Volatile variables ensure "visibility"* — but the notion is misleading, because it's not about visibility per se, as all updates to variables are eventually seen by all other threads, and marking a variable as `volatile` doesn't necessarily publish changes to that variable any sooner (although in fairness, x86 CPUs have stronger ordering guarantees than ARM CPUs in this regard, so there may be differences of behavior for normal variables, depending on what you're doing);
- *Volatile variables are not for "synchronization"* — which is false, as volatile reads and writes are a form of synchronization, even if the guarantees are weaker than when using locks or when using `compare-and-set` (CAS).
- *Volatile variables prevent CPU caching* — depending on the JVM, their use may or may not reduce caching, the problem being that CPU caching is complex, and also the JVM is free to optimize away volatile semantics, the guarantees of the _JMM_[^1] are higher-level than that, and if you're thinking of CPU caching, you're probably doing it wrong.

As a somewhat more advanced mental model, volatile variables introduce _memory barriers_[^2], however:

- Memory barriers are only introduced when the JVM writes, and then reads from the same volatile variable (in a pair, just like you must synchronize on the same lock/monitor for synchronization to work);
- The JVM is free to optimize away memory barriers, as long as the ordering guarantees are preserved; for example, that's what the JVM's _escape analysis_[^3] is for.

## Guaranteed Ordering

What volatile reads and writes give us are happens-before relationships[^4], AKA guaranteed *ordering*. Say, for example, we have the following declaration:

```java
class State {
  public String value1 = null;
  public String value2 = null;
  public volatile boolean hasValues = false;
}
```

The producer could do this:

```java
state.value1 = "Hello";
state.value2 = "World";
state.hasValues = true;
```

From the point of view of the producer, `value1` and `value2` are always updated before `hasValues`. The question is, what happens when we look at the evolution of these variables from another thread? If `hasValues` wouldn't be `volatile`, we could see `value1` or `value2` as `null`.

The consumer could do this:

```java
// Waits until the volatile write is seen
while (!state.hasValues) {
  // spin
}
// We are now guaranteed that `value1` and `value2` are set:
System.out.println(
  "Got values: " + state.value1 + " " + state.value2
);
```

### Q: Why does this work?

This works because the JVM guarantees that once the update to our volatile variable is seen on the consumer thread (`hasValues == true`), then all previous updates are also seen. It's a happens-before relationship, the updates to `value1` and `value2` being guaranteed to happen before `hasValue = true`.

At the hardware level, this means that a "memory barrier" could be introduced, which prevents the CPU from reordering instructions, but thinking of memory barriers in this case would be error-prone.

### Q: Could we see those values updated before the volatile update?

Of course. Worth noting that unless we wait for `hasValue`, we get no guarantees on what we'll see to all updates prior to it. We could see `value1` and/or `value2` as `null`, randomly. This is why thinking about "*CPU caching*" is entirely misleading.

### Q: Don't we need to mark as `volatile` all variables?

No, making `value1` and `value2` to be `volatile` can be worse than useless, at it may lead to poorer performance, due to extra memory barriers (forced orderings). The JVM may try to understand what you're trying to do, but it's not that smart. And adding `volatile` all over the place does not make your code thread-safe. Volatile variables only make your code thread-safe if you can reason about the ordering.

## Synchronization sample

You may think that we can't make code thread-safe just via volatile reads and writes, but you'd be wrong, as there are cases in which we can. Which can be very useful for performance or predictability (lock-free algorithms).

The following is an inefficient (SPSC) queue, see the comments. If you can understand why this sample is correct, you understand volatile variables:

```java
import java.util.Objects;

/**
 * This is a "single-producer, single-consumer" (SPSC) queue.
 * <p>
 * SPSC means that we can have a single producer (a thread using `push`),
 * working concurrently with a single consumer
 * (another thread using `pop`).
 * <p>
 * This queue is not thread-safe if we have multiple concurrent
 * producers, or multiple concurrent consumers.
 */
public class SPSCRiskyQueue<A> {
  /**
   * State machine with possible states:
   * wait-for-producer | wait-for-consumer
   *
   * The state is "volatile" because it is used to order updates.
   * Remove "volatile" and witness the test fail.
   */
  private volatile String state = "wait-for-producer";
  private int pushedCount = 0;
  private A value = null;

  public void push(A value) throws InterruptedException {
    while (!Objects.equals(state, "wait-for-producer")) {
      spin();
    }
    this.value = value;
    pushedCount++;
    state = "wait-for-consumer";
  }

  public A pop() throws InterruptedException {
    while (!Objects.equals(state, "wait-for-consumer")) {
      spin();
    }
    // System.out.println("Read elements: " + pushedCount);
    final var value = this.value;
    state = "wait-for-producer";
    return value;
  }

  public long getPushedCount() {
    return pushedCount;
  }

  private void spin() throws InterruptedException {
    // For some reason this piece of logic introduces more ordering,
    // which makes the test more non-deterministic (it takes longer to
    // see it fail).
    Thread.onSpinWait();
    if (Thread.interrupted())
      throw new InterruptedException();
  }
}
```

Try removing the `volatile` annotation from `hasValues`, see how this test works:

```java
import java.util.concurrent.CountDownLatch;

/**
 * Code for TESTING...
 */
class Main {
  public static void runTest() throws InterruptedException {
    final var queue = new SPSCRiskyQueue<Integer>();
    final var count = 10000;
    final var state = new long[] { 0L };

    final var prepareLatch = new CountDownLatch(2);
    final var concurrentStartLatch = new CountDownLatch(1);

    final var producer = new Thread(() -> {
      try {
        prepareLatch.countDown();
        concurrentStartLatch.await();
        for (int i = 0; i < count; i++) {
          queue.push(i);
        }
      } catch (InterruptedException ignored) {}
    });

    final var consumer = new Thread(() -> {
      try {
        prepareLatch.countDown();
        concurrentStartLatch.await();
        for (int i = 0; i < count; i++) {
          state[0] += queue.pop();
        }
      } catch (InterruptedException ignored) {}
    });

    producer.setDaemon(true);
    producer.start();
    consumer.setDaemon(true);
    consumer.start();
    // Ready, set, go!
    prepareLatch.await();
    concurrentStartLatch.countDown();

    producer.join(3000);
    consumer.join(3000);

    final var sum = state[0];
    final var pushed = queue.getPushedCount();
    System.out.println("Sum: " + sum + "; pushed: " + pushed);
    if (sum != (count * (count - 1)) / 2 || pushed != count) {
      throw new IllegalStateException("Concurrency test failed");
    }
  }

  public static void main(String[] args) throws InterruptedException {
    for (int i = 0; i < 10000; i++) {
      runTest();
    }
  }
}
```

---

[^1]: [Java Memory Model](https://en.wikipedia.org/wiki/Java_memory_model) is the set of multi-platform guarantees that Java makes for multithreaded code.
[^2]: [Memory barriers](https://en.wikipedia.org/wiki/Memory_barrier) are CPU instructions that can force the ordering of updates. The [JSR-133 Cookbook](https://gee.cs.oswego.edu/dl/jmm/cookbook.html) can be good for gaining an understanding, but take it with a grain of salt.
[^3]: [Escape analysis](https://en.wikipedia.org/wiki/Escape_analysis) is a method for determining the scope of objects, in order to enable subtle optimizations. If the lifetime of an object is limited to the current method or thread, then Java may avoid intrinsic synchronization, or heap allocations. Java's capabilities have been more limited than what's possible.
[^4]: Reasoning about concurrency can be in terms of [happens-before relationships](https://en.wikipedia.org/wiki/Happened-before), i.e., the order in which events are observed.
