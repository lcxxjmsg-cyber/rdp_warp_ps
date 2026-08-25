🌐 **Idioma / Language**: [English](README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md) | [Русский](README.ru.md)

# rdpwarp — Escritorio remoto multis ¡sesión para Windows

> Permite que una PC con Windows acepte **varios usuarios conectados de forma remota a la vez**. Fácil de usar.

## Contenido

- [¿Qué es?](#qué-es)
- [Funciones](#funciones)
- [Inicio rápido](#inicio-rápido)
- [Descargar desde Releases](#descargar-desde-releases)
- [Preguntas frecuentes](#preguntas-frecuentes)
- [Desinstalación](#desinstalación)
- [Requisitos](#requisitos)
- [Licencia](#licencia)

## ¿Qué es?

El Escritorio remoto de Windows normalmente permite solo una sesión a la vez. Esta herramienta usa **RDP Wrapper (rdpwrap)** para eliminar ese límite y permitir que varios usuarios se conecten y usen la misma PC simultáneamente.

## Funciones

- Instalación / desinstalación con un clic, activar la multis ¡sesión
- Configurar máx. sesiones, una sesión por usuario, seguridad (NLA / capa de seguridad), pantalla, tiempos de espera y puerto
- Detecta automáticamente tu compilación de Windows y repara los offsets tras las actualizaciones
- Vigilante auto-reparable (inicio + revisión diaria)
- 8 idiomas

## Inicio rápido

**Método 1: conexión directa**

```powershell
powershell -c "(irm https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

**Método 2: usar un proxy (recomendado en China)**

```powershell
powershell -c "$env:GH_MIRROR='https://gh-proxy.com/';(irm https://gh-proxy.com/https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

Cuando aparezca el aviso **UAC**, haz clic en **Sí** y luego elige **1** para instalar. Para uso a largo plazo u offline, descarga a continuación.

## Descargar desde Releases

Ve a **[Releases](https://github.com/lcxxjmsg-cyber/rdp_warp_ps/releases)**, descarga `rdp_warp_ps-vX.Y.Z.zip`, descomprímelo y haz doble clic en **`start.bat`** (elevación automática). O ejecuta:

```powershell
.\rdpwarps.ps1 -Install    # instalación silenciosa
.\rdpwarps.ps1 -Uninstall  # desinstalación limpia
```

## Preguntas frecuentes

**P1: ¿TermService queda detenido tras la instalación?**
Lo más probable es que **Smart App Control / Integridad de la memoria** (code integrity) bloquee el rdpwrap sin firmar. Desactiva «Smart App Control» e «Integridad de la memoria», **reinicia** y añade `C:\Program Files\rdpwarp` y `C:\rdpwarp` a las exclusiones de Defender.

**P2: ¿Puedo ver la sesión de otro usuario?**
Las ediciones de cliente solo permiten ver **tus propias** sesiones. La visualización entre usuarios requiere **Windows Server + RDS** (admin + la política «Establecer reglas para el control remoto» + reinicio).

**P3: ¿«Se requieren privilegios de administrador»?**
El script se eleva automáticamente. Si se rechaza el UAC, haz clic derecho en «Ejecutar como administrador» o usa `start.bat`.

## Desinstalación

Ejecuta `.\rdpwarps.ps1 -Uninstall`: restaura la configuración y elimina los archivos desplegados, el vigilante y las exclusiones de Defender.

## Requisitos

- Windows 8.1 / 10 / 11, Windows Server 2008 ~ 2025
- PowerShell 5.1, privilegios de administrador
- El soporte real depende de que tu versión de `termsrv.dll` pase una validación estricta

## Licencia

Úsalo solo en dispositivos que poseas o que tengas permiso de administrar. Se basa en proyectos comunitarios como [stascorp/rdpwrap](https://github.com/stascorp/rdpwrap) y RDPWrapOffsetFinder.
