---
title: "Execute Shell Commands in Java/Scala/Kotlin"
image: /assets/media/articles/2022-exec-shell-command.png
date: 2022-10-03 08:13:13 +03:00
last_modified_at: 2022-10-05 09:15:59 +03:00
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

<p class="warn-bubble" markdown="1">
**UPDATE (2022-10-05):** all code samples were updated to concurrently collect the output from the input streams. This makes the code more foolproof, as programs with a lot of output can overflow a stream's buffer.
</p>

This article is a follow-up to: [execute shell commands in F#](./2020-12-06-execute-shell-command-in-fsharp.md).

## Java

This has been developed with Java 17, so please excuse the use of newer syntax additions, such as "record", or "var". The only dependency that this declares is Apache's [commons-text](https://commons.apache.org/proper/commons-text/), because we need to do proper escaping of shell arguments:

```java
///usr/bin/env jbang "$0" "$@" ; exit $?
//JAVA 17+
//DEPS org.apache.commons:commons-text:1.9

import org.apache.commons.text.StringEscapeUtils;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.time.Duration;
import java.util.Arrays;
import java.util.Objects;
import java.util.concurrent.*;
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
   * <p>
   * See {@link #executeShellCommand(ExecutorService, String, String...)}
   * for the version that executes `/bin/sh` commands.
   */
  public static CommandResult executeCommand(
    ExecutorService es,
    Path executable,
    String...args
  ) throws IOException, InterruptedException {
    Objects.requireNonNull(executable);
    Objects.requireNonNull(args);

    final var commandArgs = prepend(
      executable.toAbsolutePath().toString(),
      args
    );
    final var proc = Runtime.getRuntime().exec(commandArgs);
    Future<byte[]> stdout = null;
    Future<byte[]> stderr = null;
    try {
      // Reading output streams in parallel
      stdout = es.submit(() -> proc.getInputStream().readAllBytes());
      stderr = es.submit(() -> proc.getErrorStream().readAllBytes());
      return new CommandResult(
        proc.waitFor(),
        // Should both be ready after `waitFor`
        new String(stdout.get(), StandardCharsets.UTF_8),
        new String(stderr.get(), StandardCharsets.UTF_8)
      );
    } catch (ExecutionException e) {
      throw new RuntimeException(e);
    } finally {
      // Should close streams as well:
      proc.destroy();
      // Idempotent — it's fine if already complete:
      TaskUtils.cancelAll(stdout, stderr);
    }
  }

  /**
   * Executes shell commands.
   * <p>
   * WARN: command arguments need be given explicitly because
   * they need to be properly escaped.
   */
  public static CommandResult executeShellCommand(
    ExecutorService es,
    String command,
    String... args
  ) throws IOException, InterruptedException {
    Objects.requireNonNull(command);
    Objects.requireNonNull(args);

    final String shellCommand = Arrays
      .stream(prepend(command, args))
      .map(StringEscapeUtils::escapeXSI)
      .collect(Collectors.joining(" "));

    return executeCommand(
      es,
      Path.of("/bin/sh"),
      "-c",
      shellCommand
    );
  }

  private static String[] prepend(String elem, String[] array) {
    final var newArray = new String[array.length+1];
    newArray[0] = elem;
    System.arraycopy(array, 0, newArray, 1, array.length);
    return newArray;
  }
}

class TaskUtils {
  public static <A> A withTimeout(
    ExecutorService es, 
    Duration timeout, 
    Callable<A> task
  ) throws InterruptedException, TimeoutException {
    final var ft = new FutureTask<>(task);
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

  public static void cancelAll(Future<?>...futures) {
    for (final var f : futures)
      if (f != null) {
        f.cancel(true);
      }
  }
}

class Main {
  public static void main(String[] args) throws Exception {
    final var es = Executors.newCachedThreadPool();
    try {
      final var r =
        TaskUtils.withTimeout(es, Duration.ofSeconds(2), () ->
          OSUtils.executeShellCommand(es, "ls", "-alh")
        );
      System.out.print(r.stdout());
      System.out.print(r.stderr());
      System.exit(r.exitCode());
    } finally {
      es.shutdown();
    }
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

### Notes on concurrency in Java

The code needs an explicit `ExecutorService` because we need concurrent execution for:

1. reading the STDOUT and STDERR input streams;
2. triggering a timeout with interruption of the running process;

I don't like passing explicit `ExecutorService` references, because blocking I/O is best executed on top of unbounded thread-pools, so the configuration is error-prone. On the other hand, platform threads are expensive, and I also don't like libraries that initiate their own thread-pools for blocking I/O. This is why I'm very happy about the upcoming [Virtual Threads](https://openjdk.org/jeps/425) from Java 19.

To collect the input streams in parallel, we submit 2 jobs in this thread-pool:

```java
Future<byte[]> stdout = es.submit(() -> proc.getInputStream().readAllBytes());
Future<byte[]> stderr = es.submit(() -> proc.getErrorStream().readAllBytes());
```

In Java, cancelling blocking I/O tasks is done via [thread interruption](https://docs.oracle.com/javase/tutorial/essential/concurrency/interrupt.html), however it's a low-level protocol that's very error-prone (especially if you don't own the threads you're interrupting). This is why it's best to leave interruption to higher level abstractions, like `Future<?>` references initialized via `ExecutorService#submit`.  We use `ExecutorService.submit` in order to create `Future` references that can be cancelled. In this case it doesn't really help, as that `InputStream#read` doesn't listen to thread interruption signals, but it's a good practice anyway, as a future implementation might be interruptible.

And to have blocking I/O timing out after a timespan, we can use the same mechanism, although for such use-case you're better off finding a library that does this better. And I am hopeful for what will come out of the additions for [structured concurrency](https://openjdk.org/jeps/428).

```java
public static <A> A withTimeout(
  ExecutorService es, 
  Duration timeout, 
  Callable<A> task
) throws InterruptedException, TimeoutException {
 final var ft = new FutureTask<>(task);
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

Note how I'm just using blocking I/O, and not bothering with any async abstractions here. That's because [Java 19](./2022-09-21-java-19.md) moves Java's paradigm back to blocking I/O, and the underlying API (`Runtime#exec`) is based on blocking I/O.

## Scala

For Scala, we're going to introduce a [Cats-Effect](https://typelevel.org/cats-effect/) dependency to describe the above as an interruptible `IO` data type. It's not in the standard library, but all my Scala projects have an `IO` data type 😎. Besides the cool factor of working with this legendary monadic type, `IO` can handle the timeout under the hood via thread interruption:

```scala
#!/usr/bin/env -S scala-cli shebang -q

//> using scala "2.13.9"
//> using lib "org.typelevel::cats-effect::3.3.12"
//> using lib "org.apache.commons:commons-text:1.9"

import cats.effect.{ExitCode, IO, IOApp}
import cats.syntax.all._
import org.apache.commons.text.StringEscapeUtils
import java.nio.charset.StandardCharsets.UTF_8
import java.nio.file.Path
import scala.concurrent.duration._

final case class CommandResult(
  exitCode: Int,
  stdout: String,
  stderr: String,
)

object OSUtils {
  def executeCommand(executable: Path, args: String*): IO[CommandResult] =
    IO.blocking {
      val commandArgs = executable.toAbsolutePath.toString +: args
      Runtime.getRuntime.exec(commandArgs.toArray)
    }
    // A `bracket` works like `try-with-resources` or `try-finally`
    .bracket { proc =>
      // These aren't "interruptible", what actually interrupts them 
      // is proc.destroy(); and due to how they are used, it's better
      // to not declare them as interruptible, as to not mislead:
      val collectStdout = IO.blocking {
        new String(proc.getInputStream.readAllBytes(), UTF_8)
      }
      val collectStderr = IO.blocking {
        new String(proc.getErrorStream.readAllBytes(), UTF_8)
      }
      // This is actually cancellable via thread interruption
      val awaitReturnCode = IO.interruptible { 
        proc.waitFor()
      }
      for {
        // Starts jobs asynchronously
        stdoutFiber <- collectStdout.start
        stderrFiber <- collectStderr.start
        // Waits for process to complete
        code <- awaitReturnCode
        // Reads output
        stdout <- stdoutFiber.joinWithNever
        stderr <- stderrFiber.joinWithNever
      } yield {
        CommandResult(code, stdout, stderr)
      }
    } { proc =>
      IO.blocking {
        println("Destroying process")
        proc.destroy()
      }
    }

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
      r <- OSUtils.executeShellCommand("ls", "-alh").timeout(3.seconds)
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

### Notes on concurrency in Scala

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

This works because we've used `IO.bracket` and the `IO.interruptible` builder in `executeCommand`, which knows how to cancel the running task via actual thread interruption. And `timeout` creates a concurrent race condition, cancelling the running process after the given timespan. The Cats-Effect library is designed for safe resource acquisition and release, having cancellation baked in.

Forking concurrent "fibers" happens, in this sample, via `.start`. At the moment of writing, forked fibers aren't getting cancelled when the main fiber is cancelled. This is because Cats-Effect has [other mechanisms](https://typelevel.org/cats-effect/docs/std/supervisor) for dealing with scopes, and `.start` is considered to be lower-level. But it was appropriate for this sample.

## Kotlin

For Kotlin, we are going to use its [coroutines](https://kotlinlang.org/docs/coroutines-overview.html) support (with the [kotlinx.coroutines](https://github.com/Kotlin/kotlinx.coroutines/) dependency):

```kotlin
///usr/bin/env jbang "$0" "$@" ; exit $?

//JAVA 17+
//KOTLIN 1.7.20
//DEPS org.apache.commons:commons-text:1.9
//DEPS org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.runInterruptible
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import org.apache.commons.text.StringEscapeUtils
import java.nio.charset.StandardCharsets.UTF_8
import java.nio.file.Path
import kotlin.time.Duration.Companion.seconds

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
  // Blocking I/O should use threads designated for I/O
  withContext(Dispatchers.IO) {
    val cmdArgs = listOf(executable.toAbsolutePath().toString()) + args
    val proc = Runtime.getRuntime().exec(cmdArgs.toTypedArray())
    try {
      // Concurrent execution ensures the stream's buffer doesn't
      // block processing when overflowing
      val stdout = async {
        runInterruptible(Dispatchers.IO) {
          // That `InputStream.read` doesn't listen to thread interruption
          // signals; but for future development it doesn't hurt
          String(proc.inputStream.readAllBytes(), UTF_8)
        }
      }
      val stderr = async {
        runInterruptible(Dispatchers.IO) {
          String(proc.errorStream.readAllBytes(), UTF_8)
        }
      }
      CommandResult(
        exitCode = runInterruptible(Dispatchers.IO) { proc.waitFor() },
        stdout = stdout.await(),
        stderr = stderr.await()
      )
    } finally {
      // This interrupts the streams as well, so it terminates 
      // async execution, even if thread interruption for that 
      // InputStream doesn't work
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

fun main(vararg args: String) = runBlocking {
  // Dealing with timeouts
  val r = withTimeout(3.seconds) {
    executeShellCommand("ls", "-alh")
  }
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

### Notes on concurrency in Kotlin

Kotlin's coroutine jobs are [cancellable](https://kotlinlang.org/docs/cancellation-and-timeouts.html). The [runInterruptible](https://github.com/Kotlin/kotlinx.coroutines/issues/1947) function transforms regular blocking code into a suspending function that can be cancelled, with the cancellation signal being converted into thread interruption. And by explicitly specifying `Dispatchers.IO` as the "coroutine context", we also require the execution to happen on the thread-pool designated for blocking I/O tasks.

Due to use of the API, and due to the [structured concurrency](https://www.youtube.com/watch?v=Mj5P47F6nJg) design, installing timeouts works as expected:

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
