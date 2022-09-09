---
title: "Scala isn't fun anymore"
tags: 
  - Personal
  - Politics
  - Scala
image: /assets/media/articles/scala.png
date: 2022-09-09 08:00:37 +03:00
last_modified_at: 2022-09-09 11:02:52 +03:00
description: >
  I've just spent over a day, going to sleep at 1:00 am, to upgrade dependencies and fix eviction warnings in the build of a Scala project.
---

I've just spent over a day, going to sleep at 1:00 am, to upgrade dependencies and fix eviction warnings in the build of a Scala project. Had to fix the usual suspects:

- [Slf4j-api](https://www.slf4j.org/) `1.7.x` evicted by `2.0.0`. They are binary backwards compatible, but the linking to the backend happens at runtime, so it can fail at runtime. This was a mix and match job. I had to downgrade [Doobie](https://github.com/tpolecat/doobie) from `0.13.4` to `0.13.3`, because that one patch version also bumped HikariCP from `3.4.5` to `4.0.3`, which in turn bumped `slf4j-api`.
- [HikariCP](https://github.com/brettwooldridge/HikariCP), also a mix and match job, because [akka-persistence-jdbc](https://github.com/akka/akka-persistence-jdbc) also depends on it. I would have stayed on `4.0.3`, but Akka wants `3.4.x`, and I have no idea if they are compatible.
- [Scala-xml](https://github.com/scala/scala-xml) `1.2.0` evicted by `2.1.0`; unfortunately we rely on Twirl templates, that require both a sbt plugin and a library dependency, and sbt plugins still rely on Scala 2.12, which require Scala-xml `1.2.0`. The fix was to forcefully upgrade to `2.1.0` and hope for the best.
- [Jackson (JSON)](https://github.com/FasterXML/jackson) `2.11.4` evicted by `2.12.7` — normally, in Java world, this would be fine, except that [jackson-module-scala](https://github.com/FasterXML/jackson-module-scala) is sensitive to minor version bumps, and it fails at runtime (thank God we have unit tests); and we wouldn't use `jackson-module-scala`, but ALAS, [akka-serialization-jackson](https://doc.akka.io/docs/akka/current/serialization-jackson.html) depends on it. This was hard to fix, because it manifests as a weird runtime exception, and I had no idea where it came from or who's complaining.
  - In case you're wondering, we use [Circe](https://github.com/circe/circe) too, but Circe has been fine this round, as nobody updated its minor version (`early-semver`).
  - **You can guess the maturity of any Scala project by the number of libraries it uses to do JSON parsing.**
- `org.apache.kafka:kafka-clients` version `3.0.1` was also evicted by `7.0.5-css`; the former is used by [akka-streams-kafka](https://github.com/akka/alpakka-kafka), whereas the latter is required by [kafka-avro-serializer](https://github.com/confluentinc/schema-registry); no worries, I consulted this [HTML table of compatibility](https://docs.confluent.io/platform/current/installation/versions-interoperability.html#cp-ak-compatibility) and I think they were compatible.

Couple of months ago this list was bigger, but I prefer dropping dependencies causing issues like hot potatoes.

This was before I went in to fix the compilation and the test errors; at least Scala fails a lot at compile time, instead of runtime. Getting `sbt evicted` to stay silent can be a chore. In fairness, sbt is really sweet for the ability to turn eviction warnings to errors, by setting the [versioning schemes](https://www.scala-lang.org/blog/2021/02/16/preventing-version-conflicts-with-versionscheme.html) for the required dependencies. Did I mention that I absolutely love sbt? (except for how freaking slow it is)

Anyway, this wasn't fun:

```scala
// https://www.scala-lang.org/blog/2021/02/16/preventing-version-conflicts-with-versionscheme.html
libraryDependencySchemes ++= ourLibraryVersioningSchemes,
// Configures eviction reports
evicted / evictionWarningOptions := EvictionWarningOptions.default
  .withWarnDirectEvictions(true)
  .withWarnEvictionSummary(true)
  .withWarnScalaVersionEviction(true)
  .withWarnTransitiveEvictions(true)
  .withShowCallers(true),
// Checks evictions on resolving dependencies
update := update.dependsOn(evicted).value,
```

PRO-TIP: to hunt down from where transitive dependencies come from, `sbt dependencyBrowseTreeHTML` is your friend 😉😍

Many Scala libraries are really well maintained and stable (e.g., Cats), and we've got the tools to do it, such as sbt being awesome at conditional/cross compilation, checking versioning schemes, or the availability of [Mima](https://github.com/lightbend/mima), a plugin meant to check for breakages of binary compatibility. It's a useful case study in communities adapting to their sins. But being the user, and having to deal with all the breakage, is still painful as hell, and I feel that in general many libraries have no respect for downstream users suffering from breakage.

Speaking of versioning schemes, I've set Akka's stuff to `pvp`. This means that minor versions break compatibility, which should trigger eviction errors. Not sure if it will work. I hope we can pin it down to `2.6.20` ([the last Open Source version](./2022-09-07-akka-is-moving-away-from-open-source.md)) 🤷‍♂️ 

This new development is such a shame, as in my experience Akka has been the gravitational force attracting a vast majority of the Java programmers (the ones into programming, not data science 😛). That will be over soon. I wonder what will happen to the libraries depending on Akka. You may think of libraries meant for the enterprise, with corporate sponsorship, but what about libraries made by volunteers, like [Twitter4s](https://github.com/DanielaSfregola/twitter4s)? Oh, well.

We're left with the Scala FP communities, which yield awesome libraries and are awesome people, but the ecosystem is essentially a microcosm of the US political landscape. I'm guessing all programming communities are turning to this nowadays. As an Easter European, however, it kind of pisses me off.

Maybe this is just me getting older (going to turn 40 soon). Maybe all programming is terrible.  I've actually started to read [Java newsletters](https://blog.jetbrains.com/idea/2022/09/java-annotated-monthly-september-2022/), maybe Spring isn't that bad, I'm also having affectionate memories of JavaScript and Python, and thinking about having a plan B in case this programming thing doesn't work out 🤷‍♂️

Oh, [how the mighty have fallen](./2020-10-10-when-my-world-vanishes.md)!

Bye, going to reboot my MacBook, since IntelliJ wanted to reload the project, and nothing works anymore.
