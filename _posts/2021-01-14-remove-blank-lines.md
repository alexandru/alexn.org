---
title: "Snippet: Remove blank lines from text"
image: /assets/media/snippets/remove-blank-lines.png
image_hide_in_post: true
tags:
  - Java
  - Programming
  - Scala
  - Snippet
feed_guid: /snippets/2021/01/14/remove-blank-lines/
redirect_from:
  - /snippets/2021/01/14/remove-blank-lines/
  - /snippets/2021/01/14/remove-blank-lines.html
description: >
  Just a regular expression.
last_modified_at: 2022-04-01 19:14:08 +03:00
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
