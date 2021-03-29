---
title: "Atom/RSS Feeds are the Best Way to Consume the Web"
date: 2021-03-29 22:58:29+0300
image: /assets/media/articles/highway.jpg
generate_toc: true
tags: 
  - Blogging
  - Jekyll
  - Web
description: "I stay connected to websites I care about via an RSS/Atom feed reader. It's better than social media for finding out what's new because it's clutter-free. By following RSS/Atom feeds, I discover wonderful gems that otherwise would be lost in the noise."
---

<p class="intro withcap" markdown="1">
  I stay connected to websites I care about via an RSS/Atom feed reader. It's better than social media for finding out what's new because it's clutter-free. By following RSS/Atom feeds, I discover wonderful gems that otherwise would be lost in the noise.
</p>

## RSS is not dead

[Web syndication](https://en.wikipedia.org/wiki/Web_syndication) is alive and kicking. A vast majority of websites and online services expose RSS/Atom feeds, and you can find workarounds for those that don't.

When I like individuals on the web, I tend to like pretty much everything that they write. Even when I connect to a fire hose, the RSS/Atom feeds are all content. Even when following pundits, you get long-form writing on websites instead of shallow opinions that must fit in 280 chars. Websites or even YouTube channels, compared with social media, are outlets in which people usually put more thought when expressing themselves.

My RSS/Atom feed reader is the best way to follow:

- Hacker News, via [hnapp.com](http://hnapp.com/)
- Twitter accounts that are important, via a self-hosted [rss-bridge](https://github.com/RSS-Bridge/rss-bridge)
- Library releases, via [GitHub's atom feeds](https://docs.github.com/en/rest/reference/activity)
- Podcasts
- Reddit (a fire hose, but I can filter by subjects I care about)
- Programming communities (Scala, Haskell, etc)
- YouTube

## Updates to my blog's feeds

<p class="warn-bubble" markdown="1">
  If you follow my blog's [RSS feeds](https://alexn.org/subscribe.html) you may have noticed that some articles were changed. That's because I modified the blog posts to be published in full, inside the RSS feed, so I had to make necessary fixes where appropriate. Sorry for the noise 🙏
</p>

My blog articles can now be enjoyed from the RSS reader, without having to open the website. See:

- [/feeds/blog.xml]({% link feeds/blog.xml %})
- [/feeds/all.xml]({% link feeds/all.xml %})

## News aggregators (RSS readers)

Web hosted:

- [Newsblur](https://newsblur.com) (managed, the best IMO)
- [FreshRSS](https://freshrss.org/) (easy to self-host)

Native:

- [Reeder](https://reederapp.com/) (macOS, iOS)
- [FeedMe](https://play.google.com/store/apps/details?id=com.seazon.feedme&hl=en_US&gl=US) (Android)

## For your blog

Own your audience!

If you're cool enough to have your own blog, maybe you've built your website with a static website generator, such as Jekyll, please don't forget about exposing an RSS/Atom feed. Don't forget about us. If you expose a good RSS feed, you can then build an automated newsletter too 😉

Here's some cool stuff to get you going:

- [jekyll-feed](https://github.com/jekyll/jekyll-feed)
- [Mailchimp RSS to Email](https://mailchimp.com/features/rss-to-email/)

Enjoy 😎
