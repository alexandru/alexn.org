---
title: "Cryptographically Strong Random on the JVM"
date: 2024-08-13 11:17:53 +03:00
last_modified_at: 2024-08-13 16:12:44 +03:00
tags:
    - Java
    - Scala
    - Kotlin
    - Programming
    - Security
    - Snippet
---

When generating random numbers for certain use-cases, such as when generating keys / IDs, it's recommended for the random function to be "cryptographically strong". Otherwise, attackers could predict random values, enabling serious security vulnerabilities. 

Instances created via Java's [Random](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Random.html), or [ThreadLocalRandom](https://docs.oracle.com/en/java/javase/21/docs/api///java.base/java/util/concurrent/ThreadLocalRandom.html), or [Scala's Random](https://www.scala-lang.org/api/current/scala/util/Random$.html) are not cryptographically strong. How such random functions usually work is that they use a "pseudo-random number generator" algorithm that starts with a seed initiated from the current timestamp. Therefore, if you can guess the timestamp and know the algorithm, you can predict the entire sequence of pseudo-random numbers.

It's probably good to avoid them by default, unless being insecure (and fast) is the requirement. Prefer the use of [SecureRandom](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/security/SecureRandom.html).

```java
import java.security.SecureRandom

final var secureRandom = new SecureRandom()
// ...
secureRandom.nextInt()
```

`SecureRandom` supports several algorithms, [see list](https://docs.oracle.com/en/java/javase/21/docs/specs/security/standard-names.html#securerandom-number-generation-algorithms). 

```scala
new java.security.SecureRandom().getAlgorithm()
// Output: NativePRNG
```

The default on my machine is `NativePRNG`. This should mean that `nextBytes` uses `/dev/urandom` (shouldn't block), but `generateSeed()` uses `/dev/random`, so it can block. You can specify an algorithm explicitly:

```java
final var secureRandom = SecureRandom.getInstance("NativePRNGNonBlocking");
```

Depending on the algorithm used, these calls can do I/O that can block the current thread in case the random stream has less entropy than requested (see [Wikipedia entry](https://en.wikipedia.org/wiki//dev/random)).

What about multi-threading? `SecureRandom` instances should be thread-safe; however, the implementation could do expensive synchronization, so I find it better to distribute the contention:

```java
// Java
import java.security.SecureRandom;

public class ThreadLocalSecureRandom {
  private static final int COUNT = 100;
  private static final SecureRandom[] INSTANCES = new SecureRandom[COUNT];

  static {
    for (int i = 0; i < COUNT; i++) {
      INSTANCES[i] = new SecureRandom();
    }
  }

  public static SecureRandom current() {
    var threadId = Thread.currentThread().getId();
    var index = Math.floorMod(threadId, COUNT);
    return INSTANCES[index];
  }
}
```

Note that [UUID.randomUUID](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/UUID.html#randomUUID()) is cryptographically strong, using `SecureRandom` under the hood. This also means that it shares the issues of `SecureRandom` — the small possibility that the thread underneath gets blocked when generating random UUIDs. This only happens under certain conditions, however, when we generate UUIDs, we generate a lot of them, in horizontally scaled nodes being started as Docker instances, so the likelihood of hitting this in production increases.

In our Scala project, we have this helper that redirects the generation of new UUIDs to threads that can be blocked (by semantically marking the operation as "blocking"):

```scala
// Scala code
import cats.effect.IO
import java.util.UUID

object UUIDUtils {
  /**
    * `UUID.randomUUID` is a risky operation, as it can block the current thread.
    * This function redirects such calls to the thread-pool meant for blocking IO.
    */
  def generateRandomUUID: IO[UUID] =
    IO.blocking(UUID.randomUUID())
}
```

This can be easily done with Kotlin's Coroutines as well:

```kotlin
// Kotlin code
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.UUID

suspend fun generateRandomUUID(): UUID = 
    withContext(Dispatchers.IO) {
        UUID.randomUUID()
    }
```
