---
date: 2020-09-15 21:48:09+0300
title: "Image Formats"
---

## Convert HEIC to JPEG in a directory

``` sh
#!/usr/bin/env bash

set -e
shopt -s nocaseglob

echo "Converting directory: $1"
cd "$1" || exit 1

convert()
{
    local source="$1"
    local dest="${source//.HEIC/.jpeg}"
    dest="${dest//.heic/.jpeg}"
    sips -s format jpeg "$source" --out "$dest"
}

find . -iname "*.heic" | while read file; do convert "$file"; done
```

## Converting to AVIF/WebP/Other

Use: [squoosh/cli](https://github.com/GoogleChromeLabs/squoosh/tree/dev/cli)
