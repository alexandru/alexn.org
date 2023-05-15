---
date: 2022-01-29 07:08:17 +02:00
last_modified_at: 2023-05-15 08:25:09 +03:00
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

## Load/unload environment variables based on directory

<https://github.com/direnv/direnv>

```sh
brew install direnv
```

For integrating with `zsh`, add in `~/.zshrc`:

```sh
eval "$(direnv hook zsh)"
```
