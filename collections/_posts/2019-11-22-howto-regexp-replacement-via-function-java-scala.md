---
title: "Regexp Replacement via Function in Java/Scala"
description:
  Replace in strings via regexp, with the replacement being calculated
  via a function.
tags:
  - Scala
  - Ruby
image: /assets/media/articles/scala-replace-all-function.png
---

Article explains how to have fine grained control over replacements when using
[String.replaceAll](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/lang/String.html#replaceAll(java.lang.String,java.lang.String))
or similar in Java or Scala. The samples given are in Scala, but if you're a
Java user, the snippets can be easily translated without any issues.

<p class='info-bubble' markdown='1'>
  The following task should be obvious to accomplish in Scala / Java,
  yet I've lost 2 hours on it, because Java's standard library is aged
  and arcane.
  <br/><br/>
  Writing this article mostly for myself, to dump this somewhere 🙂
</p>

In Ruby if  you want to replace all occurrences of a string, via a regular expression, you can use [gsub](https://ruby-doc.org/core-2.6.5/String.html#method-i-gsub):

```ruby
"HelloWorld!".gsub(/(?<=[a-z0-9_])[A-Z]/, ' \0')
#=> Hello World!
```

This API is available in Scala/Java as well:

```scala
"HelloWorld!".replaceAll("(?<=[a-z0-9_])[A-Z]", " $0")
// res: String = Hello World!
```

However Ruby goes one step further and accepts as the replacement a function block:

```ruby
"HelloWorld!".gsub(/(?<=[a-z0-9_])[A-Z]/) {|ch| ch.downcase }
#=> Hello world!

"Apollo 12".gsub(/\d+/) {|num| num.to_i + 1}
#=> "Apollo 13"
```

The Java API exposed by [Pattern](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/regex/Pattern.html) is a little awkward, so lets see how to do this in Scala / Java:

```scala
type Index = Int
type MatchGroup = String

def replaceAll(regex: Pattern, input: String)
  (f: (Index, MatchGroup, List[MatchGroup]) => String): String = {

  val m = regex.matcher(input)
  val sb = new StringBuffer

  while (m.find()) {
    val groups = {
      val buffer = ListBuffer.empty[String]
      var i = 0
      while (i < m.groupCount()) {
        buffer += m.group(i + 1)
        i += 1
      }
      buffer.toList
    }
    val replacement = f(m.start(), m.group(), groups)
    m.appendReplacement(sb, Matcher.quoteReplacement(replacement))
  }

  m.appendTail(sb)
  sb.toString
}
```

What happens here is that [Matcher](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/regex/Matcher.html) allows you to replace all occurrences of a string with an iterator-like protocol by using:

- [.find](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/regex/Matcher.html#find()): for finding the next occurrence in a `while` loop
- [.appendReplacement](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/regex/Matcher.html#appendReplacement(java.lang.StringBuilder,java.lang.String)): which appends the remaining text after the discovery of the last match and the current one, plus the replacement that you've calculated for the current match
  - Note this requires the usage of [quoteReplacement](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/regex/Matcher.html#quoteReplacement(java.lang.String)), because otherwise the logic in `appendReplacement` will treat certain special chars like `\` and `$`, so this specifies that you want the replacement to be verbatim
- [.appendTail](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/regex/Matcher.html#appendTail(java.lang.StringBuilder)): to append to the final string whatever is left

We can now describe something like this:

```scala
def camelCaseToSnakeCase(input: String): String =
  replaceAll("[A-Z](?=[a-z0-9_])".r.pattern, input) { (i, ch, _) =>
    (if (i > 0) "_" else "") + ch.toLowerCase
  }

// And usage:
camelCaseToSnakeCase("RebuildSubscribersCounts")
//=> res: String = rebuild_subscribers_counts
```

Or like this:

```scala
def incrementNumbersIn(input: String): String =
  replaceAll("\\d+".r.pattern, input) { (_, num, _) =>
    (num.toInt + 1).toString
  }

// And usage:
incrementNumbersIn("Apollo 12")
//=> res: String = Apollo 13
```

Enjoy ~
