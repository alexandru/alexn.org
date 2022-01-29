---
date: 2022-01-29 07:08:17+0200
title: "Unix shell (CLI)"
---

Find zombie processes:

```sh
ps axo stat,ppid,pid,comm | grep -w defunct
```
