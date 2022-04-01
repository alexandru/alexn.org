---
title: "Block comments on the web"
date: 2020-10-20 22:51:45+0300
image: /assets/media/articles/block-comments.png
image_hide_in_post: true
tags:
  - Browser
  - Web
description: "Comments on the web can be toxic, and a waste of time. Here's how to block them..."
---

<p class="intro">
  Comments on the web can be toxic, and a waste of time. Here's how to block them ...
</p>

## In Firefox/Chrome, and Android

I assume you already use [uBlock Origin](https://github.com/gorhill/uBlock), and if not, then throw away whatever alternative you have, and switch to it. 

On Android, uBlock Origin is supported by [Firefox](https://www.mozilla.org/en-US/firefox/mobile/). If Firefox isn't an option, there are others. At the moment of writing [Vivaldi](https://vivaldi.com/) has backed-in content blocking, and supports custom filtering rules, but you might have to publish these rules, in a text file, somewhere online. [Adguard](https://adguard.com) might also support custom content filtering rules, although I have issues with trusting them MITM my traffic.

In uBlock Origin, add these to "_My Filters_" in its dashboard:

```
news.ycombinator.com##table.comment-tree
reddit.com##div.commentarea

youtube.com###comments

||disqus.com/embed/comments/
||disqus.com/embed.js
###disqus_thread
##.dsq-brlink
##.disqus-container
```

Here's how it should look like:

<figure>
  <img src="{% link assets/media/articles/block-comments.png %}?{{ 'now' | date: '%Y%m%d%H%M' }}" alt="Screenshot of uBlock Origin's My Filters section" />
</figure>

These rules block comments from:

- Hacker News
- Reddit
- YouTube
- Disqus (on all websites)

Optionally, for extra sanity and street cred, also add these rules 😎

```
||twitter.com
||facebook.com
```

A short primer on the syntax ...

- Prefix CSS selectors with `##`; so `##.dsq-brlink` will block HTML elements with a `.dsq-brlink` class, and `###disqus_thread` will block HTML elements with a `#disqus_thread` ID
  - These CSS selectors can be "generic", meaning they apply to all websites (in the case of Disqus), or they can apply to a specific domain: e.g. `###disqus_thread` is a cosmetic filter that applies to all websites, whereas `youtube.com###comments` filters HTML elements with a `#comments` ID that are shown on `youtube.com`
  - See relevant [cheat sheet section](https://adblockplus.org/filter-cheatsheet#elementhiding){:target="_blank"}
- You can block specific resources from loading; a `||` prefix means that a domain name follows, until a separator such as `/`
  - A rule such as `||disqus.com/embed.js` will block `/embed.js` on all subdomains of `disqus.com`
  - See relevant [cheat sheet section](https://adblockplus.org/filter-cheatsheet#blocking2){:target="_blank"}

For more details on these rules, see this cheat sheet: <br>
[Adblock filters explained](https://adblockplus.org/filter-cheatsheet)

### Publish it

You can publish this list, as a text file, somewhere, anywhere, and reuse it wherever you have uBlock Origin installed. For example, I published mine at:

[{{ site.domain }}{{ site.baseurl }}/assets/misc/block-lists/comments.txt]({% link assets/misc/block-lists/comments.txt %}){:target="_blank"}

You can then import it in uBlock Origin easily:

<figure>
  <img src="{% link assets/media/articles/block-comments2.png %}?{{ 'now' | date: '%Y%m%d%H%M' }}" alt="Screenshot of uBlock Origin's Filter List" />
</figure>

## Safari / iOS (iPhone, iPad)

Safari, on macOS and iOS, has content blockers too. Not as capable, but they do the job. An excellent one is [Wipr](https://giorgiocalderolla.com/wipr.html), but it doesn't allow setting custom rules.

- A prepackaged solution that can block comments is [Quiet](https://lighthouse16.com/quiet/), but that's less fun
- [1Blocker](https://1blocker.com/) appears to allow for [creating custom rules](https://support.1blocker.com/hc/en-us/articles/360002309738-Creating-Custom-Rules), but I haven't tried it yet
- [Building your own content blocker](https://developer.apple.com/documentation/safariservices/creating_a_content_blocker) could be a fun project

If you know of a better solution, write about it in the comments section 😅😂
