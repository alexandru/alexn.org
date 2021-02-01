---
date: 2020-08-24 16:24:31+0300
title: "MacOS"
---

## Finder Shortcuts

- `Cmd + Shift + G`: Go to Folder
- `Cmd + Shift + .`: Toggle visibility of dot files

## Stop Apple Music / iTunes from starting on Play

Source: [Stop iTunes From Launching When You Press Play On Your Mac’s Keyboard](https://www.howtogeek.com/274345/stop-itunes-from-launching-when-you-press-play-on-your-macs-keyboard/)

```
launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist
```

## Troubleshooting

- PRAM reset: <https://support.apple.com/en-us/HT204063>
- SMC reset: <https://support.apple.com/en-us/HT201295>
- System Integrity Protection: 
  * [How to Disable System Integrity Protection (rootless) in Mac OS X](https://osxdaily.com/2015/10/05/disable-rootless-system-integrity-protection-mac-os-x/)
  * [Configuring System Integrity Protection](https://developer.apple.com/library/archive/documentation/Security/Conceptual/System_Integrity_Protection_Guide/ConfiguringSystemIntegrityProtection/ConfiguringSystemIntegrityProtection.html)

## Other Documents

- [DNS Settings](dns-settings.md#macos)
- [Emacs server setup](emacs.md#emacs-server-as-macos-service)
- [Screenshots synchronization](dropbox.md#screenshots-sync-on-macos)
