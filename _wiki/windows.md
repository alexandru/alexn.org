---
date: 2020-08-24 16:24:31 +03:00
last_modified_at: 2025-01-21T18:59:34+02:00
---

# Windows 10

## Installation on Macbooks

### Create bootable USB stick for installing Windows

1: Download the Windows ISO file from Microsoft's website.
2: Identify the disk number of the USB drive: `diskutil list`
3: `diskutil unmountDisk /dev/diskN` 
4: `sudo dd if=/path/to/windows.iso of=/dev/rdiskN bs=1m` 

### Boot Camp

To download the drivers:

1. From MacOS: Boot Camp Assistant -> Menu -> "Action" -> "Download Windows Support Software"
2. From Windows: <https://github.com/timsutton/brigadier>

### Third-party utilities

- To make the Macbook's touchpad not suck: <https://github.com/imbushuo/mac-precision-touchpad>

### Support for Hyper-Threading

- Source: [Hacker News comment](https://news.ycombinator.com/item?id=22875681)
- Documentation: [Enabling VT-x on Mac Book Air in Bootcamp](https://dea.nbird.com.au/2017/02/24/enabling-vt-x-on-mac-book-air-in-bootcamp/)
- Download: [rEFInd](https://www.rodsbooks.com/refind/)

## Set-up tutorials

- [A No-Bullshit Guide to Setting up Windows 10](https://b.s5.pm/os/2021/08/28/windows-setup.html) ([archive](https://web.archive.org/web/20210809064346/https://b.s5.pm/os/2021/08/28/windows-setup.html))