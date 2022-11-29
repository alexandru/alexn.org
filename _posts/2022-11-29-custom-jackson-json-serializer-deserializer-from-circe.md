---
title: "Custom Jackson JSON serializer/deserializer from Circe"
image: /assets/media/articles/2022-jackson-codecs.png
image_hide_in_post: true
tags:
  - Scala
  - Snippet
---

<p class="intro withcap" markdown=1>
Snippet for when you're using [Circe](https://github.com/circe/circe) and want to define custom [Jackson](https://github.com/FasterXML/jackson) serializers/deserializers from Circe's codec definitions.
</p>

It's not very efficient, as deserialization seems to parse the JSON in both Jackson and Circe, but I don't have better ideas.

```scala
import com.fasterxml.jackson.core.{ JsonGenerator, JsonParser, TreeNode }
import com.fasterxml.jackson.databind.deser.std.StdDeserializer
import com.fasterxml.jackson.databind.ser.std.StdSerializer
import com.fasterxml.jackson.databind.{ DeserializationContext, SerializerProvider }
import io.circe.parser.decode
import io.circe.syntax._
import io.circe.{ Decoder, Encoder }
import scala.reflect.ClassTag

class JacksonSerializerFromCirce[A: ClassTag: Encoder] 
extends StdSerializer[A](
    implicitly[ClassTag[A]].runtimeClass.asInstanceOf[Class[A]]
  ) {
  override def serialize(
    value: A, 
    gen: JsonGenerator, 
    provider: SerializerProvider
  ): Unit = {
    val json = value.asJson.noSpaces
    gen.writeRawValue(json)
  }
}

class JacksonDeserializerFromCirce[A: ClassTag: Decoder] 
  extends StdDeserializer[A](
    implicitly[ClassTag[A]].runtimeClass.asInstanceOf[Class[A]]
  ) {
  override def deserialize(
    p: JsonParser, 
    ctxt: DeserializationContext
  ): A = {
    decode[A](p.readValueAsTree[TreeNode]().toString) match {
      case Right(a) => a
      case Left(e) => throw e
    }
  }
}
```

Usage:

```scala
import io.circe.Codec
import io.circe.generic.semiauto.deriveCodec

@JsonSerialize(using = classOf[Sample.Serializer])
@JsonDeserialize(using = classOf[Sample.Deserializer])
final case class Sample(
  name: String,
  isActive: Boolean
)

object Sample {
  implicit val codec: Codec[Sample] = 
    deriveCodec

  class Serializer 
    extends JacksonSerializerFromCirce[Sample]
  class Deserializer 
    extends JacksonDeserializerFromCirce[Sample]
}
```
