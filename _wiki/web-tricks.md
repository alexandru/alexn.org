---
date: 2020-10-29 12:48:21+0300
title: "Web"
---

## Browser benchmarks

- <https://browserbench.org/>
  - <https://browserbench.org/Speedometer2.0/>
  - <https://browserbench.org/JetStream/>
  - <https://browserbench.org/MotionMark/>
- <https://krakenbenchmark.mozilla.org/>
- <https://www.wirple.com/bmark/>
- <https://web.basemark.com/>

## JavaScript Tricks

### Detect the Brave Browser

```js
(navigator.brave && await navigator.brave.isBrave() || false)
```

Credit: <https://stackoverflow.com/a/60954062>
