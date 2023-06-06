---
title: "Scala 3 Significant Indentation Woes: Sample"
image: /assets/media/articles/2023-scala-indentation-woes.png
image_hide_in_post: true
date: 2023-06-06 14:48:10 +03:00
last_modified_at: 2023-06-06 15:17:19 +03:00
tags:
  - Programming
  - Python
  - Scala
  - Scala 3
description: >
  Here's a fairly straightforward Scala 3 sample, using significant indentation. Can you spot the compilation error?
---

<p class="intro">
Here's a fairly straightforward Scala 3 sample, using significant indentation. Can you spot the compilation error?
</p>

```scala
//> using scala "3.3.0"

def sequence[A](list: List[Option[A]]): Option[List[A]] =
  list.foldLeft(Option(List.newBuilder[A])):
    (acc, a) =>
      acc.flatMap: xs =>
        a.map: x =>
          xs.addOne(x)
    .map(_.result())
```

Here's the compilation error:
```text
[error] ./sample.scala:9:10
[error] Found:    List[A]
[error] Required: scala.collection.mutable.Builder[A, List[A]]
[error]     .map(_.result())
[error]          ^^^^^^^^^^
Error compiling project (Scala 3.3.0, JVM)
Compilation failed
```

Here's the corrected code:
```scala
//> using scala "3.3.0"

def sequence[A](list: List[Option[A]]): Option[List[A]] =
  list.foldLeft(Option(List.newBuilder[A])):
    (acc, a) =>
      acc.flatMap: xs =>
        a.map: x =>
          xs.addOne(x)
  .map(_.result())
```

FYI, this cannot happen in Python, because Python does not allow breaking lines like that:

```python
class MyList:
  def __init__(self, list):
    self.list = list
  def map(self, f):
    return MyList([f(x) for x in self.list])

# Doesn't parse
MyList([1, 2, 3])
  .map(lambda x: x + 1)
```

The error is:
```text
  File "/tmp/sample.py", line 9
    .map(lambda x: x + 1)
IndentationError: unexpected indent
```

And if you try what Scala expects:
```python
# Doesn't parse
MyList([1, 2, 3])
.map(lambda x: x + 1)
```

The error is:
```
  File "/tmp/sample.py", line 9
    .map(lambda x: x + 1)
    ^
SyntaxError: invalid syntax
```

Yikes! What Python does is to make expressions unambiguous by requiring the escaping of line endings via a backslash:

```python
MyList([1, 2, 3]) \
  .map(lambda x: x + 1)
```

Scala's syntax keeps being compared with Python's, however, they couldn't be more different, as Python has had a very strict policy to avoid ambiguity.
