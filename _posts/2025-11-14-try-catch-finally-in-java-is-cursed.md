---
title: "Try-catch-finally in Java is Cursed"
image: /assets/media/articles/2025-java-try-finally.png
image_hide_in_post: true
date: 2025-11-10T11:54:08+02:00
last_modified_at: 2025-11-14T10:18:11+02:00
tags:
  - Java
  - Programming
description: >
  In Java, try-catch-finally can ignore returns, mask exceptions, and breaks the interruption protocol.
---

Java has a usable interruption protocol, and that's good. However, one problem with it is that it relies on `InterruptedException`, and it can be caught and ignored. Being a "checked exceptions", many developers simply ignore it

```java
BlockingQueue<Task> queue;
// ...
while (isActive) {
  try {
    var task = queue.take();
    process(task);
  } catch (InterruptedException e) {
    // ignore
  }
}
```

There are reasons for why you may want to react to a thread interrupt. Maybe you want to close some resources. What's bad about it is that you can continue as if nothing happened.

But it's not just the interruption protocol that's problematic here, but the semantic of `try-catch-finally` as well ([sample attribution](https://news.ycombinator.com/item?id=45808899)):

```java

void infiniteLoop() {
  while (true) {
    try { return; } 
    finally { continue; }
  }
}

```

Yep, you can ignore `return`, too. This works as well:

```java
try {
  return 42;
} finally {
  // What actually gets returned
  return 0;
}
```

Also, exception suppression — in this case, the client won't get `FileNotFoundException`, not even as a "suppressed" exception.

```java
try {
  // can throw FileNotFoundException
  return Files.readString(Path.of("missing.txt")); 
} finally {
  throw new RuntimeException("Cleanup failed");
}
```

If you think this can't happen, consider the classic resource-usage pattern:

```java
InputStream in = ...;
try {
  process(in);
} finally {
  // can throw IOException, masking any exception 
  // that happened in `process`
  in.close(); 
}
```

Thankfully, this is improved by `try-with-resources`, in which case the exception thrown by `close()` gets added as a "suppressed" exception to the one thrown by the `try` block.
