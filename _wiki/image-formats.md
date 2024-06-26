---
date: 2020-09-15 21:48:09 +03:00
last_modified_at: 2022-09-01 17:23:07 +03:00
---

# Image Formats

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
