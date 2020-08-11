```typescript
type Left<L, never> = {
  either: "left"
  value: L
}

type Right<never, R> = {
  either: "right",
  value: R
}

type Either<L, R> = Left<L, never> | Right<never, R>

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