---
title: "Java's Cultural Problem"
image: /assets/media/articles/java-logo.png
tags:
  - Java
  - JVM
  - Languages
  - Programming Rant
description: >
  Java is good by modern standards, from a technical perspective, the platform having received a lot of improvements from Java 8 to 17. Unfortunately, it still stinks, and the problem is its "enterprise" culture.
---

<p class="intro withcap">
  Java is good by modern standards, from a technical perspective, the platform having received a lot of improvements from Java 8 to 17. Unfortunately, it still stinks, and the problem is its "enterprise" culture.
</p>

Let me illustrate the problem via examples ... 

[Quarkus](https://quarkus.io/) is a very promising framework, being a lightweight replacement for Spring, promising compatibility with [GraalVM's Native Image](https://www.graalvm.org/reference-manual/native-image/). Full of hope, I enthusiastically opened its documentation, and started with [how to configure an app](https://quarkus.io/guides/config), expecting something with common sense, like [Dropwizard's quick-start guide](https://www.dropwizard.io/en/latest/getting-started.html#creating-a-configuration-class).

Quarkus depends on [SmallRye Config](https://github.com/smallrye/smallrye-config). And if you want to map your configuration to objects, [the documentation](https://quarkus.io/guides/config-mappings) has this to say:

```java
@ConfigMapping(prefix = "server")
interface ServerConfig {
  String host();

  int port();
}
```

In Java's world, interfaces and abstract classes get used by dependency injection libraries, with methods left abstract in order for their implementation to be filled-in later. Any [FP developer](https://alexn.org/blog/2017/10/15/functional-programming/) should scream when seeing this, because:

1. This should be a pure data structure;
2. These abstract methods signal the possibility of side effects — in general, it is the possibility of side effects that drives the demand for abstract methods, as pure data structures rarely need it;

Do you know what the library does in this instance? I sure don't. It could be reading from a file and block a thread on every access, it could be thread unsafe, I wouldn't know, since whatever it does is magic™️, and this isn't my data structure. Even if it generates a pure data structure, for all I know its implementation can always change in future versions to also launch rockets to Mars.

Since Java 14 we have [records](https://docs.oracle.com/en/java/javase/14/language/records.html). The more common-sense definition doesn't work, the library being (currently) unable to work with it:

```java
//
// java.lang.IllegalStateException: SRCFG00043: 
// The @ConfigMapping annotation can only be placed in interfaces...
// 
@ConfigMapping(prefix = "server")
final record ServerConfig(
  String host,
  int port,
) {}
```

**UPDATE:** to drive this point home, let me make it clear that I don't care from where the configuration is being read (the actual I/O side effect), but rather what happens afterwards. This configuration has an implicit usage protocol that isn't properly expressed by an abstract interface:

1. The `host` and `port` values should be read from the same configuration source;
2. These values shouldn't change during the application's lifecycle, otherwise the interface should provide the ability to register a listener;
3. There's no point in doing the side effect more than once, at the application's start;

In other words, this is not just bad FP design, this is bad OOP design. A better abstract interface would be this, which makes the behavior crystal clear:

```java
interface ServerConfigReader {
  ServerConfig read() throws IOException;
}
```

Dropwizard has a more common-sense approach, as it leaves you in charge of defining a type safe configuration object. But it, too, was infected by the Java EE culture (aka [Jakarta EE](https://en.wikipedia.org/wiki/Jakarta_EE)), preferring [Bean Validation via annotations](https://beanvalidation.org/), with the help of [hibernate-validator](https://hibernate.org/validator/).

```java
public record ServerConfig(
  @NotNull @NotEmpty
  String host,
  @NotNull
  Integer port,
  @NotNull @Email
  String noReplyEmailAddress
) {}
```

I understand the `@NotNull` annotation. Java has `null` in it, all object references can be `null`, and it's too late for that to change. What's odd is that `noReplyEmailAddress` should always be an email address, no matter the context. Not even if you consider this "raw input", because actual "raw input" is a plain string or an array of bytes, and if you ever reach this stage of having a structured `record`, then you should already have an email address.

Java's culture eschews common sense approaches, like defining new types. Defining new types would [make illegal states unrepresentable](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/). Note how, with the following definition, there is no way to get an `EmailAddress` that doesn't pass the "validation", and you don't need a freaking annotations-driven library to validate your values:

```java
import java.util.Objects;

public record EmailAddress(String value) {
  public EmailAddress {
    // We could've used an Either data type, ofc;
    Objects.requireNonNull(value);
    // regexp could be better
    if (!value.matches("^[^@\\s]+@\\S+$")) 
      throw new IllegalArgumentException(
        String.format("'%s' is not a valid email address", value));
  }
}
```

Back to Quarkus, usage of a DI container is required (via CDI annotations), and it's not easy to keep the Java EE crap out of your classes. Reading [their documentation](https://quarkus.io/guides/cdi-reference), by default you'd end up with something like this:

```java
@ConfigMapping(prefix = "greetings")
public interface GreetingServiceConfig {
  String name();
}

// Not a final class
@RequestScoped
public class GreetingService {
  // Abstract, and it cannot be private 😱
  @Inject
  GreetingServiceConfig config;

  public String greeting() {
    return "Hello, " + name + "!";
  }

  // @PreDestroy is required for "closeable" resources; 
  // I would have expected the framework to work with AutoCloseable, 
  // but ALAS it doesn't;
  @PreDestroy
  public void close() {
    LoggerFactory.getLogger(getClass).info("Destroying GreetingService!");
  }
}
```

In the sample above, adding a scope (e.g., `@RequestScoped`) makes the framework automatically initialize this "bean" when needed. And `@PreDestroy` marks methods that have to be called when the "bean" is disposed. Note that my "bean" should implement `Closeable`, but the framework completely ignores it, this being another instance in which a Java EE implementation ignores the Java language. You need that `@PreDestroy`, or otherwise you'll have a leak.

Of note is how this approach will infect your entire codebase, forcing all your downstream users to forgo Java language constructs, such as easily building an instance with `new`, or safe disposal of resources via [try-with-resources](https://docs.oracle.com/javase/tutorial/essential/exceptions/tryResourceClose.html). 

With this approach, not working with `final` classes jumps at me, because ["final" is a best practice](https://www.artima.com/articles/versioning-virtual-and-override). This isn't related to Quarkus in any way, but rather with DI containers in general. For instance, Kotlin's classes are [final by default](https://kotlinlang.org/docs/inheritance.html), yet if you want to [build Spring apps](https://kotlinlang.org/docs/jvm-spring-boot-restful.html), the recommended way would be to import the [kotling-spring](https://kotlinlang.org/docs/all-open-plugin.html#spring-support) plugin, which automatically "opens" your classes that have certain DI-related annotations. Whether you agree with "final by default" as a best practice or not, you're getting a bad deal if the framework makes that choice for you.

Quarkus ships with a [CDI 2.0](https://jakarta.ee/specifications/cdi/2.0/cdi-spec-2.0.html) implementation, like Spring before it, although [its implementation](https://quarkus.io/guides/cdi-reference) isn't fully compliant, since all those annotations and runtime behavior can't be fully supported on top of GraalVM's Native Image. It's odd seeing such a framework forcing the use of Java EE's CDI.

Quarkus makes it hard to have a common-sense [composition root](https://blog.ploeh.dk/2011/07/28/CompositionRoot/). Thankfully, I discovered how, via trial and error, meaning half-baked Stack Overflow answers and using the right keywords to appease the search gods. One of these days I'll find out what the heck is a "bean".

```java
// ------------------------------------------------
// No Java EE crap
public record GreetingServiceConfig(String name) {}

// ------------------------------------------------
// No Java EE crap
public final class GreetingService implements Closeable {
  private final GreetingServiceConfig config;

  public GreetingService(GreetingServiceConfig cfg) {
    this.config = cfg;
  }

  public String greeting() {
    return "Hello, " + config.name() + "!";
  }

  @Override
  public void close() {
    LoggerFactory.getLogger(getClass()).info("Destroying GreetingService!");
  }
}

// ------------------------------------------------
// Implements the "composition root" pattern...
//
// All of these imports are already a code smell, but at 
// least it's localized, and does help with managing DI.
import javax.enterprise.context.RequestScoped;
import javax.enterprise.inject.Disposes;
import javax.ws.rs.Produces;
import javax.enterprise.context.ApplicationScoped;
import javax.enterprise.context.RequestScoped;
import javax.enterprise.inject.Disposes;
import javax.ws.rs.Produces;

public class AppConfiguration {
  @Produces
  @ApplicationScoped
  public GreetingServiceConfig gsConfig() {
    return new GreetingServiceConfig(
      ConfigProvider.getConfig().getValue("greetings.name", String.class)
    );
  }

  @Produces
  @RequestScoped
  public GreetingService greetingService(GreetingServiceConfig config) {
    return new GreetingService(config);
  }

  // Closeable resource needs to be destroyed, and 
  // framework won't do it automatically;
  void disposesGreetingService(@Disposes GreetingService ref) {
    ref.close();
  }
}
```

This way you can limit the impact of Java EE on your codebase. But it does need restraint, and you still have to learn a domain-specific language that has few things in common with Java, the language.

Newcomers to Java have to deal with this nonsense, and it's a pity given that Java 17 is a decent language and awesome platform. Java's ecosystem still hasn't learned enough from its competition, but hope never dies.
