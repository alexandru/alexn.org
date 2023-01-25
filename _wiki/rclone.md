---
date: 2023-01-23 13:34:49 +02:00
last_modified_at: 2023-01-23 15:56:29 +02:00
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
rclone mount onedrive: ~/OneDrive \
    --volname "OneDrive" \
    --vfs-cache-mode full \
    --vfs-cache-max-age 168h0m0s \
    --vfs-cache-max-size 100G \
    --vfs-cache-poll-interval 30s \
    --log-level INFO \
    --log-file ~/Library/Logs/onedrive.log
    #--rc \
    #--rc-web-gui \
    #--rc-web-gui-no-open-browser \
    #--rc-htpasswd ~/.config/rclone/htpasswd
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

Create a script in `~/bin/mount-onedrive`:

```sh
#!/bin/sh

exec /usr/local/opt/rclone-mac/libexec/rclone/rclone mount \
    onedrive: /Users/wp79lh/OneDrive \
    --volname "OneDrive" \
    --vfs-cache-mode full \
    --vfs-cache-max-age 168h0m0s \
    --vfs-cache-max-size 100G \
    --vfs-cache-poll-interval 30s \
    --log-level INFO \
    --log-file /Users/wp79lh/Library/Logs/onedrive.log \
    --rc \
    --rc-web-gui \
    --rc-web-gui-no-open-browser \
    --rc-htpasswd /Users/wp79lh/.config/rclone/htpasswd
```

Make it executable:

```sh
chmod +x ~/bin/mount-onedrive
```

Create `~/Library/LaunchAgents/my.rclone.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>KeepAlive</key>
    <true/>
    <key>Label</key>
    <string>my.rclone</string>
    <key>ProgramArguments</key>
    <array>
      <string>/Users/wp79lh/bin/mount-onedrive</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>UserName</key>
    <string>wp79lh</string>
  </dict>
</plist>
```

The service can then be loaded via:

```sh
launchctl load -w ~/Library/LaunchAgents/my.rclone.plist
```

Or unloaded via:

```sh
launchctl unload ~/Library/LaunchAgents/my.rclone.plist
```
