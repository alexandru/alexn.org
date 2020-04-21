---
title: "Blog Updates"
date: 2020-04-21T10:00:00
tags:
  - Blogging
  - Personal
description:
  Status and updates.
---

<p class="intro withcap">
  I love writing. I write long emails, long chat texts, long code comments. Some of my rants are epic. Sometimes I'm amazed that my colleagues have the patience to read it all 🙂
</p>

Yet I've neglected my personal blog. This happens because [Twitter](https://twitter.com/alexelcu){:target="_blank"} fulfilled my needs for shitposting and for code I ended up creating snippets as [Gists](https://gist.github.com/alexandru){:target="_blank"}, many of which are private, meant for colleagues.

No more. I dusted off my blog and will commence a regular posting schedule.

<p class='info-bubble' markdown='1'>
  This blog is about programming, but take note that I don't do just functional programming, or just Scala. Today's article is about [imperative, Promise-driven JavaScript]({% link _posts/2020-04-21-javascript-semaphore.md %}).
</p>

## Website Yak Shaving

Like all professional software developers that want to write more, I started with yak shaving by updating my blog:

- Migrated from [Middleman](https://middlemanapp.com/){:rel="nofollow" target="_blank"} to [Jekyll](https://jekyllrb.com/){:rel="nofollow" target="_blank"} for generating my static website
- Changed the design from something homemade to modified [brianmaierjr/long-haul](https://github.com/brianmaierjr/long-haul){:rel="nofollow" target="_blank"}
- Disabled comments, replaced widget with an email address — if you want to talk with me about my articles, we can do so in private; design should be responsive on mobile phones
- Automatic thumbnails for Vimeo/YouTube videos, enabled for Twitter/Facebook cards; expect more videos soon
- Integration of [MathJax](https://www.mathjax.org/){:rel="nofollow" target="_blank"} for math formulas

In addition to the above:

- website is hosted by my own DigitalOcean VPS 
- cached via Cloudflare
- automatically built via GitHub Actions on pushes
- with a "web hook" handling the refresh on my VPS, via [github-webhook-listener](https://github.com/alexandru/github-webhook-listener), another massive yak shave 🙂

If you find anything broken, please let me know.
