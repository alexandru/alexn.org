---
redirect_from:
  - /wiki/web-tricks.html
  - /wiki/web-apps.html
date: 2020-11-30 17:38:13 +03:00
last_modified_at: 2023-01-20 09:07:39 +02:00
---

# Web

## Browser benchmarks

Performance:

- [browserbench.org](https://browserbench.org){:target="_blank"}
  - [Speedometer2.0](https://browserbench.org/Speedometer2.0/){:target="_blank"}
  - [JetStream](https://browserbench.org/JetStream/){:target="_blank"}
  - [MotionMark](https://browserbench.org/MotionMark){:target="_blank"}
- [BMark (HTML5 3D benchmark)](https://www.wirple.com/bmark/){:target="_blank"}
- [Basemark Web](https://web.basemark.com/){:target="_blank"}
- [UFO test (for framerate)](https://www.testufo.com/){:target="_blank"}

Features:

- [PWA feature detector](https://tomayac.github.io/pwa-feature-detector){:target="_blank"}
- [Web Notifications Test](https://www.bennish.net/web-notifications.html){:target="_blank"}

### For testing tracking & ads blocking

- [PrivacyTests](https://privacytests.org/){:target="_blank"}
- <https://adblock-tester.com/>{:target="_blank"}
- <https://coveryourtracks.eff.org/>{:target="_blank"}
- <https://d3ward.github.io/toolz/adblock.html>{:target="_blank"}
- <https://blockads.fivefilters.org/>{:target="_blank"}

## Block lists

For getting rid of cookie banners and other annoyances:

- [I don't care about cookies](https://www.i-dont-care-about-cookies.eu/abp/){:target="_blank"}
- [Adguard Annoyances](https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_14_Annoyances/filter.txt){:target="_blank"}

Personal:

- [my-hosting](/assets/misc/block-lists/my-hosting.txt)
- [no-news](/assets/misc/block-lists/no-news.txt)
- [no-social](/assets/misc/block-lists/no-social.txt)
- [no-comments](/assets/misc/block-lists/no-comments.txt)

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

- [Firefox and Chromium Security (2020)](https://madaidans-insecurities.github.io/firefox-chromium.html) ([archive](https://web.archive.org/web/20210105142528/https://madaidans-insecurities.github.io/firefox-chromium.html))
- [Brave vs Firefox](https://itsfoss.com/brave-vs-firefox/)

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

