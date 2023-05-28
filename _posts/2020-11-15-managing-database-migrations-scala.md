---
title: "Managing Database Migrations in Scala"
tags:
  - FP
  - Scala
  - SQL
  - Typelevel
description: The database schema should be described as code, in your repository. And you should be able to semi-automatically update your database schema on new deployments.
date: 2020-11-15 18:17:25+0200
image: /assets/media/articles/db-migrations-scala.png
generate_toc: true
---

<p class="intro">
  The database schema should be described as code, in your repository. And you should be able to semi-automatically update your database schema on new deployments.
</p>

A very popular Java library for handling migrations is [Flyway](https://flywaydb.org/). We'll combine that with [Typesafe Config (aka HOCON)](https://github.com/lightbend/config) for configuration, along with [PureConfig](https://github.com/pureconfig/pureconfig) for parsing it. And [Cats Effect](https://github.com/typelevel/cats-effect) for describing our effects, because we love FP, right? 😎

<p class="info-bubble" markdown="1">
  This is a complete solution, that's customizable and easy to implement (couple of lines of code), that can be used in multi-project builds, and that doesn't tie you to a [particular framework](https://www.playframework.com/documentation/2.8.x/Evolutions), or a [particular build tool](http://www.lihaoyi.com/mill/page/contrib-modules.html#flyway), or an [enterprise solution](https://www.liquibase.org/) solving problems that you don't have.
</p>

## 1. Setup MySQL on localhost

We're going to use [MariaDB (MySQL)](https://mariadb.org/) as our database, but this works with any relational database.

To start a MariaDB instance on your localhost, you could use Docker:

```sh
# NOTE: --rm means the container gets deleted after shutdown;
# if you want to keep the container around, then remove it

docker run --rm \
  --name mariadb \
  -e MYSQL_ROOT_PASSWORD=pass \
  -p 3306:3306 \
  mariadb:10.4
```

Then to create our initial database:

```sh
docker exec -it mariadb mysql -uroot -ppass \
  -e "CREATE DATABASE MyAwesomeApp"
```

<p class="warn-bubble" markdown="1">
  **WARN:** as a best practice, the `CREATE DATABASE` statement should not be in your database migrations. The database, from production at least, must be created manually. Do not create or refer to specific databases in your migrations!
</p>

## 2. Initial project setup

Start a new project with:

```
sbt new scala/scala-seed.g8
```

Then add these library dependencies to your `build.sbt`:

```scala
lazy val root = (project in file("."))
  .settings(
    //... add these ...
    libraryDependencies ++= Seq(
      "org.typelevel" %% "cats-effect" % "2.2.0",
      "com.github.pureconfig" %% "pureconfig" % "0.14.0",
      "org.flywaydb" % "flyway-core" % "7.2.0",
      "mysql" % "mysql-connector-java" % "8.0.22",
      "com.typesafe.scala-logging" %% "scala-logging" % "3.9.2",
    )
  )
```

## 3. Configuration

The app's configuration is best described as concrete types in your project. Add something like this for the JDBC connection parameters, in `src/main/resources/application.conf`:

```js
example.jdbc {
  driver = "com.mysql.cj.jdbc.Driver"

  host = "127.0.0.1"
  host = ${?DB_HOST}

  port = "3306"
  port = ${?DB_PORT}

  dbName = "MyAwesomeApp"
  dbName = ${?DB_NAME}

  url = "jdbc:mysql://"${example.jdbc.host}":"${example.jdbc.port}"/"${example.jdbc.dbName}
  url = ${?DB_CONNECTION_URL}

  user = "root"
  user = ${?DB_USER}

  password = "pass"
  password = ${?DB_PASS}

  migrations-table = "FlywaySchemaHistory"

  migrations-locations = [
    "classpath:example/jdbc"
  ]
}
```

Which is modelled by a type like this on the Scala side:

```scala
package example
package jdbc

import cats.effect.Sync
import com.typesafe.config.{ Config, ConfigFactory }
import pureconfig.{ ConfigConvert, ConfigSource }
import pureconfig.generic.semiauto._

final case class JdbcDatabaseConfig(
  url: String,
  driver: String,
  user: Option[String],
  password: Option[String],
  migrationsTable: String,
  migrationsLocations: List[String]
)

object JdbcDatabaseConfig {
  def loadFromGlobal[F[_]: Sync](configNamespace: String): F[JdbcDatabaseConfig] =
    Sync[F].suspend {
      val config = ConfigFactory.load()
      load(config.getConfig(configNamespace))
    }

  def load[F[_]: Sync](config: Config): F[JdbcDatabaseConfig] =
    Sync[F].delay {
      ConfigSource.fromConfig(config).loadOrThrow
    }

  // Integration with PureConfig
  implicit val configConvert: ConfigConvert[JdbcDatabaseConfig] =
    deriveConvert
}
```

NOTES:

- `migrations-table` specifies the name of the table auto-created by Flyway, used to keep track of what migrations have been executed thus far;
- `migrations-locations` is a list of locations for our migrations, most often a list of packages available on the classpath;
- `F[_]` here is a datatype for managing I/O, such as `cats.effect.IO` or `monix.eval.Task`, but there's no reason to not make these functions generic, such that you can later use whatever you want; see the documentation for [Cats Effect's Sync](https://typelevel.org/cats-effect/typeclasses/sync.html);

I chose this design because we may have a [multi-project build](https://www.scala-sbt.org/1.x/docs/Multi-Project.html), and we may want to run database migrations for all projects in one go.

## 4. Flyway library integration

We can now make use of [Flyway](https://github.com/flyway/flyway), coupled with our config above:

```scala
package example
package jdbc

import cats.effect.Sync
import cats.implicits._
import com.typesafe.scalalogging.LazyLogging
import org.flywaydb.core.api.configuration.FluentConfiguration
import org.flywaydb.core.api.Location
import org.flywaydb.core.Flyway
import scala.jdk.CollectionConverters._

object DBMigrations extends LazyLogging {

  def migrate[F[_]: Sync](config: JdbcDatabaseConfig): F[Int] =
    Sync[F].delay {
      logger.info(
        "Running migrations from locations: " +
        config.migrationsLocations.mkString(", ")
      )
      val count = unsafeMigrate(config)
      logger.info(s"Executed $count migrations")
      count
    }

  private def unsafeMigrate(config: JdbcDatabaseConfig): Int = {
    val m: FluentConfiguration = Flyway.configure
      .dataSource(
        config.url,
        config.user.orNull,
        config.password.orNull
      )
      .group(true)
      .outOfOrder(false)
      .table(config.migrationsTable)
      .locations(
        config.migrationsLocations
          .map(new Location(_))
          .toList: _*
      )
      .baselineOnMigrate(true)

    logValidationErrorsIfAny(m)
    m.load().migrate().migrationsExecuted
  }

  private def logValidationErrorsIfAny(m: FluentConfiguration): Unit = {
    val validated = m.ignorePendingMigrations(true)
      .load()
      .validateWithResult()

    if (!validated.validationSuccessful)
      for (error <- validated.invalidMigrations.asScala)
        logger.warn(s"""
          |Failed validation:
          |  - version: ${error.version}
          |  - path: ${error.filepath}
          |  - description: ${error.description}
          |  - errorCode: ${error.errorDetails.errorCode}
          |  - errorMessage: ${error.errorDetails.errorMessage}
        """.stripMargin.strip)
  }
}
```

## 5. Create your first DB migration

Add this in `src/main/resources/example/jdbc/V0010__CreateMyFirstTable.sql`:

```sql
CREATE TABLE MyFirstTable(
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  uKey VARCHAR(200) NOT NULL,
  uValue TEXT NOT NULL,
  createdAt TIMESTAMP NOT NULL,
  updatedAt TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX MyFirstTable__Key
ON MyFirstTable(uKey);
```

## 6. Add sbt command

Define a command, such that we can apply all migrations like:

```scala
// TBD, does not work yet
sbt run-db-migrations
```

First, define an "app" that can run all migrations:

```scala
package example
package jdbc

import cats.implicits._
import cats.effect.IOApp
import cats.effect.{ExitCode, IO}
import com.typesafe.scalalogging.LazyLogging

object DBMigrationsCommand extends IOApp with LazyLogging {
  /**
    * Lists all JDBC data-sources, defined in `application.conf`
    */
  val dbConfigNamespaces = List(
    "example.jdbc"
  )

  def run(args: List[String]): IO[ExitCode] = {
    val migrate =
      dbConfigNamespaces.traverse_ { namespace =>
        for {
          _   <- IO(logger.info(s"Migrating database configuration: $namespace"))
          cfg <- JdbcDatabaseConfig.loadFromGlobal[IO](namespace)
          _   <- DBMigrations.migrate[IO](cfg)
        } yield ()
      }
    migrate.as(ExitCode.Success)
  }
}
```

NOTE: you can unify multiple migrations locations from multiple projects, in case you have a multi-project build. This is the reason for why `dbConfigNamespaces` is a `List` 😉

Then add this in `build.sbt`:

```scala
lazy val runMigrate = taskKey[Unit]("Migrates the database schema.")
addCommandAlias("run-db-migrations", "runMigrate")

lazy val root = (project in file("."))
  .settings(
    //...
    fullRunTask(runMigrate, Compile, "example.jdbc.DBMigrationsCommand"),
    fork in runMigrate := true,
  )
```

Now test that it works:

```sh
sbt run-db-migrations
```

Then see what tables were created. Execute this in your shell:

```sh
docker exec -it mariadb mysql -uroot -ppass MyAwesomeApp \
  -e "SHOW TABLES"
```

You should get this output:

```
+------------------------+
| Tables_in_MyAwesomeApp |
+------------------------+
| FlywaySchemaHistory    |
| MyFirstTable           |
+------------------------+
```

## 7. Pro-tip: Unit-test migrations with HSQLDB

You can run these migrations in your tests too. And you can use an in-memory database, such as HSQLDB, if your SQL does not use any specific MySQL features.

Add this to your `build.sbt`:

```scala
lazy val root = (project in file("."))
  .settings(
    //...
    libraryDependencies ++= Seq(
      //...
      // Needed for testing
      "org.hsqldb" % "hsqldb" % "2.5.1" % Test,
      scalaTest % Test,
    ),
    // Recommended
    fork in Test := true,
  )
```

Add `src/test/resources/application.test.conf`:

```js
include "application.conf"

// Overrides MySQL connection with in-memory HSQLDB
example.jdbc {
  url = "jdbc:hsqldb:mem:MyAwesomeApp;sql.syntax_mys=true"
  driver = "org.hsqldb.jdbc.JDBCDriver"
}
```

Then add your test (in `src/test/scala/example/jdbc/DBTestSuite.scala`):

```scala
package example
package jdbc

import cats.effect._
import org.scalatest.funsuite.AnyFunSuite
import com.typesafe.config.ConfigFactory

class DBTestSuite extends AnyFunSuite {
  test("database migrations") {
    val conf = ConfigFactory
      .load(getClass.getClassLoader, "application.test.conf")
      .resolve()

    val jdbcConf = JdbcDatabaseConfig
      .load[SyncIO](conf.getConfig("example.jdbc"))
      .unsafeRunSync()

    val m = DBMigrations.migrate[SyncIO](jdbcConf).unsafeRunSync()
    assert(m == 1)
  }
}
```

Run with:

```
sbt test
```

Enjoy~
