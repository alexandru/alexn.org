---
title: "On Advertising and Tracking"
date: 2024-08-12 11:46:00 +03:00
last_modified_at: 2024-08-13 10:20:52 +03:00
tags:
  - Opinion
  - Web
description: >
  Ads are now, unfortunately, a vehicle for malware, scams, or services that are deceptive and barely legal. But, should we block ads?
---

<p class="intro" markdown=1>
Ads on 𝕏 (formerly Twitter) can be blocked. You can use [uBO](https://ublockorigin.com/), [uBO Lite](https://chromewebstore.google.com/detail/ublock-origin-lite/ddkjiahejlhfcafbddmgiahcphecmpfh), or [Brave](https://brave.com/). And on Android, the web interface is a decent alternative to their app, and can be used as a PWA (I recommend Brave for Android, not Firefox). This, of course, is a cat and mouse game. For instance, Facebook has made it hard for ad-blockers to keep up, they probably have a team of engineers working on anti-ad-blocking tech; uBO still works, but I wonder for how long. For the most part, ad-blocking in the browser works well.
</p>

<p class="info-bubble" markdown="1">
My wish is to write more and to publish more on my blog, and less on social media. This may mean more noise for you, my dear reader. I try maintaining a useful set of tags, so for example, you may want only my articles on [Programming](/blog/tag/programming/) or [Scala](/blog/tag/scala/). As a PRO-tip, many feed readers can filter feeds by tags; personally, I use [Newsblur](https://newsblur.com/), which has excelent filtering.
</p>

Last night, I was watching "House of the Dragon" on MAX (former HBO MAX), and they've introduced ads in their "Basic" plan. I did not mind an ad for cleaning products, although a little obnoxious, but I did mind their ad for a sports betting app. "Recorder", an online publication from Romania, has recently covered a vast international online fraud operating in Eastern Europe, gaining access to people's bank accounts via social engineering, and stealing their money. The way they reach people is via Google and Facebook ads, linking to deep fakes of public figures. And I've seen those ads with my own eyes, in my own Facebook feed, I've reported them repeatedly, and Facebook rejected my reports. 

Ads are now, unfortunately, a vehicle for malware, scams, or services that are deceptive and barely legal, which is why many secretly wish for the entire business model to burn to the ground. Also, ads are very annoying. So the answer to this question should be settled already:

## Should we block ads?

Unfortunately, there are second-order effects to blocking ads...

The free web was built on ads. Yes, there was a web before ads, but speaking as someone who has been on the Internet since the late 90s, it was a shitty web. You may not like it, but some online services are costly to host. A service like YouTube isn't possible without a sustainable business model, and it's really difficult to build YouTube alternatives because Google can only make it work at their huge scale. And peer-to-peer alternatives are a romantic notion that will just not happen. Therefore, a completely ads-free YouTube would be a service inaccessible to the poor. Even if your government started collecting taxes for keeping certain Internet services free, that could mean poorer countries may get blocked from those services. I remember being blocked from a BBC show because I'm not a UK citizen. And wanting the Internet accessibility to depend on whomever is in power is foolish.

The fact of the matter is that, in many ways, advocating for an ads-free Internet is currently advocating against the notion that *information wants to be free*.

Ad-blocking, just like piracy before it, hurts alternatives and helps incumbents. People used to pirate Microsoft Windows, or Adobe Photoshop, back in the day, even if alternatives such as Linux or Gimp were more than suitable for the average Joe's needs. Companies can't compete with free alternatives, unless they establish a monopoly. And that's precisely what happened, current day monopolies having been greatly helped by piracy. It's hard nowadays to be an indie game or software maker, which is why I can't be so harsh against DRM-enabled distribution platforms. We helped the rise of DRM and of centralized distribution channels by pirating software.

Just as with piracy, blocking ads is keeping users from trying ads-free alternatives. People are less likely to try Mastodon or Bluesky, if their 𝕏 feed isn't filled with annoying ads, and the issue is that they are still contributing to that platform's success by engaging or distributing content. "Voting with your wallet" no longer works, and then we start wishing for some government to step in and break monopolies that we helped create.

Ad-blockers are contributing to the death of the open Web. You should have noticed that the web is less popular on mobile phones. Services push people to use native apps. For example, the Reddit app is being forced on users, despite the web interface being more than adequate.

And the reason is simple — you can't block ads in apps. If your Pi-hole-based solution works right now for some use-cases, it won't work forever. Pi-hole can't work for 1st party ads, and apps can use their own DNS-Over-HTTPS endpoints.

The web works so well because the user agent is ours, acting on our behalf. We are in control, and the browser is the perfect sandbox. But with all that power comes great responsibility, and the trend that has been happening is companies driving users away from the web browser and into privacy-invasive apps. This is why browsers have tried addressing privacy-concerns in ways that don't invalidate ads-driven business models, or that breaks the web, such as Chrome's [Privacy Sandbox](https://privacysandbox.com/) initiative, or Firefox with its [privacy-preserving attribution API](https://github.com/mozilla/explainers/tree/main/ppa-experiment). Such initiatives [have been met with hostility](https://www.reddit.com/r/firefox/comments/1e43w7v/a_word_about_private_attribution_in_firefox/) by the extremely online laptop class, without them suggesting any alternative, and with the discourse highlighting that for them the issue isn't with privacy at all.

## Good and bad reasons to block ads

Blocking ads is legitimate if you want to protect yourself or others from scams, malware, or privacy-invasive tracking. Personally, I think I can protect myself, although absolutely everyone can fall for scams, it's just an issue of resources and the right timing. And I certainly would like to protect my son or my father from scams or malware. Yes, I block all the ads that I can block.

Blocking ads is immoral if you just want access to free shit.

YouTube has a quite reasonably priced Premium option. If you're not paying for YouTube Premium, and you're blocking their ads, you're just an entitled freeloader that wants to get other people's work for free. I'd say the same thing for 𝕏, except that I think their Premium+ tier isn't reasonably priced — OTOH, if you're not paying at least for "Basic", then you're a freeloader, and with 𝕏 this is more problematic, as you could contribute content to the Fediverse; and instead you're just giving 𝕏 your attention, while rambling about how Elon Musk is driving it into the ground.

Many people just want to receive the hard labor of others for free. If you're one of those people ranting about "late-stage capitalism", I'm sorry to tell you comrade, but even if the revolution comes, you'll still have to work for a living. If you're one of those people that hates the business model, wanting to drive it into the ground, then why not go for the subscription-based alternatives? Why not encourage sustainable business models that aren't ads-based?

Indie developers or corporations are just people that have to work for a living, and by depriving them of revenue, you're either contributing to their unemployment, or to a world of locked-down devices. Stealing from a corporation is still stealing from people that have to make ends-meet. As much as I hate DRM, or the walled gardens created by Apple, Google, Amazon, Spotify et al., it shouldn't be difficult to see why creators have preferred the walled gardens. 

**TLDR** — blocking ads is recommended, with the industry certainly needing a wake-up call given current practices, but don't be a freeloader because you're contributing to the death of the open web, and to the disappearance of small creators, while growing existing monopolies.
