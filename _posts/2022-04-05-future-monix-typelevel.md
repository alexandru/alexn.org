---
title: "On Typelevel and Monix"
tags:
  - Monix
  - Personal
  - Typelevel
image: /assets/media/articles/2022-04-monix.png
description: >
  Planning the future is difficult, but can bring clarity and purpose. I'm stepping down from the Typelevel Steering Committee. I also have plans for Monix's future.
last_modified_at: 2022-04-06 00:16:52 +03:00
---

<p class="intro" markdown=1>
Planning the future is difficult, but can bring clarity and purpose. See [Finding Focus in Harsh Times]({% link _posts/2022-03-30-focus.md %}) for context.
</p>

## On Typelevel

[Typelevel](https://typelevel.org/) is a great community of builders that want to practice FP in Scala. Its "*steering committee*" ([link](https://github.com/typelevel/governance/blob/main/STEERING-COMMITTEE.md) / [archive](https://web.archive.org/web/20220405203006/https://github.com/typelevel/governance/blob/main/STEERING-COMMITTEE.md)) is a group of brilliant and kind people that are doing great work in keeping the community welcoming and inclusive.

**I'm stepping down from the Typelevel "Steering Committee".**

Moderating and leading a community is gruesome work made by unsung heroes, and I can't be a part of it anymore. For some time now I've been absent, with my only contributions to steering having been rants, and frankly I'd rather get back to coding or other contributions to Open Source that I can manage.

Typelevel is growing, and you can make a difference. If you feel you're a fit, get involved, as there's a [call for 'steering committee' members](https://typelevel.org/blog/2022/04/01/call-for-steering-committee-members.html).

## The Future of Monix

[Monix](https://monix.io) has been my love project, but due to events unfolding since 2019, with life and the world going mad, I've been on an unplanned hiatus from Open Source contributions. I did contribute [monix-newtypes](https://github.com/monix/newtypes), as contributing a new project, scratching an immediate itch, felt easier 🙂

I'll be forever grateful to Piotr Gawryś, who helped in maintaining and developing Monix, but eventually development stalled. Development of Monix was stalled primarily because small, incremental improvements are no longer possible. And this happened due to the release of Cats-Effect 3.

[Cats Effect 3](https://typelevel.org/cats-effect/) is an awesome new version of an already good library. But while being a necessary upgrade, it fundamentally [changes the concurrency model](https://github.com/typelevel/cats-effect/discussions/1979) it was based on. The changes are so profound that it's arguably an entirely new library, and upgrading Monix isn't easy, because compatibility means updating *everything*. This means not just `Task`, but also `Cancelable`, `CancelableFuture`, `Observable`, `Iterant`, and I mean everything.

When Monix started, it had the goal of having "*zero dependencies*". Having no dependencies is a virtue, precisely because those dependencies can seriously break compatibility. There is no way for Monix and CE 3 to currently coexist in the same project, due to JVM's limitations and the decision for Monix to depend directly on Cats-Effect. If Monix were independent of such base dependencies, it could coexist while its maintainers could afford a hiatus.

I'm always reminded of Rich Hickey's thoughts from his [Spec-ulation Keynote](https://www.youtube.com/watch?v=oyLBGkS5ICk). TLDR — when you break compatibility, maybe it's better to change the namespace too. Given in static FP we care about correctness a lot, how to evolve APIs is a really tough problem. I'm still thinking that Monix's major versions should be allowed to coexist by changing the package name (e.g. `monix.v4`), but few other projects are doing it.

I will be resuming the work on Monix, and will be calling for volunteers. And I hope I won't let people down again. My current plan is:

- Monix will be upgraded to the Cats-Effect 3 model, which will include project-wide changes;
- The dependency on Cats and Cats-Effect 3, however, will probably be separated in different subprojects; while this involves "orphaned instances", this decision is made easier by tooling (modularity, ftw):
  - the Scala compiler supports custom implicit imports via `-Yimports`; I don't recommend it, but the option is there;
  - Scala 3 automatically suggests possible imports for missing implicits;
  - IntelliJ IDEA too automatically suggests imports;
- I'd like to make [monix-bio](https://github.com/monix/monix-bio) be part of the main project;
- I have some new functionality in mind that will make Monix an unbeatable replacement for `scala.concurrent`, RxJava, Akka Streams, and the middle-ground that people need in adopting FP in Scala;

Looking forward to having fun, I'm very excited about it, actually 🤩

If you'd like to help in building the next version of Monix, contact me.
