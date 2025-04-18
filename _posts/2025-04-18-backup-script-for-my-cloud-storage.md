---
title: "Backup Script for My Cloud Storage"
image: /assets/media/articles/2025-backup-cloud.png
date: 2025-04-18T18:53:12+03:00
last_modified_at: 2025-04-18T19:59:58+03:00
tags:
  - Python
  - Self Hosting
  - Snippet
description: >-
  This is a script that I use for backing up my OneDrive to a Nextcloud instance.
---

I currently have around ~370 GB stored in OneDrive, including the family's photo archive that I'd rather not lose. It needs backups, and currently I don't have a home NAS. I used to just sync my files, via [rclone](https://rclone.org/) to Backblaze B2, which can keep [older versions of files](https://www.backblaze.com/docs/cloud-storage-file-versions).

Recently, I moved my backups to a [Hetzner's Storage Share](https://www.hetzner.com/storage/storage-share/), which is a managed [Nextcloud](https://nextcloud.com/) service — I prefer this because it's a reasonably priced EU service, and it's based on FOSS that I could self-host. But the problem is: **how to keep older versions of files?** This is important as backups are meant to prevent accidents, such as accidental deletions, or [data degradation](https://en.wikipedia.org/wiki/Data_degradation).

The trick is in using the `--backup-dir` option of `rclone sync` ([see documentation](https://rclone.org/docs/#backup-dir-dir)). This tells the `rclone` command to copy any files that have changed or were deleted in the specified directory.

Here's a script, built for my own needs, use with care (i.e., don't execute it if you don't understand what it does).

```python
#!/usr/bin/env python3

import argparse
import datetime
import os
import re
import subprocess
import sys

RSOURCE = "onedrive"
RDEST = "nextcloud"
SYNC_PARAMS = "--delete-excluded -c --track-renames --onedrive-hash-type sha1"

EXCLUDE_PATTERNS = [
    ".git",
    ".DS_Store",
    ".localized",
    "*.swp",
    ".#*",
]

def execute(command, verbose):
    if verbose:
        sys.stdout.write("--------------------------------------------------------------------------\n")
        sys.stdout.write(command + "\n")
        sys.stdout.write("--------------------------------------------------------------------------\n")
    r = os.system(command)
    if r != 0:
        sys.stderr.write(f"Command '{command}' failed with exit code {r}\n")
        sys.exit(r)

def execute_capture_output(command):
    r = subprocess.run(
        command,
        capture_output=True,
        text=True
    )
    if r.returncode != 0:
        sys.stderr.write(r.stderr)
        sys.stderr.write("\n")
        sys.exit(r.returncode)
    return r.stdout

def list_dirs(label):
    r = execute_capture_output(["rclone", "lsd", f"{label}:"])
    names = []
    for l in r.splitlines():
        parts = re.split(r'\s+', l, maxsplit=5)
        if parts[-1].startswith("."): continue
        names.append(parts[-1])
    return names

def main():
    parser = argparse.ArgumentParser(description='Backs up files to cloud storage.')
    parser.add_argument('-d', '--dry-run', action='store_true')
    parser.add_argument('-q', '--quiet', action='store_true')
    args = parser.parse_args()

    date = datetime.datetime.now().strftime("%Y-%m-%d.%H-%M-%S")
    extra_params = [item
        for list in [
            [f"--exclude \"{e}\"" for e in EXCLUDE_PATTERNS],
            ["--verbose"] if not args.quiet else ["-q"],
            ["--dry-run"] if args.dry_run else [],
        ]
        for item in list
    ]

    for dirname in list_dirs(RSOURCE):
        backup_dir = f"{RDEST}:Backups/OneDrive/{date}/{dirname}"
        execute(
            f"rclone sync \"{RSOURCE}:{dirname}\" \"{RDEST}:{dirname}\" {SYNC_PARAMS} \"--backup-dir={backup_dir}\" {" ".join(extra_params)}",
            not args.quiet
        )

if __name__ == "__main__":
    main()
```
