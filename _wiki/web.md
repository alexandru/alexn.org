---
date: 2020-10-29 12:48:21+0300
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

- <https://browserbench.org/>
  - <https://browserbench.org/Speedometer2.0/>
  - <https://browserbench.org/JetStream/>
  - <https://browserbench.org/MotionMark/>
- <https://krakenbenchmark.mozilla.org/>
- <https://www.wirple.com/bmark/>
- <https://web.basemark.com/>

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
