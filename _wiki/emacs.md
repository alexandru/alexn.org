---
date: 2020-08-24 16:24:31+0300
last_modified_at: 2022-09-01 17:20:20 +03:00
---

# Emacs

## Installation

My preferred installation on macOS:

```sh
brew install emacs --cask
```

This installs:

```
App '/Applications/Emacs.app'.
Binary '/usr/local/bin/emacs'.
Binary '/usr/local/bin/ebrowse'.
Binary '/usr/local/bin/emacsclient'.
Binary '/usr/local/bin/etags'.
```

**GOTCHA:** make sure these are on the system path and have priority over the system's Emacs.

## Settings

```sh
git clone https://github.com/alexandru/emacs.d ~/.emacs.d
```

See [repo](https://github.com/alexandru/emacs.d).

## Emacs Server as MacOS Service

Create `~/Library/LaunchAgents/alex.emacs.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>KeepAlive</key>
    <true/>
    <key>Label</key>
    <string>alex.Emacs</string>
    <key>ProgramArguments</key>
    <array>
      <string>/usr/local/bin/emacs</string>
      <string>--fg-daemon</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>UserName</key>
    <string>replace_me_with_mac_username</string>
  </dict>
</plist>
```

The service can then be loaded via:

```sh
launchctl load -w ~/Library/LaunchAgents/alex.emacs.plist
```

Or unloaded via:

```sh
launchctl unload ~/Library/LaunchAgents/alex.emacs.plist
```

## Script for running EmacsClient

Placed in `~/bin/run-emacsclient`:

```bash
#!/usr/bin/env bash

if [ -z "$EMACSCLIENT_OPTS" ]; then
  EMACSCLIENT_OPTS="-nc"
fi

if [ $# -eq 0 ]; then
  COMMAND='/usr/local/bin/emacsclient '$EMACSCLIENT_OPTS' -e "(if (display-graphic-p) (x-focus-frame nil))"'
else
  COMMAND='/usr/local/bin/emacsclient '$EMACSCLIENT_OPTS' "$@"'
fi

if [ -z "$(shopt | grep login_shell)" ]; then
  echo "$COMMAND" | exec bash --login -s "$@"
else
  eval "exec $COMMAND"
fi
```

And a corresponding `~/bin/run-emacs-client-cli` to force the CLI mode in the terminal, instead of opening a buffer in some opened GUI window:

```bash
#!/usr/bin/env bash

export EMACSCLIENT_OPTS='-t'
exec run-emacsclient "$@"
```

## Bash/Zsh Settings

```bash
# Default zsh keybindings (emacs; might want to switch to vim later)
bindkey -e

# Adding Emacs to PATH
export PATH="$PATH:~/Applications/Emacs.app/Contents/MacOS/bin:/Applications/Emacs.app/Contents/MacOS/bin:~/Applications/Emacs.app/Contents/MacOS:/Applications/Emacs.app/Contents/MacOS"

# Default editor
export EDITOR="$HOME/bin/run-emacsclient-cli"
export VISUAL="$EDITOR"
export ALTERNATE_EDITOR="vim"

## Editor aliases
alias e="$HOME/bin/run-emacsclient-cli"
alias ew="$HOME/bin/run-emacsclient"
alias notes='$HOME/bin/run-emacsclient-cli -e "(deft)"'

emacs_open_buffer()
{
  run-emacsclient-cli -e "(let ((b (find-buffer-by-prefix \"$1\"))) nil)"
}
alias eb=emacs_open_buffer
```

## Troubleshooting

### Failed to verify signature

In my case Emacs was complaining that key `066DAFCB81E42C40` is missing.

I managed to solve it by running:

```sh
gpg --keyserver hkp://keys.gnupg.net --recv-keys 066DAFCB81E42C40
```

Afterwards starting Emacs from the command line might be a good idea.

### General unhappiness

```
brew uninstall emacs
```

Then download [VS Code](https://code.visualstudio.com/).

## Resources

- [The Emacs Lisp Style Guide](https://github.com/bbatsov/emacs-lisp-style-guide)
