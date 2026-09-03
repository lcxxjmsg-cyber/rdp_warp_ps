🌐 **Language**: [English](Shadow-README.md) | [简体中文](Shadow-README.zh-CN.md)

# Shadow (Remote Control / Session Shadowing) Guide

> Shadowing (Session Shadow / Remote Control) means using one session to **view / control another**. This tool makes it a reliable path for both **local** and **cross-machine remote** shadowing.

## Two ways to shadow

| Way | Command | Use |
|---|---|---|
| **Local** | `mstsc /shadow:<sessionID> /control [/noConsentPrompt]` | Shadow another session on the same machine |
| **Cross-machine** | `mstsc /v:<host> /shadow:<sessionID> /control /noConsentPrompt /prompt` | Shadow a session on another machine |

## How Windows shadowing works

- **Ports**: shadow does not use 3389 — it uses **139/TCP, 445/TCP + dynamic RPC (49152–65535)**. Enable these firewall rules:
  `File and Printer Sharing (SMB-In)` + `Remote Desktop - Shadow (TCP-In)` (the latter allows `RdpSa.exe`).
- **Permission**: your account must be a **local administrator** on the target; the caller needs `WINSTATION_SHADOW` (0x10) on the target.
- **Mode**: the "Remote Control" `Shadow` value decides: `0=disabled` `1=full/with consent` `2=full/no consent` `3=view/with consent` `4=view/no consent`.
- **Credentials**: for `mstsc /v` cross-machine, pass **`/prompt`** to use the credentials you type; **without `/prompt` it uses the current user's credentials**.
- **Consent**: even in no-consent mode the target may show "`PC\admin` is requesting to view your session. Do you accept?"; `/noConsentPrompt` suppresses it.
- **Control**: only `/control` lets you drive the mouse/keyboard; without it it's **view only**.
- **Limits**: the shadow goes **black/paused** if the target session is locked or has a UAC Secure-Desktop prompt; a **console** session cannot be shadowed; **a session can only be shadowed once** (RDP protocol limit).

## ⚠ Key practical difference (tested)

- **Local**: with administrator rights, **account A can freely shadow account B**'s session.
- **Cross-machine (tested)**: you **must use the credentials of the account that owns the target session (its SID)** — a different admin account gets refused when shadowing cross-machine. (Observed in the rdpwrap client scenario; behavior may vary by build. If refused, retry with the target session user's credentials via `-User/-Password` or `/prompt`.)

## Using this tool

Interactive menu: **Shadow → 3 (local) / 4 (remote) / 5 (diagnostics)**. Or directly:

```powershell
# Local (reads target user's per-user -> global policy to pick /control and /noConsentPrompt)
Invoke-RdpShadow -SessionId 7

# Cross-machine (auto /v; -User cache via cmdkey, otherwise /prompt)
Invoke-RdpShadow -Remote 192.168.1.12 -SessionId 7 -User 65633 -Password 'lengye521'
Invoke-RdpShadow -Remote 192.168.1.12 -SessionId 7        # prompts for credentials
```

Parameters: `-SessionId` / `-Remote <host>` / `-User/-Password` (cmdkey cache) / `-ForceConsent` / `-ForceNoConsent` / `-ViewOnly`.
> **Remote only supports the default port 3389**: `mstsc /shadow /v` does not accept a custom port (reports "This computer name is invalid").

## Manual cross-machine shadow (same as the tool)

```powershell
cmdkey /add:192.168.1.12 /user:target-session-user /pass:password   # cache creds
query session /server:192.168.1.12                                  # list remote sessions (needs cmdkey creds)
mstsc /v:192.168.1.12 /shadow:7 /control /noConsentPrompt /prompt
```

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| This computer name is invalid | Target RDP uses a custom port (not 3389) | Set target port to **3389** |
| The specified session is not connected | `/v` reached default 3389, but target isn't Active or is console | Ensure target is an **Active `rdp-tcp#N`** |
| Access denied (cross-machine) | No `/prompt`/creds; account not authorized on the target; or credential doesn't match the session (SID) | Add `/prompt` + the **target-authorized** account; prefer **that session's user** credentials |
| Access denied (local cross-user) | Target session created under an old Shadow value; or target asked for consent | Re-login the target user; use `-ForceNoConsent` |
| Why still need RPC after opening 445 | Shadow uses 139/445 + RPC(49152-65535) | Enable "File and Printer Sharing" + "Remote Desktop - Shadow" + the dynamic RPC range |
| Shadow black / paused | Target session locked or a UAC Secure-Desktop prompt | Unlock / handle UAC, then it resumes |

## Credentials & security

- `cmdkey` stores the credential in the current user's Credential Manager; clear it afterwards with `cmdkey /delete:<host>`.
- Cross-machine shadow is fundamentally "target authorization + credentials"; use a dedicated authorized account and delete it after testing.
- Full RDP/RDS details: main README and [Microsoft mstsc docs](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/mstsc).
