---
date: 2020-08-24 16:24:31 +03:00
last_modified_at: 2022-09-01 17:25:10 +03:00
---

# RSS / Atom feeds

## Readers

Web:

- [Feedly](https://feedly.com/) (web)
- [FreshRSS](https://freshrss.org/) (web, open source, self-hosted)
- [Miniflux](https://github.com/miniflux/miniflux) (web, open-source, self-hosted)
- [Newsblur](https://newsblur.com) (web, open source)

Native, MacOS:

- [Reeder](https://reederapp.com/)
- [NetNewsWire](https://ranchero.com/netnewswire/) (open source)

Native, Linux:

- [NewsFlash](https://gitlab.com/news-flash/news_flash_gtk)

Native, Android:

- [FeedMe](https://play.google.com/store/apps/details?id=com.seazon.feedme&hl=en_US&gl=US)
- [Fluent Reader Lite](https://play.google.com/store/apps/details?id=me.hyliu.fluent_reader_lite&hl=en_US&gl=US)

### Recommendation: Newsblur

[Newsblur](https://newsblur.com) is probably the best:

- Mobile client included for Android/iOS, OK for tablets, readable, auto Dark Mode, good integration
- Organizing with multiple categories per feed
- Newsletters forwarding support
- Filtering via "infrequent articles" and training
- Easy to migrate away

### Self-hosted recommendation: FreshRSS

[FreshRSS](https://freshrss.org/) is the best for self-hosting:

- Very easy to install and manage via Docker
- Responsive web design, can work on mobile without client
- Exposes the Fever and the GReader APIs out of the box, compatible with Reeder and other clients

Annoyances:

- Feeds can't belong to multiple categories, making organization hard
- Filtering support for dealing with noise is only rudimentary
- Couldn't find any Android clients that I liked (FeedMe is close)

## Resources

- [Mailchimp RSS to Email](https://mailchimp.com/features/rss-to-email/)
- [jekyll-feed](https://github.com/jekyll/jekyll-feed)
