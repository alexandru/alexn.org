---
title: "Use Firefox in 2025"
image: /assets/media/articles/2025-firefox.jpg
image_hide_in_post: true
date: 2025-03-03T23:51:40+02:00
last_modified_at: 2025-03-04T21:57:13+02:00
generate_toc: true
tags:
  - Browser
  - Open Source
  - Politics
  - Products
  - Web
---

<p class="intro" markdown="1">
  I grew up with the Internet, since before people had Internet connections at home or in their pocket. The browser, being the window to the open web, holds a special place in my heart. In this article I'm suggesting the use of Firefox in 2025, for both technical and political reasons, as it's still the *"user agent"* that it set out to be.
</p>

## On the desktop

Firefox remains the only one supporting [uBlock Origin](https://github.com/gorhill/uBlock), the version that's not defective by the design of the browser. Many may not notice a difference by using its [Lite version](https://github.com/uBlockOrigin/uBOL-home), the one based on Manifest v3, but I can tell you that most ad-blocking tech is easy to circumvent, whereas the full version of uBlock Origin has been the nightmare of online advertisers.

Firefox can have extensions that expose a sidebar. This is how [Sideberry](https://addons.mozilla.org/en-US/firefox/addon/sidebery/) or [Tree Style Tab](https://addons.mozilla.org/en-US/firefox/addon/tree-style-tab/) can work. Tab grouping from Chrome is nice, but you have to make a conscious effort to use groups, whereas trees are automatic, and you can simply hide that sidebar if you're not interested in it. It actually works well with Firefox's vertical tabs, with `Ctrl-E` toggling my "Sideberry" panel whenever I need it, otherwise seeing a nice vertical column of icons.

<p class="info-bubble" markdown="1">
  Vertical tabs have been officially released in [Firefox 136](https://www.mozilla.org/en-US/firefox/136.0/releasenotes/).
  Tab groups (experimental) can be enabled if you toggle `browser.tabs.groups.enabled` in `about:config`.
</p>

`Ctrl-Tab` in Firefox has the best behavior, and it's nice that if you keep `Ctrl` pressed it shows you a graphical switcher previewing around 7 tabs on my laptop's screen. I've only seen something equivalent in Vivaldi.

Firefox has great privacy, with features such as [Total Cookie Protection](https://blog.mozilla.org/en/products/firefox/firefox-rolls-out-total-cookie-protection-by-default-to-all-users-worldwide/) which isolate third-party cookies without breaking websites. It also blocks many trackers by default, although note that I don't enable "Strict" mode, as it breaks websites (and honestly, uBlock Origin is enough). It's still nice that it blocks the worst privacy offenders out of the box.

[Multi-account Containers](https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/) are really nice when you have to manage multiple accounts for the same online service (e.g., AWS). Although, note that it doesn't do much for privacy (ever since Total Cookie Protection) and the feature provides less isolation than when using "profiles".

The suggestions in the address bar, aka "Awesome Bar", are the best. Don't get me wrong, Chromium's Omnibar is pretty good, as well, but despite its improvements, IMO it's still prioritizing search over bookmarks and history.

Firefox's history synchronization works better than in all Chromium browsers I've tested. Chrome's synchronized history is missing items when you're enabling encryption, like for example when you're jumping from page to page by clicking links. What gets synchronized are the pages and the searches that you enter directly in the address bar. And the time window is more limited. Firefox's history of visited URLs, and its bookmarks, are helpful when using its address bar, as it can reliably give you suggestions, thus avoiding Google searches.

Firefox supports [DNS over HTTPS](https://en.wikipedia.org/wiki/DNS_over_HTTPS) with the best customizability — i.e., it can fall back to the system's DNS. This is important for me in case I'm connected to the corporate VPN in charge of serving corporate resources, but I still want my regular DNS queries to go through my own DoH service, encrypted as well. 

Firefox has [offline translations](https://support.mozilla.org/en-US/kb/website-translation) via offline AI. I remember disliking Google Translate because it is slow, and I also worried about my privacy, as you're sending your web page to a server. Speaking of, if you think AI isn't useful in a browser and that Mozilla shouldn't invest in AI, well, here's one sample where you're definitely wrong.

Other things I like:
* Firefox has had the best Linux and BSD support. For example, many switched to it due to its support for Wayland.
* The PDF viewer has support for editing PDF documents. On macOS this doesn't sound like much (due to Preview), but on Windows or Linux it's a blessing.
* UI of Picture-in-Picture is nice and PiP can be automatic when you switch tabs (in preview / labs).
* The Reader View is good and reliable (also [see this extension](https://addons.mozilla.org/en-US/firefox/addon/activate-reader-view/) to force activate it in the rare cases where article detection fails).
* Has great customizability, even though it feels limited at times — there's nothing that an extension, a custom stylesheet or some setting in `about:config` can't fix.

## For Android (Mobile)

Firefox on Android supports extensions, and here are the ones I'm using:
* [uBlock Origin](https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/)
* [Dark Reader](https://addons.mozilla.org/en-US/firefox/addon/darkreader/)
* [Cookie AutoDelete](https://addons.mozilla.org/en-US/firefox/addon/cookie-autodelete/)
* [LeechBlock NG](https://addons.mozilla.org/en-US/firefox/addon/leechblock-ng/)
* [SponsorBlock - Skip Sponsorships on YouTube](https://addons.mozilla.org/en-US/firefox/addon/sponsorblock/)
* [Stylus](https://addons.mozilla.org/en-US/firefox/addon/styl-us/)
* [Web Archives](https://addons.mozilla.org/en-US/firefox/addon/view-page-archive/)

Some of these features may be built into some of the available browsers, but not all of them, plus the functionality provided is better, for example:

* Dark Reader is better than the *"apply dark theme to websites"* checkbox from Chrome (activated via `chrome://flags`), it usually gets out of the way, but also allowing customizations for when it fails; I'm also one of those users that auto-switches to dark mode only at night.
* Cookie AutoDelete is built into the Brave browser, but with fewer customizations and functionality; being a power user, I prefer Firefox's extension.

Other features of Firefox for Android that I like:
* *"Open in another app"* can be disabled, or Firefox can ask what you want. It also provides a neat shortcut in the menu if you change your mind.
* New Tab page is helpful.
* Synchronization of tabs with the desktop works well, and the UI is nice (I like that I can find where it is).
* Reader Mode works well. Compared with the desktop, it can't do text to speech on its own, but there are other solutions for that, including built-in Android functionality or Pocket.

Firefox for Android has issues, such as poor performance on some websites (e.g., Mastodon, I even [opened an issue](https://github.com/mastodon/mastodon/issues/32554)) or poor PWA support. But I use my mobile browser primarily for reading articles, and for that, having a good ad-blocker, dark mode (for when needed), or a working reader mode are much more important.

## Firefox, the User Agent

The [user agent](https://en.wikipedia.org/wiki/User_agent) is a piece of software responsible for interacting with the web, such as a browser, but it's critical that this agent represents the user and its interests. A user agent shouldn't represent the interests of the publishers or that of the advertisers while harming the user. Publishers and advertisers are important as well, but the user should come first.

Think of Chrome. When you log into Chrome, it automatically logs you into your Google account on the web. It also activates a setting named *"improve search suggestions"* by which Chrome shares your navigation history with Google. It doesn't matter if you have encryption enabled, that feature will be on for every new device, as it's not synchronizing from your account's settings either. Chrome is adversarial towards users. On every released version, any privacy conscious user would have to carefully read its release notes and look at its settings page, thinking about *"how will these new features screw me in the future?"* Do you like uBlock Origin? Google has deprecated it and lied about the reasoning for doing so, knowing full well that the replacement is much less capable. We're talking about the desktop because Chrome on Android does not support extensions, even though it could without much effort, being the same codebase.

Chrome is an excellent browser, but when the user's interests conflict with that of Google, it's the interests of Google that win.

A browser being a good user agent isn't solely about trust, but about ability as well. A browser isn't a good user agent if it can't be extended in ways that conflicts with the interests of its maker. You need extensions [to retake your browser](https://andregarzia.com/2025/02/retaking-the-web-browser-one-small-step-at-a-time.html). I believe Firefox is still a worthy User Agent, despite Mozilla's blunders. This isn't just a feeling, but a fact based in Firefox's current technical abilities.

But for Firefox's sake, I hope Mozilla understands why many people still use Firefox because once trust is lost, it may never return.

## Politics

I tried staying apolitical for a long time, but this is no longer possible, as this is now about my self-interest. And given the worldwide politics, especially in light of the US administration becoming hostile towards the European Union, I'm becoming increasingly more uncomfortable using or recommending products or services from the US's Big Tech companies. Likewise, I'm uncomfortable with products built by MAGA figures. When other people place their country first, voting for an administration that turns against allies, I have to remember that I'm a European first, sorry.

You may disagree, and that's fine by me. Software is usually amoral, and your threat model may be different from mine. But being EU-friendly is important to me for obvious reasons and unfortunately, in the world we now inhabit, I find myself increasingly wary about the software that I'm adopting. And don't get me wrong, I try avoiding Russian and Chinese software and services as well 🤷‍♂️

Other browsers that would bring me some peace of mind would be [Tor](https://www.torproject.org/), [Mullvad](https://mullvad.net/), or [Vivaldi](https://vivaldi.com/). There may be others, like [Zen](https://zen-browser.app/). As a general rule, they either have to be community maintained or backed by an EU company, with Firefox being the only exception that I'm going to allow, for now.

Note that I'm not naive about where the major contributions are coming from. There are only 3 major browser engines, all 3 developed by US companies, all 3 primarily funded by Google's Ads. But I can live with Open-Source and I think the forks can do a reasonable job at disabling hostile functionality, such as all the phoning to the mothership, with [mixed results](https://privacytests.org/).

## Controversies

Mozilla isn't without controversy, and lately, they've [doubled down](https://blog.mozilla.org/en/mozilla/mozilla-leadership-growth-planning-updates/) on them diversifying their revenue via more advertising, [updating their privacy](https://blog.mozilla.org/en/products/firefox/update-on-terms-of-use/) to make it unambiguous that they intend to share your personal data with advertisers. Yikes! 

Many people view this as a betrayal of their values, and there's some truth to that. Take a look at this old ad, when they seemed to have more of a drive for doing the right thing:

{% include youtube.html id="AIKLdVEWPrE" caption="Firefox a different kind of browser" image="https://img.youtube.com/vi/AIKLdVEWPrE/hqdefault.jpg" %}

But when talking about Mozilla's direction, one has to keep in mind that to develop and maintain a browser, you need a lot of money. In our country, we have a saying like *"you're my brother, but cheese costs money".* Chrome's estimates, for example, exceed 1 billion $ per year in development costs. People don't want to pay for browsers, you can't rely on the donations of people preferring to ad-block YouTube instead of paying for Premium. And asking for governments, like the EU, to fund it is not a great idea for obvious reasons, such as Mozilla not being an EU entity or the fact that the state serves the interest of their taxpayers, and not the interest of the whole world. 

Mozilla has been surviving on Google's Ads ever since the Search deal. Google, at this point, is funding all 3 major browser engines, and this includes Safari, given that Google is paying Apple around 20 billions per year in the search deal. This has consequences. For example, even though both Mozilla and Apple have been singing the privacy tune, they never did anything to upset their cash cow, which is Google Search. So let's be honest — Firefox has been funded by ad-tech since 2006, and Mozilla diversifying their revenue can't be a worse betrayal of their values than what happened since then.

What's important for me aren't the words, but what they actually accomplish. Thus far, Firefox has gone to further lengths than any other browser to preserve privacy in ways that actually matter. For example, the aforementioned [offline translation](https://support.mozilla.org/en-US/kb/website-translation) feature that doesn't leak your web page to an online server. I also remember when they released [PDF.js](https://github.com/mozilla/pdf.js), so back when the PDF viewer in Chrome was a proprietary blob (FoxIt, does it still ship with it?), Mozilla was like "hold my beer" and built an Open-Source PDF viewer in freaking JavaScript and HTML. Their history is filled with great feats, both old and recent, that just can't be easily erased.

In fact, the introduction of their [privacy-preserving attribution](https://support.mozilla.org/en-US/kb/privacy-preserving-attribution) feature is far more worrying than any of the new words in their Privacy Policy. On the other hand, I can give them the benefit of the doubt, at least for now. At the very least, I know that they'll try making PPA privacy-preserving. Mostly because I don't have much choice left.
