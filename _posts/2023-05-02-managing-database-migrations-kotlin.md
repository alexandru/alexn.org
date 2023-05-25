---
title: "Managing Database Migrations in Kotlin"
image: /assets/media/articles/2023-kotlin-db-migrations.png
date: 2023-05-02 10:32:06 +03:00
last_modified_at: 2023-05-25 10:30:16 +03:00
generate_toc: true
tags: 
  - Kotlin
  - SQL
description: >
  The database schema should be described as code, in your repository. And you should be able to semi-automatically update your database schema on new deployments. Now in Kotlin, with Gradle and Flyway.
---

<p class="intro withcap">
  The database schema should be described as code, in your repository. And you should be able to semi-automatically update your database schema on new deployments. Now in Kotlin, with Gradle and Flyway.
</p>

<p class="info-bubble" markdown="1">
  This article is a rewrite of my [previous article](./2020-11-15-managing-database-migrations-scala.md) on the same topic, that was showing code snippets meant for [Scala](https://www.scala-lang.org/) and the [sbt](https://www.scala-sbt.org/) build tool. This article is meant for Kotlin (or Java), with Gradle integration, but also making use of Flyway.
</p>

We're going to use [Flyway](https://flywaydb.org/) to manage our database migrations, a Java library that's useful enough.

Before we start, note that Flyway has a [Gradle plugin](https://plugins.gradle.org/plugin/org.flywaydb.flyway), just like it has an [sbt plugin](https://github.com/flyway/flyway-sbt) or a Maven plugin. And with something like Spring Boot or Quarkus, you can get out of the box configuration for Flyway / Liquidbase, possibly using those plugins. We are not going to look at such integrations in this article, because they force you into a rigid configuration, project structure, or deployment possibilities. Here are some potential issues with such integrations:

1. Reusing your database connection settings, specified somewhere else;
2. Creating an executable JAR that can execute those migrations;
3. Executing the migrations at application startup (not recommended for serious™️ apps, but always an option);
4. Running different migration files for different database types, depending on configuration;
5. Having subprojects, that may be independent, each with their own set of database migrations.

We gain all of this flexibility with some manual wiring that's only a couple of lines of code.

<p class="warn-bubble" markdown="1">
  This article will depend just on Flyway's API, or in other words, just on `flyway-core`. We are not using any available integrations with the build tools.
</p>

## 1. PostgreSQL setup

We are going to use PostgreSQL as our sample database. To start an instance, you could use Docker. Here's a sample `docker-compose.yaml`:

```yaml
version: '3.3'

services:
  postgresdb:
    container_name: postgresdb
    image: 'postgres:15-alpine'
    ports:
      - "5432:5432"
    healthcheck:
      test: ['CMD', 'pg_isready', '-U', 'postgres']
    volumes:
      - 'postgresdb-volume:/var/lib/postgresql/data'
    restart: always
    environment:
      POSTGRES_PASSWORD: pass

volumes:
  postgresdb-volume:
```

Start this instance:

```sh
docker-compose -f ./docker-compose.yaml up -d
```

And create your initial database named `my_sample_db` (this step is pretty hard to add as part of your migration files, so might as well not do it):

```sh
docker exec -it postgresdb /usr/local/bin/psql \
  -U postgres \
  -c "CREATE DATABASE my_sample_db"
```

## 2. Initial project setup

Create a new directory and switch to it from the shell:

```sh
mkdir migrations-sample
cd migrations-sample/
```

To start your new Kotlin project (accept all defaults):

```sh
gradle init --type kotlin-application --dsl kotlin
```

We need to specify a configuration file, and it's going to be our own configuration file, because why not? One way of doing that is to use the [Kotlinx Serialization](https://github.com/Kotlin/kotlinx.serialization) plugin and library, so we'll need to add it as a dependency.

Edit the file `app/build.gradle.kts`, and make sure the `plugins` section looks like this:

```kotlin
plugins {
  kotlin("jvm") version "1.8.21"
  kotlin("plugin.serialization") version "1.8.21"
  application
}
```

And we'll need these library dependencies:

```kotlin
dependencies {
  // For managing our database migrations
  // https://github.com/flyway/flyway
  implementation("org.flywaydb:flyway-core:9.17.0")

  // For parsing CLI arguments
  // https://github.com/Kotlin/kotlinx-cli
  implementation("org.jetbrains.kotlinx:kotlinx-cli:0.3.5")

  // For couroutines support; not strictly needed, but it's nice to
  // indicate when blocking I/O needs the thread-pool meant for blocking stuff.
  // https://github.com/Kotlin/kotlinx.coroutines
  implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.0-RC")

  // For parsing our configuration file. Using:
  //  - https://github.com/Kotlin/kotlinx.serialization
  //  - https://github.com/lightbend/config (HOCON as the format)
  implementation("org.jetbrains.kotlinx:kotlinx-serialization-hocon:1.5.0")

  // Database driver (JDBC)
  implementation("org.postgresql:postgresql:42.6.0")

  // Flyway has built-in logging, which we can expose via SLF4J/Logback
  implementation("ch.qos.logback:logback-classic:1.4.7")
}
```

We're adding logging (via slf4j/logback), and we might want to silence Flyway's logging for anything that's unimportant. Let's also add a `logback.xml` file to the `app/src/main/resources` directory:

```xml
<configuration debug="false">
  <statusListener class="ch.qos.logback.core.status.NopStatusListener" />
  <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
    <withJansi>true</withJansi>
    <encoder>
      <pattern>[%date{ISO8601}] [%highlight(%level)] [%boldYellow(%marker)] [%logger] [%thread] %cyan([%mdc]) — %msg%n</pattern>
    </encoder>
  </appender>

  <logger name="org.flywaydb.core" level="WARN" />

  <root level="info">
    <appender-ref ref="STDOUT" />
  </root>
</configuration>
```

## 3. Configuration

Create a new file `app/src/main/resources/database.conf` with the following contents:

```json
jdbc-connection.main {
  driver = "org.postgresql.Driver"

  url = "jdbc:postgresql://localhost:5432/my_sample_db"
  url = ${?JDBC_CONNECTION_MAIN_URL}

  username = "sample_user"
  username = ${?JDBC_CONNECTION_MAIN_USERNAME}

  password = ${JDBC_CONNECTION_MAIN_PASSWORD}

  migrationsTable = "main_migrations"
  migrationsLocations = [
    "classpath:db/migrations/main/psql"
  ]
}
```

There are several things to unpack here:

1. This is our own format, you can define your own, or reuse whatever configuration file you have; in this case the file is using HOCON (a JSON superset), it's included as a "resource" in the final artefact, and it is allowing for environment variables to override the values;
2. `migrationsTable` and `migrationsLocations` are needed because we may have multiple sub-projects, each with their own (independent) migrations, and we want to execute them all;
3. We specify the username and the password, but these are the app's credentials, and are not the user and password used when migrating the DB; I think it's a security vulnerability to allow the app's user to modify tables, or create triggers on its own, so this "MAIN" user should have limited permisisons (but you can ignore this "best practice");

And then, using the `kotlinx-serialization-hocon` dependency, we can model this as a type-safe data class, and read this file in our own code. Add this file in `app/src/main/kotlin/`:

```kotlin
package migrations.sample

import com.typesafe.config.Config
import com.typesafe.config.ConfigFactory
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.hocon.Hocon

@Serializable
data class JdbcConnectionConfig(
  val url: String,
  val driver: String,
  val username: String,
  val password: String,
  val migrationsTable: String,
  val migrationsLocations: List<String>,
  val migrationsPlaceholders: Map<String, String> = emptyMap()
) {
  companion object {
    @OptIn(ExperimentalSerializationApi::class)
    suspend fun loadFromGlobal(
      configNamespace: String,
      config: Config? = null
    ): JdbcConnectionConfig =
      withContext(Dispatchers.IO) {
        val rawCfg = config ?: ConfigFactory.load().resolve()
        val cfg = rawCfg.getConfig(configNamespace)
        Hocon.decodeFromConfig(serializer(), cfg)
      }
  }
}
```

Modeling your app's configuration in such a type-safe way isn't necessarily required, and it's certainly not a very common practice in Java projects. But it's a pity, as it makes APIs clearer, being a great way to document your configuration in the code itself.

## 4. Flyway API library integration

Create a new file `RunMigrations.kt` in `app/src/main/kotlin/`:

```kotlin
package migrations.sample

import com.typesafe.config.ConfigFactory
import kotlinx.cli.ArgParser
import kotlinx.cli.ArgType
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import org.flywaydb.core.Flyway
import org.flywaydb.core.api.configuration.FluentConfiguration
import org.flywaydb.core.api.output.MigrateResult
import org.slf4j.LoggerFactory
import kotlin.system.exitProcess

/**
 * Given a JDBC configuration, run the associated DB migrations.
 *
 * NOTE: `adminUsername` and `adminPassword` are different from the
 * credentials specified in `JdbcConnectionConfig`. That's because the
 * "admin" user may be different from the app's user. So if an
 * `adminUsername` and an `adminPassword` are provided, Flyway will
 * use that admin user to execute migrations.
 *
 * Flyway uses "placeholders" that can be used in the SQL migrations.
 * These can be specified in `JdbcConnectionConfig`, but this code
 * also sets 2 special placeholders to use from the
 * `JdbcConnectionConfig` itself: `dbUsername` and `dbPassword`. These
 * can be used to create the app's user as part of the defined
 * migrations.
 */
suspend fun dbMigrate(
  config: JdbcConnectionConfig,
  adminUsername: String?,
  adminPassword: String?
): MigrateResult =
  withContext(Dispatchers.IO) {
    val m: FluentConfiguration = Flyway.configure()
      .dataSource(
        config.url,
        adminUsername ?: config.username,
        if (adminUsername != null) adminPassword else config.password,
      )
      .group(true)
      .outOfOrder(false)
      .table(config.migrationsTable)
      .locations(*config.migrationsLocations.toTypedArray())
      .baselineOnMigrate(true)
      .loggers("slf4j")
      .placeholders(
        config.migrationsPlaceholders +
            mapOf(
              "dbUsername" to config.username,
              "dbPassword" to config.password
            ).filterValues { it != null }
      )

    val validated = m
      .ignoreMigrationPatterns("*:pending")
      .load()
      .validateWithResult()

    if (!validated.validationSuccessful) {
      val logger = LoggerFactory.getLogger("RunMigrations")
      for (error in validated.invalidMigrations) {
        logger.warn(
          """
            |Failed to validate migration:
            |  - version: ${error.version}
            |  - path: ${error.filepath}
            |  - description: ${error.description}
            |  - error code: ${error.errorDetails.errorCode}
            |  - error message: ${error.errorDetails.errorMessage}
          """.trimMargin("|").trim()
        )
      }
    }
    m.load().migrate()
  }

object RunMigrations {
  private suspend fun migrateNamespace(
    label: String,
    config: JdbcConnectionConfig,
    adminUsername: String,
    adminPassword: String
  ): Unit = withContext(Dispatchers.IO) {
    val result = dbMigrate(
      config,
      adminUsername,
      adminPassword
    )
    println("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=")
    println("Migrating: $label")
    println("------------------------------------")
    println("Initial schema version: ${result.initialSchemaVersion}")
    println("Target schema version: ${result.targetSchemaVersion}")
    if (result.migrations.isNotEmpty()) {
      println("------------------------------------")
      println("Executed migrations:")
      for (migration in result.migrations) {
        println(" - ${migration.version} ${migration.type} ${migration.description}")
      }
    }
    if (result.warnings.isNotEmpty()) {
      println("------------------------------------")
      System.err.println("WARNINGS:")
      for (warning in result.warnings) {
        System.err.println(" - $warning")
      }
    }
    println("------------------------------------")
    if (result.success) {
      println("Successfully migrated: $label!")
    } else {
      System.err.println("ERROR: Failed to migrate $label!")
      exitProcess(1)
    }
  }

  @JvmStatic
  fun main(args: Array<String>) {
    val parser = ArgParser("RunMigrations")
    val adminUsername by parser.argument(
      ArgType.String,
      fullName = "admin-username",
      description = "Admin username for the database. Example: postgres"
    )
    val adminPassword by parser.argument(
      ArgType.String,
      fullName = "admin-password",
      description = "Admin password for the database."
    )
    parser.parse(args)

    runBlocking {
      val config =
        ConfigFactory.load("database.conf").resolve()
      val mainConfig =
        JdbcConnectionConfig.loadFromGlobal(
          "jdbc-connection.main",
          config
        )
      migrateNamespace(
        "main",
        mainConfig,
        adminUsername,
        adminPassword
      )
    }
  }
}
```

In this code, we only deal with a single database configuration and its associated migrations. But note that we can have multiple database configurations, each with their own migrations, corresponding to different subprojects. You simply add multiple `migrateNamespace` calls.

## 5. Adding the SQL migrations

We are going to create files in `app/src/main/resources/db/migrations/main/psql`. This matches the `migrationsLocations` defined in the `database.conf` above (which gets parsed in `JdbcConnectionConfig`).

Create a new file named `V0010__create-user.sql`:

```sql
CREATE USER "${dbUsername}" WITH PASSWORD '${dbPassword}';
CREATE SCHEMA IF NOT EXISTS sample
  AUTHORIZATION "${dbUsername}";

GRANT
  CONNECT,
  TEMPORARY
ON DATABASE "my_sample_db"
TO "${dbUsername}";
```

Then create another file named `V0020__create-tables.sql` and add some nice tables to it:

```sql
CREATE TABLE sample.users
(
  id bigint not null generated always as identity primary key,
  email varchar(255) not null,
  password varchar(255) default null,
  timezone varchar(30) not null,
  created_at timestamp with time zone not null,
  updated_at timestamp with time zone not null
);

CREATE TABLE sample.stuff
(
  id bigint not null generated always as identity primary key,
  user_id bigint not null,
  json_data jsonb not null,
  created_at timestamp with time zone not null,
  updated_at timestamp with time zone not null,
  foreign key (user_id) references sample.users(id)
    on delete cascade
    on update cascade
);

GRANT
  SELECT,
  INSERT,
  UPDATE,
  DELETE,
  TRUNCATE
ON ALL TABLES IN SCHEMA sample
TO "${dbUsername}";
```

## 6. Gradle configuration

We need the following in `build.gradle.kts`:

```kotlin
tasks.register<JavaExec>("migrate") {
  group = "Execution"
  description = "Migrates the database to the latest version"
  classpath = sourceSets.getByName("main").runtimeClasspath
  mainClass.set("migrations.sample.RunMigrations")

  val user = System.getenv("POSTGRES_ADMIN_USER")
    ?: "postgres"
  val pass = System.getenv("POSTGRES_ADMIN_PASSWORD")
    ?: throw GradleException(
      "POSTGRES_ADMIN_PASSWORD environment variable must be set"
    )
  args = listOf(user, pass)
}
```

## 7. Running the migrations

```sh
# Needed by the Gradle task
export POSTGRES_ADMIN_PASSWORD="pass"
# Needed by the application (HOCON) config
export JDBC_CONNECTION_MAIN_PASSWORD="pass"

./gradlew migrate
```

Which will output:

```
> Task :app:migrate
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Migrating: main
------------------------------------
Initial schema version: 0020
Target schema version: null
------------------------------------
Successfully migrated: main!

BUILD SUCCESSFUL in 2s
3 actionable tasks: 2 executed, 1 up-to-date
```

## 8. Pro-tip: unit-test migrations with HSQLDB

You can use something like HSQLDB to unit-test your JDBC-based code. HSQLDB is an in-memory database perfect for tests.

```kotlin
dependencies {
  //...
  testImplementation("org.hsqldb:hsqldb:2.5.1")
}
```

In your `src/test/resources` you could have a `test.database.conf` with a setup like:

```json
include "database.conf"

// Overrides PostgreSQL connection with in-memory HSQLDB
jdbc-connection.main {
  url = "jdbc:hsqldb:mem:MyTestDB;sql.syntax_pgs=true"
  driver = "org.hsqldb.jdbc.JDBCDriver"
  username = null
  password = null
}
```

Here we are using the [PostgreSQL compatibility mode](https://hsqldb.org/doc/2.0/guide/compatibility-chapt.html#coc_compatibility_postgres), which isn't perfect, as it only supports standard RDBMS stuff. Depending on your SQL code, it might be enough. Note that it probably doesn't work with `jsonb` columns 🙂 but for simpler schemas it might be enough. Or you could have code specific for HSQLDB by manipulating the `migrationsLocations` setting to point to a different path:

```json
include "database.conf"

jdbc-connection.main {
  //...
  migrationsLocations = [
    "classpath:db/migrations/main/hsqldb"
  ]
}
```

And then in your tests you can run those migrations by simply calling that `dbMigrate` function, and then profit! 🤑

```kotlin
class MyTest {
  @Test fun something() =
    runBlocking {
      val rawConfig =
        ConfigFactory.load("test.database.conf").resolve()
      val jdbcConfig =
        JdbcConnectionConfig.loadFromGlobal(
          "jdbc-connection.main",
          rawConfig
        )
      // Ta da!
      dbMigrate(jdbcConfig)
      //...
    }
}
```

Your DB API mocks will never be the same again! 😎

## Epilogue

For a sample project, checkout this GitHub repository:

**[sample-projects/kotlin-db-migrations](https://github.com/alexandru/sample-projects/tree/main/kotlin-db-migrations)**

Enjoy~
