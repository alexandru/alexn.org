---
title: "Scala 3 Enums"
image: /assets/media/articles/2023-scala-enums.png
image_hide_in_post: true
date: 2023-05-25 14:15:29 +03:00
last_modified_at: 2023-05-25 16:05:04 +03:00
tags:
  - Java
  - Scala
  - Scala3
  - Programming
description: >
  In Scala, how do we model enumerations of values? What are the possible issues? How does Scala compare with Java? What are the changes in Scala 3?
---

<p class="intro withcap">
  In Scala, how do we model enumerations of values? What are the possible issues? How does Scala compare with Java? What are the changes in Scala 3?
</p>

Here's a simple enumeration in Java:

```java
// Java code
enum Colors {
  Red, Green, Blue
}
```

Adding keys as strings is also possible:

```java
// Java code
enum Colors {
  Red("RED"), Green("GREEN"), Blue("BLUE");

  private final String value;

  Colors(String value) {
    this.value = value;
  }

  public String getValue() {
    return value;
  }
}
```

Java should also do exhaustiveness checks in its new `switch` statement ([JEP 354](https://openjdk.org/jeps/354)):

```java
//JAVA 17+

Colors myColor = Colors.Green;
String label = switch (myColor) {
  case Red -> Colors.Red.getValue();
}
```

Which should fail to compile with the following error:

```text
error: the switch expression does not cover all possible input values
  String label = switch (myColor) {
```

The equivalent in Scala 2.x was supposed to be the [Enumeration](https://www.scala-lang.org/api/2.13.10/scala/Enumeration.html) class:

```scala
// Scala 2.x code
object Colors extends Enumeration {
  val Red, Green, Blue = Value
}

// Or you can assign custom keys to each value:
object Colors extends Enumeration {
  val Red = Value("RED")
  val Green = Value("GREEN")
  val Blue = Value("BLUE")
}

// The created type is `Colors.Value`
val myColor: Colors.Value = Colors.Green
```

The generated type is `Colors.Value`. This can create issues, because it's an inner type of `Enumeration` that's being erased at runtime, therefore it's not the equivalent of a Java `enum` (think of doing serialization with Jackson):

```scala
classOf[Colors.Value]
// val res: Class[Colors.Value] = class scala.Enumeration$Value

object Size extends Enumeration {
  val S, M, L, XL, XXL = Value
}

// Yikes!
classOf[Size.Value] == classOf[Colors.Value] 
// => true
```

Importantly, `Enumeration` provides `values` and `withName` as utilities:

```scala
Colors.values // List(Red, Green, Blue)
Colors.withName("Red") // Colors.Value = Red
```

Another big problem with `Enumeration` is that it's incapable of doing exhaustiveness checks when pattern matching. Nowadays, this is less safety than what Java provides. The following code compiles without warnings:

```scala
myColor match {
  case Colors.Red => println("Red")
}
```

The replacement that almost everyone used was "sealed" traits/classes, which can encode tagged union types:

```scala
// Scala 2.x code

// The `extends Product with Serializable` boilerplate
// is needed to eliminate type-inference junk
sealed abstract class Color(val value: String) 
  extends Product with Serializable

object Color {
  case object Red extends Color("RED")
  case object Green extends Color("GREEN")
  case object Blue extends Color("BLUE")
}
```

This is a bit more verbose, but we can do exhaustiveness checks:

```scala
val myColor: Color = Color.Green
myColor match {
  case Color.Red => println("Red")
}
// myColor match {
// ^
// On line 2: warning: match may not be exhaustive.
// It would fail on the following inputs: Blue, Green
```

This is super useful, especially with [-Xfatal-warnings enabled](./2020-05-26-scala-fatal-warnings.md).

One problem here is that we no longer have an enumeration of all available values, and this can make things difficult:

```scala
object Color {
  // ...

  // Error-prone, since we need to ensure that 
  // we list them all:
  val values: Set[Color] = Set(
    Red, 
    Green, 
    Blue
  )

  def apply(value: String): Option[Color] =
    values.find(_.value == value)
}
```

There are libraries that can help, such as [Enumeratum](https://github.com/lloydmeta/enumeratum/).

```scala
#!/usr/bin/env -S scala-cli shebang -q

//> using scala "2.13.10"
//> using lib "com.beachape::enumeratum:1.7.2"

import enumeratum._
import enumeratum.values._

sealed abstract class Color(val value: String) 
  extends StringEnumEntry

object Color extends StringEnum[Color] {
  case object Red extends Color("RED")
  case object Green extends Color("GREEN")
  case object Blue extends Color("BLUE")

  val values: IndexedSeq[Color] = findValues
}

println(Color.values) // Vector(Red, Green, Blue)
println(Color.withValueOpt("Red")) // Some(Red)
```

Thankfully, Enumeratum is compatible with Scala 3. However, I found a flaw. The following code compiles without warnings:

```scala
import enumeratum.values._

sealed abstract class Color(val value: String) 
  extends StringEnumEntry

object Color extends StringEnum[Color] {
  case object Red extends Color("RED")
  case object Green extends Color("GREEN")
  case object Blue extends Color("BLUE")

  // Yikes! This is most likely a bug.
  final case class Other(r: Int, g: Int, b: Int) 
    extends Color(s"OTHER($r,$g,$b)")

  val values: IndexedSeq[Color] = findValues
}

// No `Other` in this list:
println(Color.values) // Vector(Red, Green, Blue)
```

The problem is, of course, that it invalidates our assumptions about how to serialize and deserialize this. Let's say we've been using Circe, and we already had the codecs defined:

```scala
//> using lib "io.circe::circe-core:0.14.5"
//> using lib "io.circe::circe-parser:0.14.5"

import io.circe._
import io.circe.parser._
import io.circe.syntax._

implicit val colorEncoder: Encoder[Color] = 
  Encoder[String].contramap(_.value)

implicit val colorDecoder: Decoder[Color] = 
  Decoder[String].emap(Color.withValueOpt(_).toRight("Invalid color"))
```

When we add our `case class`, this obviously doesn't work:

```scala
(Color.Other(1,2,3): Color).asJson() // "OTHER(1,2,3)"

decode[Color]("\"OTHER(1,2,3)\"") // Left(DecodingFailure at : Invalid color)
```

People don't necessarily realize that an enumeration is powered by Enumeratum, or what the limitations are.

To fix this, we could find another library, or we could write our own macro. But I dislike macros, I think we'd do just fine with a runtime error:

```scala
#!/usr/bin/env -S scala-cli shebang -q

//> using scala "2.13.10"
//> using lib "org.scala-lang:scala-reflect:2.13.10"

import scala.reflect.runtime.{universe => ru}
import scala.reflect.runtime.{currentMirror => cm}

def findValues[T: ru.TypeTag]: Set[T] = {
  val tpe = ru.typeOf[T]
  val clazz = tpe.typeSymbol.asClass
  if (!clazz.isSealed) {
    throw new AssertionError(s"Type $tpe is not sealed")
  }
  clazz.knownDirectSubclasses.map { sym =>
    if (sym.isModule)
      cm.reflectModule(sym.asModule)
        .instance
        .asInstanceOf[T]
    else if (sym.isModuleClass)
      cm.reflectModule(sym.asClass.module.asModule)
        .instance
        .asInstanceOf[T]
    else 
      throw new AssertionError(
        s"Direct subtype of $tpe is not an object: $sym"
      )
  }
}

sealed abstract class Color(val value: String) 
  extends Product with Serializable

object Color {
  case object Red extends Color("RED")
  case object Green extends Color("GREEN")
  case object Blue extends Color("BLUE")

  val values = findValues[Color]

  def apply(value: String): Option[Color] =
    values.find(_.value == value)
}

println(Color.values) // Set(Red, Green, Blue)
println(Color("RED")) // Some(Red)
```

Now, if you try to add a new case class, you'll get a runtime error when trying to access the `object Color`:

```scala
object Color {
  // ...
  case class Other(r: Int, g: Int, b: Int) 
    extends Color(s"OTHER($r,$g,$b)")
}
// This will now throw a java.lang.AssertionError: 
// 'Direct subtype of Color is not an object: class Other'
Color.values
```

**This is not a macro**. You can write a macro, if you want, using mostly the same logic. Like all things with Scala 2's compile-time reflection, and macros, the `knownDirectSubclasses` is buggy, and this code breaks in some instances, like when defining `Color` as an inner class. Also, the macro may be error-prone in other ways. See this [StackOverflow answer](https://stackoverflow.com/questions/13671734/iteration-over-a-sealed-trait-in-scala) for a hint on how to do that.

In Scala 3, we can easily define a macro:

```scala
#!/usr/bin/env -S scala-cli shebang -q

//> using scala "3.2.2"

inline def findValues[T](using
  m: scala.deriving.Mirror.SumOf[T]
): Set[T] = 
  allInstances[m.MirroredElemTypes, m.MirroredType].toSet

inline def allInstances[ET <: Tuple, T]: List[T] =
  import scala.compiletime.*

  inline erasedValue[ET] match
    case _: EmptyTuple => Nil
    case _: (t *: ts)  => 
      summonInline[ValueOf[t]].value.asInstanceOf[T] :: allInstances[ts, T]

//-------------------------------------------------------------------------
//...
  
sealed abstract class Color(val value: String) 
  extends Product with Serializable

object Color:
  case object Red extends Color("RED")
  case object Green extends Color("GREEN")
  case object Blue extends Color("BLUE")

  // Uncomment this to get a compile-time error:
  // case class Other(r: Int, g: Int, b: Int) 
  //   extends Color(s"OTHER($r,$g,$b)")

  val values = findValues[Color]

  def apply(value: String): Option[Color] =
    values.find(_.value == value)

println(Color.values) // Set(Red, Green, Blue)
println(Color("RED")) // Some(Red)
```

This is an actual macro, and it will throw a compile-time error if `Color` is not a sealed trait, or if we try to define a `case class Other`.

Of course, in Scala 3, we already have the new [enums](https://docs.scala-lang.org/scala3/reference/enums/enums.html), so the above code is only necessary if we want to port our Scala 2 code to Scala 3. In Scala 3, we can just write:

```scala
enum Color(val value: String):
  case Red extends Color("RED")
  case Green extends Color("GREEN")
  case Blue extends Color("BLUE")

object Color:
  def apply(value: String): Option[Color] =
    values.find(_.value == value)
  
println(Color.values.toSet) // Set(Red, Green, Blue)
Color("RED") // Some(Red)
```

If we try to add a case class to our enumeration, we can, but `values` will no longer be available:

```scala
// BROKEN CODE
enum Color(val value: String):
  case Red extends Color("RED")
  case Green extends Color("GREEN")
  case Blue extends Color("BLUE")
  case Other(r: Int, g: Int, b: Int) 
    extends Color(s"OTHER($r,$g,$b)")

object Color:
  def apply(value: String): Option[Color] =
    values.find(_.value == value)
```

Our Scala 3 compiler will then throw this error:

```text
-- [E006] Not Found Error: -----------------------------------------------------
11 |    values.find(_.value == value)
   |    ^^^^^^
   |    Not found: values
   |
   | longer explanation available when compiling with `-explain`
1 error found
```

Furthermore, in Scala 3 we can easily define enums that are compatible with Java, by extending [java.lang.Enum](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/lang/Enum.html), making them compatible with Java libraries:

```scala
// Scala 3

enum Color extends java.lang.Enum[Color]:
  case Red, Green, Blue
```

<p markdown="1">
**TLDR:**<br>
`Scala 2` involves a lot of error-prone boilerplate.<br>
`Scala 3` is pretty cool in its handling of enums and macros ❤️
</p>

It doesn't seem like much, but we have A LOT of enumerations in our codebase. The new `enum` is one of my favorite Scala 3 features, as it removes the error-prone boilerplate.
