---
title: "Unix shell (CLI)"
date: 2022-01-29 07:08:17 +02:00
last_modified_at: 2022-03-29 10:45:31 +03:00
---

Find zombie processes:

```sh
ps axo stat,ppid,pid,comm | grep -w defunct
```
