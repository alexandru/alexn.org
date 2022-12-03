---
date: 2022-11-22 11:55:19 +02:00
last_modified_at: 2022-11-22 16:52:15 +02:00
---

# Mastodon

## Twitter migration

<p class="warn-bubble" markdown="1">
**WARN:** Mastodon ain't Twitter. Its design and available features are slightly different, as a matter of philosophy.
</p>

### Instances

Mastodon is "federated". At [joinmastodon.org](https://joinmastodon.org/) you can find a list of instances available, but it's not complete.

It's a good idea to prefer alternatives to [mastodon.social](https://mastodon.social), because this server is being hammered by new traffic. On the other hand, instances are servers maintained by volunteers, so it's best to find some properly maintained ones.

For professionals in the software industry, these instances seem to be pretty good:

- [fosstodon.org](https://fosstodon.org/) (English-only)
- [hachyderm.io](https://hachyderm.io/)

Some smaller instances you might want to consider:

- [functional.cafe](https://functional.cafe/)
- [indieweb.social](https://indieweb.social/)
- [types.pl](https://types.pl)

### Getting started resources

- [How To Use Mastodon and the Fediverse: Basic Tips](https://fedi.tips/how-to-use-mastodon-and-the-fediverse-basic-tips/);
- [Quick-start guide](https://blog.joinmastodon.org/2018/08/mastodon-quick-start-guide/);
- [An Increasingly Less-Brief Guide to Mastodon](https://github.com/joyeusenoelle/GuideToMastodon/);

### Available apps

- The website works well on mobile too;
- On Android, the official app isn't very good for now, prefer [Tusky](https://play.google.com/store/apps/details?id=com.keylesspalace.tusky&pli=1);
- See list of [available apps](https://joinmastodon.org/apps);

### Utilities

Browser extension that redirects you from Mastodon4 instances to your home instance (makes it easier to follow people):<br>
[mastodon4-redirect](https://github.com/raikasdev/mastodon4-redirect) ([Firefox](https://addons.mozilla.org/en-US/firefox/addon/mastodon4-redirect/){:target="_blank"}, [Chrome](https://chrome.google.com/webstore/detail/mastodon4-redirect/acbfckpoogjdigldffcbldijhgnjpfnc){:target="_blank"}).

To find your Twitter friends on Mastodon: <br>
<https://fedifinder.glitch.me>

For the cool factor, implement "WebFinger" on your own domain: <br>
<https://rossabaker.com/projects/webfinger/>

For following Twitter's drama, without logging into Twitter: <br>
<https://twitterisgoinggreat.com>

### Download Twitter archive

Download your Twitter archive and store it somewhere safe, even if you don't plan on leaving Twitter: <br>
<https://twitter.com/settings/download_your_data>

The archive download is fairly usable. But you might want to parse your archive, to replace `t.co` links and spit out markdown files:

- [Converting Your Twitter Archive to Markdown](https://matthiasott.com/notes/converting-your-twitter-archive-to-markdown)
- [twitter-archive-parser (GitHub)](https://github.com/timhutton/twitter-archive-parser)

### Leaving Twitter?

First download your Twitter archive and store it somewhere safe: <br>
<https://twitter.com/settings/download_your_data>

If you'd like to delete your Twitter account, depending on how popular your account is, you might want to avoid deleting it, to prevent impersonation/cybersquatting. I recommend to:

1. Download your Twitter archive;
2. Delete all your tweets: <https://tweetdelete.net>
3. Modify your profile to inform your visitors that you moved;
4. Maybe also lock your account, to prevent new followers;
