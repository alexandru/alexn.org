---
title: "Custom Zsh Prompt"
date: 2020-08-24 16:24:31 +03:00
last_modified_at: 2022-03-29 10:46:15 +03:00
---

References:
- [Moving to zsh, part 6 – Customizing the zsh Prompt](https://scriptingosx.com/2019/07/moving-to-zsh-06-customizing-the-zsh-prompt/)
- [256 COLORS - CHEAT SHEET](https://jonasjacek.github.io/colors/)
- [256 Terminal colors and their 24bit equivalent (or
  similar)](https://www.calmar.ws/vim/256-xterm-24bit-rgb-color-chart.html)

```sh
# ------------------------------------------------------------------------------
# Customize PROMPT
# ------------------------------------------------------------------------------

autoload -Uz vcs_info
precmd_vcs_info() {
  vcs_info
}
precmd_functions+=(precmd_vcs_info)
setopt prompt_subst

export PROMPT="%F{196}%B%(?..?%? )%b%f%F{117}%2~%f%F{245} %#%f "
export RPROMPT="%B\$vcs_info_msg_0_%f%b"

zstyle ':vcs_info:git:*' formats '%F{240}%b %f %F{237}%r%f'
zstyle ':vcs_info:*' enable git
```

In iTerm2 make sure to enable [Use built-in Powerline glyphs](https://www.iterm2.com/documentation-preferences-profiles-text.html).

How this looks:

![Screenshot of zsh prompt](assets/custom-zsh-prompt.png)
