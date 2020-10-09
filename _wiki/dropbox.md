# Dropbox

## Remove all shared links

Go to <https://www.dropbox.com/share/links>, open the browser's JavaScript console (⌘ + ⎇ + I) and paste the following:

```js
$$("#links-list .mc-popover-trigger").forEach((n) => {
  console.log("delete", n);
  n.click();
  $(".delete-link").click();
  $(".button-primary").click();
});
```

## Screenshots Sync on MacOS

In case Dropbox's "Share Screenshots" option isn't working (since it periodically stops working), or in case you don't want to automatically share a link to synchronized screenshots ...

### Solution 1: Configure MacOS's Screen Capture

Change the filename prefix:

```
defaults write com.apple.screencapture name "Screenshot"
```

Change the location:

```
defaults write com.apple.screencapture location /Users/alex/Dropbox/Screenshots/
```

Finally, refresh settings:

```
killall SystemUIServer
```

### Solution 2: Sync via Script

Have a script in `/usr/local/bin/detect-screenshots.rb`:

```ruby
#!/usr/bin/env ruby

Dir["/Users/alex/Desktop/Screen*at*.png"].each do |f|
  if f =~ /(\d{4}-\d{2}-\d{2})\s+at\s+(\d{2}\.\d{2}\.\d{2})/
    cmd = "mv \"#{f}\" \"/Users/alex/Dropbox/Screenshots/Screenshot #{$1} #{$2}\.png\""
    puts cmd
    `#{cmd}`
  end
end
```

Then add this file in `~/Library/LaunchAgents/alex.screenshot.detect.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>alex.screenshot.detect</string>
    <key>EnableGlobbing</key>
    <true />
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/detect-screenshots</string>
    </array>
    <key>WatchPaths</key>
    <array>
        <string>/Users/alex/Desktop/</string>
    </array>
    <key>ThrottleInterval</key>
    <integer>5</integer>
    <key>StandardOutPath</key>
    <string>/Users/alex/Library/Logs/detect-screenshots.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/alex/Library/Logs/detect-screenshots.log</string>
</dict>
</plist>
```

Then load it:

```
launchctl load -w ~/Library/LaunchAgents/alex.screenshot.detect.plist
```
