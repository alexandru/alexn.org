---
date: 2020-08-24 16:24:31+0300
title: "Web Apps"
---

## Progressive Web Apps (PWAs)

- <https://web.dev/progressive-web-apps/>
- <https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps>

## Make desktop apps

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

