---
date: 2020-08-24 16:24:31 +03:00
last_modified_at: 2026-07-02 18:46:24 +0300
---

# Windows

## Installation on Macbooks

### Boot Camp

To download the drivers:

1. From MacOS: Boot Camp Assistant -> Menu -> "Action" -> "Download Windows Support Software"
2. From Windows: <https://github.com/timsutton/brigadier>

### Workaround TPM 2.0 requirement

Intel Macbooks have a T2 security chip, so Windows 11 is NOT officially supported.

To install:
1. Use Microsoft’s Windows 11 Media Creation Tool to create the USB.
2. Boot the Mac from it.
3. When Windows Setup complains about TPM / unsupported hardware, press: 
   `Shift + F10`
4. Run `regedit`
5. Create this key: `HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig`
6. Add these DWORD values set to `1`...

```
BypassTPMCheck
BypassSecureBootCheck
```

### Activate Windows license

- <https://massgrave.dev/>
- <https://github.com/massgravel/Microsoft-Activation-Scripts>

### Set Caps-Lock as Ctrl

Open *Powershell as Administrator* and execute:

```powershell
$hex = "0000000000000000020000001D003A0000000000"
$bytes = for ($i = 0; $i -lt $hex.Length; $i += 2) {
    [Convert]::ToByte($hex.Substring($i, 2), 16)
}

New-ItemProperty `
  -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout" `
  -Name "Scancode Map" `
  -PropertyType Binary `
  -Value $bytes `
  -Force
```

### Third-party utilities

- To make the Macbook's touchpad not suck: <https://github.com/imbushuo/mac-precision-touchpad>

### Support for HyperV

Required for WSL2.

Install [rEFInd](https://www.rodsbooks.com/refind/).

NOTE: for some reason, on my Macbook Pro 2019, with Windows 11, I had to do nothing, so this may not be needed.

## Set-up tutorials

- [A No-Bullshit Guide to Setting up Windows 10](https://b.s5.pm/os/2021/08/28/windows-setup.html) ([archive](https://web.archive.org/web/20210809064346/https://b.s5.pm/os/2021/08/28/windows-setup.html))