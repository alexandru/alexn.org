#!/usr/bin/env -S scala-cli shebang

//> using scala "3.3.0"

import scala.reflect.ClassTag
import java.lang.annotation.Retention
import java.lang.annotation.RetentionPolicy
import java.lang.annotation.Target
// import java.lang.annotation.AnnotationTarget

enum LogMessage:
  case OfString(value: String, details: Option[LogMessage])
  case OfList(value: List[LogMessage])
  case OfMap(value: Map[String, LogMessage])
  case OfException(value: Throwable)

trait LogShow[T]:
  extension (t: T)
    def logShow: LogMessage

@Retention(RetentionPolicy.RUNTIME)
class LogShowWith(cls: Class[_])
    extends scala.annotation.ClassfileAnnotation
    with java.lang.annotation.Annotation:
  def annotationType(): Class[_ <: java.lang.annotation.Annotation] =
    classOf[LogShowWith]

class LogSerializer(map: Map[Class[_], LogShow[_]]):
  def serialize[T: ClassTag](t: T): LogMessage =
    val cls = summon[ClassTag[T]].runtimeClass
    map.get(cls) match
      case Some(show) =>
        show.asInstanceOf[LogShow[T]].logShow(t)
      case None =>
        println(cls.getAnnotationsByType(classOf[LogShowWith]))
        throw IllegalArgumentException(s"Cannot serialize $cls")

@LogShowWith(classOf[FooLogShow])
case class Foo(
  hello: String,
  world: String
)

class FooLogShow extends LogShow[Foo]:
  extension (foo: Foo)
    def logShow: LogMessage =
      LogMessage.OfMap(
        Map(
          "hello" -> LogMessage.OfString(foo.hello, None),
          "world" -> LogMessage.OfString(foo.world, None)
        )
      )

println(LogSerializer(Map.empty).serialize(Foo("hello", "world")))

trait Functor[F[_]]:
  extension [A, B](fa: F[A])
    def map(f: A => B): F[B]

object Functor:
  export Applicative.given

trait Applicative[F[_]] extends Functor[F]:
  def pure[A](a: A): F[A]

  extension [A, B](fa: F[A])
    def ap(ff: F[A => B]): F[B]

object Applicative:
  export Monad.given

extension [A](a: A)
  inline def pure[F[_]: Applicative]: F[A] =
    summon[Applicative[F]].pure(a)

trait Monad[F[_]] extends Applicative[F]:
  extension [A, B](fa: F[A])
    def flatMap(f: A => F[B]): F[B]

object Monad:
  given Monad[List] with
    def pure[A](a: A): List[A] = List(a)

    extension [A, B](fa: List[A])
      def map(f: A => B): List[B] = fa.map(f)
      def ap(ff: List[A => B]): List[B] = ff.flatMap(fa.map)
      def flatMap(f: A => List[B]): List[B] = fa.flatMap(f)

extension [F[_], A](list: List[F[A]])
  def sequence(using Monad[F]): F[List[A]] =
    list.foldLeft(List.newBuilder[A].pure[F]):
      (acc, a) =>
        for
          xs <- acc
          x <- a
        yield xs.addOne(x)
    .map(_.result())
