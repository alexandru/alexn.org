---
title: "Execute Shell Commands in Java/Scala/Kotlin"
image: /assets/media/articles/2022-exec-shell-command.png
date: 2022-10-03 08:13:13 +03:00
last_modified_at: 2022-10-03 16:15:30 +03:00
tags:
  - Snippet
  - Java
  - Scala
  - Kotlin
generate_toc: true
description: >
  The following describes snippets for executing shell commands, in Java, Scala, and Kotlin, using standard functionality. It's also useful to compare Java vs Scala vs Kotlin for this particular problem.
---

<p class="intro withcap" markdown=1>
The following describes snippets for executing shell commands, in Java, Scala, and Kotlin, using standard functionality. It's also useful to compare Java vs Scala vs Kotlin for this particular problem.
</p>

<p class="info-bubble" markdown=1>
These snippets make use of [Runtime.getRuntime().exec](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/lang/Runtime.html#exec(java.lang.String%5B%5D)). You may find libraries that already do this, but I find dependencies to be a risk, and wheel reinvention to be fun. I apologize for the NIH in advance.
</p>

This article is a follow-up to: [execute shell commands in F#](./2020-12-06-execute-shell-command-in-fsharp.md).

## Java

This has been tested with Java 17, so please excuse the use of newer syntax additions, such as "record", or "var". The only dependency that this declares is Apache's [commons-text](https://commons.apache.org/proper/commons-text/), because we need to do proper escaping of shell arguments.

```java
///usr/bin/env jbang "$0" "$@" ; exit $?

//JAVA 17+
//DEPS org.apache.commons:commons-text:1.9

import org.apache.commons.text.StringEscapeUtils;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.time.Duration;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;
import java.util.Objects;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.stream.Collectors;

record CommandResult(
  int exitCode,
  String stdout,
  String stderr
) {}

class OSUtils {
  /**
   * Executes a program. This needs to be a valid path on the
   * file system.
   *
   * See {@link #executeShellCommandTimed(String, String[], Duration)}
   * for the version that executes `/bin/sh` commands.
   */
  public static CommandResult executeCommandTimed(
    Path executable,
    String[] args,
    Duration timeout
  ) throws IOException, InterruptedException, TimeoutException {
    Objects.requireNonNull(executable);
    Objects.requireNonNull(args);

    final var commandArgs = prepend(
      executable.toAbsolutePath().toString(),
      args
    );
    final var proc = Runtime.getRuntime().exec(commandArgs);
    try {
      if (timeout != null) {
        final var millis = timeout.get(ChronoUnit.MILLIS);
        if (!proc.waitFor(millis, TimeUnit.MILLISECONDS))
          throw new TimeoutException(
            String.format("Command execution timed out after %s", timeout)
          );
      }
      return new CommandResult(
        proc.waitFor(),
        new String(proc.getInputStream().readAllBytes(), StandardCharsets.UTF_8),
        new String(proc.getErrorStream().readAllBytes(), StandardCharsets.UTF_8)
      );
    } finally {
      proc.destroy();
    }
  }

  /**
   * Convenience overload for:
   * {@link #executeShellCommandTimed(String, String[], Duration)}.
   *
   * For shell commands see:
   * {@link #executeShellCommand(String, String...)}.
   */
  public static CommandResult executeCommandTimed(
    Path command,
    String...args
  ) throws IOException, InterruptedException {
    try {
      return executeCommandTimed(command, args, null);
    } catch (TimeoutException e) {
      throw new RuntimeException(e);
    }
  }

  /**
   * Executes shell commands.
   *
   * WARN: command arguments need be given explicitly because
   * they need to be properly escaped.
   */
  public static CommandResult executeShellCommandTimed(
    String command,
    String[] args,
    Duration timeout
  ) throws IOException, InterruptedException, TimeoutException {
    Objects.requireNonNull(command);
    Objects.requireNonNull(args);

    final var shellCommand = Arrays
      .stream(prepend(command, args))
      .map(StringEscapeUtils::escapeXSI)
      .collect(Collectors.joining(" "));

    return executeCommandTimed(
      Path.of("/bin/sh"),
      new String[] { "-c", shellCommand },
      timeout
    );
  }

  /**
   * Convenience overload for:
   * {@link #executeShellCommandTimed(String, String[], Duration)}.
   *
   * WARN: command arguments need be given explicitly because
   * they need to be properly escaped.
   */
  public static CommandResult executeShellCommand(
    String command,
    String...args
  ) throws IOException, InterruptedException {
    try {
      return executeShellCommandTimed(command, args, null);
    } catch (TimeoutException e) {
      throw new RuntimeException(e);
    }
  }

  // This should be standard functionality, I shouldn't need to import a
  // library to create a copy with a prepended element;
  private static String[] prepend(String elem, String[] array) {
    final var newArray = new String[array.length+1];
    newArray[0] = elem;
    System.arraycopy(array, 0, newArray, 1, array.length);
    return newArray;
  }
}

class Main {
  public static void main(String[] args) 
    throws IOException, InterruptedException {

    final var r = OSUtils.executeShellCommand("ls", "-alh");
    System.out.print(r.stdout());
    System.out.println(r.stderr());
    System.exit(r.exitCode());
  }
}
```

### Scripting with Java

The above sample is an executable script, you can play with it directly via [JBang](https://www.jbang.dev/). On macOS this can be easily installed via:

```sh
brew install jbang

# You might want this too:
brew install openjdk@17
```

Save the above script as `runCommand.java`. You can then execute the script above:

```sh
jbang ./runCommand.java

# Or make the script executable; works due to the included 'shebang'
# (https://en.wikipedia.org/wiki/Shebang_(Unix))
chmod +x ./runCommand.java

# And then run it directly
./runCommand.java
```

### Handling Timeouts in Java

The above sample, in Java, has overloads for specifying a `Duration`. This happens because commands can take forever to execute, and a timeout should also destroy the active process:

```java
OSUtils.executeShellCommandTimed(
  "sleep",
  new String[] { "30" },
  Duration.ofSeconds(3)
);
```

In Java such concerns could be handled via [thread interruption](https://docs.oracle.com/javase/tutorial/essential/concurrency/interrupt.html), however interruption in Java is low-level and error-prone. Doable if careful:

```java
import java.util.concurrent.*;
//...
final var ec = Executors.newCachedThreadPool();
try {
  final var ft = new FutureTask<>(() ->
    // Executing something that takes a long time
    OSUtils.executeShellCommand("sleep", "30")
  );
  ec.submit(ft);
  try {
    final var r = ft.get(3, TimeUnit.SECONDS);
    System.out.print(r.stdout());
    System.out.println(r.stderr());
    System.exit(r.exitCode());
  } catch (TimeoutException e) {
    // Remember to send the actual interruption signal, 
    // or you'll have a process leak
    ft.cancel(true);
    throw e;
  }
} finally {
  ec.shutdown();
}
```

You should probably extract a utility for this, or find a library that does this better:

```java
public static <A> A withTimeout(
  ExecutorService es, 
  Duration timeout, 
  Callable<A> cb
) throws InterruptedException, TimeoutException {
  final var ft = new FutureTask<>(cb);
  try {
    es.submit(ft);
    return ft.get(timeout.toMillis(), TimeUnit.MILLISECONDS);
  } catch (ExecutionException e) {
    ft.cancel(true);
    throw new RuntimeException(e);
  } catch (Exception e) {
    ft.cancel(true);
    throw e;
  }
}
```

I don't like that explicit `ExecutorService` (I/O operation being blocking, the thread-pool probably needs to be unbounded, hence configuration is error-prone), but in this area I'm very excited of [Java 19](./2022-09-21-java-19.md).

## Scala

For Scala, we're going to introduce a [Cats-Effect](https://typelevel.org/cats-effect/) dependency to describe the above as an interruptible `IO` data type. It's not in the standard library, but all my Scala projects have an `IO` data type 😎. Besides the cool factor of working with this legendary monadic type, `IO` can handle the timeout under the hood via thread interruption:

```scala
#!/usr/bin/env -S scala-cli shebang -q

//> using scala "2.13.9"
//> using lib "org.typelevel::cats-effect::3.3.12"
//> using lib "org.apache.commons:commons-text:1.9"

import cats.effect.{ExitCode, IO, IOApp}
import org.apache.commons.text.StringEscapeUtils
import java.nio.charset.StandardCharsets.UTF_8
import java.nio.file.Path

final case class CommandResult(
  exitCode: Int,
  stdout: String,
  stderr: String,
)

object OSUtils {
  /** Executes a program. This needs to be a valid path on the
    * file system.
    *
    * See [[executeShellCommand]] for the version that executes 
    * `/bin/sh` commands.
    */
  def executeCommand(executable: Path, args: String*): IO[CommandResult] =
    IO.interruptible {
      val commandArgs = executable.toAbsolutePath.toString +: args
      val proc = Runtime.getRuntime.exec(commandArgs.toArray)
      try {
        CommandResult(
          exitCode = proc.waitFor(),
          stdout = new String(proc.getInputStream.readAllBytes(), UTF_8),
          stderr = new String(proc.getErrorStream.readAllBytes(), UTF_8)
        )
      } finally {
        proc.destroy()
      }
    }

  /** Executes shell commands.
    *
    * WARN: command arguments need be given explicitly because
    * they need to be properly escaped.
    */
  def executeShellCommand(command: String, args: String*): IO[CommandResult] =
    executeCommand(
      Path.of("/bin/sh"),
      "-c",
      (command +: args).map(StringEscapeUtils.escapeXSI).mkString(" ")
    )
}

object Main extends IOApp {
  def run(args: List[String]): IO[ExitCode] =
    for {
      r <- OSUtils.executeShellCommand("ls", "-alh")
      _ <- IO.print(r.stdout)
      _ <- IO.print(r.stderr)
    } yield ExitCode(r.exitCode)
}
```

### Scripting with Scala

The above Scala sample is an executable script, you can play with it directly via [Scala CLI](https://scala-cli.virtuslab.org/). On macOS this can be easily installed via:

```sh
brew install Virtuslab/scala-cli/scala-cli
```

Save the above script as `runCommand.scala`. You can then execute it:

```sh
scala-cli run ./runCommand.scala

# Or make the script executable; works due to the included 'shebang'
# (https://en.wikipedia.org/wiki/Shebang_(Unix))
chmod +x ./runCommand.scala

# And then run it directly
./runCommand.scala
```

### Handling Timeouts in Scala

`IO` can handle this automatically via its [timeout](https://typelevel.org/cats-effect/api/3.x/cats/effect/IO.html#timeout[A2%3E:A](duration:scala.concurrent.duration.FiniteDuration):cats.effect.IO[A2]) method:

```scala
import scala.concurrent.duration._
//...
for {
  r <- OSUtil
    .executeShellCommand("sleep", "30")
    .timeout(3.seconds)
  _ <- IO.print(r.stdout)
  _ <- IO.print(r.stderr)
} yield ExitCode(r.exitCode)
```

This works because we've used the `IO.interruptible` builder in `executeCommand`, which knows how to cancel the running task via actual thread interruption. And `timeout` creates a concurrent race condition, cancelling the running process after the given timespan.

## Kotlin

For Kotlin, we are going to use its [coroutines](https://kotlinlang.org/docs/coroutines-overview.html) support (with the [kotlinx.coroutines](https://github.com/Kotlin/kotlinx.coroutines/) dependency):

```kotlin
///usr/bin/env jbang "$0" "$@" ; exit $?

//JAVA 17+
//KOTLIN 1.7.20
//DEPS org.apache.commons:commons-text:1.9
//DEPS org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.runInterruptible
import org.apache.commons.text.StringEscapeUtils
import java.nio.charset.StandardCharsets.UTF_8
import java.nio.file.Path

data class CommandResult(
  val exitCode: Int,
  val stdout: String,
  val stderr: String,
)

/**
 * Executes a program. This needs to be a valid path on the
 * file system.
 *
 * See [executeShellCommand] for the version that executes
 * `/bin/sh` commands.
 */
suspend fun executeCommand(
  executable: Path, 
  vararg args: String
): CommandResult =
  runInterruptible(Dispatchers.IO) {
    val cmdArgs = listOf(executable.toAbsolutePath().toString()) + args
    val proc = Runtime.getRuntime().exec(cmdArgs.toTypedArray())
    try {
      CommandResult(
        exitCode = proc.waitFor(),
        stdout = String(proc.getInputStream().readAllBytes(), UTF_8),
        stderr = String(proc.getErrorStream().readAllBytes(), UTF_8)
      )
    } finally {
      proc.destroy()
    }
  }

/**
 * Executes shell commands.
 *
 * WARN: command arguments need be given explicitly because
 * they need to be properly escaped.
 */
suspend fun executeShellCommand(
  command: String, 
  vararg args: String
): CommandResult =
  executeCommand(
    Path.of("/bin/sh"),
    "-c",
    (listOf(command) + args)
      .map(StringEscapeUtils::escapeXSI)
      .joinToString(" ")
  )

fun main() = runBlocking {
  val r = executeShellCommand("ls", "-alh")
  System.out.print(r.stdout)
  System.err.print(r.stderr)
  System.exit(r.exitCode)
}
```

### Scripting with Kotlin

[JBang](https://www.jbang.dev/) has experimental Kotlin support. Save the above script as `runCommand.kt`. You can then execute the script like so:

```sh
jbang ./runCommand.kt

# Or make the script executable; works due to the included 'shebang'
# (https://en.wikipedia.org/wiki/Shebang_(Unix))
chmod +x ./runCommand.kt

# And then run it directly
./runCommand.kt
```

### Handling Timeouts in Kotlin

Kotlin's coroutine jobs are [cancellable](https://kotlinlang.org/docs/cancellation-and-timeouts.html). The [runInterruptible](https://github.com/Kotlin/kotlinx.coroutines/issues/1947) function transforms regular blocking code into a suspending function that can be cancelled, with the cancellation signal being converted into thread interruption. And by explicitly specifying `Dispatchers.IO` as the "coroutine context", we also require the execution to happen on the thread-pool designated for blocking I/O tasks.

So installing timeouts works out of the box:

```kotlin
import kotlinx.coroutines.withTimeout
import kotlin.time.Duration.Companion.seconds

//...
val r = withTimeout(3.seconds) {
  executeShellCommand("sleep", "30")
}
```

This is equivalent with the Scala sample. Kotlin's "suspended" functions are slick, for many purposes being [equivalent with IO](https://arrow-kt.io/docs/effects/io/) (also see [Arrow](https://arrow-kt.io/)).

An `IO` data type can be better due to reusability and compositionality, but it relies on `flatMap` handling the sequencing of effects (instead of Java's `;`), which is at the same time a strength and a weakness — for one, it can be awkward to learn and use without syntactic sugar, it leads to more TIMTOWTDI, and it encourages reuse via a lot of [type-level programming that may be too complex](https://github.com/fsharp/fslang-suggestions/issues/243#issuecomment-916079347). In Scala having [type classes](./2022-05-13-oop-vs-type-classes-part-1-ideology.md) and [Cats](https://typelevel.org/cats/) is pretty awesome, though.
