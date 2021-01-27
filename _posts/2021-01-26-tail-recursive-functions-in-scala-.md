---
title: "Tail Recursive Functions (in Scala)"
date: 2021-01-26 21:49:35+0200
image: /assets/media/articles/tail-recursive-functions.png
image_hide_in_post: true
tags: 
  - Algorithms
  - FP
  - Programming
  - Scala
description: "Turning imperative algorithms to tail-recursive functions isn't necessarily obvious. In this article (and video) I'm showing you the trick you need, and in doing so, we'll discover the Zen of Functional Programming."
---

{% include youtube.html id="Ua1iMD4icLU" image="/assets/media/articles/tail-recursive-functions.png" %}

Turning imperative algorithms to tail-recursive functions isn't necessarily obvious. In this episode I'm showing you the trick you need, and in doing so, we'll discover the Zen of Functional Programming.

<p class="info-bubble">
  Choose between watching the video on YouTube (linked above), or reading the article (below), or both.
</p>

- [The Trick](#the-trick)
- [(Actual) Recursion](#actual-recursion)
- [Zen of Functional Programming?](#zen-of-functional-programming)

## The Trick

Let's start with a simple function that calculates the length of a list:

```scala
def len(l: List[_]): Int =
  l match {
    case Nil => 0
    case _ :: tail => len(tail) + 1
  }
```

It's a recursive function with a definition that is mathematically correct. However, if we try to test it, this will fail with a `StackOverflowError`:

```scala
len(List.fill(100000)(1))
```

The problem is that the input list is too big. And because the VM still has work to do after that recursive call, needing to do a `+ 1`, the call isn't in "tail position", so the [call-stack](https://en.wikipedia.org/wiki/Call_stack){:target="_blank"} must be used. A `StackOverflowError` is a memory error, and in this case it's a correctness issue, because the function will fail on reasonable input.

First let's describe it as a dirty `while` loop instead:

```scala
def len(l: List[_]): Int = {
  var count = 0
  var cursor = l

  while (cursor != Nil) {
    count += 1
    cursor = cursor.tail
  }
  count
}
```

THE TRICK for turning such functions into tail-recursions is to turn those variables, holding state, into _function parameters_.

```scala
def len(l: List[_]): Int = {
  // Using an inner function to encapsulate this implementation
  @tailrec
  def loop(cursor: List[_], count: Int): Int =
    cursor match {
      // Our end condition, copied after that while
      case Nil => count
      case _ :: tail =>
        // Copying the same logic from that while statement
        loop(cursor = tail, count = count + 1)
    }
  // Go, go, go
  loop(l, 0)
}
```

Now this version is fine. Note the use of the `@tailrec` annotation — all this annotation does is to make the compiler throw an error in case the function is not actually tail-recursive. That's because that call is error-prone, and it needs repeating, this is an issue of correctness.

Let's do a more complex example to really internalize this. Let's calculate the N-th number in the Fibonacci sequence — here's the memory unsafe recursive version:

```scala
def fib(n: Int): BigInt = 
  if (n <= 0) 0
  else if (n == 1) 1
  else fib(n - 1) + fib(n - 2)

fib(0) // 0
fib(1) // 1
fib(2) // 1
fib(3) // 2
fib(4) // 3
fib(5) // 5

fib(100000) // StackOverflowError (also, really slow)
```

First turn this into a dirty `while` loop:

```scala
def fib(n: Int): BigInt = {
  // Kids, don't do this at home 😅
  if (n <= 0) return 0
  // Going from 0 to n, instead of vice-versa  
  var a: BigInt = 0 // instead of fib(n - 2)
  var b: BigInt = 1 // instead of fib(n - 1)
  var i = n

  while (i > 1) {
    val tmp = a
    a = b
    b = tmp + b
    i -= 1
  }
  b
}
```

Then turn its 3 variables into function parameters:

```scala
def fib(n: Int): BigInt = {
  @tailrec
  def loop(a: BigInt, b: BigInt, i: Int): BigInt =
    // first condition
    if (i <= 0) 0
    // end of while loop
    else if (i == 1) b     
    // logic inside while loop statement
    else loop(a = b, b = a + b, i = i - 1)

  loop(0, 1, n)
}
```

## (Actual) Recursion

Tail-recursions are just loops. But some algorithms are actually _recursive_, and can't be described via a `while` loop that uses constant memory. What makes an algorithm actually recursive is _usage of a stack_. In imperative programming, for low-level implementations, that's how you can tell if recursion is required ... does it use a manually managed stack or not?

But even in such cases we can use a `while` loop, or a `@tailrec` function. Doing so has some advantages. Let's start with a `Tree` data-structure:

```scala
sealed trait Tree[+A]

case class Node[+A](value: A, left: Tree[A], right: Tree[A])
  extends Tree[A]
case object Empty
  extends Tree[Nothing]
```

Defining a fold, which we could use to sum-up all values for example, will be challenging:

```scala
def foldTree[A, R](tree: Tree[A], seed: R)(f: (R, A) => R): R =
  tree match {
    case Empty => seed
    case Node(value, left, right) =>
      // Recursive call for the left child
      val leftR = foldTree(left, f(seed, value))(f)
      // Recursive call for the right child
      foldTree(right, leftR)(f)
  }
```

This is the simple version. And it should be clear that the size of the call-stack will be directly proportional to _the height of the tree_. And turning it into a `@tailrec` version means we need to _manually manage a stack_:

```scala
def foldTree[A, R](tree: Tree[A], seed: R)(f: (R, A) => R): R = {
  @tailrec def loop(stack: List[Tree[A]], state: R): R =
    stack match {
      // End condition, nothing left to do
      case Nil => state
      // Ignore empty elements
      case Empty :: tail => loop(tail, state)
      // Step in our loop
      case Node(value, left, right) :: tail =>
        // Adds left and right nodes to stack, evolves the state
        loop(left :: right :: tail, f(state, value))
    }
  // Go, go, go!
  loop(List(tree), seed)
}
```

<p class="info-bubble" markdown="1">
  If you want to internalize this notion — recursion == usage of a stack — a great exercise is the [backtracking algorithm](https://en.wikipedia.org/wiki/Backtracking). Implement it with recursive functions, or with dirty loops and a manually managed stack, and compare. The plot thickens for backtracking solutions using 2 stacks 🙂
</p>

Does this manually managed stack buy us anything?

Well yes, if you need such recursive algorithms, such a stack can take up your whole heap memory, which means it can handle a bigger input. But note that with the right input, your process can still blow up, this time with an out-of-memory error (OOM).

<p class="info-bubble" markdown="1">
  NOTE — in real life, shining examples of algorithms using manually managed stacks are [Cats-Effect's IO](https://typelevel.org/cats-effect/) and [Monix's Task](https://monix.io/), since they literally replace the JVM's call-stack 😄
</p>

## Zen of Functional Programming?

In FP, you turn variables into (immutable) function parameters. And state gets evolved via function calls 💡

That's it, that's all there is to FP (plus the design patterns, and the pain of dealing with I/O 🙂).

Enjoy!
