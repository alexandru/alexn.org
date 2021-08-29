---
date: 2020-08-24 16:24:31+0300
title: "Firefox"
---

## Cool Extensions

- [Auto Tab Discard](https://addons.mozilla.org/en-US/firefox/addon/auto-tab-discard/)
- [Awesome RSS](https://addons.mozilla.org/en-US/firefox/addon/awesome-rss/)
- [CleanURLs](https://addons.mozilla.org/en-US/firefox/addon/clearurls/)
- [Close discarded tabs](https://addons.mozilla.org/en-US/firefox/addon/close-discarded-tabs/)
- [Cookie Quick Manager](https://addons.mozilla.org/en-US/firefox/addon/cookie-quick-manager/)
- [Decentraleyes](https://addons.mozilla.org/en-US/firefox/addon/decentraleyes/)
- [Enhancer for YouTube™](https://addons.mozilla.org/en-US/firefox/addon/enhancer-for-youtube/)
- [Facebook Container](https://addons.mozilla.org/en-US/firefox/addon/facebook-container/)
- [Firefox Multi-Account Containers](https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/)
- [HTTPS Everywhere](https://addons.mozilla.org/en-US/firefox/addon/https-everywhere/)
- [I don't care about cookies](https://addons.mozilla.org/en-US/firefox/addon/i-dont-care-about-cookies/)
- [Notifier for GitHub](https://addons.mozilla.org/en-US/firefox/addon/notifier-for-github/)
- [Privacy Badger](https://privacybadger.org/)
- [Stylus](https://addons.mozilla.org/en-US/firefox/addon/styl-us/)
- [Tab Reloader](https://addons.mozilla.org/en-US/firefox/addon/tab-reloader/)
- [Terms of Service; Didn’t Read](https://addons.mozilla.org/en-US/firefox/addon/terms-of-service-didnt-read/)
- [Tree Style Tab](https://addons.mozilla.org/en-US/firefox/addon/tree-style-tab/)
- [Wayback Machine](https://addons.mozilla.org/en-US/firefox/addon/wayback-machine_new/)
- [uBlock Origin](https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/)
- [vim-vixen](https://github.com/ueokande/vim-vixen)

## Auto-sync about:config settings

Source:
<https://www.addictivetips.com/web/sync-about-config-preferences-with-firefox-sync/>

For each setting to be synched, add:

``` 
services.sync.prefs.<setting> true
```

Examples:

```
services.sync.prefs.toolkit.legacyUserProfileCustomizations.stylesheets

services.sync.prefs.media.hardwaremediakeys.enabled
```

## Enable media keys on MacOS

Sources:

- <https://bugzilla.mozilla.org/show_bug.cgi?id=1575995>
- <https://bugzilla.mozilla.org/show_bug.cgi?id=1112032>

In [about:config](about:config):

```js
media.hardwaremediakeys.enabled = true

// For syncing the setting
services.sync.prefs.media.hardwaremediakeys.enabled = true


dom.media.mediasession.enabled = true

// For syncing the setting
services.sync.prefs.dom.media.mediasession.enabled = true
```

## Activate compact mode (after Proton)

In `about:config`:

```js
browser.compactmode.show = true
```

Source: <https://support.mozilla.org/en-US/kb/compact-mode-workaround-firefox>

## Restore Pinned Tabs on Demand

Note sure how to prevent the pinned tabs from opening at all, but at least this delays them loading, until you activate the tabs:

``` js
browser.sessionstore.restore_pinned_tabs_on_demand = true

services.sync.prefs.browser.sessionstore.restore_pinned_tabs_on_demand = true
```

## Hide Native Tabs (for Tree Style Tabs)

<https://medium.com/@Aenon/firefox-hide-native-tabs-and-titlebar-f0b00bdbb88b>

In [about:config](about:config) set:

``` js
toolkit.legacyUserProfileCustomizations.stylesheets = true

// For syncing the setting
services.sync.prefs.toolkit.legacyUserProfileCustomizations.stylesheets = true
```

Then in the `<Profile folder>/chrome/userChrome.css`:

``` css
/* hides the native tabs */
#TabsToolbar {
  visibility: collapse;
}

#sidebar-header {
  visibility: collapse !important;
}
```

## All about: Pages

- [about:about](about:about)
- [about:addons](about:addons)
- [about:buildconfig](about:buildconfig)
- [about:cache](about:cache)
- [about:checkerboard](about:checkerboard)
- [about:config](about:config)
- [about:crashes](about:crashes)
- [about:credits](about:credits)
- [about:debugging](about:debugging)
- [about:devtools](about:devtools)
- [about:downloads](about:downloads)
- [about:home](about:home)
- [about:license](about:license)
- [about:logo](about:logo)
- [about:memory](about:memory)
- [about:mozilla](about:mozilla)
- [about:networking](about:networking)
- [about:newtab](about:newtab)
- [about:performance](about:performance)
- [about:plugins](about:plugins)
- [about:preferences](about:preferences)
- [about:privatebrowsing](about:privatebrowsing)
- [about:profiles](about:profiles)
- [about:rights](about:rights)
- [about:robots](about:robots)
- [about:serviceworkers](about:serviceworkers)
- [about:studies](about:studies)
- [about:support](about:support)
- [about:sync-log](about:sync-log)
- [about:telemetry](about:telemetry)
- [about:url-classifier](about:url-classifier)
- [about:webrtc](about:webrtc)

## Docs

- [Configuring Networks to Disable DNS over HTTPS](https://support.mozilla.org/ro/kb/configuring-networks-disable-dns-over-https)
- [Canary domain - use-application-dns.net](https://support.mozilla.org/en-US/kb/canary-domain-use-application-dnsnet)
- [Trusted Recursive Resolver](https://wiki.mozilla.org/Trusted_Recursive_Resolver)