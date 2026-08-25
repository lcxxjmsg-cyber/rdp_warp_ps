🌐 **Langue / Language**: [English](README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md) | [Русский](README.ru.md)

# rdpwarp — Bureau à distance multi-session pour Windows

> Permettez à un PC Windows d'accepter **plusieurs utilisateurs connectés à distance en même temps**. Simple à utiliser.

## Sommaire

- [Qu'est-ce que c'est ?](#quest-ce-que-cest-)
- [Fonctionnalités](#fonctionnalités)
- [Démarrage rapide](#démarrage-rapide)
- [Télécharger depuis les Releases](#télécharger-depuis-les-releases)
- [FAQ](#faq)
- [Désinstallation](#désinstallation)
- [Configuration requise](#configuration-requise)
- [Licence](#licence)

## Qu'est-ce que c'est ?

Le Bureau à distance de Windows n'autorise normalement qu'une seule session à la fois. Cet outil utilise **RDP Wrapper (rdpwrap)** pour lever cette limite et permettre à plusieurs utilisateurs de se connecter et d'utiliser le même PC simultanément.

## Fonctionnalités

- Installation / désinstallation en un clic, activer la multi-session
- Configurer le nombre max de sessions, une session par utilisateur, la sécurité (NLA / couche de sécurité), l'affichage, les délais et le port
- Détecte automatiquement votre build Windows et répare les offsets après les mises à jour
- Gardien auto-réparateur (démarrage + vérification quotidienne)
- 8 langues

## Démarrage rapide

**Méthode 1 : connexion directe**

```powershell
powershell -c "(irm https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

**Méthode 2 : utiliser un proxy (recommandé en Chine)**

```powershell
powershell -c "$env:GH_MIRROR='https://gh-proxy.com/';(irm https://gh-proxy.com/https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

Quand l'invite **UAC** apparaît, cliquez sur **Oui**, puis choisissez **1** pour installer. Pour un usage à long terme ou hors ligne, téléchargez ci-dessous.

## Télécharger depuis les Releases

Allez dans **[Releases](https://github.com/lcxxjmsg-cyber/rdp_warp_ps/releases)**, téléchargez `rdp_warp_ps-vX.Y.Z.zip`, décompressez, puis double-cliquez sur **`start.bat`** (élévation auto). Ou :

```powershell
.\rdpwarps.ps1 -Install    # installation silencieuse
.\rdpwarps.ps1 -Uninstall  # désinstallation propre
```

## FAQ

**Q1 : TermService reste arrêté après l'installation ?**
Il s'agit probablement de **Smart App Control / Intégrité de la mémoire** (code integrity) qui bloque le rdpwrap non signé. Désactivez « Smart App Control » et « Intégrité de la mémoire », **redémarrez**, et ajoutez `C:\Program Files\rdpwarp` et `C:\rdpwarp` aux exclusions de Defender.

**Q2 : Puis-je surveiller la session d'un autre utilisateur ?**
Les éditions client ne permettent que de surveiller **vos propres** sessions. La surveillance entre utilisateurs nécessite **Windows Server + RDS** (admin + la règle « Définir les règles de contrôle à distance » + redémarrage).

**Q3 : « Droits administrateur requis » ?**
Le script s'élève automatiquement. Si l'UAC est refusé, faites un clic droit « Exécuter en tant qu'administrateur » ou utilisez `start.bat`.

## Désinstallation

Exécutez `.\rdpwarps.ps1 -Uninstall` : restaure les paramètres, supprime les fichiers déployés, le gardien et les exclusions Defender.

## Configuration requise

- Windows 8.1 / 10 / 11, Windows Server 2008 ~ 2025
- PowerShell 5.1, privilèges administrateur
- La prise en charge réelle dépend de la validation stricte de votre version `termsrv.dll`

## Licence

À utiliser uniquement sur des appareils que vous possédez ou que vous êtes autorisé à gérer. Construit sur des projets communautaires comme [stascorp/rdpwrap](https://github.com/stascorp/rdpwrap) et RDPWrapOffsetFinder.
