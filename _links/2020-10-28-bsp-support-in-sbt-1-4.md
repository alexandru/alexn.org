---
link: "https://www.scala-lang.org/blog/2020/10/27/bsp-in-sbt.html"
title: "BSP Support in sbt 1.4"
author: "Adrien Piquerez, Scala Center"
date: 2020-10-28 08:53:18+0200
image: /assets/media/snippets/sbt-bsp-announcement.png
tags:
  - Programming
  - Scala
---

_"Today we are proud to announce that support of BSP has been shipped into sbt 1.4.0 ... BSP in sbt improves the integration of sbt inside IDEs and code editors."_

_"By formalizing BSP, we aimed at providing a standard protocol of communication between IDEs and build tools, in which the build tool plays the role of the server that performs the operation requested by the IDE. The ultimate goal being to ease the integration on both sides while providing a better experience to the end-users."_

_"BSP is inspired by LSP, the Language Server Protocol. The main difference being that LSP abstracts over the language whereas BSP abstracts over the build tool."_