---
title: "Scala's Gitter to Discord migration mistake"
image: /assets/media/articles/scala.png
tags: 
  - Open Source
  - Opinion
  - Scala
description: >
  The Scala community is increasingly using Discord for “real-time chat”. This was announced in December, and the community page lists several Discord “servers”, one of them belonging to Typelevel. I think this move from Gitter to Discord is probably a mistake.
---

<p class="intro withcap" markdown=1>
The Scala community is increasingly using Discord for "real-time chat". This was [announced in December](https://www.scala-lang.org/blog/2021/12/21/discord.html), and the [community page](https://www.scala-lang.org/community/) lists several Discord "servers", one of them belonging to Typelevel. I think this move from Gitter to Discord is probably a mistake.
</p>

I participated in [Typelevel's migration](https://typelevel.org/blog/2021/05/05/discord-migration.html) as well. The migration was done out of genuine concern for the health of the community, and I considered Discord as a good experiment to have. One can also argue that the community simply went to where the users wanted to be, although in our case it was definitely a decision pushed forward by a committee that helped the migration. Can't speak for others, but I went after a couple of contributors to convince them to join Discord.

When comparing Gitter to Discord, the main reasons for why I now believe Gitter is better is because:

1. Information on Gitter is public, it does not require an account to read;
2. Information on Gitter can be linked from across the web;
3. Information on Gitter being public, is indexed by search engines and is being archived;

By contrast, Discord is an information black hole, Discord is a closed ecosystem, Discord is anti-web. It doesn't matter how much Gitter's client used to annoy you, these reasons alone make Gitter better than Discord, with Discord unable to have any redeeming quality that make it better for Open Source contributors that want to provide support or to spread knowledge.

If engagement of new people is a concern, Discord can't be better because it can't be read without having an account. If the slowed growth of the community is a concern, I don't think Gitter was to blame, or that Discord made things better. I could be convinced with numbers, but I don't think those numbers exist.

If per-repo silos are a concern, Discord can't be better because its servers and channels can't be linked from across the web. Compare the discoverability of <https://gitter.im/typelevel/cats> or <https://gitter.im/http4s/http4s> with <https://discord.gg/XF3CXcMzqD>. On Gitter, people in the `scala/scala` Gitter chat room could be redirected to the `http4s/http4s` chat room, via web links (an outstanding technology). On Discord, however, that's not how it works, because Scala-lang and Typelevel have different servers. You must convince people to jump between servers, and to join a server you need an invitation. Discord servers are islands, which makes them silos in a way that Gitter chat rooms have never been.

As an Open Source contributor, to open a support channel, your project has to be either very popular, or be part of / related to Scalameta, or Typelevel, or ZIO, or Play Framework. Otherwise, you'll have an uphill battle to convince people in joining Discord, or if they already are Discord users, to convince them to join your server. And creating a support channel on a server that you don't own means giving up control of that channel to the server's admins, which has pros and cons. Giving up control means there's better enforcement of a code of conduct, making people feel safer however, I'm not convinced that the chat rooms are nicer/safer than they were on Gitter.

Maybe I'm wrong, and moderation is indeed a soul-wrecking job made by unsung heroes. I will also add that there is value in having a Gitter channel per repo, with separate moderators, because on big servers moderation isn't a job that can be done by one or a couple of individuals. Not without it leading to burnout. We are burning out our most valuable contributors by pushing them to pick up administrative tasks.

If inclusivity is a concern, usage of Discord discriminates against those that cannot or will not use Discord, either because Discord blocks them, or because of privacy concerns. Discord's Terms of Service has been controversial, and they are known for having banned people for discussing cheats in games. AFAIK they once banned a server that discussed anti-cheating solutions. It also asks for phone numbers if it detects VPNs or Tor, and their app does not work from behind our corporate VPN/proxy, which I believe is a deliberate strategy, not a bug.  If you live in a country that's problematic for the US, which of Discord or Gitter do you think is more likely to ban you?

I was triggered by the news that [Thunderbird](https://matrix.org/blog/2022/04/08/this-week-in-matrix-2022-04-08#thunderbird) now supports Matrix. Matrix is an [open standard for decentralized chat](https://matrix.org/). [Gitter has joined Element](https://element.io/blog/gitter-is-joining-element/), and it [speaks Matrix](https://matrix.org/blog/2020/12/07/gitter-now-speaks-matrix), which means you can use the [Element app](https://element.io/) to connect to it. It's not perfect, but it works.

Open Source needs open platforms for teaching. We need the web to stay decentralized. And decentralization is always inconvenient at first, solutions evolve more slowly, but think of how pervasive and awesome email or the web are. I'm not even advertising for Gitter, I'm just anti-Discord. Personally, I'd wish for [Discourse.org](https://www.discourse.org/) servers to be more common in the community. Shout-out to [users.scala-lang.org](https://users.scala-lang.org/),[contributors.scala-lang.org](https://contributors.scala-lang.org/) or [discuss.lightbend.com](https://discuss.lightbend.com/). Real-time chat isn't good for providing support or for spreading knowledge IMO, but that's a personal preference that wouldn't exclude people out of the conversation or lock information behind proprietary walls. 

If you're an Open Source contributor, or user, what I ask of you is to not give up on the open web. That ship may have sailed, but one can hope.

## Update:

To answer one concern — Gitter may not be good for finding information in it, however we are comparing a technical problem with a system that is "defective by design", just [like DRM is](https://en.wikipedia.org/wiki/Defective_by_Design). There is nothing you can do to fix DRM's issues, just like there is nothing that can be done to fix Discord.

I remember legendary conversations that happened on Gitter, and they are still accessible. The web is filled, for example, with bits of wisdom by Fabio Labella (SystemFw) — here's where he exposed his ideas for what became Cats-Effect 3's new interruption model:

[gitter.im/typelevel/cats-effect?at=5c5f1a2fef98455ea4096756](https://gitter.im/typelevel/cats-effect?at=5c5f1a2fef98455ea4096756)

Such bits may be hard to find, but there, I just pointed you to a useful conversation on Gitter, which is accessible, and you don't have to have a Discord account in order for you to read it. When comparing how much they suck, they aren't in the same league.
