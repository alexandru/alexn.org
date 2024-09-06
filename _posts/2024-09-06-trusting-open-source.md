---
title: "Trusting Open-Source"
image: /assets/media/articles/2024-thomas-surprised.jpg
image_caption: >
  My cat, Thomas, trying to understand "source available" licenses
tags:
  - Open Source
  - Proprietary Software
---

<p class="intro" markdown=1>
"Shrink-wrapped", "off-the-shelf" apps, or what the young have come to know as premium apps from the app store, are destined to languish, to become expensive subscriptions, or to be sold to shady companies that will sell your data or make your computer part of a botnet. Proprietary apps are destined to either disappear, most of them taking your data with them, or to rip you off.
</p>

I use plenty of proprietary software, my days of FOSS idealism are long gone. But I still prefer Open-Source apps when suitable choices are available. Even if I have to pay for a subscription (e.g., Newsblur), even if it is ads funded (e.g., all browsers), and sometimes even when the product is inferior, as long as it meets my needs (e.g., Gimp). This need is amplified when we build products because I want sane foundations to build on. I would never willingly pick a programming language with a proprietary compiler, a proprietary database system, or depend on proprietary libraries.

This is because Open-Source can accept contributions, or it can be *forked*. If you need control or responsibility, you can assume it. If you don't have the expertise for it, you can pay others to provide service. You may not want control, or you may not have the resources, but that possibility is there. Open-Source software is not immortal, but as long as there's interest, people can find ways to keep it going.

The point of Open-Source isn't and has never been "*source available*". That's just a prerequisite and a nice to have. The purpose has always been giving users the freedom to use for whatever purpose, or to fork the software, which in turn translates to lower development costs for the software makers. Software makers have to give up control, the bargain they have to make to receive contributions. This obviously wouldn't be a good business model, unless you treat the software as a gift to the world, and as a [commoditized complement](https://www.joelonsoftware.com/2002/06/12/strategy-letter-v/) of other products or services. Beware of companies selling support for Open-Source software, as this creates the perverse incentive to keep the software difficult to use and insecure.

There are multiple issues with "*source available*" licensing. 

Firstly, Open-Source licensing gives you peace of mind because they are old and tested. You know exactly what you're getting. The problem with freemium licensing is that money doesn't change hands, there's no contract, no negotiation, so the license is all you have, and that license is open to interpretation. Legal departments in corporations may ban copyleft licenses, but copyleft licenses are well understood, whereas licensing that's designed to ban AWS is not.

<p class="info-bubble" markdown="1">
As a side-note, I find it worrying that idealism in youth, nowadays, is less about freedom, and more about hatred against the rich and powerful. On computer forums, whenever you see someone defending Free Software / Open-Source, that person is likely a graybeard that remembers the times before Open-Source software became this common infrastructure we all rely on.
</p>

You'd think that the source being available is still a good thing because you can read it, helping with understanding and debugging. But that just opens you up to copyright or patent lawsuits, should you end up being inspired by that source code in your own work. This was a thing back when Microsoft had their [Shared Source initiative](https://en.wikipedia.org/wiki/Shared_Source_Initiative), a company that has continuously threatened Linux and Android phone makers with patent lawsuits, even post-Ballmer, while their "Microsoft changed" marketing campaign was ongoing.

You may be able to contribute to the project, but then you're just foolishly doing unpaid labor, as you won't be able to assume control, should you desire it. The raison d'être of Open-Source is gone. And if the software maker goes under, if you built your business on top, forking the software won't be possible, or if it is under some restricted freedoms, few will want to touch it.

Note that [BSL](https://mariadb.com/bsl-faq-mariadb/), a license designed for [delayed Open-Source publication](https://opensource.org/delayed-open-source-publication), is at least more honest and better than source-available licensing designed to ban a company's competition, like [SSPL](https://en.wikipedia.org/wiki/Server_Side_Public_License). Due to the breach of trust, software like MongoDB, Redis or Elasticsearch are dead to me. Interestingly, Elasticsearch recently returned to Open-Source, re-licensed as AGPL, although, I don't understand why anyone would want to return to it, instead of the more free and more secure [Opensearch](https://opensearch.org/).

Proprietary software has a place in this world. We all have to put food on the table. Open-Source is infrastructure, it's "the commons", but it doesn't have good business models, and we don't need control for everything. Some tools can be rented instead of owned. But trust in business is everything. And once gone, it's gone, although it seems like the young may have to relearn history's lessons the hard way 🥲
