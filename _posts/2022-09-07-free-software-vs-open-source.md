---
title: "Open Source vs Free Software"
image: /assets/media/articles/open-source.png
image_hide_in_post: true
date: 2022-09-07 19:28:56 +03:00
last_modified_at: 2023-05-28 09:39:22 +03:00
tags:
  - Politics
  - Open Source
description: >
  You may think that Open Source is about having "access to source code", whereas Free Software is about freedom. Kids, gather around, let me tell you why that's wrong.
---

<p class="intro" markdown=1>
You may think that Open Source is about having "*access to source code*", whereas Free Software is about freedom. Kids, gather around, let me tell you why that's wrong.
</p>

Open Source is based on the [Debian Free Software Guidelines](https://en.wikipedia.org/wiki/Debian_Free_Software_Guidelines). The DFSG was first published in July 1997, the primary author being Bruce Perens. This was Debian Linux's social contract. And in 1998 the [Open Source Initiative](https://en.wikipedia.org/wiki/Open_Source_Initiative) was born, with "Open Source" being officially coined, although the term [happened earlier](https://en.wikipedia.org/wiki/The_Cathedral_and_the_Bazaar).

Interestingly, DSFG and its successor, the Open Source definition, where not based on the Free Software definition. And the Free Software definition did not contain "freedom zero" (aka Open Source's rule 6), which was added later, being inspired by OSS's definition.

However, the definitions of [Free Software](https://www.gnu.org/philosophy/free-sw.en.html) and that of [Open Source](https://opensource.org/osd) are equivalent. I know of no license that is compatible with Free Software, and not with Open Source, or vice-versa. For all intents and purposes, the 2 definitions are the same, except that the Open Source one seems to be more precise (to this uninformed citizen).

So what's the difference?

The difference is one of ideology ... while both emphasize the freedom to do what you wish with a program and its source-code, Free Software is an online movement that believes **proprietary software is immoral**. And while certain proprietary software may be acceptable for now, it is only acceptable on the path towards it being made Free Software. In other words, Free Software proponents are working towards an ideal world in which all software is Free Software.

Open Source, on the other hand, leaves these politics behind and focuses on the economics of it — Open Source software should exist because it's good from an economic standpoint, on its own merits, because it can be better than proprietary software (cheaper to build, more secure, etc.). This mentality is shunned by Free Software advocates, who'd prefer Free Software even if there wouldn't be any economic advantage to it.

The Open Source definition exists because businesses wanted to release products as Free Software, but either wanted a more clear social contract, or wanted nothing to do with its politics, or the organization behind it. It's still about freedom though, but from a slightly different perspective.

When I say that I prefer Open Source software, I say so because I want complete control over it. I want the ability to inspect it, to fix it (or pay others to fix it), to enhance it, and to freely distribute those changes. Some restrictions on redistribution may apply (e.g., GPL), but "redistribution" is clearly defined by copyright law, and those aren't restrictions on usage, or on the ability to share the derived work. Freedom is about having control, with the ensuing responsibility.

Many times I prefer proprietary software; I'm typing this on a MacBook after all. Sometimes I don't want freedom, I just want to get the job done. But, if I am to build a program, I'd rather build on top of Open Source infrastructure, because it's a pretty bad idea to depend on the whims of some other company that may not even answer phone calls.

The difference between Free Software and Open Source does manifest in what people choose to work on. It's the difference between [GCC](https://en.wikipedia.org/wiki/GNU_Compiler_Collection) and [LLVM](https://en.wikipedia.org/wiki/LLVM). For those unfamiliar, GCC is (was?) a monolith that made it hard for companies, such as Apple, to build proprietary plugins and tools that interact with it, such as Xcode. It wasn't just the license, as allegedly the code was by design made to interact poorly with tooling such that tooling would have to be distributed under a GPL-compatible license. Or so the saying goes. This is precisely how LLVM grew, being funded by Apple, and I might say that LLVM is now a wildly successful project. You might say that the difference is in the copyright license: copyleft vs liberal, but that would be wrong. For another example, Linux's ethos is [closer to Open Source](https://www.theregister.com/2006/03/10/torvalds_gpl_drm/), which is why some people still hoped for [GNU Hurd](https://en.wikipedia.org/wiki/GNU_Hurd) to arrive, in spite of Linux's dominance (and no, it's not GNU/Linux 😜).

Ever since the movements were born, it attracted many followers amongst computer programmers and sysadmins. As Linux started to dominate Internet servers, and as former junior programmers and sysadmins became seniors with buying power, Open Source gained market-appeal. It's why we had attempts to redefine it, like Microsoft's [Shared Source](https://en.wikipedia.org/wiki/Shared_Source_Initiative), which granted access to the source code, but only for non-commercial purposes. You'll be forgiven if you don't remember [Microsoft's Rotor](https://en.wikipedia.org/wiki/Shared_Source_Common_Language_Infrastructure), as nobody cared, and [Mono developers](https://en.wikipedia.org/wiki/Mono_(software)) were banned from reading that source code, since Microsoft was threatening the Linux ecosystem with patents lawsuits. This was back when Microsoft compared copyleft licenses to a virus and did everything in their power to stop its spread.

Keeping to the official *Open Source definition* is more than just pedantry. If a license is Open Source, you know exactly what you can do with that software, lawyers rarely needed. When a piece of software is not Open Source, the primary cost is your (economic) freedom, and that's something you need to take into account when calculating your risk and budget.

Open Source is free as in "free market economy" 😉
