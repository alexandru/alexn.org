---
title: "Monix Task vs Scalaz vs Future, The Benchmark"
description:
  The Task in Monix has really good performance. See the benchmark.
tags:
  - FP
  - Scala
  - Monix
  - Typelevel
image: /assets/media/articles/monix-1024.png
---

<p class="intro withcap" markdown='1'>The Monix [Task](https://monix.io/docs/2x/eval/task.html) was heavily inspired by `scalaz.concurrent.Task` and by `scala.concurrent.Future`. That's not a secret and I'll be forever grateful to their authors. I've ran a benchmark and I'm glad to report that the Monix [Task](https://monix.io/docs/2x/eval/task.html) beats in performance both.</p>

Such results are actually unexpected, because the Monix `Task` has to
do tricks in order to be "*cancelable*", a trait that allows it to
close opened resources when race conditions happen, which really means
extra footwork. But no, right now, it beats both in performance and by
quite the margin.

Details:

- Benchmark used is
  [TaskGatherBenchmark](https://github.com/monixio/monix/blob/v2.0-RC13/benchmarks/src/main/scala/monix/TaskGatherBenchmark.scala)
  in the repository
- Monix version: `2.0-RC13`
- Scalaz version: `7.2.4`
- Scala version: `2.11.8`
- Java version: `1.8.0_60`
- OS: OS X El Captain, version `10.11.6`

### Sequence

The purpose of this test is the performance of `flatMap`, or in other
words the performance of the run-loop, on both normal/synchronous
tasks and tasks that are forked in separate (logical) threads. So in
other words:

```scala
Task.sequence(tasks)
```

Which is translated more or less into this:

```scala
tasks.foldLeft(init)((acc,et) => acc.flatMap(b => et.map(e => b += e)))
```

So for synchronous tasks (that evaluate immediately), and note here
that Scala's `Future` is not applicable since `Future` is not
trampolined:

| Source | Type | Operation | Score | Error | Units |
|--------|------|-----------|-------|-------|-------|
| Monix | Sync | Sequence | 6716.906 | 157.947 | ops/s |
| Scalaz | Sync | Sequence | 3518.888 | 167.148 | ops/s |
{: class=benchmark border=1 cellpadding=10}

And for tasks that fork threads on execution:

| Source | Type | Operation | Score | Error | Units |
|--------|------|-----------|-------|-------|-------|
| Monix | Forked | Sequence | 2044.624 | 24.852 | ops/s |
| Scalaz | Forked | Sequence | 1090.355 | 15.851 | ops/s |
| S.Future | Forked | Sequence | 1753.614 | 20.871 | ops/s |
{: class=benchmark border=1 cellpadding=10}

As you can see, the Monix `Task` has twice the throughput of Scalaz
and fares quite better compared with Scala's standard `Future`.

### Gather

The gather operation would be:

```scala
Task.gather(tasks)
```

This works like `sequence`, except that the evaluation has non-ordered
effects. What this means is that, if the tasks are forking threads,
then they get executed in parallel.

For synchronous/immediate tasks the numbers are:

| Source | Type | Operation | Score | Error | Units |
|--------|------|-----------|-------|-------|-------|
| Monix | Sync | Gather | 3800.559 | 341.509 | ops/s |
| Scalaz | Sync | Gather | 2152.441 | 13.569 | ops/s |
| S.Future | Forked | Sequence | 1753.614 | 20.871 | ops/s |
{: class=benchmark border=1 cellpadding=10}

And for forked tasks:

| Source | Type | Operation | Score | Error | Units |
|--------|------|-----------|-------|-------|-------|
| Monix | Forked | Gather | 1396.797 | 17.098 | ops/s |
| Scalaz | Forked | Gather | 1014.452 | 13.569 | ops/s |
| S.Future | Forked | Sequence | 1753.614 | 20.871 | ops/s |
{: class=benchmark border=1 cellpadding=10}

Including the results of `Future.sequence` as well, because `Future`
has strict evaluation and it can be used to execute futures in
parallel. The performance of `gather` can be worse than
`Future.sequence`, because of the execution model. But if it executes
tasks that have immediate execution, or a mixed batch, then it is much
better.

### Gather Unordered

The `gatherUnordered` operation would be:

```scala
Task.gatherUnordered(tasks)
```

This behaves like `gather`, except that it does not care for the order
in which the results are served. Can have much better performance if
you don't care about order.

For synchronous/immediate tasks:

| Source | Type | Operation | Score | Error | Units |
|--------|------|-----------|-------|-------|-------|
| Monix | Sync | Unordered | 5654.462 | 150.792 | ops/s |
| Scalaz | Sync | Unordered | 3340.645 | 244.145 | ops/s |
| S.Future | Forked | Sequence | 1753.614 | 20.871 | ops/s |
{: class=benchmark border=1 cellpadding=10}

For forked tasks:

| Source | Type | Operation | Score | Error | Units |
|--------|------|-----------|-------|-------|-------|
| Monix | Forked | Unordered | 1658.055 | 12.114 | ops/s |
| Scalaz | Forked | Unordered | 1657.454 | 35.218 | ops/s |
| S.Future | Forked | Sequence | 1753.614 | 20.871 | ops/s |
{: class=benchmark border=1 cellpadding=10}

Again, performance is really good for synchronous tasks, whereas for
forked tasks it evens out with the performance of `Future.sequence`.

### Raw output

```
[info] # Run complete. Total time: 00:04:28
[info]
[info] Benchmark                              Mode  Cnt     Score     Error  Units
[info] TaskGatherBenchmark.gatherMonixA      thrpt   10  1396.797 ±  17.098  ops/s
[info] TaskGatherBenchmark.gatherMonixS      thrpt   10  3800.559 ± 341.509  ops/s
[info] TaskGatherBenchmark.gatherScalazA     thrpt   10  1014.452 ±  13.569  ops/s
[info] TaskGatherBenchmark.gatherScalazS     thrpt   10  2152.441 ±  24.811  ops/s
[info] TaskGatherBenchmark.sequenceFutureA   thrpt   10  1753.614 ±  20.871  ops/s
[info] TaskGatherBenchmark.sequenceMonixA    thrpt   10  2044.624 ±  24.852  ops/s
[info] TaskGatherBenchmark.sequenceMonixS    thrpt   10  6716.906 ± 157.947  ops/s
[info] TaskGatherBenchmark.sequenceScalazA   thrpt   10  1090.355 ±  15.851  ops/s
[info] TaskGatherBenchmark.sequenceScalazS   thrpt   10  3518.888 ± 167.148  ops/s
[info] TaskGatherBenchmark.unorderedMonixA   thrpt   10  1658.055 ±  12.114  ops/s
[info] TaskGatherBenchmark.unorderedMonixS   thrpt   10  5654.462 ± 150.792  ops/s
[info] TaskGatherBenchmark.unorderedScalazA  thrpt   10  1657.454 ±  35.218  ops/s
[info] TaskGatherBenchmark.unorderedScalazS  thrpt   10  3340.645 ± 244.145  ops/s
```

Cheers!
