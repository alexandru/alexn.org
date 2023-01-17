---
title: "Cleanup Scala/Java project"
feed_guid: /snippets/2022/01/22/cleanup-scala-project/
redirect_from: 
  - /snippets/2022/01/22/cleanup-scala-project/
  - /snippets/2022/01/22/cleanup-scala-project.html
tags:
  - CLI
  - Scala
  - Shell
description: >
  Snippet for cleaning up a Scala project's directory of all compiled files.
last_modified_at: 2023-01-17 13:17:48 +02:00
---

```sh
#!/usr/bin/env bash
set -e

DIR_TO_CLEAN="$1"

if [ -z "$DIR_TO_CLEAN" ]; then
  echo "ERROR: path was not given!"
  exit 1
elif ! [[ -d "$DIR_TO_CLEAN" ]]; then
  echo "ERROR: path given is not a directory!"
  exit 2
fi

cd "$DIR_TO_CLEAN" || exit 1

# Deletes the project's "target" directories,
# except for stuff in ./project or in dot dirs (.bloop)
find . -name target -type d \
  -not \( -path './project*' -o -path './.*' \) \
  -print \
  -prune \
  -exec rm -rf "{}" \;

# Deletes all empty directories, except for stuff in dot dirs (.git)
find . -type d -empty \
  -not \( -path './.*' -o -path './project*' \) \
  -print \
  -prune \
  -exec rm -r "{}" \;
```
