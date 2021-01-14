---
title: "Remove blank lines from text in Java/Scala"
date: 2021-01-14 15:29:25+0200
image: /assets/media/snippets/remove-blank-lines.png
tags:
  - Java
  - Programming
  - Regexp
  - Scala
---

```scala
text.replaceAll("(?m)(^\\s*$\\r?\\n)+", "")
```

Or via `Pattern` objects:

```scala
import java.util.regex.Pattern

Pattern
  .compile("(^\\s*$\\r?\\n)+", Pattern.MULTILINE)
  .matcher(text)
  .replaceAll("")
```
