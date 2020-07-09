# Custom Zsh Prompt

```sh
# ------------------------------------------------------------------------------
# Customize PROMPT
#
# https://scriptingosx.com/2019/07/moving-to-zsh-06-customizing-the-zsh-prompt/
# https://jonasjacek.github.io/colors/
# https://www.calmar.ws/vim/256-xterm-24bit-rgb-color-chart.html
#
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
