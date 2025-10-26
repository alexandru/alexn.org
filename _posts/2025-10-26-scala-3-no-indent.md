---
title: "Scala 3 / No Indent"
image: /assets/media/articles/2023-scala3-indentation-4-spaces.png
image_hide_in_post: true
date: 2025-10-26T10:35:53+02:00
last_modified_at: 2025-10-26T12:15:55+02:00
tags:
  - Languages
  - Programming
  - Programming Rant
  - Scala
  - Scala 3
description: >
  Scala 3 came with "significant indentation". And I still dislike it, despite trying hard, so I'm switching back to braces.
---

<p class="intro" markdown="1">
Scala 3 came with [significant indentation](https://docs.scala-lang.org/scala3/reference/other-new-features/indentation.html) ([🏛️](https://web.archive.org/web/20250914105033/https://docs.scala-lang.org/scala3/reference/other-new-features/indentation.html)). And I still [dislike it](./2023-06-06-scala-3-significant-indentation-woes-sample.md), despite [trying hard](./2023-11-08-in-scala-3-use-4-spaces-for-indentation.md). So I'm switching back to braces.
</p>

<p class="info-bubble" markdown="1">
Oh, no 😱 not this kind of rant again! Sorry, but it must be said about once per year 💪 — the rants will continue until morale improves!
</p>

Here are some reasons:

1. It can lead to compilation errors that have weird explanations (e.g., types don't match). My number one concern with significant indentation is ambiguity. CoffeeScript suffered from ambiguity (thank goodness it's dead), YAML suffers from ambiguity, and Python doesn't allow multi-line expressions (without a `\\`) or multi-line lambdas to avoid ambiguity.
2. Copy/paste doesn't work well, because when inserting a newline, editors have the tendency to keep the indentation of the previous line, so in most cases, when pasting, you're at the wrong indentation level, and depending on the editor's behavior, the first line of the pasted block might shift relative to the rest of the block. Scalafmt won't help as it chokes on invalid syntax. My text editing skills are relatively good, and I still find myself unable to efficiently copy/paste blocks of code with significant indentation. Note that with braces, pasting at the wrong indentation level simply doesn't matter and Scalafmt can do its job.
3. Editors now have to be smarter about jumping to the beginning and end of a block or expression. E.g., these classic Vim shortcuts no longer work for navigation:
   - `[{` and `[(` for jumping to the opening brace or paren;
   - `]}` and `])` for jumping to the closing brace or paren;
   - `%` for jumping to matching brace or paren.
4. You could avoid some braces before, e.g., by being more expression-oriented. Braces are a visual aid for blocks using statements, and for example, you could easily spot functions described by single expressions (with a high likelihood that they are pure), versus functions using statements.
5. Braces are a visual aid for [lexical scope](https://en.wikipedia.org/wiki/Scope_(computer_science)) — they make it easier to explain what scopes or blocks of code are to beginners. I've heard the argument that students have an easier time with significant indentation, but that's just NOT true in my experience, quite the opposite. You can feel the tension due to the existence of (optional) `end` markers, as if non-English students needed yet another English keyword.
6. Whitespace changes make diffs (PR reviews) noisy. With braces, we do have formatting changes, but we can ignore it when insignificant.
7. Like it or not, braces are a _de facto standard_ due to the popularity of the C/C++ family. Even relatively newer languages, like Rust, use braces. Folks, sorry, but Pascal is dead, ML-languages are still niche, despite first appearing in the 1970s, and everyone hates CoffeeScript.
8. Scala 2.x codebases will be with us for a very long time, which is why we'll have to live with both old-style and new-style syntax, forever. Like with Perl's [TMTOWTDI](https://en.wikipedia.org/wiki/Perl#Philosophy), having the ability to use the Klingon language is cool, but the risk/reward ratio isn't great.

## No-Indent 💪

Take a stand and reject significant indentation. Add this to your `build.sbt` file:

```scala
ThisBuild / scalacOptions ++= Seq(
  "-rewrite",
  "-no-indent",
)
```

And if you're using Scalafmt, an OK configuration for me in `.scalafmt.conf` is this:

```ini
runner.dialect = scala3

# Even with old syntax, I dislike redundant braces, although there
# might be a case for adding them to aid clarity for big expressions
rewrite.rules = [RedundantBraces]
rewrite.redundantBraces.maxBreaks = 10

rewrite.scala3.convertToNewSyntax = true
rewrite.scala3.removeOptionalBraces = false
```

Note: Scalafmt doesn't appear to have the ability to rewrite the code from significant indentation to old-syntax, but it can rewrite from old-syntax to significant indentation (which is why we have to rely on Scalac's `-no-indent -rewrite`). This suggests Scalafmt has more information when braces are available, and so do we 😉
