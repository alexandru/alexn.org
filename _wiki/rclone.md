---
date: 2023-01-23 13:34:49 +02:00
last_modified_at: 2023-01-26 09:54:05 +02:00
---

# RClone

## Install (macOS)

This is required for getting `mount` to work properly, see:

- [Issue #5373](https://github.com/rclone/rclone/issues/5373)
- [gromgit/homebrew-fuse](https://github.com/gromgit/homebrew-fuse)

Run:

```sh
brew install --cask macfuse

brew install gromgit/fuse/rclone-mac
```

## Mount (OneDrive)

```sh
#!/usr/bin/env bash

LOG_PATH="$HOME/Library/Logs/rclone-onedrive-mirror.log"
MOUNT_DIR="$HOME/Library/CloudStorage/OneDrive"
mkdir -p "$MOUNT_DIR"

/usr/local/opt/rclone-mac/libexec/rclone/rclone mount \
    onedrive: "$MOUNT_DIR" \
    --volname "OneDrive" \
    --buffer-size 64M \
    --vfs-read-ahead 512M \
    --vfs-cache-mode full \
    --vfs-cache-max-age 8760h \
    --vfs-cache-max-size 100G \
    --vfs-cache-poll-interval 30s \
    --vfs-write-back 5s \
    --attr-timeout 8700h \
    --dir-cache-time 8760h \
    --poll-interval 30s \
    --log-level INFO \
    --log-file "$LOG_PATH"
    # Optional:
    # --rc \
    # --rc-web-gui \
    # --rc-web-gui-no-open-browser \
    # --rc-htpasswd "$HOME/.config/rclone/htpasswd"

# Optionally, inform the user when the process stops.
# Requires: brew install terminal-notifier
PROC_EXIT_CODE="$?"
terminal-notifier -title "OneDrive mount stopped!" -message "$LOG_PATH"
exit $PROC_EXIT_CODE
```

Notes:
- Web interface is served at <http://127.0.0.1:5572/>, see: [Remote controlling rclone with its API](https://rclone.org/rc/);
- For the cache options used, see: [VFS File Caching](https://rclone.org/commands/rclone_mount/#vfs-file-caching);

For serving the remote control web UI, you need credentials:

```sh
touch ~/.config/rclone/htpasswd
htpasswd -B ~/.config/rclone/htpasswd alex
```

### macOS service

The above command supports a `--daemon` option, but I'd like automatic launch at startup, maybe even restarts.
Create a script in `~/bin/mount-onedrive`:

Create `~/Library/LaunchAgents/my.rclone-onedrive-mount.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>KeepAlive</key>
    <true/>
    <key>Label</key>
    <string>my.rclone-onedrive-mount</string>
    <key>ProgramArguments</key>
    <array>
      <string>/Users/myname/bin/mount-onedrive</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>UserName</key>
    <string>myname</string>
  </dict>
</plist>
```

The service can then be loaded via:

```sh
launchctl load -w ~/Library/LaunchAgents/my.rclone-onedrive-mount.plist
```

Or unloaded via:

```sh
launchctl unload ~/Library/LaunchAgents/my.rclone-onedrive-mount.plist
```

## Bisync

Alternatively there's a [bisync](https://rclone.org/bisync/) command.

On first run, the database needs to be initialized, via `--resync`, but as a warning, this can override the files of "path2" with those of "path1".

This is the `onedrive-sync-init` script:

```sh
#!/usr/bin/env bash

function notifyIfError() {
    PROC_EXIT_CODE="$1"
    if [ "$PROC_EXIT_CODE" -ne 0 ]; then
        terminal-notifier -title "OneDrive sync failed!" -message "Check the logs"
        echo "OneDrive sync failed"
        exit "$PROC_EXIT_CODE"
    fi
}

mkdir -p ~/OneDrive/Bisync
mkdir -p ~/OneDrive/.db

rclone bisync onedrive: ~/OneDrive/Bisync \
    --resync \
    --filters-file ~/.config/rclone/onedrive-filter.conf \
    --workdir ~/OneDrive/.db \
    -v "$@"
notifyIfError "$?"

# Adds .rclone-check files in the top sub-directories
find ~/OneDrive/Bisync -type d -d 1 -exec touch "{}/.rclone-check" \;
notifyIfError "$?"

# Syncs those .rclone-check files
rclone bisync onedrive: ~/OneDrive/Bisync \
    --filters-file ~/.config/rclone/onedrive-filter.conf \
    --workdir ~/OneDrive/.db \
    -v "$@"
notifyIfError "$?"
```

This is the `onedrive-sync-periodic` script, which could be installed in crontab:

```sh
#!/usr/bin/env bash

rclone bisync onedrive: ~/OneDrive/Bisync \
    --check-access \
    --check-filename ".rclone-check" \
    --filters-file ~/.config/rclone/onedrive-filter.conf \
    --workdir ~/OneDrive/.db \
    -v "$@"

PROC_EXIT_CODE="$1"
if [ "$PROC_EXIT_CODE" -ne 0 ]; then
    terminal-notifier -title "OneDrive sync failed!" -message "Check the logs"
    echo "OneDrive sync failed"
    exit "$PROC_EXIT_CODE"
fi
```

And then there's the `~/.config/rclone/onedrive-filter.conf` file, which dictates what to sync (aka selective sync):

```conf
- **/.DS_Store
- **/.localized
- **/*.swp

+ /Documents/**
+ /Scanned/**
+ /Screenshots/**

# Exclude everything by default
- **
```
