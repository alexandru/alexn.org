---
title: "Fatal Warnings and Linting in Scala"
description:
  Strengthen your code via `-Xfatal-warnings`, linting and piss off your colleagues with useful compiler errors.
tags:
  - Scala
image: /assets/media/articles/scala-xfatal-warnings.png
generate_toc: true
---

<p class="intro" markdown='1'>
  The best practices are those enforced by the build tools, as part of the build process. Don't annoy your colleagues in code reviews; let the build tools do that for you.
</p>

The Scala compiler has multiple linting options available and emits some warnings out of the box that would be more useful as errors. Let's see how we can rely on the Scala compiler to strengthen our code and piss off your colleagues with clean code requirements.

## Best Practice: Stop Ignoring Warnings!

Some of it might be noise; however, in that noise, some real gems might be missed, warnings that signal bugs. For example, the compiler can do exhaustiveness checks when pattern matching:

```scala
def size(list: List[_]): Int =
  list match {
    case _ :: rest => 1 + size(rest)
  }
// On line 2: warning: match may not be exhaustive.
//        It would fail on the following input: Nil
```

Here's what happens next:

```scala
size(List(1,2,3))
// scala.MatchError: List() (of class scala.collection.immutable.Nil$)
```

It shouldn't be just a warning. Even if you're diligent, this warning can get lost in a sea of other warnings, like it often does. And here we were lucky, because the runtime exception was triggered on the happy path, but our luck would eventually run out and end up with such exceptions in production.

## 1. Activate -Xfatal-warnings

To turn all compiler warnings into errors, you can activate `-Xfatal-warnings`. In [build.sbt](https://www.scala-sbt.org/1.x/docs/Basic-Def.html):

```scala
scalacOptions ++= Seq(
  "-Xfatal-warnings",
  //...
)
```

<p class="info-bubble" markdown="1">
  **NOTE:** it's probably a good idea to exclude this from the `console` configuration, see [section 2.3](#23-relax-the-console-configuration).
</p>

Now if we try out the code above, we get an error like this:

```
[error] .../Example.scala:10:5: match may not be exhaustive.
[error] It would fail on the following input: Nil
[error]     list match {
[error]     ^
[error] one error found
```

Thus we can no longer ignore it.

### 1.1. Make only some warnings fatal (Scala 2.13)

There's a new `-Wconf` option in Scala 2.13.2 ([see PR](https://github.com/scala/scala/pull/8373)). With it, we can still keep some warnings as warnings.

Use-case: say you're upgrading an Akka project. It's going to have a ton of `@deprecated` warnings that you may not want to fix right now, but you still want to keep the exhaustiveness checks as errors.

```scala
scalacOptions ++= Seq(
  // "-Xfatal-warnings",
  "-Wconf:cat=deprecation:ws,any:e",
)
```

What this does is to turn all warnings into errors, *except for deprecation* messages, which are still left as warnings. To break it down:

- `cat=deprecation` refers to deprecation messages (classes/methods marked with `@deprecated` being called) and `:ws` says that for these warnings a "warning summary" should be shown
- `any:e` says that for any other kind of warning, signal it via an error

Run this in a terminal for more help:

```sh
scalac -Wconf:help
```

## 2. Activate All Linting Options

There are many useful compiler options that you could activate. You can find a (possibly non-complete) list on [docs.scala-lang.org](https://docs.scala-lang.org/overviews/compiler-options/index.html).

<p class="info-bubble">
  <strong>WARNING:</strong> the compiler evolves and it's good to keep this list up to date (see next tip)!
</p>

For Scala 2.13 at the time of writing, here's my list of `scalac` options:

```scala
scalacOptions := Seq(
  // Feature options
  "-encoding", "utf-8",
  "-explaintypes",
  "-feature",
  "-language:existentials",
  "-language:experimental.macros",
  "-language:higherKinds",
  "-language:implicitConversions",
  "-Ymacro-annotations",

  // Warnings as errors!
  "-Xfatal-warnings",

  // Linting options
  "-unchecked",
  "-Xcheckinit",
  "-Xlint:adapted-args",
  "-Xlint:constant",
  "-Xlint:delayedinit-select",
  "-Xlint:deprecation",
  "-Xlint:doc-detached",
  "-Xlint:inaccessible",
  "-Xlint:infer-any",
  "-Xlint:missing-interpolator",
  "-Xlint:nullary-override",
  "-Xlint:nullary-unit",
  "-Xlint:option-implicit",
  "-Xlint:package-object-classes",
  "-Xlint:poly-implicit-overload",
  "-Xlint:private-shadow",
  "-Xlint:stars-align",
  "-Xlint:type-parameter-shadow",
  "-Wdead-code",
  "-Wextra-implicit",
  "-Wnumeric-widen",
  "-Wunused:implicits",
  "-Wunused:imports",
  "-Wunused:locals",
  "-Wunused:params",
  "-Wunused:patvars",
  "-Wunused:privates",
  "-Wvalue-discard",
)
```

There are many useful options in there, from disallowing "adapted args", detecting inaccessible code, inferred `Any`, shadowing of values, to unused imports and params and others.

### 2.1. Use the sbt-tpolecat plugin

Keeping that list of compiler options up to date is exhausting, new useful options get added all the time, others are deprecated, and especially for libraries, you have to deal with multiple Scala versions in the same project.

A better option is to include [sbt-tpolecat](https://github.com/DavidGregory084/sbt-tpolecat) in your project.

### 2.2. Exclude annoying linting options

Some linting options can trigger false positives that are too annoying. It's fine to remove them from your project or specific configurations (e.g. `Test`, `Console`).

For example, I do not like the `-Wunused:privates` option because it triggers an annoying false positive when defining (unused) default values in `case class` definitions.

If using `sbt-tpolecat`, as mentioned above, you can include something like this in your build definition:

```scala
scalacOptions in Compile ~= { options: Seq[String] =>
  options.filterNot(
    Set(
      "-Wunused:privates"
    )
  )
}
```

### 2.3. Relax the console configuration

When playing around in the console, it's a good idea to deactivate `Xfatal-warnings`, along with some of the more annoying warnings.

You could [use sbt-tpolecat](#21-use-the-sbt-tpolecat-plugin), which already does this automatically, or you could add this to `build.sbt`:

```scala
val filterConsoleScalacOptions = { options: Seq[String] =>
  options.filterNot(Set(
    "-Xfatal-warnings",
    "-Werror",
    "-Wdead-code",
    "-Wunused:imports",
    "-Ywarn-unused:imports",
    "-Ywarn-unused-import",
    "-Ywarn-dead-code",
  ))
}

// ...
scalacOptions.in(Compile, console) ~= filterConsoleScalacOptions,
scalacOptions.in(Test, console) ~= filterConsoleScalacOptions
```

Credit for this snippet: [DavidGregory084/sbt-tpolecat](https://github.com/DavidGregory084/sbt-tpolecat/blob/v0.1.11/src/main/scala/io/github/davidgregory084/TpolecatPlugin.scala#L109).

## 3. Silence some warnings

Sometimes you want to ignore a certain warning:

- maybe it's a false positive
- maybe you want something "unused", as a placeholder

### 3.1. Silencer plugin (Scala < 2.13)

You can use the [ghik/silencer](https://github.com/ghik/silencer) compiler plugin.

For our sample above, if we want to silence that exhaustiveness check:

```scala
import com.github.ghik.silencer.silent

@silent("not.*?exhaustive")
def size(list: List[_]): Int =
  list match {
    case _ :: rest => 1 + size(rest)
  }
```

The annotation accepts a regular expression that matches the warning being silenced.

You can also use silence warnings for an entire folder, useful if you have auto-generated source files:

```scala
// Alternative, if using the silencer plugin
scalacOptions ++= Seq(
  "-P:silencer:pathFilters=.*[/]src_managed[/].*",
)
```

### 3.2. Using @nowarn and -Wconf in Scala 2.13.2

Scala 2.13 has added the [-Wconf flag for configurable warnings, @nowarn annotation for local suppression](https://github.com/scala/scala/pull/8373).

`@nowarn` can be more fine grained. We could do just like the above and silence with a pattern matcher:

```scala
import scala.annotation.nowarn

@nowarn("msg=not.*?exhaustive")
def size(list: List[_]): Int =
  list match {
    case _ :: rest => 1 + size(rest)
  }
```

But we can do better, because the actual error messages are brittle. We can silence based on the "category" of the warning. To find the category of a warning, we can (temporarily) enable extra verbosity in these messages via this compiler option in `build.sbt`:

```scala
scalacOptions += "-Wconf:any:warning-verbose"
```

That error will then look like this:

```
[error] ... [other-match-analysis @ size] match may not be exhaustive.
```

The category is "`other-match-analysis`", so we can silence it like this:

```scala
@nowarn("cat=other-match-analysis")
def size(list: List[_]): Int =
  list match {
    case _ :: rest => 1 + size(rest)
  }
```

You can also silence warnings for entire folders, via `-Wconf`, useful if you have auto-generated files (e.g. from templates):

```scala
// Turns off warnings for generated files and for templates
scalacOptions ++= Seq(
  "-Wconf:src=src_managed/.*:silent",
)
```

<p class="info-bubble" markdown="1">
  **NOTE:** for **forward compatibility** in older Scala versions, with the [Silencer plugin](#31-silencer-plugin-scala--213), coupled with [scala-library-compat](https://github.com/scala/scala-library-compat), you can use the new `@nowarn` annotation with older Scala versions, however only the `@nowarn("msg=<pattern>")` filtering is supported.
</p>

## 4. Other linters

You shouldn't stop at Scala's linting options. There are other sbt plugins available that can enforce certain best practices. Off the top of my head:

- [Scalafix](https://github.com/scalacenter/scalafix) (this one can even rewrite the code for you 😉)
- [Wartremover](https://github.com/wartremover/wartremover)
- [Scapegoat](https://github.com/sksamuel/scapegoat)
- [Scalastyle](https://github.com/scalastyle/scalastyle)

With these, you could ban `null` or `Any` from your project, among other beneficial options.

Any useful plugins that I'm missing?

### 4.1. Example: disable .toString conversions

I recently disabled unsafe `.toString` and `string + any` conversions in our work project, with the purpose to not leak sensitive customer data in logs. To do this I enabled "_Wartremover_" with this configuration in `build.sbt`, and it is doing wonders:

```scala
wartremoverErrors in (Compile, compile) := Seq(Wart.ToString, Wart.StringPlusAny),
wartremoverErrors in (Test, test) := Seq.empty,
```

Coupled with a custom logger interface making use of its own type class, we can ensure that data structures containing protected data cannot leak by mistake via logging (either Logback or `println` statements).

## Final words

Scala is a static language, but sometimes it isn't static or opinionated enough. The more you can prove about your code at compile-time, the less defects you can have at runtime.

Now go forth and annoy your colleagues with actually useful compiler errors!
