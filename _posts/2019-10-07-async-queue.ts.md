---
title: "Async Queue in TypeScript"
feed_guid: /snippets/2019/10/07/async-queue.ts/
redirect_from:
  - /snippets/2019/10/07/async-queue.ts/
  - /snippets/2019/10/07/async-queue.ts.html
last_modified_at: 2022-04-01 18:50:37 +03:00
tags:
  - Async
  - JavaScript
  - Snippet
  - TypeScript
description:
  Production-ready, Promise-enabled async queue.
---

```ts
type Callback<A> = (a: A) => void;

/**
 * Delays stuff for ensuring fairness.
 */
export function yieldRunLoop(): Promise<void> {
  const fn: (cb: (() => void)) => void = typeof setImmediate !== 'undefined'
    ? setImmediate
    : cb => setTimeout(cb, 0)
  return new Promise(fn)
}

/**
 * Async queue implementation
 */
export class Queue<A> {
  private readonly elements: A[] = []
  private readonly callbacks: ([Callback<A>, Callback<Error>])[] = []

  enqueue = async (a: A) => {
    const cbs = this.callbacks.shift()
    if (cbs) {
      // fairness + guards against stack overflows
      await yieldRunLoop()
      const [resolve, _] = cbs
      resolve(a)
    } else {
      this.elements.push(a)
    }
  }

  dequeue = async () => {
    if (this.elements.length > 0) {
      return this.elements.shift() as A
    } else {
      let cb: [Callback<A>, Callback<any>] | undefined
      const p = new Promise<A>((resolve, reject) => { cb = [resolve, reject] })
      if (!cb) throw new Error("Promise constructor")
      this.callbacks.push(cb)
      return await p
    }
  }

  rejectAllActive = (e: Error) => {
    while (this.callbacks.length > 0) {
      const cbs = this.callbacks.pop()
      if (!cbs) continue
      const [_, reject] = cbs
      reject(e)
    }
  }
}

/**
 * Consumer implementation.
 *
 * @param workers specifies the number of workers to start in parallel
 * @param blockProcessFromExiting if `true` then blocks the Nodejs process from exiting
 *
 * @returns a `[promise, cancel]` tuple, where `cancel` is a function that can be used
 *          to stop all processing and `promise` can be awaited for the completion of
 *          all workers, workers that complete on cancellation
 */
export function consumeQueue<A>(queue: Queue<A>, workers: number, blockProcessFromExiting: boolean = false) {
  const Cancel = new Error("queue-cancel-all")
  const startWorker =
    async (isActive: boolean[], process: (a: A) => Promise<void>) => {
      await yieldRunLoop()
      try {
        while (isActive.length > 0 && isActive[0]) {
          const a = await queue.dequeue()
          try {
            await process(a)
          } catch (e) {
            console.error("Error while processing queue message:", a, e)
          }
          // Fairness + protection against stack-overflow
          await yieldRunLoop()
        }
      } catch (e) {
        if (e != Cancel) throw e
      }
    }

  // For keeping the process alive, for as long as there is a run-loop active
  function startTick() {
    let tickID: Object
    function tick() { tickID = setTimeout(tick, 1000) }
    tick()
    return () => clearTimeout(tickID as any)
  }

  return (process: (a: A) => Promise<void>) => {
    const isActive = [true]
    const cancelTick = blockProcessFromExiting ? startTick() : () => {}
    const cancel = () => {
      isActive[0] = false
      queue.rejectAllActive(Cancel)
      cancelTick()
    }

    const tasks: Promise<void>[] = []
    for (let i=0; i<workers; i++) {
      tasks.push(startWorker(isActive, process))
    }

    const all = Promise.all(tasks).then(_ => undefined as void)
    return [all, cancel] as [Promise<void>, () => void]
  }
}
```

And usage:

```ts
async function main() {
  console.log("Starting...")
  const queue = new Queue<string>()

  const [promise, cancel] = consumeQueue(queue, 3, true)(
    async msg => {
      await new Promise(r => setTimeout(r, 1000))
      console.log(msg)
    })

  process.on('SIGINT', async () => {
    console.log("\nCancelling...\n")
    cancel()
  })

  await queue.enqueue("Hello")
  await queue.enqueue("World!")

  // Requires `blockProcessFromExiting` to be `true`
  await promise
  console.log("Done!")
}

main().catch(console.error)
```