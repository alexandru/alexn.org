---
title: "Running integration tests, with Scala + sbt"
image: /assets/media/snippets/sbt-integration-tests.png
image_hide_in_post: true
tags:
  - sbt
  - Scala
  - Testing
  - Snippet
feed_guid: /snippets/2020/10/05/running-integration-tests.scala/
redirect_from:
  - /snippets/2020/10/05/running-integration-tests.scala/
  - /snippets/2020/10/05/running-integration-tests.scala.html
description: >
  Scala sbt setup for separating unit tests from integrationt tests.
last_modified_at: 2022-04-01 16:38:35 +03:00
---

For separating integration tests, from unit tests, in `build.sbt`:

```scala
// sbt command-line shortcut
addCommandAlias("ci-integration", "Integration/testOnly -- -n integrationTest")

lazy val IntegrationTest = config("integration").extend(Test)

//...
lazy val root = Project(base = file("."))
  .configs(IntegrationTest)
  .settings(
    // Exclude integration tests by default (in ScalaTest)
    Test / testOptions += Tests.Argument(TestFrameworks.ScalaTest, "-l", "integrationTest"),
    // Include integration tests, by nullifying the above option
    IntegrationTest / testOptions := Seq.empty,
  )
  .settings(
    // Enable integration tests
    inConfig(IntegrationTest)(Defaults.testTasks)
  )
```

Then in your tests:

```scala
import org.scalatest.Tag
import org.scalatest.funsuite.AsyncFunSuite

object IntegrationTest extends Tag("integrationTest")

class MyTestSuite extends AsyncFunSuite {
  // Tagging this test as an integration test
  test("integration works", IntegrationTest) {
    ???
  }
}
```

Then run:

```sh
sbt ci-integration
```
