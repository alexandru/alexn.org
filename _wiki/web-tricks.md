---
date: 2020-10-29 12:48:21+0300
title: "Web Tricks"
---

## Detect the Brave Browser

```js
(navigator.brave && await navigator.brave.isBrave() || false)
```

Credit: <https://stackoverflow.com/a/60954062>
