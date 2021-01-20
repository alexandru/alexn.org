---
title: "Tagless Final vs OOP"
date: 2021-01-20 11:24:14+0200
image: /assets/media/snippets/tagless-final-vs-oop.png
tags: 
  - FP
  - OOP
  - Scala
---

These may as well be interview questions for Scala developers:

1. Which signature do you prefer? 
2. Just looking at the signature, what can potentially be wrong with the "tagless final" version?

```scala
// Tagless final
def registerUser[F[_]: UserDB : EmailService : Monad](user: User): F[Unit]

// ReaderT (Kleisli) & OOP
def registerUser[F[_]: Monad](
  user: User): Kleisli[F, (UserDB[F], EmailService[F]), Unit]

// Plain function arguments & OOP
def registerUser[F[_] : Monad](
  user: User, 
  db: UserDB[F], 
  es: EmailService[F]): F[Unit]

// OOP class
final class RegistrationService[F[_]: Monad](
  db: UserDB[F], 
  es: EmailService[F]) {

  def registerUser(user: User): F[Unit]
}
```
