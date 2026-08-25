🌐 **Sprache / Language**: [English](README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md) | [Русский](README.ru.md)

# rdpwarp — Multisession-Remotedesktop für Windows

> Ermöglicht, dass sich **mehrere Benutzer gleichzeitig remote an einem Windows-PC anmelden**. Einfach zu bedienen.

## Inhalt

- [Was ist das?](#was-ist-das)
- [Funktionen](#funktionen)
- [Schnellstart](#schnellstart)
- [Von den Releases herunterladen](#von-den-releases-herunterladen)
- [FAQ](#faq)
- [Deinstallation](#deinstallation)
- [Systemanforderungen](#systemanforderungen)
- [Lizenz](#lizenz)

## Was ist das?

Das Windows-Remotedesktop erlaubt normalerweise nur eine Sitzung gleichzeitig. Dieses Tool nutzt **RDP Wrapper (rdpwrap)**, um diese Grenze aufzuheben, sodass mehrere Benutzer gleichzeitig auf denselben PC zugreifen können.

## Funktionen

- Ein-Klick-Installation / Deinstallation, Multisession aktivieren
- Max. Sitzungen, Einzelsitzung pro Benutzer, Sicherheit (NLA / Sicherheitsebene), Anzeige, Timeouts und Port konfigurieren
- Erkennt Ihren Windows-Build automatisch und repariert Offsets nach Updates
- Selbstheilender Watchdog (Start + tägliche Prüfung)
- 8 Sprachen

## Schnellstart

**Methode 1: direkte Verbindung**

```powershell
powershell -c "(irm https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

**Methode 2: Proxy verwenden (in China empfohlen)**

```powershell
powershell -c "$env:GH_MIRROR='https://gh-proxy.com/';(irm https://gh-proxy.com/https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

Wenn die **UAC**-Abfrage erscheint, klicken Sie auf **Ja**, dann wählen Sie **1** für die Installation. Für langfristige oder Offline-Nutzung laden Sie es unten herunter.

## Von den Releases herunterladen

Öffnen Sie **[Releases](https://github.com/lcxxjmsg-cyber/rdp_warp_ps/releases)**, laden Sie `rdp_warp_ps-vX.Y.Z.zip` herunter, entpacken Sie es und doppelklicken Sie dann auf **`start.bat`** (automatische Höherstufung). Oder:

```powershell
.\rdpwarps.ps1 -Install    # stille Installation
.\rdpwarps.ps1 -Uninstall  # saubere Deinstallation
```

## FAQ

**F1: TermService bleibt nach der Installation gestoppt?**
Wahrscheinlich blockiert **Smart App Control / Speicher-Integrität** (Code-Integrität) das unsignierte rdpwrap. Deaktivieren Sie „Smart App Control" und „Speicher-Integrität", **starten Sie neu** und fügen Sie `C:\Program Files\rdpwarp` und `C:\rdpwarp` zu den Defender-Ausschlüssen hinzu.

**F2: Kann ich die Sitzung eines anderen Benutzers mitverfolgen?**
Client-Editionen erlauben nur das Mitverfolgen **Ihrer eigenen** Sitzungen. Benutzerübergreifendes Mitverfolgen erfordert **Windows Server + RDS** (Admin + die Richtlinie „Regeln zur Fernsteuerung festlegen" + Neustart).

**F3: „Administratorrechte erforderlich"?**
Das Skript stuft sich automatisch hoch. Wird UAC abgelehnt, rechtsklicken Sie auf „Als Administrator ausführen" oder verwenden Sie `start.bat`.

## Deinstallation

Führen Sie `.\rdpwarps.ps1 -Uninstall` aus: stellt die Einstellungen wieder her und entfernt bereitgestellte Dateien, Watchdog und Defender-Ausschlüsse.

## Systemanforderungen

- Windows 8.1 / 10 / 11, Windows Server 2008 ~ 2025
- PowerShell 5.1, Administratorrechte
- Die tatsächliche Unterstützung hängt davon ab, ob Ihre `termsrv.dll`-Version die strenge Prüfung besteht

## Lizenz

Nur auf Geräten verwenden, die Sie besitzen oder verwalten dürfen. Basiert auf Community-Projekten wie [stascorp/rdpwrap](https://github.com/stascorp/rdpwrap) und RDPWrapOffsetFinder.
