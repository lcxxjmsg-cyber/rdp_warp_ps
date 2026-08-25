🌐 **Language**: [English](README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md) | [Русский](README.ru.md)

# rdpwarp — Multi-session Remote Desktop for Windows

> Let one Windows PC allow **multiple users to log in remotely at the same time**. Easy to use.

## Contents

- [What is it?](#what-is-it)
- [Features](#features)
- [Quick start](#quick-start)
- [Download from Release](#download-from-release)
- [FAQ](#faq)
- [Uninstall](#uninstall)
- [Requirements](#requirements)
- [License](#license)

## What is it?

Windows Remote Desktop normally allows only one session at a time. This tool uses **RDP Wrapper (rdpwrap)** to unlock that limit, so several users can connect to and use the same PC at once.

## Features

- One-click install / uninstall, enable multi-session Remote Desktop
- Configure max sessions, single-session-per-user, security (NLA / security layer), display, timeouts and port
- Automatically detects your Windows build and repairs offsets after updates
- Self-healing watchdog (starts at boot, checks daily)
- 8 languages

## Quick start

**Method 1: direct connection**

```powershell
powershell -c "(irm https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

**Method 2: use a proxy (recommended in China)**

```powershell
powershell -c "$env:GH_MIRROR='https://gh-proxy.com/';(irm https://gh-proxy.com/https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

When the **UAC** prompt appears, click **Yes**, then choose **1** to install. For long-term or offline use, download below.

## Download from Release

Go to **[Releases](https://github.com/lcxxjmsg-cyber/rdp_warp_ps/releases)**, download `rdp_warp_ps-vX.Y.Z.zip`, extract it, then double-click **`start.bat`** (auto-elevates). Or run:

```powershell
.\rdpwarps.ps1 -Install    # silent install
.\rdpwarps.ps1 -Uninstall  # clean uninstall
```

## FAQ

**Q1: TermService stays stopped after install?**
Most likely **Smart App Control / Memory Integrity** (code-integrity) is blocking the unsigned rdpwrap. Turn off "Smart App Control" and "Memory Integrity", **reboot**, and add `C:\Program Files\rdpwarp` and `C:\rdpwarp` to Defender exclusions.

**Q2: Can I shadow another user's session?**
Client editions only allow shadowing **your own** sessions. Cross-user shadowing needs **Windows Server + RDS** (admin + the "Set rules for remote control" policy + reboot).

**Q3: "Admin required"?**
The script self-elevates automatically. If UAC is denied, right-click "Run as administrator" or use `start.bat`.

## Uninstall

Run `.\rdpwarps.ps1 -Uninstall` — it restores settings, removes deployed files, the watchdog and Defender exclusions.

## Requirements

- Windows 8.1 / 10 / 11, Windows Server 2008~2025
- PowerShell 5.1, administrator privileges
- Real support depends on your `termsrv.dll` version passing strict validation

## License

For use only on devices you own or are allowed to manage. Builds on community projects such as [stascorp/rdpwrap](https://github.com/stascorp/rdpwrap) and RDPWrapOffsetFinder.
