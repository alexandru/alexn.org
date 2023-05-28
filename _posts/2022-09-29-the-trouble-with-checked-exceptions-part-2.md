---
title: "The Trouble with Checked Exceptions: Part 2"
image: /assets/media/articles/2022-checked-exceptions.png
date: 2022-09-29 01:41:48 +03:00
last_modified_at: 2023-05-28 09:39:22 +03:00
tags:
  - Java
  - Scala
description: >
  Java's Checked Exceptions are problematic, and it's not only due to their ergonomics. The bigger problem is that they are in conflict with abstraction and OOP. Also, few people care about typed exceptions (unless they are happy path results, not errors).
---

<p class="intro" markdown=1>
Java's Checked Exceptions are problematic, and it's not only due to their ergonomics. The bigger problem is that they are in conflict with abstraction and OOP. Also, few people care about typed exceptions (unless they are happy path results, not errors).
</p>

And Scala solutions have a tendency to reinvent Java's checked exceptions, due to the allure of static typing, I guess. You should read my previous articles on this matter:

1. [Bifunctor IO and Java's Checked Exceptions](https://alexn.org/blog/2018/05/06/bifunctor-io/);
2. [Scala OOFP Design Sample](https://alexn.org/blog/2022/04/18/scala-oop-design-sample/), in which I argue for "*designing errors out of existence*";

In support, I stumbled on the perfect example from Java's standard library. It's a classic one, it turns out, I'm not the first to point at it ... Java's [StringBuilder](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/lang/StringBuilder.html), which implements the following method:

```java
Appendable append(CharSequence csq) throws IOException;
```

Which is why code using `StringBuilder` can end up with ridiculous try-catch statements like this:

```java
try {
  buffer.append(string)
} catch (IOException ignored) {
  // never happens!
}
```

Java does have a redeeming quality here. Due to the covariance of the return type, you can make the return type more specific, which means you can skip from the `throws` clause in implementations (the equivalent of `throws Nothing`).

```java
class StringBuilder implements Appendable {
  // ...
  @Override
  public StringBuilder append(Sequence s) {
    //...
  }
}
```

`StringBuilder` works in-memory, it can never throw `IOException`. The reason for that signature is because `StringBuilder` implements [Appendable](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/lang/Appendable.html), and that `IOException` is there just in case `Appendable` gets implemented by something that does side effects. Note that this isn't a case of ergonomics, but rather a fundamental problem. It wouldn't matter if we used your favorite bifunctor `IO` or monad transformer, replacing checked-exceptions with `Either`:

```scala
trait Appendable {
  // Same issue, although EitherT is worse due to
  // having issues with covariance;
  def append(csq: CharSequence): EitherT[IO, IOException, Unit]
}
```

Covariance issues of `EitherT` aside, introducing an `Either` data type makes this even more awkward:

```scala
trait Appendable {
  def append(csq: CharSequence): Either[IOException, Unit]
}

class StringBuilder extends Appendable {
  // ...
  // Awkward, because the `Either` is now completely unneeded,
  // and because it's lying, since on top of the JVM,
  // `Throwable` can always happen...
  override def append(Sequence s): Either<Nothing, Unit> = ???
}
```

Scala users already suffer from `flatMap` chains replacing `;` and from unneeded type wrappers, so I'm guessing that if we squint enough, we can make this work.

Regardless of how you model this, fact of the matter is that `StringBuilder` will never throw `IOException`. Like all Scala things, we could try introducing type parameters, or abstract type members, but that's ridiculous, because the interface becomes unusable, as you can't treat the error if you don't know what it is, so you're either going to work with `Any`, or you're going to have an extra type parameter at all call sites:

```scala
// Ridiculous!
trait Appendable {
  type Error

  def append(csq: CharSequence): EitherT[IO, Error, Unit]
}

// Even more ridiculous! (ver.2)
trait Appendable[+E] {
  def append(csq: CharSequence): EitherT[IO, E, Unit]
}
```

We have the issues mentioned in the original article:

1. `IOException` is often an irrelevant exception, equivalent with `Throwable`, as it doesn't provide anything more specific than a signal for "*you can probably retry*", something which `Throwable` does too;
2. The error type is an encapsulation leak, which forces a tax on all implementations;
3. It pushes complexity to the user;

Ironically, in Java's world, input errors (i.e., those thrown by tasks that you can't retry) are often not checked exceptions. E.g., `InvalidArgumentException` is a `RuntimeException`, and this one gets thrown in constructors, being what libraries like Jackson expect for validating input when parsing, a contract that you have to find by reading the documentation. You can see here another issue with checked exceptions: importance gets decided by the library author instead of the downstream user, but this classification is often wrong, as it depends on the use-case at the call-site.

Going further than the issue of abstract methods leaking implementation details, this is also an issue of *changes breaking compatibility*. Turns out, `IOException` isn't a good super-type for I/O related exceptions, and the library's authors might want to change that signature to this:

```java
Appendable append(CharSequence csq) throws IOException, SQLException;
```

The implementation leak should be even more obvious, it would be absurd to deal with `SQLException` when using a `StringBuilder`. But even more problematic is that this breaks both source and binary compatibility, hurting all downstream users of the API, and [Mima](https://github.com/lightbend/mima) will complain, leading to interesting compromises. Turns out, people care about correctness only as long the fix is cheap 😉 so imagine, if you will, big repositories making liberal use of this function, alongside an entire ecosystem of libraries built on top of it. And remember, in this case, the exception type is absolutely useless, as people care only about these things:

1. closing resources safely — important to remember that a vast majority of call-sites care about the `finally` more than the `catch`;
2. retrying locally (in which case this information is insufficient);
3. short-circuiting the happy-path, and logging the message and the call stack trace (globally, as locally this is done only when the outcome gets ignored);

BTW, this widening of the exception type isn't unheard of. In Java's standard library we now have:

1. [Closeable](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/io/Closeable.html), which has a `close() throws IOException`, inheriting from `AutoCloseable`;
2. [AutoCloseable](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/lang/AutoCloseable.html), a newer interface (introduced by try-with-resources) that has a `close() throws Exception`, a trick in order to make `Closeable` compatible with it (covariance FTW), and note the total lack of information in `throws Exception`;

I don't know why `AutoCloseable` was introduced, but if I were to take a guess, it's probably because having that `IOException` in the interface of `Closeable` sucks. Java designers carrying about compatibility, however, chose this path instead of just modifying `Closeable`, which is what a Scala FP developer would have done, to force correctness down on everyone 😎

There is no loss of information, of course, if we just used `IO`, which is what Java meant to do, but lacked the right type to do it:

```scala
trait Appendable {
  // "throws IOException" is Java's `IO`, but it didn't quite work out
  def append(csq: CharSequence): IO[Unit]
}
```

The `throws Throwable` part is implicit in I/O tasks. And now the interface is abstract enough to be useful, yet more specific, in the sense that we can see that it has side effects, but not because of the returned exceptions. And evaluating an `IO` can throw.

Scala is an OOP language, and I've never worked on any major codebase that did not contain OOP interfaces. It's a take it or leave it sort of deal. And this is a taste of the [different ideologies in OOP versus static FP](https://alexn.org/blog/2022/05/13/oop-vs-type-classes-part-1-ideology/). What FP developers call "parametricity" is actually in opposition to well encapsulated abstractions. It's white-box versus black-box design.

For me, not carrying about implementation details is a powerful coping mechanism. And you also see such design choices in [the design of everyday things](https://en.wikipedia.org/wiki/The_Design_of_Everyday_Things) that you use, meaning that user interfaces often get designed with the minimum amount of info and control knobs exposed for the users to be able to do their job. Think about the complexity of your car, in stark contrast to its simple controls (2 pedals, a steering wheel, and rearview mirrors), the ultimate black box. And all cars get steered mostly in the same way, standard interface, no reason to expose controls for implementation-specific errors.

Exposing stuff "just in case" is not a good recipe, as it shifts responsibility on the user, and the user will do stupid things. Can't emphasize this enough: **errors should be designed out of existence!**

For your reading pleasure, here are some references talking about these issues:

- [The Trouble with Checked Exceptions, a conversation with Anders Hejlsberg](https://www.artima.com/articles/the-trouble-with-checked-exceptions);
- [Java's checked exceptions where a mistake — Rod Waldhoff](https://radio-weblogs.com/0122027/stories/2003/04/01/JavasCheckedExceptionsWereAMistake.html);

Or hear Bruce Eckel, a quote from "Thinking in Java":

> Examination of small programs leads to the conclusion that requiring exception specifications could both enhance developer productivity and enhance code quality, but experience with large software projects suggests a different result – decreased productivity and little or no increase in code quality.

It's difficult, however, to convince people that their carefully designed, super explicit return types are actually a smell of bad design. Therefore, the legend and allure of checked exceptions will persist, but hey, placebos are valid treatments too 😛
