---
date: 2022-01-29 07:08:17 +02:00
last_modified_at: 2023-02-01 10:15:45 +02:00
---

# Unix shell (CLI)

## Find zombie processes:

```sh
ps axo stat,ppid,pid,comm | grep -w defunct
```

## Measure memory

Useful project:
<https://github.com/astrofrog/psrecord>

```sh
psrecord \
    --duration 30 \
    --interval 2 \
    --include-children \
    --plot /tmp/plot.png \
    <pid>
```
