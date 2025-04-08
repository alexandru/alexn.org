---
date: 2020-08-24 16:24:31 +03:00
last_modified_at: 2025-04-08 20:37:15 +0300
---

# Firefox

## Cool Extensions

- [Auto Tab Discard](https://addons.mozilla.org/en-US/firefox/addon/auto-tab-discard/);
- [Consent-o-matic](https://addons.mozilla.org/en-US/firefox/addon/consent-o-matic/) ([GitHub](https://github.com/cavi-au/Consent-O-Matic)): automatic handling of GDPR consent popups;
- [Cookie Quick Manager](https://addons.mozilla.org/en-US/firefox/addon/cookie-quick-manager/);
- [Enhancer for YouTube™](https://addons.mozilla.org/en-US/firefox/addon/enhancer-for-youtube/);
- [Firefox Multi-Account Containers](https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/);
- [Netflix 1080p](https://addons.mozilla.org/en-US/firefox/addon/netflix-1080p-firefox/) ([GitHub](https://github.com/TheGoddessInari/netflix-1080p-firefox)): enables 1080p playback on Netflix;
- [Notifier for GitHub](https://addons.mozilla.org/en-US/firefox/addon/notifier-for-github/): shows GitHub notifications in the toolbar;
- [Old Reddit Redirect](https://addons.mozilla.org/en-US/firefox/addon/old-reddit-redirect/) ([GitHub](https://github.com/tom-james-watson/old-reddit-redirect));
- [RSS Preview](https://addons.mozilla.org/en-US/firefox/addon/rsspreview/) ([GitHub](https://github.com/aureliendavid/rsspreview)): previews RSS feeds in the browser;
- [Sideberry](https://addons.mozilla.org/en-US/firefox/addon/sidebery/) ([GitHub](https://github.com/mbnuqw/sidebery)): shows tabs like a tree, alternative to Tree Style Tab (better, IMO);
- [Stylus](https://addons.mozilla.org/en-US/firefox/addon/styl-us/): custom CSS for websites;
- [Tab Reloader](https://addons.mozilla.org/en-US/firefox/addon/tab-reloader/): reloads tabs at a specified interval;
- [Tabliss](https://addons.mozilla.org/en-US/firefox/addon/tabliss/) ([GitHub](https://github.com/joelshepherd/tabliss)): a customizable new tab page with beautiful backgrounds;
- [Terms of Service; Didn’t Read](https://addons.mozilla.org/en-US/firefox/addon/terms-of-service-didnt-read/): shows a summary of the terms of service of the website you're visiting;
- [Toggle Tab Pin](https://addons.mozilla.org/en-US/firefox/addon/toggle-pin-tab/) ([GitHub](https://github.com/andreicristianpetcu/toggle-pin-tab)): pins/unpins tabs with a keyboard shortcut;
- [Tree Style Tab](https://addons.mozilla.org/en-US/firefox/addon/tree-style-tab/): shows tabs like a tree;
- [uBlock Origin](https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/): the best ad-blocker;
- [Wayback Machine](https://addons.mozilla.org/en-US/firefox/addon/wayback-machine_new/): save and view archived versions of websites;

## Settings

[about:config](about:config)

### Auto-sync about:config settings

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

### Activate compact mode (after Proton)

In `about:config`:

```js
browser.compactmode.show = true
```

Source: <https://support.mozilla.org/en-US/kb/compact-mode-workaround-firefox>

### Restore Pinned Tabs on Demand

Note sure how to prevent the pinned tabs from opening at all, but at least this delays them loading, until you activate the tabs:

``` js
browser.sessionstore.restore_pinned_tabs_on_demand = true

services.sync.prefs.browser.sessionstore.restore_pinned_tabs_on_demand = true
```

### Hide Native Tabs (for Tree Style Tabs)

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

### Enable calculator

Source: <https://xoxo.zone/@annika/111459732964070961>

```
browser.urlbar.suggest.calculator = true

services.sync.prefs.browser.urlbar.suggest.calculator = true
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
