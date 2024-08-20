---
title: "1Password vs. Bitwarden"
date: 2024-08-20 09:41:41 +03:00
last_modified_at: 2024-08-20 13:20:55 +03:00
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
* Sort by date created / updated — useful to find the items that have changed. This seems like a small thing, but it's difficult to extract this info from Bitwarden.
* Full history of items, available on the web UI — Bitwarden only keeps a history of the main password.
* Attachments management (that doesn't suck).
* Flawless Passkey support — I did not bump into any issues with it.
* Useful [CLI](https://developer.1password.com/docs/cli/get-started/), very straightforward to use for managing secrets in your local environment.
* Flawless unlocking with [Touch ID](https://support.1password.com/touch-id-mac/), including the CLI.
* [SSH key management](https://developer.1password.com/docs/ssh/manage-keys/).
* [Share items with anyone](https://support.1password.com/share-items/).
* Global shortcut, on macOS at least; also on macOS, it can autofill in other apps, not just the browser.
* Keyboard shortcuts that work — for both the desktop app and the browser extension.
* "Show in large type".
* More document types — e.g. bank accounts, software licenses.
* Offline support — possible to edit or save new items while offline.
* Nicer integration with [Fastmail's masked emails](https://support.1password.com/fastmail/).

As downsides for 1Password:

* High cost — I pay 68 EUR per year for the family plan (5.65 EUR per month), and I only share the subscription with my son — for professionals this is cheap, but for students, unemployed folks, or the average Joe in general, it's definitely expensive.
* Proprietary software, closed-source — this isn't a problem for me, except...
* Subscription-based — they used to have a standalone version that was connecting to Dropbox, and it felt like a betrayal when they dropped it.
* Good, reliable software, but I have trouble trusting companies that took a lot of venture capital and are pressured to grow.

## Bitwarden

* Open Source — being FOSS at the very least protects it somewhat from the company dying or introducing unreasonable prices.
* It has a server-side clone, [Vaultwarden](https://github.com/dani-garcia/vaultwarden), that can be easily self-hosted for $0 — but be warned, the [third-party audits](https://bitwarden.com/blog/third-party-security-audit/) do not apply to it.
* Usable free plan.
* Very cheap Premium for solo professionals ($10 / year).
* Username generator.
* Usable CLI, although a little awkward, and lacking Touch ID support, AFAIK. You need [jq](https://jqlang.github.io/jq/) and general wizardry with Unix command-line tools for it to be usable.
* Send text or files.
* Translated in more languages — e.g., Romanian.
* Usable Passkey support (but see below).
  
As downsides for Bitwarden:

* Deplorable UI — there's no other way to describe it; I tried getting my father used to it, but it was mission impossible.
  * You have to use both the desktop app and the web vault because both suck in different ways, and neither is sufficient, so you have to throw the CLI in the mix for common maintenance tasks.
* No usable offline support — you can disconnect from the network, but it becomes read-only, and the UI is confusingly letting you edit items, and you can lose those edits.
* Almost no usable keyboard shortcuts — i.e., `Cmd+Shift+Y` in the browser, for activating the extension, is unusable because it doesn't let you do anything via the keyboard next.
* Managing attachments is very unintuitive.
* The browser extension is difficult to configure, e.g., to use Touch ID, although this has more to do with it being more conservative when asking for permissions.
* Passkey support isn't as flawless, I bumped into some issues with it when generating passkeys.
* CLI utility is very slow; it's as if it interrogates the server on every command, yet it still needs `bw sync` for the synchronization of the latest changes.
* Bitwarden took VC capital as well, but in fairness, its Open-Source nature makes it less prone to it turning against its customers or dying.

Note that it being Open Source, being cheaper, with the ability to self-host, and having a usable FOSS (Rust-based, efficient) clone, almost makes up for these shortcomings.
