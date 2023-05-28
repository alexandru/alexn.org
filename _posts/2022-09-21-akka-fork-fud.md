---
title: "Akka Fork FUD"
image: /assets/media/articles/akka-logo.png
image_hide_in_post: true
generate_toc: true
tags:
  - Open Source
  - Scala
date: 2022-09-21 12:00:00 +03:00
last_modified_at: 2022-09-21 23:22:54 +03:00
description: >
  Lightbend made Akka proprietary from version 2.7.x onward. This left the community wondering about the possibility of a fork, and unfortunately, I see some FUD that needs to be addressed.
---

<p class="intro" markdown=1>
Lightbend [made Akka proprietary](./2022-09-07-akka-is-moving-away-from-open-source.md) from version 2.7.x onward. This left the community wondering about the possibility of a fork, and unfortunately, I see some FUD that needs to be addressed.
</p>

## Fear: Lightbend can sue

There is a high likelihood that bugs get discovered and will have to be fixed in both the BSL-licensed Akka, and in the community fork. As such, this leaves people wondering ... what if Lightbend sues for copyright infringement? What if the bug fixes are so similar that a court will decide such bug fixes are derivate works of the BSL-licensed code?

<p class="info-bubble" markdown="1">
Speaking of a fork, I'd license all new development of a fork in a copyleft license, like [LGPLv3](https://www.gnu.org/licenses/lgpl-3.0.en.html), precisely so that the BSL-licensed Akka can't use it, and it would be compatible with the current Apache 2.0 license. But IANAL, and I don't know how practical a copyleft license is for such libraries. This inability to share future bug fixes can go both ways 😉
</p>

First, of how many lawsuits targeting Open Source forks have you heard of? Do your research and name them. I'd bet that your list will be mostly blank. Because, it turns out, suing and winning in cases of copyright or patents infringement is actually hard.

Anyone can sue for anything, and due to the high costs of such lawsuits, settlements are quite common. But for the few lawsuits against FOSS products that happened, it didn't go so well for the plaintiff. For example, Oracle, with its patents war chest, sued Google for using pieces from a [3rd party Java implementation](https://en.wikipedia.org/wiki/Apache_Harmony) in Android, built via reverse engineering. They also sued for copyright infringement. And Oracle lost. I remember the anti-Java FUD campaigns from back then, people being happy they picked some alternative, like JavaScript, even if Oracle's patents war chest probably impacted them, too, since modern JS engines are also derivates of Smalltalk and Java's Hotspot VM.

As a similar issue, for years people have [spread FUD about Mono](https://en.wikipedia.org/wiki/Mono_(software)), the clean room dotNET-compatible implementation (I was part of that choir). The likelihood of Microsoft suing was high, actually, as this was unfolding in the age when Microsoft was threatening to sue Linux distributions (they never stopped the patents racketeering BTW). Microsoft never sued for Mono, probably because they would've lost. [Their puppet company](https://en.wikipedia.org/wiki/SCO%E2%80%93Linux_disputes#Microsoft_funding_of_SCO_controversy) did lose. If the Mono contributors could manage to not look at .NET's disassembled code, or at [Rotor](https://en.wikipedia.org/wiki/Shared_Source_Common_Language_Infrastructure) for that matter, I think projects smaller than that can be fine. Note, lawsuits may not work, but many in the Linux, or Mono, or [BSD](https://en.wikipedia.org/wiki/UNIX_System_Laboratories,_Inc._v._Berkeley_Software_Design,_Inc.) camps can probably tell you: FUD works, as big organizations are risk-averse.

In our case, we aren't even talking of clean room reverse engineering, which is a much bigger problem. In this instance a fork is perfectly legal due to the Apache 2.0 license, which is perfect for forking, because it contains an explicit patents grant too. Worth mentioning, as this explicit patents grant does not favor any company, and covers derivate works too. This in contrast with what Facebook and Microsoft have been doing 😉 and why Apache 2.0 is better than the MIT or BSD licenses.

**The whole value proposition of [Open Source](./2022-09-07-free-software-vs-open-source.md) is that you can [fork](https://en.wikipedia.org/wiki/Fork_(software_development)).** That's all there is to it. There's nothing else worthwhile about Open Source that's worth mentioning.

If that's not true, then might as well drop all Open Source libraries and tools from your project right now, especially those projects built by companies that require copyright agreements or assignments, legally binding documents granting them the right to re-license everything you contribute as proprietary software.

For instance, one of the contenders for Akka's market share is ZIO. Ziverge, the company behind it, does require a [grant of rights](https://zio.dev/about/contributing/#2-grant-of-rights) ([archive](https://web.archive.org/web/20220921044332/https://zio.dev/about/contributing/#2-grant-of-rights)) on all contributions, giving them the right to distribute your contributions under a proprietary license. Discussions on copyleft aside, they can do precisely what Lightbend is doing. Personally, I don't trust such CLAs and companies that require them, unless we're speaking of the Apache Foundation. If I'd fear the companies behind FOSS projects, at the very least I'd use libraries that don't require CLAs for contributions.

<p class="info-bubble" markdown="1">
**NOTE:** not all companies do this, not all FOSS projects do this. [Typelevel](https://typelevel.org/) in particular does not require the signing of any copyright agreement, and the only agreement required of you is for your work to get distributed strictly under Apache 2.0 (see [contributing](https://github.com/typelevel/cats-effect/blob/series/3.x/CONTRIBUTING.md#licensing)), mentioned here as [I was there](https://github.com/typelevel/cats-effect/issues/521), complaining. [I am not the first to have this opinion](https://www.linuxjournal.com/content/contributor-agreements-considered-harmful), I won't be the last either. And as the most successful FOSS project in history, now getting a majority of contributions from companies, the Linux kernel should be enough to give you pause.
</p>

**The only protection we get, in all such cases, is the Apache 2.0 license, due to the ability for forking.** Open Source licenses exist because "trust" isn't enough, and if you rely on trust, and you're not paying, then "you're the product". If the ability to fork is off the table, then all Open Source software built by companies is a liability. Might as well drop such dependencies, as they are all landmines that will keep you hostage when the company behind them flips.

Thankfully, that's not how Open Source works.

And I am mentioning Ziverge explicitly, as they are the ones spreading these fears right now. Not cool. Especially because Akka can't be replaced. There are a lot of projects building on top of Akka, including projects built in Java or [in .NET](https://getakka.net/), that can't just switch to something else, no matter how much you like your monads and dislike actors. And all claims otherwise are either shortsighted or disingenuous, given how software development at scale works.

I've always been a fan of "growing the whole pie" in terms of market share. Competition does in fact grow the market for everyone. Which is why I never understood ["fear, uncertainty and doubt" (FUD)](https://en.wikipedia.org/wiki/Fear,_uncertainty,_and_doubt) as a marketing tactic, because it shrinks the pie for everyone, and the salesmen using FUD end up getting a bigger piece from a smaller pie.

Akka has been a central part of Scala, the gravitational force that attracted a lot of developers, and quite frankly, if Akka users get thrown under the bus like this, in order to pump up the numbers for some company or another, I will view the entire Scala ecosystem as a liability, for any project, in spite of all my Scala investments, and I'm sure that I won't be alone. It's not personal, it's just business.

Don't get me wrong, **nobody can demand free labor, a fork may not be possible,** but let us all leave our crystal balls at home, and just leave it to the market. Because Scala is small, compared to the juggernauts in this space, and unfortunately how this Akka situation is being handled shows the world what Scala is made of. It's unfair, and I wish this wasn't so, but it is what it is.

## Fear: Akka is too complex

The idea is that Akka is built with VC money, a lot of work went into it, and a community fork isn't sustainable, as it requires man-hours and knowledge about distributed systems.

All I can say is that forks like [Akka .NET](https://getakka.net/) and [OpenSearch](https://opensearch.org/) exist (🎤 drop).

Yes, it will take resources, but if there really are big companies with Akka investments, such a fork can happen. And if a fork doesn't happen, that's life, and maybe Akka isn't so popular or valuable after all.

For our project, I'd also argue that we have everything needed in Akka already, and what we require (beside bug fixing) is for Akka to not hold us back when upgrading dependencies. I'd like to update the libraries that Akka depends on, I'd like us to upgrade to Scala 3 at some point. Updating such dependencies in an Akka fork may take a lot of effort, but it probably doesn't require a PhD in distributed computing.

Therefore, personally, I remain hopeful.
