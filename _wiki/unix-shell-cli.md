---
date: 2022-01-29 07:08:17 +02:00
last_modified_at: 2022-09-01 17:26:09 +03:00
---

# Unix shell (CLI)

## Find zombie processes:

```sh
ps axo stat,ppid,pid,comm | grep -w defunct
```
