---
date: 2020-08-24 16:24:31+0300
title: "GNU Screen"
---

[Documentation](https://www.gnu.org/software/screen/manual/screen.html)

## Cheatsheet

Start a new session:

```bash
screen
```

Start a new named session:

```bash
screen -S <name>
```

List sessions:

```bash
screen -ls
```

Re-attach sesion:

```bash
screen -r <name>
```

Main commands:

- Shortcuts menu: `Ctrl-a ?`
- Command mode: `Ctrl-a :`
- Detach session: `Ctrl-a d`

Window management:

- Create a new window: `Ctrl-a c`
- Kill current window: `Ctrl-a k`
- Next window: `Ctrl-a n`
- Prev window: `Ctrl-a p`
- Jump to window: `Ctrl-a 0-9`
- Split vertical: `Ctrl-a |`
- Split horizontal: `Ctrl-a S`
- Focus next region: `Ctrl-a ^`
- Quit split screen mode: `Ctrl-a Q`

## Custom .screenrc

```
shell -$SHELL

# Buffer size
defscrollback 50000

# Allow bold colors - necessary for some reason
attrcolor b ".I"

# Tell screen how to set colors. AB = background, AF=foreground
termcapinfo xterm 'Co#256:AB=\E[48;5;%dm:AF=\E[38;5;%dm'

# Erase background with current bg color
defbce "on"

# Enable 256 color term
term xterm-256color

# Very nice tabbed colored hardstatus line
hardstatus string '%{= Kd} %{= Kd}%-w%{= Kr}[%{= KW}%n %t%{= Kr}]%{= Kd}%+w %-= %{KG} %H%{KW}|%{KY}%101`%{KW}|%D %M %d %Y%{= Kc} %C%A%{-}'

#
## Control-^ (usually Control-Shift-6) is traditional and the only key not used by emacs
escape ^^^^
#
## do not trash BackSpace, usually DEL
bindkey -k kb
bindkey -d -k kb
#
## do not trash Delete, usually ESC [ 3 ~
bindkey -k kD
bindkey -d -k kD
  
# Hide hardstatus: ctrl-a f 
bind f eval "hardstatus ignore"
# Show hardstatus: ctrl-a F
bind F eval "hardstatus alwayslastline"
```
