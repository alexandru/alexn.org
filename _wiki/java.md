---
date: 2022-09-12 08:58:10 +03:00
last_modified_at: 2022-09-18 12:42:18 +03:00
---

# Java

## Resources

### Core functionality

- [Guava](https://github.com/google/guava);
- [Vavr](https://github.com/vavr-io/vavr): persistent collections, Scala-inspired;
- [PCollections](https://github.com/hrldcpr/pcollections): persistent collections;

### SQL libraries

- [Hibernate](https://hibernate.org/): ORM, and I hate ORMs;
- [JDBI](https://jdbi.org/): light layer on top of JDBC, string-based queries;
- [jOOQ](https://www.jooq.org/): type safe SQL, alternative to Hibernate;

### Database migrations

- [Flyway](https://flywaydb.org/);
- [Liquidbase](https://www.liquibase.org/);

### Frameworks

- [Dropwizard](https://www.dropwizard.io/);
- [Quarkus](https://quarkus.io/): built for compatibility with GraalVM's native image;
- [Spring Boot](https://spring.io/projects/spring-boot/) (see [the initializer](https://start.spring.io/));

### Tools

- [Gradle](https://gradle.org/): the accepted Maven alternative;
- [JBang](https://www.jbang.dev/): scripting with Java;

## Setup

### SDKMan!

Install:

```sh
https://sdkman.io/install
```

To list available Java SDKs:

```sh
sdk list java
```

To install:

```sh
# OpenJDK
sdk install java 11.0.2-open

# GraalVM
sdk install 22.2.r17-grl

# Oracle
sdk install 17.0.4-oracle
```

After the installation of GraalVM, add this to `.zshrc`:

```sh
export GRAALVM_HOME=$HOME/.sdkman/candidates/java/22.2.r17-grl/
```

Also install the `native-image`:

```sh
${GRAALVM_HOME}/bin/gu install native-image
```


### OpenJDK Builds

Noteworthy:

- [Eclipse Temurin](https://adoptium.net/): the old AdoptOpenJDK;
- [IBM Semeru](https://developer.ibm.com/languages/java/semeru-runtimes/): these are the new [OpenJ9](https://www.eclipse.org/openj9/) builds;
- [jdk.java.net](https://jdk.java.net/): reference OpenJDK builds;

Also see: [JDK distributions](https://sdkman.io/jdks).

## Resources / Links

- [New Developer Friendly Features After Java 8](https://piotrminkowski.com/2021/02/01/new-developer-friendly-features-after-java-8/) — Piotr Mińkowski;
- [New language features since Java 8 to 18](https://advancedweb.hu/new-language-features-since-java-8-to-18/) — Dávid Csákvári;

### Dependency injection / CDI

- [Quarkus / CDI and "java config" DI definitions](https://stackoverflow.com/questions/58544079/quarkus-cdi-and-java-config-di-definitions);
  - [Composition Root](https://blog.ploeh.dk/2011/07/28/CompositionRoot/);
  