---
date: 2020-11-30 17:38:13+0300
title: "Web"
---

## Client Tricks

### Detect the Brave Browser

```js
(navigator.brave && await navigator.brave.isBrave() || false)
```

Credit: <https://stackoverflow.com/a/60954062>

### Detect Dark Mode

From JavaScript:

```js
"matchMedia" in window && 
window.matchMedia('(prefers-color-scheme: dark)').matches
```

From CSS:

```css
@media (prefers-color-scheme: dark) {
    /* ... */
}
```

### Detect Dark Reader (browser extension)

For detecting the [Dark Reader](https://darkreader.org/) browser extension:

```js
"querySelector" in document &&
!!document.querySelector("meta[name=darkreader]")
```

## Browser benchmarks

Performance:

- <https://browserbench.org/>
  - <https://browserbench.org/Speedometer2.0/>
  - <https://browserbench.org/JetStream/>
  - <https://browserbench.org/MotionMark/>
- <https://krakenbenchmark.mozilla.org/>
- <https://www.wirple.com/bmark/>
- <https://web.basemark.com/>

Features:

- <https://tomayac.github.io/pwa-feature-detector/>

### For testing ads-blocking

<p class="warn-bubble" markdown="1">
  **WARN:** some of these websites may distribute [malvertising](https://en.wikipedia.org/wiki/Malvertising), pirated or NSFW content. Load at your own risk!
</p>

- [adblock-tester.com](https://adblock-tester.com/){:target="_blank",rel="nofollow"}
- [coveryourtracks.eff.org](https://coveryourtracks.eff.org/){:target="_blank",rel="nofollow"}
- [google.com](https://www.google.com/search?q=vpn){:target="_blank",rel="nofollow"}
  - Features first-party ads, blockable via generic cosmetic rules in uBlock Origin
- [youtube.com](https://www.youtube.com/results?search_query=vpn){:target="_blank",rel="nofollow"}
  - [video sample](https://www.youtube.com/watch?v=xGjGQ24cXAY){:target="_blank",rel="nofollow"}
  - Features first-party ads
- [bild.de](https://www.bild.de/){:target="_blank",rel="nofollow"}
  - Features anti-ad-blocking tech
- [nytimes.com](https://www.nytimes.com/){:target="_blank",rel="nofollow"}
  - Features annoying cookies / trackers banner
- [forbes.com](https://www.forbes.com/){:target="_blank",rel="nofollow"}
  - Features annoying cookies / trackers dialog, and huge ad banners
- [businessinsider.com](https://www.businessinsider.com/us-fda-approve-pfizer-vaccine-biontech-covid-uk-mhra-2020-12){:target="_blank",rel="nofollow"}
  - Trackers/cookies dialog, notification spam
- [g4media.ro](https://www.g4media.ro/){:target="_blank",rel="nofollow"}
  - Trackers/cookie dialog, notification spam, Google ads
- [technoreels.com](https://techoreels.com/4920/s4/){:target="_blank",rel="nofollow"}
  - WARN: malvertising, intrusive ads, anti-ad-blocking tech (kicking in after several seconds)
- [lookmovie.io](https://lookmovie.io/shows/view/2382108-see-dad-run-2012#S3-E8-88337){:target="_blank",rel="nofollow"}
  - WARN: pirated content, illegal software; anti-ad-blocking tech
- [lostmediawiki.com](https://forums.lostmediawiki.com/thread/5336/dark-forums-theme-available){:target="_blank",rel="nofollow"}
  - Anti-ad-blocking tech
- [multics.eu](https://multics.eu/){:target="_blank",rel="nofollow"}
  - Anti-ad-blocking tech

## Progressive Web Apps (PWAs)

- <https://web.dev/progressive-web-apps/>
- <https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps>

### Wrap web pages as desktop apps

Using: <https://github.com/jiahaog/nativefier>

```
nativefier \
    --maximize \
    -u "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:76.0) Gecko/20100101 Firefox/76.0" \
    --internal-urls ".*.google.com.*" \
    --name "YouTube Music" \
    "https://music.youtube.com/"
```

```
nativefier \
    -u "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:76.0) Gecko/20100101 Firefox/76.0" \
    --maximize \
    --counter \
    --name "Twitter" \
    "https://twitter.com"
```

```
nativefier \
    -u "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:76.0) Gecko/20100101 Firefox/76.0" \
    --maximize \
    --counter \
    --name "Gitter" \
    "https://gitter.im"
```

## Browser comparisons

Chrome vs Firefox:

- [Firefox and Chromium Security (2020)](https://madaidans-insecurities.github.io/firefox-chromium.html) ([archive](https://web.archive.org/web/20210105142528/https://madaidans-insecurities.github.io/firefox-chromium.html))
