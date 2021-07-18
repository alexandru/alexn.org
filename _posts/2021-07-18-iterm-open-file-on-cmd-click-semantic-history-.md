---
title: "Combining the terminal (iTerm) with the IDE"
date: 2021-07-18 15:23:50+0300
image: /assets/media/articles/iterm-semantic-history-demo.png
image_hide_in_post: true
tags:
  - macOS
  - Scala
description: "`⌘+Click` on a file path triggers my terminal to open that file inside my IDE, and that helps a lot."
---

`⌘+Click` on a file path triggers my terminal to open that file inside my IDE, and that helps a lot:

<figure>
  <img src="{% link assets/media/articles/iterm-semantic-history-demo.gif %}" alt="" />
  <figcaption>Demo of iTerm's semantic history</figcaption>
</figure>

I'm a terminal-first, IDE-second guy. Whatever I can get quickly done in the terminal, I do in the terminal.

When doing software development, if you compile and test the code in the terminal, going back and forth between the terminal and your IDE has friction. A lot of people just open a terminal from within their IDE, but personally I don't like that, I think the terminal with the build tool should run separately from the IDE, because you then have the flexibility to restart them independently, or switch IDEs when in the mood.

I'm using [iTerm](https://iterm2.com/), the macOS terminal emulator. And I do a lot of [Scala](https://scala-lang.org/) programming, spending a lot of time in [sbt](https://www.scala-sbt.org/), its build tool, for compiling at testing the project. As IDEs I use [IntelliJ IDEA](https://www.jetbrains.com/idea/) or [VS Code](https://code.visualstudio.com/) + [Metals](https://scalameta.org/metals/) interchangeably.


iTerm can be configured to open files in your editor or IDE of choice via its [Semantic History](https://iterm2.com/documentation-preferences-profiles-advanced.html) feature. My difficulty is that I want to use two IDEs, not just one. IntelliJ IDEA is very heavy, and I want files opened in it only when it's running. Another problem is that IntelliJ requires a problematic command parameter if you want to specify the line number. So here's how to workaround that ...

Create a file in `~/bin/iterm-goto` and copy/paste this script:


```bash
#!/usr/bin/env bash

GOTO_FILE="$1"
GOTO_LINE="$2"
GOTO_CHAR="$3"

if ! [ -f "$GOTO_FILE" ]; then
    echo "ERROR: file path missing or invalid!" >&2
    exit 1
fi

pgrep -x "idea" > /dev/null
IDEA_RUNNING=$?


if [[ "$GOTO_FILE" =~ ^.*\.(scala|sbt)$ ]] && [ $IDEA_RUNNING -eq 0 ]; then
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

Make sure to make it executable:

```sh
chmod +x ~/bin/iterm-goto
```

Then configure iTerm by:

1. Open its settings (`Cmd+,`)
2. Go into `Profiles > Advanced > Semantic History`
3. Select `Run command...`
4. Copy/paste: `$HOME/bin/iterm-goto \1 \2`

It should look like this:

<figure>
  <img src="{% link assets/media/articles/iterm-semantic-history.png %}" alt="" />
  <figcaption>
    Picture showing iTerm's Semantic History setting.
  </figcaption>
</figure>

Enjoy~
