🌐 **Language**: [English](README.md) | [简体中文](README.zh-CN.md)

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

```powershell
powershell -c "(irm https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
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
Yes. Shadowing works locally (`主菜单 → 影子 → 发起影子-本机`) and **across machines** (`→ 发起影子-远程`), which launches `mstsc /v:<host> /shadow:<id> /control /noConsentPrompt /prompt`. Requirements:
- The caller must be an **elevated administrator** with the WinStation remote-control right `0x10` on the **target** machine.
- For cross-machine, provide a **target-authorized account** (via the tool's `-User/-Password`, which caches it with `cmdkey`, or add `/prompt` and type it when prompted).
- The target session must be a **non-console, Active** `rdp-tcp#N` session; the **RDP port must be the default 3389** (`mstsc /shadow /v` doesn't accept a custom port — it gives "invalid computer name").
- The tool reads the target shadow policy (per-user → global) to pick `/control` and `/noConsentPrompt`. `Shadow=2` = full control without consent (the recommended "Full access without permission" for a TeamViewer-style view); a normal-user target may still prompt for consent (re-login that session to pick it up).
- A **console** session cannot be shadowed (or shadow others).
- **Same session can only be shadowed once** (an RDP protocol limit).

See **`Shadow-README.md`** in the repo for the full guide + troubleshooting.

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
