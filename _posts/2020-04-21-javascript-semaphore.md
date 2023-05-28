---
title: "Parallelizing Work via a JavaScript Semaphore"
date: 2020-04-21T16:00:00
description:
  Simple and very effective implementation of a Semaphore, used for easily parallelizing work in JavaScript/TypeScript.
tags:
  - Asynchrony
  - Concurrency
  - JavaScript
  - TypeScript
image: /assets/media/articles/async-semaphore-typescript.png
---

<p class="intro" markdown='1'>
  This is a simple, but very effective implementation of a `Semaphore`, used for easily parallelizing work in JavaScript/TypeScript. And while libraries for doing this might be available, quality varies and implementing your own stuff is fun.
</p>

Use-case: many times we iterate over a list of items and then do expensive network requests, like reading and writing to a database.

<p class='info-bubble' markdown='1'>
  Scala already has good implementations for doing this, no need to reinvent the wheel. See:
  [cats.effect.concurrent.Semaphore](https://typelevel.org/cats-effect/concurrency/semaphore.html) and [monix.catnap.Semaphore](https://monix.io/api/3.1/monix/catnap/Semaphore.html).
</p>

Simple example:

```typescript
// Dummy function
function saveToDatabase(item: number): Promise<void> {
 return new Promise(f => {
   if (item % 1000 === 0) { console.log("Progress: ", item) }
   setTimeout(f, 100 /* millis */)
 })
}

// ...
for (let i = 0; i < 100000; i++) {
  await saveToDatabase(i)
}
```

But this will be very slow, taking ~2.8 hours to finish.

On the other hand, if we try a naive solution via `Promise.race`, this can easily overwhelm your database and your script can crash with "*out of memory*" or "*out of available file handles*" errors. This is also not adequate in case producing those items in the first place is an expensive process (e.g. going over an async iterator). We can certainly hold 100,000 items in memory, but talk about 100 million or more and things start to fall apart.

```typescript
const promises: Promise<void>[] = []

for (let i = 0; i < 100000; i++) {
  promises.push(saveToDatabase(i))
}

await Promise.race(promises)
```

Let's implement a simple data structure that can help us parallelize the workload, but only execute at most 100 tasks in parallel:

```typescript
const semaphore = new AsyncSemaphore(100)

for (let i = 0; i < 100000; i++) {
  await semaphore.withLockRunAndForget(() => saveToDatabase(i))
}

await semaphore.awaitTerminate()
console.log("Done!")
```

Execution time will be ~1.7 minutes (compared with 2.8 hours for the first sample).

The method `withLockRunAndForget` only waits in case the semaphore doesn't have handles available. And when the loop is finished, we need `awaitTerminate` to wait for all active tasks to finish.

Implementation, which can be copy/pasted in your project:

```typescript
export class AsyncSemaphore {
  private _available: number
  private _upcoming: Function[]
  private _heads: Function[]

  private _completeFn!: () => void
  private _completePr!: Promise<void>

  constructor(public readonly workersCount: number) {
    if (workersCount <= 0) throw new Error("workersCount must be positive")
    this._available = workersCount
    this._upcoming = []
    this._heads = []
    this._refreshComplete()
  }

  async withLock<A>(f: () => Promise<A>): Promise<A> {
    await this._acquire()
    return this._execWithRelease(f)
  }

  async withLockRunAndForget<A>(f: () => Promise<A>): Promise<void> {
    await this._acquire()
    // Ignoring returned promise on purpose!
    this._execWithRelease(f)
  }

  async awaitTerminate(): Promise<void> {
    if (this._available < this.workersCount) {
      return this._completePr
    }
  }

  private async _execWithRelease<A>(f: () => Promise<A>): Promise<A> {
    try {
      return await f()
    } finally {
      this._release()
    }
  }

  private _queue(): Function[] {
    if (!this._heads.length) {
      this._heads = this._upcoming.reverse()
      this._upcoming = []
    }
    return this._heads
  }

  private _acquire(): void | Promise<void> {
    if (this._available > 0) {
      this._available -= 1
      return undefined
    } else {
      let fn: Function = () => {/***/}
      const p = new Promise<void>(ref => { fn = ref })
      this._upcoming.push(fn)
      return p
    }
  }

  private _release(): void {
    const queue = this._queue()
    if (queue.length) {
      const fn = queue.pop()
      if (fn) fn()
    } else {
      this._available += 1

      if (this._available >= this.workersCount) {
        const fn = this._completeFn
        this._refreshComplete()
        fn()
      }
    }
  }

  private _refreshComplete(): void {
    let fn: () => void = () => {/***/}
    this._completePr = new Promise<void>(r => { fn = r })
    this._completeFn = fn
  }
}
```

Enjoy~
