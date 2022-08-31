---
title: 'Vim'
date: 2020-11-04 13:57:32 +02:00
last_modified_at: 2022-08-31 14:03:14 +0300
---

## Docs & Articles

Important:

- [Quick Reference](./vim-quickref.txt)
- [Vim Cheatsheet](https://vim.rtorr.com/) ([archive](https://web.archive.org/web/20210201154856/https://vim.rtorr.com/)) / [Github Repo](https://github.com/rtorr/vim-cheat-sheet) ([archive](https://web.archive.org/web/20210201155116/https://github.com/rtorr/vim-cheat-sheet))
- [Vim Graphical Cheatsheet](http://www.viemu.com/vi-vim-cheat-sheet.gif) ([archive](https://web.archive.org/web/20210201160106/http://www.viemu.com/vi-vim-cheat-sheet.gif))

Other:

- [Use Vim macros to automate frequent tasks](https://www.redhat.com/sysadmin/use-vim-macros)
- [Configuring .ideavimrc](https://medium.com/@danidiaz/configuring-ideavimrc-de16a4da0715) ([archive](https://web.archive.org/web/20210201132546/https://medium.com/@danidiaz/configuring-ideavimrc-de16a4da0715))
- [Everyone Who Tried to Convince Me to use Vim was Wrong](https://yehudakatz.com/2010/07/29/everyone-who-tried-to-convince-me-to-use-vim-was-wrong/) ([archive](https://web.archive.org/web/20210201154621/https://yehudakatz.com/2010/07/29/everyone-who-tried-to-convince-me-to-use-vim-was-wrong/))
- [Seven habits of effective text editing](https://www.moolenaar.net/habits.html) ([archive](https://web.archive.org/web/20210201155823/https://www.moolenaar.net/habits.html))
- [Vim - precision editing at the speed of thought (Vimeo.com video)](https://vimeo.com/53144573)
- [Vim Adventures (game)](https://vim-adventures.com/)
- [Vim content by Alvin Alexander](https://alvinalexander.com/taxonomy/term/3013/) ([archive](https://web.archive.org/web/20210201155458/https://alvinalexander.com/taxonomy/term/3013/))
- [Vim Tips for the Intermediate Vim User](https://jemma.dev/blog/intermediate-vim-tips) ([archive](https://web.archive.org/web/20210201151013/https://jemma.dev/blog/intermediate-vim-tips))
- [VimGolf](https://www.vimgolf.com/) ([archive](https://web.archive.org/web/20210201151233/https://www.vimgolf.com/))

## Setup

### Installing the Python provider

Some plugins require the Python provider to be available. This can be checked
with the following vim command:

```vim
:checkhealth provider
```

This requires the [pynvim](https://github.com/neovim/pynvim) Python package.
It's best if the setup uses `virtualenv`. On macOS prefer to use `pyenv`:

```sh
brew install pyenv pyenv-virtualenv
```

This needs the following initialization code in `~/.zshrc`:

```sh
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
```

Then, install a Python 3 version:

```sh
pyenv install 3.10.6
```

Create a new virtualenv:

```sh
pyenv virtualenv 3.10.6 neovim
```

Activate it temporarily in your shell session:

```sh
pyenv activate neovim
```

Install the required Python package:

```sh
pip install pynvim
```

Then add this to `~/.config/nvim/init.vim`:

```vim
let g:python3_host_prog=expand('~/.pyenv/versions/neovim/bin/python')
```

## Random tips

### Documentation

- `:help`
- `:help g`
- `:help motion.txt`
- `:help spell.txt`
- `:help user-manual`
- `:help visual.txt`

### Surround text

Functionality from [vim-surround](https://github.com/tpope/vim-surround), which also works in VS Code (with VSCodeVim):

```
v                    # Enter visual mode
<visually select>    # Use the keyboard to select the section of text
s                    # Press upper case S
"                    # Specify what you want to surround the visual selection with
```

### Visual-block mode

This works like (and implemented with) multi-cursors in other editors (see [VS Code](https://code.visualstudio.com/docs/editor/codebasics#_multiple-selections-multicursor) ([archive](https://web.archive.org/web/20210201153540/https://code.visualstudio.com/docs/editor/codebasics#_multiple-selections-multicursor))).

- `Ctrl-v` to enter visual-block mode
  - Select block
- `I` (capital letter) to enter insert mode
- `<Esc>` to exit insert mode

### Copy & Paste

Shortcuts:

- `d` is for cut, `y` is for copy, `p` or `P` are for paste

Normally one uses the clipboard register to cut, copy and paste, which is `*`. 
So `"*y` copies to the system clipboard, and `"*p` pastes from that clipboard.

To activate the system clipboard for copy and pasting with the "unnamed" register, add this to `.vimrc`:

```
set clipboard+=unnamed
```

### Fold / Unfold

- `zc`: fold
- `zo`: unfold
- `zM`: fold all
- `zR`: unfold all

### Go to ...

- `gd`: go to definition
- `gx`: open link
- `Ctrl+O`: jump back to last position

### Vimdiff

- `do`: Get changes from other window into the current window
- `dp`: Put the changes from current window into the other window.
- `]c`: Jump to the next change.
- `[c`: Jump to the previous change.
- `Ctrl W + Ctrl W`: Switch to the other split window.

### Record macros

- to record macros: `q<register><commands>q`
  - pressing `qa` starts recording in register `a`
  - pressing `q` again stops recording
- to view recorded macros: `:reg`
- to play the macro once: `@<register>`
  - `@a` plays the macro in register `a`
- to repeat the macro execution: `@@`
