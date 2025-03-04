---
date: 2022-12-04 12:01:00 +02:00
last_modified_at: 2025-03-04T18:18:43+02:00
---

# Bookmarklets

Samples are meant for the [bookmarklet generator]({% link assets/html/bookmarklet-generator.html %}){:target="_blank"}, that generates code compatible with Firefox for Android (as it has issues with the classic `window.open`, which has to be avoided). The code looks like this, and it's general purpose enough:

```javascript
javascript:(function() {
    var url = location.href;
    var title = document.title;
    var a = document.createElement('a');
    a.href = 'https://bsky.app/intent/compose?text=%s'
        .replace(/%s/g, encodeURIComponent(url))
        .replace(/%t/g, encodeURIComponent(title));
    a.target = '_blank';
    a.rel = 'noopener noreferrer';
    document.body.appendChild(a);
    a.click();
    setTimeout(function() {
        document.body.removeChild(a);
    }, 100);
})()
```

## Sharing

### Bluesky

URL (page URL and title):

```
https://bsky.app/intent/compose?text=%22%t%22%0A%0A%s
```

[👉 Generate bookmarklet]({% link assets/html/bookmarklet-generator.html %}?title=Share%2520on%2520Bluesky&url=https%253A%252F%252Fbsky.app%252Fintent%252Fcompose%253Ftext%253D%252522%2525t%252522%25250A%25250A%2525s){:target="_blank"}

### Mastodon

URL used (both page title and URL):

```
https://mastodon.social/share?text=%22%t%22%0A%0A%s
```

[👉 Generate bookmarklet]({% link assets/html/bookmarklet-generator.html %}?title=Share%2520on%2520Mastodon&url=https%253A%252F%252Fmastodon.social%252Fshare%253Ftext%253D%252522%2525t%252522%25250A%25250A%2525s){:target="_blank"}

### Reddit

URL (just page URL):

```
https://old.reddit.com/submit?url=%s
```

[👉 Generate bookmarklet]({% link assets/html/bookmarklet-generator.html %}?title=Share%2520on%2520Reddit&url=https%253A%252F%252Fold.reddit.com%252Fsubmit%253Furl%253D%2525s){:target="_blank"}

### LinkedIn

URL (just page URL):

```
https://www.linkedin.com/sharing/share-offsite/?url=%s
```

[👉 Generate bookmarklet]({% link assets/html/bookmarklet-generator.html %}?title=Share%2520on%2520LinkedIn&url=https%253A%252F%252Fwww.linkedin.com%252Fsharing%252Fshare-offsite%252F%253Furl%253D%2525s){:target="_blank"}

### Facebook

URL used (both page title and URL):

```
https://www.facebook.com/sharer.php?src=bm&v=4&i=1628766166&u=%s&t=%t
```

[👉 Generate bookmarklet]({% link assets/html/bookmarklet-generator.html %}?title=Share%2520on%2520Facebook&url=https%253A%252F%252Fwww.facebook.com%252Fsharer.php%253Fsrc%253Dbm%2526v%253D4%2526i%253D1628766166%2526u%253D%2525s%2526t%253D%2525t){:target="_blank"}

### 𝕏/Twitter

URL used (both page title and URL):

```
https://x.com/intent/tweet?text=%22%t%22%0A%0A%s
```

[👉 Generate bookmarklet]({% link assets/html/bookmarklet-generator.html %}?title=Share%2520on%2520%25F0%259D%2595%258F%252FTwitter&url=https%253A%252F%252Fx.com%252Fintent%252Ftweet%253Ftext%253D%252522%2525t%252522%25250A%25250A%2525s){:target="_blank"}

## Subscribing

### FreshRSS

URL:

```
https://my.freshrss.host/i/?c=feed&a=add&url_rss=%s
```

[👉 Generate bookmarklet]({% link assets/html/bookmarklet-generator.html %}?title=Subscribe%2520(FreshRSS)&url=https%253A%252F%252Fmy.freshrss.host%252Fi%252F%253Fc%253Dfeed%2526a%253Dadd%2526url_rss%253D%2525s){:target="_blank"}

### NewsBlur

URL:

```
https://www.newsblur.com/?url=%s
```

[👉 Generate bookmarklet]({% link assets/html/bookmarklet-generator.html %}?title=Subscribe%2520(NewsBlur)&url=https%253A%252F%252Fwww.newsblur.com%252F%253Furl%253D%2525s){:target="_blank"}
