---
title: "Running integration tess in Scala, with sbt"
image: /assets/media/snippets/sbt-integration-tests.png
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
