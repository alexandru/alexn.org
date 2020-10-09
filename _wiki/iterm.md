---
date: 2020-08-24 16:24:31+0300
---

# iTerm2

Tips for [iTerm2](https://www.iterm2.com/){:target="_blank"}.

## Configure opening of file paths (semantic history)

In iTerm's settings, goto `Profiles` -> `Advanced` -> `Semantic
History`.

### Opening files in IntelliJ IDEA + Visual Studio Code

First create IntelliJ IDEA's command line launcher. Press `⇧ Shift + ⇧ Shift` (twice) to bring up the [Navigate -> Search Everywhere](https://www.jetbrains.com/help/idea/searching-everywhere.html#search_all){:target="_blank"} dialog. Then write "*create command-line launcher*" in the search box, to select the desired action, then press `⏎ Enter`:

![Screenshot of Search Everywhere dialog](./assets/intellij-idea-create-cmd-line-launcher.png)

Now `idea` is installed on the command line, on MacOS this is tipically in `/usr/local/bin/idea`.

Similarly, in [Visual Studio Code](https://code.visualstudio.com/){:target="_blank"} press `⌘ Cmd + P`, type "*install code command*", and press `⏎ Enter`:

![Screenshot of 'install code command' in VS Code](assets/vs-code-install-cmd-line.png)

The `idea` command line utility isn't compatible with iTerm's settings, plus if we want to discriminate based on file type, an extra script is needed. Save this in `$HOME/bin/iterm-goto`:

``` sh
#!/bin/sh

GOTO_FILE="$1"
GOTO_LINE="$2"
GOTO_CHAR="$3"

if ! [ -f "$GOTO_FILE" ]; then
    echo "ERROR: file path missing or invalid!" >&2
    exit 1
fi

# Discriminate based on file extension, open only .scala or .sbt files in IntelliJ IDEA ...
if [[ "$GOTO_FILE" =~ ^.*\.(scala|sbt)$ ]]; then
    EDITOR_PATH="$(which idea)"

    if [ -z "$IDEA_PATH" ]; then
        EDITOR_PATH="/usr/local/bin/idea"
    fi

    if ! [ -z "$GOTO_LINE" ]; then
        exec "$EDITOR_PATH" --line "$GOTO_LINE" "$GOTO_FILE"
    else
        exec "$EDITOR_PATH" "$GOTO_FILE"
    fi
else
    EDITOR_PATH="$(which code)"

    if [ -z "$EDITOR_PATH" ]; then
        EDITOR_PATH="/usr/local/bin/code"
    fi

    if ! [ -z "$GOTO_CHAR" ]; then
        exec "$EDITOR_PATH" --goto "$GOTO_FILE:$GOTO_LINE:$GOTO_CHAR"
    elif ! [ -z "$GOTO_LINE" ]; then
        exec "$EDITOR_PATH" --goto "$GOTO_FILE:$GOTO_LINE"
    else
        exec "$EDITOR_PATH" "$GOTO_FILE"
    fi
fi
```

Then in iTerm's settings, goto `Profiles` -> `Advanced` -> `Semantic
History`, and set `Run command ...` to:

``` sh
$HOME/bin/iterm-goto \1 \2
```

![Screenshot of iTerm's Semantic History setting](./assets/iterm-semantic-history-setting.png)
