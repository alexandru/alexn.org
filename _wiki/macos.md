---
date: 2020-08-24 16:24:31 +03:00
last_modified_at: 2025-01-24T14:18:11+02:00
---

# macOS

## Finder Shortcuts

- `Cmd + Shift + G`: Go to Folder
- `Cmd + Shift + .`: Toggle visibility of dot files

## Useful Apps

- [Ice](https://github.com/jordanbaird/Ice): Powerful menu bar manager for macOS, OSS alternative to Bartender;
- [Hot](https://github.com/macmade/Hot): for monitoring the CPU temperature;
- [Smart Scroll](https://www.marcmoini.com/sx_en.html): makes the mouse more useful;
- [Turbo Booster Switcher](https://github.com/rugarciap/Turbo-Boost-Switcher): switches off "turbo boost" for Intel CPUs, prevents overheating;

## Stop Apple Music / iTunes from starting on Play

Source: [Stop iTunes From Launching When You Press Play On Your Mac’s Keyboard](https://www.howtogeek.com/274345/stop-itunes-from-launching-when-you-press-play-on-your-macs-keyboard/)

```
launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist
```

## Find which app is stealing focus

Answer from [StackExchange](https://apple.stackexchange.com/questions/123730/is-there-a-way-to-detect-what-program-is-stealing-focus-on-my-mac):

```python
#!/usr/bin/python

try:
    from AppKit import NSWorkspace
except ImportError:
    print "Can't import AppKit -- maybe you're running python from brew?"
    print "Try running with Apple's /usr/bin/python instead."
    exit(1)

from datetime import datetime
from time import sleep

last_active_name = None
while True:
    active_app = NSWorkspace.sharedWorkspace().activeApplication()
    if active_app['NSApplicationName'] != last_active_name:
        last_active_name = active_app['NSApplicationName']
        print '%s: %s [%s]' % (
            datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            active_app['NSApplicationName'],
            active_app['NSApplicationPath']
        )
    sleep(1)
```

Needs `pyobjc`:

```sh
pip install pyobjc
```

## Resources / Troubleshooting

- PRAM reset: <https://support.apple.com/en-us/HT204063>
- SMC reset: <https://support.apple.com/en-us/HT201295>
- System Integrity Protection:
  * [How to Disable System Integrity Protection (rootless) in Mac OS X](https://osxdaily.com/2015/10/05/disable-rootless-system-integrity-protection-mac-os-x/)
  * [Configuring System Integrity Protection](https://developer.apple.com/library/archive/documentation/Security/Conceptual/System_Integrity_Protection_Guide/ConfiguringSystemIntegrityProtection/ConfiguringSystemIntegrityProtection.html)

- [Force updates for older Macs](https://github.com/dortania/OpenCore-Legacy-Patcher)

## Other Documents

- [DNS Settings](dns-settings.md#macos)
- [Emacs server setup](emacs.md#emacs-server-as-macos-service)
- [Screenshots synchronization](dropbox.md#screenshots-sync-on-macos)
