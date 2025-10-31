---
title: "Scala 3 / HOCON Parsing"
image: /assets/media/articles/2025-scala-configcodec.png
date: 2025-10-30T19:33:31+02:00
last_modified_at: 2025-10-31T12:23:27+02:00
tags:
  - Scala
  - Scala 3
  - Programming
  - Snippet
description: >
  How to parse HOCON in Scala 3? How to use Circe for HOCON? How to work with multiple JSON codecs per data structure?
---

<p class="intro">
  How to parse HOCON in Scala 3? How to use Circe for HOCON? How to work with multiple JSON codecs per data structure?
</p>

<p class="info-bubble" markdown="1">
This article is using Scala 3 with [-no-indent](./2025-10-26-scala-3-no-indent.md). And this file is executable with [Scala CLI's Markdown support](https://scala-cli.virtuslab.org/docs/guides/power/markdown) 🤖
</p>

```bash
scala --power --enable-markdown \
  https://raw.githubusercontent.com/alexandru/alexn.org/refs/heads/main/_posts/2025-10-30-scala-3-hocon-parsing.md
```

I've just started migrating our project at work to Scala 3. It's a work-in-progress, but it's been going well, and thus far the biggest roadblock has been the [PureConfig library](https://github.com/pureconfig/pureconfig), an awesome library, but it didn't seem to have complete support for Scala 3. In particular, it doesn't seem to have support for `ConfigWriter` derivation, yet. So I've started to think of alternatives.

<p class="warn-bubble" markdown="1" name="update-1">
**UPDATE:** PureConfig apparently has `ConfigWriter` derivation in the codebase, as part of a different module, found out about it from this [Reddit comment](https://old.reddit.com/r/scala/comments/1okokac/scala_3_hocon_parsing/nmc3s2u/): see [source code](https://github.com/pureconfig/pureconfig/blob/1f272aa/modules/generic-scala3/src/main/scala/pureconfig/generic/scala3/HintsAwareConfigWriterDerivation.scala), added in [this PR](https://github.com/pureconfig/pureconfig/pull/1671). I don't know how well it works, but it's encouraging. Unfortunately, I checked the status by just [looking at outdated docs](https://pureconfig.github.io/docs/scala-3-derivation.html#limitations) 🤦‍♂️
</p>

One solution I've found is to use the [circe](https://github.com/circe/circe) library, with [circe-config](https://github.com/circe/circe-config). And here-in lie challenges:

1. Rewriting the configuration files is not an option:
   - PureConfig used `kebab-case` for its keys;
   - It also allowed us to use `type = type-name` for discriminating union types.
   - Any solution we pick needs to be configured for these conventions.
2. Deriving the type-class instances should be painless — people shouldn't need to remember an import.
3. We also do JSON encodings with `camelCase` via Circe, sometimes for types that are also used in configuration files, therefore those types need different HOCON config vs JSON encodings.

So in summary:
- Circe needs to be configured to parse and generate HOCON;
- The type-class instances need to be different, but still globally visible — to avoid conflicts and preserve "type-class coherence".

Starting with some dependencies:

```scala
//> using scala "3.3.7"
//> using dep "io.circe::circe-core:0.14.15"
//> using dep "io.circe::circe-config:0.10.2"
//> using options -no-indent
```

In order to respect our HOCON's conventions, we needed a Circe Configuration:

```scala
import io.circe.derivation.Configuration

given hoconConventions: Configuration = {
  val kebabCase: String => String =
    _.replaceAll("([a-z])([A-Z])", "$1-$2").toLowerCase

  Configuration.default
    .withTransformMemberNames(kebabCase)
    .withDiscriminator("type")
    .withTransformConstructorNames(kebabCase)
}
```

Note that with Circe, the auto-derivation we want goes something like this:

```scala ignore
case class HttpConfig(
  hostname: String,
  port: Int,
  contextPath: Option[String]
)

object HttpConfig {
  given Codec[HttpConfig] = 
    Codec.AsObject.derivedConfigured
}
```

As mentioned before, I'd rather have a different type-class, and I don't want to have to remember to import `hoconConventions`, but we can just create different type-classes that wrap Circe's:

```scala
import io.circe.{Encoder, Decoder, Codec}

trait ConfigEncoder[A] {
  def encoder: Encoder.AsObject[A]
}

trait ConfigDecoder[A] {
  def decoder: Decoder[A]
}

trait ConfigCodec[A]
  extends ConfigEncoder[A]
  with ConfigDecoder[A] {

  def codec: Codec.AsObject[A]
}
```

The difficult part is auto-deriving these, but thankfully, Scala 3 makes it easy:

```scala
import scala.deriving.Mirror

object ConfigEncoder {
  // Calling `derivedConfigured` ourselves, then wrapping it
  //
  inline def derived[A](using inline A: Mirror.Of[A]): ConfigEncoder[A] = {
    // IMPORTANT — Scala needs to know how to derive
    // a Circe `Encoder` from a `ConfigEncoder`.
    import Givens.given
    
    val underlying = io.circe.Encoder.AsObject.derivedConfigured[A]
    Derived(underlying)
  }

  final private case class Derived[A](encoder: Encoder.AsObject[A])
    extends ConfigEncoder[A]
}
```

Importantly, Scala must find the defined encoders for a class's fields, therefore it must have a way to convert from `ConfigEncoder` into `io.circe.Encoder` and from `ConfigDecoder` to `io.circe.Decoder`. But these need to be imported only in the lexical scope of those `inline def derived` functions:

```scala
private object Givens {
  given circeEncoder[A](using encoder: ConfigEncoder[A]): Encoder.AsObject[A] =
    encoder.encoder

  given circeDecoder[A](using decoder: ConfigDecoder[A]): Decoder[A] =
    decoder.decoder
}
```

Similarly, we describe the derivation logic for `ConfigDecoder` and `ConfigCodec`:

```scala
object ConfigDecoder {
  inline def derived[A](using inline A: Mirror.Of[A]): ConfigDecoder[A] = {
    // IMPORTANT — Scala needs to know how to derive
    // a Circe `Encoder` from a `ConfigEncoder`.
    import Givens.given
    val underlying = Decoder.derivedConfigured[A]
    Derived(underlying)
  }

  final private case class Derived[A](decoder: Decoder[A])
    extends ConfigDecoder[A]
}

object ConfigCodec {
  inline def derived[A](using inline A: Mirror.Of[A]): ConfigCodec[A] = {
    // IMPORTANT — Scala needs to know how to derive
    // a Circe `Encoder` from a `ConfigEncoder`.
    import Givens.given
    val underlying = Codec.AsObject.derivedConfigured[A]
    Derived(underlying)
  }

  final private case class Derived[A](codec: Codec.AsObject[A]) 
    extends ConfigCodec[A] {
    override def decoder = codec
    override def encoder = codec
  }
}
```

OK, so I think we can do better than this with some utilities. This is a copy/paste-able snippet:

```scala reset
import com.typesafe.config.Config
import com.typesafe.config.ConfigFactory
import com.typesafe.config.ConfigRenderOptions
import com.typesafe.config.ConfigValue
import com.typesafe.config.ConfigValueFactory
import io.circe.derivation.Configuration
import io.circe.syntax.given
import io.circe.Codec
import io.circe.Decoder
import io.circe.Encoder
import io.circe.Json
import scala.deriving.Mirror
import scala.jdk.CollectionConverters.*

trait ConfigEncoder[A] {
  def encoder: io.circe.Encoder.AsObject[A]

  extension (a: A) {
    def toRawConfig: Config = {
      given Encoder.AsObject[A] =
        encoder
      ConfigFactory.empty().withFallback(
        jsonToConfigValue(a.asJson)
      )
    }

    def renderConfigString: String =
      toRawConfig.root().render(renderOptions)
  }
}

object ConfigEncoder {
  inline def derived[A](using inline A: Mirror.Of[A]): ConfigEncoder[A] = {
    import Givens.given
    val underlying = io.circe.Encoder.AsObject.derivedConfigured[A]
    Derived(underlying)
  }

  final private case class Derived[A](encoder: Encoder.AsObject[A])
    extends ConfigEncoder[A]
}

trait ConfigDecoder[A] {
  def decoder: io.circe.Decoder[A]

  final def decodeConfig(
    config: com.typesafe.config.Config
  ): Either[io.circe.Error, A] = {
    import io.circe.config.parser
    parser.decode[A](config)(using decoder)
  }

  final def parseConfigString(
    configString: String
  ): Either[io.circe.Error, A] = {
    val config = ConfigFactory.parseString(configString)
    decodeConfig(config)
  }
}

object ConfigDecoder {
  def apply[A](using ConfigDecoder[A]): ConfigDecoder[A] =
    summon[ConfigDecoder[A]]

  inline def derived[A](using inline A: Mirror.Of[A]): ConfigDecoder[A] = {
    import Givens.given
    val underlying = Decoder.derivedConfigured[A]
    Derived(underlying)
  }

  final private case class Derived[A](decoder: Decoder[A])
    extends ConfigDecoder[A]
}

trait ConfigCodec[A]
  extends ConfigEncoder[A]
  with ConfigDecoder[A] {

  def codec: Codec.AsObject[A]
}

object ConfigCodec {
  inline def derived[A](using inline A: Mirror.Of[A]): ConfigCodec[A] = {
    import Givens.given
    val underlying = Codec.AsObject.derivedConfigured[A]
    Derived(underlying)
  }

  final private case class Derived[A](codec: Codec.AsObject[A]) extends ConfigCodec[A] {
    override def decoder =
      codec
    override def encoder =
      codec
  }
}

private object Givens {
  given circeEncoder[A](using encoder: ConfigEncoder[A]): Encoder.AsObject[A] =
    encoder.encoder

  given circeDecoder[A](using decoder: ConfigDecoder[A]): Decoder[A] =
    decoder.decoder

  given hoconConventions: Configuration =
    Configuration.default
      .withTransformMemberNames(kebabCase)
      .withDiscriminator("type")
      .withTransformConstructorNames(kebabCase)

  private val kebabCase: String => String =
    _.replaceAll("([a-z])([A-Z])", "$1-$2").toLowerCase
}

private def jsonToConfigValue(json: Json): ConfigValue =
  json.fold(
    ConfigValueFactory.fromAnyRef(null),
    boolean => ConfigValueFactory.fromAnyRef(boolean),
    number =>
      number.toLong match {
        case Some(long) => ConfigValueFactory.fromAnyRef(long)
        case None => ConfigValueFactory.fromAnyRef(number.toDouble)
      },
    str => ConfigValueFactory.fromAnyRef(str),
    arr => ConfigValueFactory.fromIterable(arr.map(jsonToConfigValue).asJava),
    obj => ConfigValueFactory.fromMap(obj.toMap.view.mapValues(jsonToConfigValue).toMap.asJava)
  )

private val renderOptions =
  ConfigRenderOptions
    .defaults()
    .setOriginComments(false)
    .setComments(true)
    .setFormatted(true)
    .setJson(false)
```

To test it, we first define a more complex data structure:

```scala
// Providing both HOCON and JSON codecs, separately 
// (to prove it works)

final case class AppConfig(
  appName: String,
  http: HttpConfig,
  inputConfig: InputConfig
) derives ConfigCodec, Codec.AsObject

final case class HttpConfig(
  hostname: String,
  port: Int,
  contextPath: Option[String]
) derives ConfigCodec, Codec.AsObject

sealed trait InputConfig derives ConfigCodec, Codec.AsObject

object InputConfig {
  final case class Kafka(
    bootstrapServers: String,
    topic: String,
    groupId: String
  ) extends InputConfig derives ConfigCodec, Codec.AsObject

  final case class IbmMq(
    queueManager: String,
    channel: String,
    connectionName: String,
    queueName: String
  ) extends InputConfig derives ConfigCodec, Codec.AsObject
}
```

And then we can test it by decoding and the re-encoding, for both HOCON and JSON, to prove a point:

```scala
import cats.syntax.all.*

val appConfigHocon = """
app-name = "my-app"

http {
  hostname = "localhost"
  port = 8081
  context-path = "/mq"
}

input-config {
  type = ibm-mq
  queue-manager = "QM1"
  channel = "CHANNEL1"
  connection-name = "localhost(1414)"
  queue-name = "VESPER.QUEUE"
}
"""

val appConfigFromHocon = ConfigDecoder[AppConfig]
  .parseConfigString(appConfigHocon)
  .valueOr(throw _)
// encode it again and print it
println("FROM HOCON:\n---------")
println(appConfigFromHocon.renderConfigString)

// Proving that we have different codecs for JSON 
// (with different conventions):
val appConfigJson = """
{
  "appName" : "vesper-app-mq",
  "http" : {
    "hostname" : "localhost",
    "port" : 8081,
    "contextPath" : "/mq"
  },
  "inputConfig" : {
    "IbmMq" : {
      "queueManager" : "QM1",
      "channel" : "CHANNEL1",
      "connectionName" : "localhost(1414)",
      "queueName" : "VESPER.QUEUE"
    }
  }
}
"""

import io.circe.parser.decode
import io.circe.syntax.*

val appConfigFromJson = 
  decode[AppConfig](appConfigJson).valueOr(throw _)

println("FROM JSON:\n---------")
println(appConfigFromJson.asJson.spaces2)
```

**NOTE:** you just learned to provide multiple JSON encodings for THE SAME data-structures. Pretty cool, huh? 😉
