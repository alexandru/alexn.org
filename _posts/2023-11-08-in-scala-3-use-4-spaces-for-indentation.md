---
title: "In Scala 3, use 4 Spaces for Indentation"
image: /assets/media/articles/2023-scala3-indentation-4-spaces.png
date: 2023-11-08 20:17:04 +02:00
last_modified_at: 2023-11-09 09:46:11 +02:00
generate_toc: true
tags:
  - Programming
  - Programming Rant
  - Scala
  - Scala 3
description: >
  Scala’s coding style advised to use 2 spaces of indentation, but that was before Scala 3’s optional braces, which introduces significant indentation. It’s time for an upgrade of the coding style.
---

<p class="intro" markdown=1>
  Scala's coding style advised to [use 2 spaces of indentation](https://docs.scala-lang.org/style/indentation.html), but that was before Scala 3's [optional braces](https://docs.scala-lang.org/scala3/reference/other-new-features/indentation.html), which introduces significant indentation. It's time for an upgrade of the coding style.
</p>

## Wisdom

The Linux kernel uses [indentation with 8 characters](https://www.kernel.org/doc/html/v6.6/process/coding-style.html#indentation), the reasoning being readability and keeping [cyclomatic complexity](https://en.wikipedia.org/wiki/Cyclomatic_complexity) low. And I quote:

> Rationale: The whole idea behind indentation is to clearly define where a block of control starts and ends. Especially when you've been looking at your screen for 20 straight hours, you'll find it a lot easier to see how the indentation works if you have large indentations.
>
> Now, some people will claim that having 8-character indentations makes the code move too far to the right, and makes it hard to read on an 80-character terminal screen. The answer to that is that if you need more than 3 levels of indentation, you're screwed anyway, and should fix your program.

Using 2-spaces of indentation, in Scala, wasn't terrible despite the high cyclomatic complexity. This is because Scala is very expression-oriented, very type safe, and very functional. This means that the compiler can catch a lot of errors, and due to tools such as exhaustive pattern matching, tail-recursive or higher-order functions, we rarely miss branches. Using 2-spaces for indentation was already in a gray area, however. And with significant indentation, it definitely moved into the red zone.

You may think this isn't serious. I'm seeing indentation errors in blog articles, which weren't there before. And I've made a couple of mistakes myself. Sometimes, the compiler [catches it](./2023-06-06-scala-3-significant-indentation-woes-sample.md), but that may not happen in case of effectful expressions with an irrelevant `Unit` result. And for it to be human-readable, it has to be in your face, unambiguous, even after 10 hours of looking at your screen.

## FAQ

### Why not use tabs?

That battle is already lost:

- A vast majority of style guides advise against tabs;
- For some forsaken reason, people like vertical alignment in Scala, which won't work with tabs (ASCII-art, goddamn);
- People who use spaces [make more money](https://stackoverflow.blog/2017/06/15/developers-use-spaces-make-money-use-tabs/);
- I'm not even sure if Scalafmt supports tabs, can't find the setting.

BONUS — using spaces will piss off the tabs-people:

{% include youtube.html id="SsoOG6ZeyUI" caption="Tabs versus Spaces" %}

### What are similar languages doing?

Here is the style guide for other languages with [the off-side rule](https://en.wikipedia.org/wiki/Off-side_rule):

- Make: tabs (8 characters);
- Python: 4 spaces;
- F#: 4 spaces;
- Elm: 4 spaces;
- Haskell: 2–4 spaces;
- YAML: 2 spaces;
- CoffeeScript: 2 spaces.

This may be my selection bias, but based on these numbers, I could draw a graph with how much people like these languages 😜

<p class="warn-bubble" markdown="1">
  **NOTE:** Python is different from Scala, as it has the *"only one way of doing things"* philosophy, it's statement oriented, and it doesn't allow significant indentation in the middle of expressions. This is the reason for why Python never got multi-line lambdas. Python is conservative, and the average cyclomatic complexity is lower.
</p>

## Tooling & Configuration

Add an [EditorConfig](https://editorconfig.org) file, in the root of your project, like this:

```ini
# EditorConfig is awesome: https://EditorConfig.org

# top-most EditorConfig file
root = true

# Unix-style newlines with a newline ending every file
[*]
end_of_line = lf
insert_final_newline = true

[*.{scala,sbt,sc}]
indent_style = space
indent_size = 4
max_line_length = 100
```

Configure the [Scalafmt](https://scalameta.org/scalafmt/) plugin, with the following settings in `.scalafmt.conf`:

```
runner.dialect = scala3

maxColumn = 100
indent.main = 4

newlines.source = keep
rewrite.scala3.convertToNewSyntax = true
rewrite.scala3.removeOptionalBraces = yes
rewrite.scala3.insertEndMarkerMinLines = 5
```

For your IDE, you should also install extensions for doing syntax coloring for indentation level:

- [Indent-rainbow for VS Code](https://marketplace.visualstudio.com/items?itemName=oderwat.indent-rainbow);
- [Indent-rainbow for IntelliJ](https://plugins.jetbrains.com/plugin/13308-indent-rainbow).

When significant indentation enters your life, add some rainbow coloring 🌈

## Sample

This is a sample from one of my personal/small projects, integrating directly with JDBC. Your mileage may vary, and going from 2-spaces to 4-spaces requires adjustments, but your eyes will thank you for it:

```scala
import cats.effect.IO
import cats.effect.kernel.Resource
import com.zaxxer.hikari.HikariDataSource
import com.zaxxer.hikari.HikariConfig
import cats.effect.kernel.Resource.ExitCase
import java.sql.Connection
import java.sql.PreparedStatement

final case class Database(
    config: JdbcConnectionConfig,
    pool: HikariDataSource
):
    def connection: Resource[IO, Connection] =
        Resource.make:
            IO.blocking:
                pool.getConnection().nn
            .flatTap: c =>
                IO(c.setAutoCommit(true))
        .apply: c =>
            IO.blocking(c.close())

    def transaction: Resource[IO, Connection] =
        for
            conn <- connection
            _ = conn.setAutoCommit(false)
            _ <- Resource.makeCase(IO.unit):
                case ((), ExitCase.Succeeded) =>
                    IO.blocking:
                        conn.commit()
                        conn.setAutoCommit(true)
                case ((), ExitCase.Canceled | ExitCase.Errored(_)) =>
                    IO.blocking:
                        conn.rollback()
                        conn.setAutoCommit(true)
        yield conn

    def withConnection[A](block: Connection ?=> IO[A]): IO[A] =
        connection.use(ref => block(using ref))

    def withTransaction[A](block: Connection ?=> IO[A]): IO[A] =
        transaction.use(ref => block(using ref))

    def query[A](sql: String)(block: PreparedStatement => A)(using Connection): IO[A] =
        IO.blocking:
            summon[Connection].prepareStatement(sql).nn
        .bracket: stm =>
            IO.interruptible:
                block(stm)
            .cancelable:
                IO.blocking(stm.cancel())
        .apply: stm =>
            IO.blocking(stm.close())

end Database

object Database:
    def connect(config: JdbcConnectionConfig): Resource[IO, Database] =
        for
            pool <- createPool(config)
        yield Database(config, pool)

    def createPool(config: JdbcConnectionConfig): Resource[IO, HikariDataSource] =
        Resource.apply(IO.blocking:
            val cfg = HikariConfig().tap: it =>
                it.setDriverClassName(config.driver)
                it.setJdbcUrl(config.url)
                for
                    u <- config.user
                    p <- config.password
                do
                    it.setUsername(u)
                    it.setPassword(p)
                end for
                it.addDataSourceProperty("cachePrepStmts", "true")
                it.addDataSourceProperty("prepStmtCacheSize", "250")
                it.addDataSourceProperty("prepStmtCacheSqlLimit", "2048")
                // Instructs HikariCP to not throw if the pool cannot be seeded
                // with an initial connection
                it.setInitializationFailTimeout(0)

            val res = HikariDataSource(cfg)
            val cancel = IO.blocking(res.close())
            (res, cancel)
        )
end Database
```

Go forth and spread the word! 📢
This stuff matters 💪
