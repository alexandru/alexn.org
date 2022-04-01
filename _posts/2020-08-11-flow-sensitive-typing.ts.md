---
title: "TypeScript Sample: Flow Sensitive Typing"
tags:
  - TypeScript
  - Snippet
feed_guid: /snippets/2020/08/11/flow-sensitive-typing.ts/
redirect_from:
  - /snippets/2020/08/11/flow-sensitive-typing.ts/
  - /snippets/2020/08/11/flow-sensitive-typing.ts.html
description: >
  Demonstrating Typescript's untagged union types.
last_modified_at: 2022-04-01 17:02:35 +03:00
---

Demonstrating Typescript's untagged union types:

```typescript
type Left<L> = {
  either: "left"
  value: L
}

type Right<R> = {
  either: "right",
  value: R
}

type Either<L, R> = Left<L> | Right<R>

function left<L, R=never>(value: L): Either<L, R> {
  return { either: "left", value }
}

function right<R, L=never>(value: R): Either<L, R> {
  return { either: "right", value }
}

// ----
const value = left<string, number>("Hello!")

// Flow-sensitive typing in action
if (value.either == "left") {
  const l: string = value.value
  console.log("string: ", l)
} else {
  const r: number = value.value
  console.log("number", r)
}
```