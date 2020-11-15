---
title: "Managing Database Migrations in Scala"
---

The database schema should be described as code, in your repository. And you should be able to semi-automatically update your database schema on new deployments.

A very popular Java library for handling migrations is [Flyway](https://flywaydb.org/). We'll combine that with [Typesafe Config (aka HOCON)](https://github.com/lightbend/config) for configuration, along with [PureConfig](https://github.com/pureconfig/pureconfig) for parsing it. And [Cats Effect](https://github.com/typelevel/cats-effect) for describing our effects, because we love FP, right? 😎

We're going to use [MariaDB (MySQL)](https://mariadb.org/) as our database, but this works with any relational database.

