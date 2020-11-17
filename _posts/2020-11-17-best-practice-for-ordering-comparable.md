---
title: "Best practice for natural Ordering"
date: 2020-11-17 11:02:13+0200
tags:
  - Best Practices
  - Scala
image: /assets/media/articles/ordering.png
description: Definitions of `scala.math.Ordering` MUST BE consistent with `equals`, an often overlooked law that can lead to problems.
---

Scala has [scala.math.Ordering](https://www.scala-lang.org/api/2.13.3/scala/math/Ordering.html), Java has [java.lang.Comparable](https://docs.oracle.com/javase/8/docs/api/java/lang/Comparable.html). These are interfaces used for defining a natural order, which can then be used to sort lists of elements, or in data structures implemented via binary search trees, such as [SortedSet](https://www.scala-lang.org/api/2.13.3/scala/collection/SortedSet.html).

This is what it looks like:

```scala
trait Ordering[A] {
  def compare(x: A, y: A): Int
}
```

That function is supposed to define a "total order", by returning a number that's:

- strictly negative if `x < y`
- strictly positive if `x > y`
- `0` in case `x == y`

What's often overlooked is that — ordering has to be *consistent with equals*, as a law, or in other words:

```
compare(x, y) == 0 <-> x == y
```

Example:

```scala
import scala.math.Ordering

final case class Contact(
  lastName: String,
  firstName: String,
  phoneNumber: String
)

object Contact {
  // WRONG — never do this!
  implicit val ordering: Ordering[Contact] =
    (x: Contact, y: Contact) => 
      x.lastName.compareTo(y.lastName)
}
```

This might seem reasonable if you were building some sort of contacts agenda, but isn't. Some reasons:

1. data-structures backed by binary-search trees can use just `compare` when searching for keys
2. the result of sorting a list should not depend on its initial ordering

Example of what can happen when sorting lists:

```scala
val agenda1 = List(
  Contact("Nedelcu", "Alexandru", "0738293904"),
  Contact("Nedelcu", "Amelia", "0745029304"),
)

agenda1.sorted
//=> List(Contact(Nedelcu,Alexandru,0738293904), Contact(Nedelcu,Amelia,0745029304))

val agenda2 = List(
  Contact("Nedelcu", "Amelia", "0745029304"),
  Contact("Nedelcu", "Alexandru", "0738293904"),
)

agenda2.sorted
//=> List(Contact(Nedelcu,Amelia,0745029304), Contact(Nedelcu,Alexandru,0738293904))

agenda1.sorted == agenda2.sorted
//=> false
```

Example of what happens when using `SortedSet`:

```scala
import scala.collection.immutable.SortedSet

val set1 = SortedSet(agenda1:_*)
//=> TreeSet(Contact(Nedelcu,Alexandru,0738293904))

val set2 = SortedSet(agenda2:_*)
//=> TreeSet(Contact(Nedelcu,Amelia,0745029304))
```

`SortedSet`, being a `Set` implementation, is not duplicating items, and as you can see here, it basically eliminates all contacts with the same `lastName`, except for the first one it saw.

<p class="info-bubble" markdown="1">
  If you've ever defined your ordering like this, don't feel bad, as it happens to many of us. I was bitten by this just last week, in spite of knowing what I was doing ... I defined a `private` ordering and figured that it won't get used improperly. Except that after a refactoring, by yours truly, it did end up being used improperly. Which is why definitions have to always be correct, as their correctness has to survive refactorings, even when it's just you operating on that codebase.
</p>

The correct definition for our `Ordering` would be:

```scala
object Contact {
  implicit val ordering: Ordering[Contact] =
    (x: Contact, y: Contact) => {
      x.lastName.compareTo(y.lastName) <||>
      x.firstName.compareTo(y.firstName) <||>
      x.phoneNumber.compareTo(y.phoneNumber)
    }

  // Just to help us out, this time
  private implicit class IntExtensions(val num: Int) extends AnyVal {
    def `<||>`(other: => Int): Int = 
      if (num == 0) other else num
  }
}
```

Don't take shortcuts, don't do anything less than this, even if you think that you currently don't need it. Because one of your colleagues, or even your future self, might reuse this definition without knowing that it's broken.
