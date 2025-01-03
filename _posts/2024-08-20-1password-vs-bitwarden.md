---
title: "1Password vs. Bitwarden"
date: 2024-08-20 09:41:41 +03:00
last_modified_at: 2024-09-04T09:58:20+03:00
tags:
  - Products
  - Self Hosting
  - Open Source
---

<p class="intro">
  Optimising costs and my workflow is a personal obsession of mine. I've been a 1Password user for years, and I keep trying Bitwarden. If you want to pick between the two, here are the differences between them at the time of writing.
</p>

<p class="warn-bubble" markdown="1">
Take this comparisson for what it is: a snapshot in time. In a year from now, both would have evolved, and some of these items may no longer be valid.
</p>

I'm not enumerating here what they both do well, such as trustworthiness, the ability to reliably autofill login credentials, or the cross-platform and cross-browser coverage. These are their pros and cons relative to each other:

## 1Password

* Significantly better UI and UX — and this isn't a subjective opinion.
* Sort by date created / updated — useful to find the items that have changed. This seems like a small thing, but it's difficult to extract this info from Bitwarden ([see workaround](/wiki/bitwarden/#cli-commands)).
* Full history of items, available on the web UI — Bitwarden only keeps a history of the main password.
* Attachments management (that doesn't suck).
* Flawless Passkey support — I did not bump into any issues with it.
* Auto-filling works for TOTP codes, and multi-step dialogs are now automated, no longer requiring intervention (i.e., UIs that first ask for email, then for password, then for TOTP).
* Useful [CLI](https://developer.1password.com/docs/cli/get-started/), very straightforward to use for managing secrets in your local environment.
* Flawless unlocking with [Touch ID](https://support.1password.com/touch-id-mac/), including the CLI.
* [SSH key management](https://developer.1password.com/docs/ssh/manage-keys/).
* [Share items with anyone](https://support.1password.com/share-items/).
* Global shortcut (`⌘\`) that's very efficient, on macOS at least; also on macOS, 1Password can autofill in other apps, not just the browser, easily invoked via this global shortcut.
* Keyboard shortcuts that work really well — for both the desktop app and the browser extension.
* "Show in large type".
* More document types — e.g. bank accounts, software licenses, Wi-Fi networks.
* Offline support — possible to edit or save new items while offline.
* Nicer integration with [Fastmail's masked emails](https://support.1password.com/fastmail/).
* Managing the vaults of your organization or family is very intuitive.
* Exports (for backups or migrations) contain everything, including shared vaults or attachments.

As downsides for 1Password:

* The autofill behavior for the provided "websites" are limiting — for example, I would have liked URL-prefix matching.
* Android has some issues — e.g., the aforementioned customizable autofill behavior (i.e., host vs base domain) does not work (I hope they fix it), and sometimes, the UI failed to open, so I had to restart the app.
* High cost — I pay 68 EUR per year for the family plan (5.65 EUR per month), and I only share the subscription with my son — for professionals this is cheap, but for students, unemployed folks, or the average Joe in general, it's definitely expensive.
* Proprietary software, closed-source — this isn't a problem for me, except...
* Subscription-based — they used to have a standalone version that was connecting to Dropbox, and it felt like a betrayal when they dropped it.
* Good, reliable software, but I have trouble trusting companies that took a lot of venture capital and are pressured to grow.

## Bitwarden

* Open Source — being FOSS at the very least protects it somewhat from the company dying or introducing unreasonable prices.
  * It has a server-side clone, [Vaultwarden](https://github.com/dani-garcia/vaultwarden), that can be easily self-hosted for $0 — but be warned, the [third-party audits](https://bitwarden.com/blog/third-party-security-audit/) do not apply to it.
  * The company may not keep their Open-Source policy (see below).
* Usable free plan.
* Very cheap Premium for solo professionals ($10 / year).
* Username generator.
* Usable CLI, although a little awkward, and lacking Touch ID support, AFAIK. You need [jq](https://jqlang.github.io/jq/) and general wizardry with Unix command-line tools for it to be usable.
* Send text or files.
* Translated in more languages — e.g., Romanian.
* Usable Passkey support (but see below).
* The settings for URL matching are more flexible and work on Android as well (vs 1Password, which is experiencing issues).
  
As downsides for Bitwarden:

* Deplorable UI — there's no other way to describe it; I tried getting my father used to it, but it was mission impossible.
  * You have to use both the desktop app and the web vault because both suck in different ways, and neither is sufficient, so you have to throw the CLI in the mix for common maintenance tasks.
* No usable offline support — you can disconnect from the network, but it becomes read-only, and the UI is confusingly letting you edit items, and you can lose those edits.
* Managing organizations is less than ideal. E.g., if you move items in an organization, you can only change their ownership afterward by cloning them, and you can only do that on the web UI.
* The browser extension fails to auto-complete TOTP codes, you have to rely on those codes being copied in the clipboard.
* Almost no usable keyboard shortcuts — i.e., `Cmd+Shift+Y` in the browser, for activating the extension, is unusable because it doesn't let you do anything via the keyboard next. [Their documentation](https://bitwarden.com/help/keyboard-shortcuts/) should warn people that the handful of available shortcuts are not usable in keyboard-only flows. The desktop app is really bad at it, e.g., when editing an item, you can't even press `Cmd/Ctrl+S` for save, or `Esc` for cancel, like in every other app. This isn't just a nice to have, for people with visual impairment being an accessibility disaster.
* Managing attachments is very unintuitive. And you can't view attached PDFs without downloading them.
* The browser extension is difficult to configure, e.g., to use Touch ID, although this has more to do with it being more conservative when asking for permissions.
* Passkey support isn't as flawless, I bumped into some issues with it when generating passkeys.
* CLI utility is very slow; it's as if it interrogates the server on every command, yet it still needs `bw sync` for the synchronization of the latest changes.
* CLI utility does not have integration with the desktop app's biometrics login, so you end up with a `BW_SESSION` in your bash/zsh profile, making it insecure, or you have to introduce your master password every time, which is annoying.
* Exports (for backups or migrations) don't contain attachments, and you need separate exports for organizations — makes it unintuitive and hard to backup your data. And most of their documentation articles on exports don't mention that organizations need separate exports.
* On Android, the UI can become very slow, if the server is slow — at the time of writing, when using the `vault.bitwarden.eu` server, the app was unusable for me due to how slow it was, with Android sometimes complaining that the app should be killed, but it worked significantly better with my self-hosted Vaultwarden instance. So the app is very dependent on the server's latency, and doesn't have good cache management.
* On Android, the UX for auto-completion is not ideal, with the accessibility draw-over being frequently in the way.
* Bitwarden took VC capital as well, and while it's Open-Source nature may protect the project's future...
* Their new Secrets Manager is, apparently, not fully open source and its UI couldn't be used by [Vaultwarden](https://github.com/dani-garcia/vaultwarden/discussions/3368). This at least points to the very real possibility that the company may pull a bait and switch in the future, like so many other companies that build their popularity via FOSS licensing.

I've tried self-hosting Vaultwarden, the clone, via my Docker-enabled server, and it was effortless to install, and the running process very efficient. I'm impressed, that's how all FOSS projects meant for self-hosting should be. Furthermore, I want more stuff built with Rust + SQLite. The Fediverse should take notes 😉

For me, Bitwarden's Open-Source nature almost makes up for the above deficiencies. Almost, but not quite. I can see myself using Bitwarden, if I were solo, but I'm trying to get my family to use password managers, and right now the UX makes that difficult. I'll try it again next year.
