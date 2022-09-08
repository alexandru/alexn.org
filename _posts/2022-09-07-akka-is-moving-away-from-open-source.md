---
title: "Akka is moving away from Open Source"
image: /assets/media/articles/akka-logo.png
tags:
  - Open Source
  - Scala
generate_toc: true
image_hide_in_post: true
date: 2022-09-07 19:31:21 +03:00
last_modified_at: 2022-09-08 10:44:33 +03:00
description: >
  According to today’s announcement, Lightbend is changing Akka’s licensing to "Business Source License (BSL)". This is not an Open Source, or a Free Software license. This is a proprietary license.
---

<p class="intro withcap" markdown=1>
According to [today's announcement](https://www.lightbend.com/blog/why-we-are-changing-the-license-for-akka), Lightbend is changing Akka's licensing to "*Business Source License (BSL)*". This is not an [Open Source](https://opensource.org/osd-annotated), or a [Free Software](https://www.gnu.org/philosophy/free-sw.en.html) license. This is a proprietary license.
</p>

<p class="warn-bubble" markdown="1">
  **UPDATE:** The license change [arrived in the repository](https://github.com/akka/akka/pull/31561).
</p>

## Freedom

Read [their licensing FAQ](https://www.lightbend.com/akka/license-faq). Here's what to take away from it:

1. It restricts free usage to non-commercial purposes only, otherwise for any production use you'll need to have a commercial license:
   - This violates Open Source's **rule 6**: "*no discrimination against fields of endeavor*";
   - Or Free Software's **freedom zero**: "*the freedom to run the program as you wish, for any purpose*";
2. It adds a clause that says the software will eventually be licensed as Open Source after 3-4 years.

The commercial license might be free of charge for small companies. That is, if you're comfortable building your company on [freeware](https://en.wikipedia.org/wiki/Freeware) that's always subject to change.

Note that such licenses are similar to what Microsoft tried doing with their [shared source initiative](https://en.wikipedia.org/wiki/Shared_Source_Initiative), back in the day when they were comparing copyleft licenses to a virus. It never took off — access to source code is NOT the point of Open Source / Free Software, but rather the freedom to use that source code, even if you're making money off of it, even if you're an evil genius that wants to take over the world with your sharks with freaking laser beams attached to their heads, all powered by FOSS.

I understand the reasoning given in the blog post, but I disagree with it. Here's why ...

Akka, like other products that pulled a bait-and-switch (e.g., MongoDB and others), is popular *because it was marketed as being Open Source / Free Software*, as developers such as myself would never touch proprietary libraries with a ten-foot pole. Such libraries for me simply don't exist. There are 2 reasons for it:

1. I need control of whatever runs in my program, I need the ability to fix it myself, or to have other people fix it for me, people that may not be affiliated with the maker of those tools;
2. Software licenses are expensive, add up, and even in big companies that can afford it, going through the endless bureaucracy of having such expenses approved is freaking painful, which is why FOSS may be even more popular in corporations than it is in startups;

[Open Source is free as in "free market economy."](./2022-09-07-free-software-vs-open-source.md)

## Market for Open Source

Selling support or extra tooling in FOSS sometimes works, because it's complementary — employees can introduce a FOSS library or tool, without any kind of expense approval from upper management, and then the contract for extra stuff can come later, after it has proven its value.

 [Smart companies try to commoditize their products’ complements](https://www.joelonsoftware.com/2002/06/12/strategy-letter-v/), which is what Lightbend tried, but apparently it didn't work for them. Probably because a software library makes for a poor complement.

The blog post mentions that MariaDB also adopted this proprietary license. The claim is misleading, because [MariaDB (the product) is licensed under GPL2 / LGPL2](https://mariadb.com/kb/en/licensing-faq/), just like MySQL before it. It couldn't be otherwise as, to my knowledge, Oracle hasn't donated the copyright of MySQL. What MariaDB (the company) is actually doing is to offer complementary products, such as MaxScale, otherwise the core server and clients are still Open Source, under GPL2 and LGPL2 respectively. See their [own documentation](https://mariadb.com/projects-using-bsl-11/). The difference couldn't be more striking. In embracing this license, MariaDB became more open compared to other companies that are doing the [open-core model](https://en.wikipedia.org/wiki/Open-core_model). Whereas Lightbend is embracing this license for their core, on which infrastructure is already built. MariaDB took nothing away from what we already had, a rock-solid FOSS database. Not to mention that MariaDB is server software, not a library.

It's morally wrong to make the product popular, by advertising it as Open Source / Free Software, and then doing a reversal later. Don't get me wrong, I am sympathetic to the issue that Open Source contributors aren't getting paid. But in the Java community nobody wants to pay licenses for libraries. If that model ever worked, it was in other ecosystems, such as that of .NET, and that model has been dying there as well. Turns out, trying to monetize software libraries is a losing proposition.

## Contributor's agreements

<p class="info-bubble" markdown="1">
**UPDATED (2022-09-08 09:32:18):** This section was modified to correct some missunderstandings. The previous version of this section is [available on archive.org](https://web.archive.org/web/20220908073048/https://alexn.org/blog/2022/09/07/akka-is-moving-away-from-open-source/#copyright-assignments).
</p>

Lightbend developed most of Akka, but due to its popularity, Akka definitely received contributions from the community. I'm fairly sure that the people that have contributed to Akka will not get compensated right now. This is similar to other products that made similar moves, such as MongoDB. And I'd love to be proven wrong, BTW, although I'm not sure what compensation would be appropriate, given that FOSS contributions are often made in the faith that the project will keep being FOSS.

What makes such license changes possible, even if the project used a copyleft license, is the [contributor's license aggreement (CLA)](https://www.lightbend.com/contribute/cla), which is very similar to [Apache's CLA](https://www.apache.org/licenses/contributor-agreements.html), saying:

> "*Grant of Copyright License. Subject to the terms and conditions of this Agreement, You hereby grant to the Company and to recipients of software distributed by the Company a perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable copyright license to reproduce, prepare derivative works of, publicly display, publicly perform, sublicense, and distribute Your Contributions and such derivative works.*" ([source](https://downloads.lightbend.com/website/legal/LightbendIndividualContributorLicenseAgreement.pdf))

IANAL, but contributors grant them the right to *"sublicense"*, meaning that they can redistribute your work under a different license. In other words, the project could have used a copyleft license (GPL), and a license change would still have been possible. Granted, it could have been worse, like the FSF requiring [copyright assignments](https://www.gnu.org/licenses/why-assign.en.html).

Would a copyleft license help, such as the [LGPL](https://www.gnu.org/licenses/lgpl-3.0.en.html)?

It depends. Copyleft licenses would prevent the code from being incorporated into proprietary code. However, the license change is still possible, depending on the contributor's aggreement being signed.

<p class="warn-bubble" markdown="1">
I think copyright assignment in Open Source, or aggreements that grant relicensing rights, are EVIL, in spite of all good reasons for it. I do not like to contribute to FOSS projects that ask for such permissions, and you should avoid it too. A license change should require the explicit approval of all contributors, no matter how hard that is.
</p>

## Will a fork happen?

The silver lining is that the code will be made Open Source in 3-4 years time. However, consider that:

1. Once a license change happened, it can happen again; license changes destroy trust in the future of the project;
2. 3-4 years is an eternity in Scala's ecosystem (or for libraries in general), due to all the binary backwards compatibility breakage — consider how Akka took a long time to upgrade to Scala 3, or that whatever bug fixes are coming for the current Akka, we'll probably need those fixes;

Also, older versions are still FOSS, still licensed under APL 2.0. This means that a [fork](https://en.wikipedia.org/wiki/Fork_(software_development)) is possible. That's the primary value of FOSS actually — if you're not happy with the direction of the project, you can always fork. I guess we shall see. Note that forks are hard, primarily due to the resources needed and the branding. People don't switch easily. But regardless, the notion that Akka is a FOSS project is now over, which means any potential for outside contributions to Akka proper is gone.

I do hope for a fork to happen. Will FOSS libraries depending on Akka stick to the old FOSS versions, break compatibility by upgrading to the new and non-FOSS versions, or maintain multiple versions? In my opinion, an unintentional fork will happen regardless, simply because many projects will refuse to upgrade to newer versions. I have no popularity metrics though, my assumption here being that Akka is popular enough.

## Feelings

Akka is a great project, and has been one of the major reasons for why people chose Scala, or even Java. We've been using it at work, with great success. However, going forward I can no longer recommend any kind of investment in it.

Again, I understand and have known the struggle that FOSS developers and companies go through. FOSS is just not a good business model. But when making decisions about what libraries to use, or where to invest my time, such concerns are simply not my problem. Consider that before this license change I have recommended Akka, and I may have contributed to Akka in my free time, if I ever found the need for it. But after this change, I can no longer do so without getting paid 🤷‍♂️

I do want to thank Lightbend, from the bottom of my heart ❤️, for all they have contributed. I always loved their work. And I just wish that whatever this is wouldn't have happened. But it did, and now we have to deal with it.
