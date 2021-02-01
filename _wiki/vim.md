---
date: 2020-11-04 13:57:32+0200
title: 'Vim'
---

## References

- [Quickref](./vim-quickref.txt)
- [Vim Tips for the Intermediate Vim User](https://jemma.dev/blog/intermediate-vim-tips)
  [(archive)](https://web.archive.org/web/20210201151013/https://jemma.dev/blog/intermediate-vim-tip)
- [VimGolf](https://www.vimgolf.com/)
  [(archive)](https://web.archive.org/web/20210201151233/https://www.vimgolf.com/)
- [Configuring .ideavimrc](https://medium.com/@danidiaz/configuring-ideavimrc-de16a4da0715) 
  [(archive)](https://web.archive.org/web/20210201151332/https://medium.com/@danidiaz/configuring-ideavimrc-de16a4da0715)
- [Vim surround plugin tutorial](http://www.futurile.net/2016/03/19/vim-surround-plugin-tutorial/)
  [(archive)](https://web.archive.org/web/20210201151440/http://www.futurile.net/2016/03/19/vim-surround-plugin-tutorial/)

## Shell setup

For Zsh:

```sh
set -o vi
```

For Bash:

```sh
bindkey -v
```

Indicating the editing mode via the prompt in Zsh:

```zsh
export BASE_RPROMPT="$RPROMPT"

zstyle ':vcs_info:git:*' formats '%F{240}%b %f %F{237}%r%f'
zstyle ':vcs_info:*' enable git

function zle-line-init zle-keymap-select {
    RPS1="%B%F{237}${${KEYMAP/vicmd/--NORMAL--}/(main|viins)/--INSERT--}%f%b $BASE_RPROMPT"
    RPS2="$RPS1"
    zle reset-prompt
}

zle -N zle-line-init
zle -N zle-keymap-select
```

## Fold / Unfold

- `zc`: fold
- `zo`: unfold
- `zM`: fold all
- `zR`: unfold all

## Surround text

Functionality from [vim-surround](https://github.com/tpope/vim-surround), which also works in VS Code (with VSCodeVim):

```
v                    # Enter visual mode
<visually select>    # Use the keyboard to select the section of text
S                    # Press upper case S
"                    # Specify what you want to surround the visual selection with
```

## Copy & Paste

Shortcuts:

- `d` is for cut, `y` is for copy, `p` or `P` are for paste

Normally one uses the clipboard register to cut, copy and paste, which is `*`. 
So `"*y` copies to the system clipboard, and `"*p` pastes from that clipboard.

To activate the system clipboard for copy and pasting with the "unnamed" register, add this to `.vimrc`:

```vimrc
set clipboard+=unnamed
```

## Articles and References

- [Vim Tips for the Intermediate Vim User](https://jemma.dev/blog/intermediate-vim-tips)
- [VimGolf](https://www.vimgolf.com/)
- [Configuring .ideavimrc](https://medium.com/@danidiaz/configuring-ideavimrc-de16a4da0715)
- [Vim surround plugin tutorial](http://www.futurile.net/2016/03/19/vim-surround-plugin-tutorial/)