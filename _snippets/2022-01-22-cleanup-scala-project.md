---
title: "Cleanup Scala/Java project"
date: 2022-01-22 11:16:00+0200
tags:
  - Bash
  - CLI
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
