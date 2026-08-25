🌐 **Language**: [English](#english) | [简体中文](#简体中文) | [日本語](#日本語) | [한국어](#한국어) | [Français](#français) | [Deutsch](#deutsch) | [Español](#español) | [Русский](#русский)

---

# English

## rdpwarp — Multi-session Remote Desktop for Windows

> Let one Windows PC allow **multiple users to log in remotely at the same time**. Easy to use.

### What is it?

Windows Remote Desktop normally allows only one session at a time. This tool uses **RDP Wrapper (rdpwrap)** to unlock that limit, so several users can connect to and use the same PC at once.

### Features

- One-click install / uninstall, enable multi-session Remote Desktop
- Configure max sessions, single-session-per-user, security (NLA / security layer), display, timeouts and port
- Automatically detects your Windows build and repairs offsets after updates
- Self-healing watchdog (starts at boot, checks daily)
- 8 languages

### Quick start

```powershell
powershell -c "(irm https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

When the **UAC** prompt appears, click **Yes**, then choose **1** to install. For long-term or offline use, download below.

### Download from Release

Go to **[Releases](https://github.com/lcxxjmsg-cyber/rdp_warp_ps/releases)**, download `rdp_warp_ps-vX.Y.Z.zip`, extract it, then double-click **`start.bat`** (auto-elevates). Or run:

```powershell
.\rdpwarps.ps1 -Install    # silent install
.\rdpwarps.ps1 -Uninstall  # clean uninstall
```

### FAQ

**Q1: TermService stays stopped after install?**
Most likely **Smart App Control / Memory Integrity** (code-integrity) is blocking the unsigned rdpwrap. Turn off "Smart App Control" and "Memory Integrity", **reboot**, and add `C:\Program Files\rdpwarp` and `C:\rdpwarp` to Defender exclusions.

**Q2: Can I shadow another user's session?**
Client editions only allow shadowing **your own** sessions. Cross-user shadowing needs **Windows Server + RDS** (admin + the "Set rules for remote control" policy + reboot).

**Q3: "Admin required"?**
The script self-elevates automatically. If UAC is denied, right-click "Run as administrator" or use `start.bat`.

### Uninstall

Run `.\rdpwarps.ps1 -Uninstall` — it restores settings, removes deployed files, the watchdog and Defender exclusions.

### Requirements

- Windows 8.1 / 10 / 11, Windows Server 2008~2025
- PowerShell 5.1, administrator privileges
- Real support depends on your `termsrv.dll` version passing strict validation

### License

For use only on devices you own or are allowed to manage. Builds on community projects such as [stascorp/rdpwrap](https://github.com/stascorp/rdpwrap) and RDPWrapOffsetFinder.

---

# 简体中文

## rdpwarp — Windows 多会话远程桌面一键工具

> 让一台 Windows 电脑**同时支持多个用户远程桌面登录**，简单易用。

### 这是什么？

Windows 的「远程桌面」默认一次只允许一个用户登录。本工具借助 **RDP Wrapper（rdpwrap）** 解锁该限制，让多人可同时连接并使用同一台电脑。

### 它能做什么？

- 一键安装 / 卸载，开启多会话远程桌面
- 设置最大会话数、每用户单会话、安全级别（NLA / 安全层）、显示、超时、端口等
- 自动匹配当前系统版本，Windows 更新后自动修复偏移
- 看门狗自愈（开机自启 + 每日检查）
- 支持 8 种语言

### 快速开始

**方式一：能直连**

```powershell
powershell -c "(irm https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

**方式二：走代理（仅国内被 ISP 封锁时用）**

```powershell
powershell -c "$env:GH_MIRROR='https://gh-proxy.com/';(irm https://gh-proxy.com/https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

出现 **UAC** 提示点「是」，运行后选 **1** 一键安装。想长期 / 离线使用，请看下方下载。

### 从 Release 下载使用

前往 **[Releases](https://github.com/lcxxjmsg-cyber/rdp_warp_ps/releases)**，下载 `rdp_warp_ps-vX.Y.Z.zip`，解压后双击 **`start.bat`**（自动提权）。或运行：

```powershell
.\rdpwarps.ps1 -Install    # 静默安装
.\rdpwarps.ps1 -Uninstall  # 干净卸载
```

### 常见问题

**Q1：装完 TermService 还是停的？**
多半是 **Smart App Control / 内存完整性（代码完整性）** 拦了未签名的 rdpwrap。关闭「智能应用控制」和「内存完整性」，**重启**，并把 `C:\Program Files\rdpwarp`、`C:\rdpwarp` 加入 Defender 排除项。

**Q2：能影子别人的会话吗？**
客户端版只支持影子「自己」的会话；跨用户影子需 **Windows Server + RDS**（管理员 + 「设置远程控制的规则」策略 + 重启）。

**Q3：提示需要管理员权限？**
脚本会自动提权；若 UAC 被取消，请右键「以管理员身份运行」或双击 `start.bat`。

### 卸载

运行 `.\rdpwarps.ps1 -Uninstall`：恢复设置、删除已部署文件、移除看门狗与 Defender 排除项。

### 系统要求

- Windows 8.1 / 10 / 11，Windows Server 2008 ~ 2025
- PowerShell 5.1、管理员权限
- 实际支持取决于当前 `termsrv.dll` 版本能否通过严格校验

### 许可

请仅在你拥有或获准管理的设备上使用。基于 [stascorp/rdpwrap](https://github.com/stascorp/rdpwrap)、RDPWrapOffsetFinder 等社区项目构建。

---

# 日本語

## rdpwarp — Windows マルチセッション リモートデスクトップツール

> 1 台の Windows PC で**複数のユーザーが同時にリモートログイン**できるようにします。簡単に使えます。

### これは何？

Windows の「リモートデスクトップ」は通常 1 セッションしか同時に使えません。このツールは **RDP Wrapper（rdpwrap）** を使ってその制限を解除し、複数ユーザーが同時に接続・利用できるようにします。

### できること

- ワンクリックでインストール / アンインストール、マルチセッション有効化
- 最大セッション数、ユーザーごと 1 セッション、セキュリティ（NLA / セキュリティ層）、表示、タイムアウト、ポートを設定
- Windows のビルドを自動検出し、更新後のオフセットを自動修復
- 自己修復ウォッチドッグ（起動時 + 毎日チェック）
- 8 言語対応

### クイックスタート

```powershell
powershell -c "(irm https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

**UAC** のプロンプトが出たら「はい」を選び、**1** でインストール。長期 / オフライン利用は下記からダウンロード。

### リリースからダウンロード

**[Releases](https://github.com/lcxxjmsg-cyber/rdp_warp_ps/releases)** から `rdp_warp_ps-vX.Y.Z.zip` をダウンロードし、解凍後 **`start.bat`** をダブルクリック（自動昇格）。あるいは：

```powershell
.\rdpwarps.ps1 -Install    # サイレントインストール
.\rdpwarps.ps1 -Uninstall  # アンインストール
```

### よくある質問

**Q1：インストール後も TermService が停止したまま？**
おそらく **Smart App Control / メモリ整合性（コード整合性）** が未署名の rdpwrap をブロックしています。「Smart App Control」と「メモリ整合性」をオフにし、**再起動**。さらに `C:\Program Files\rdpwarp`、`C:\rdpwarp` を Defender の除外に追加。

**Q2：他人のセッションをシャドウできますか？**
クライアント版では**自分の**セッションのみシャドウ可能。ユーザー間のシャドウは **Windows Server + RDS** が必要（管理者 + 「リモート制御の規則を設定」ポリシー + 再起動）。

**Q3：「管理者権限が必要」と出ますか？**
スクリプトが自動昇格します。UAC が拒否されたら「管理者として実行」を右クリック、または `start.bat` を使用。

### アンインストール

`.\rdpwarps.ps1 -Uninstall` を実行すると、設定を復元し、配置ファイル・ウォッチドッグ・Defender 除外を削除します。

### 動作環境

- Windows 8.1 / 10 / 11、Windows Server 2008 ~ 2025
- PowerShell 5.1、管理者権限
- 実際の対応は `termsrv.dll` のバージョンが厳密な検証を通るかによります

### ライセンス

所有または管理を許可されたデバイスでのみ使用してください。[stascorp/rdpwrap](https://github.com/stascorp/rdpwrap)、RDPWrapOffsetFinder などのコミュニティプロジェクトを基にしています。

---

# 한국어

## rdpwarp — Windows 다중 세션 원격 데스크톱 도구

> Windows PC 한 대에서 **여러 사용자가 동시에 원격 로그인**할 수 있게 합니다. 간편합니다.

### 이것은 무엇인가요?

Windows의 원격 데스크톱은 기본적으로 한 사용자만 로그인할 수 있습니다. 이 도구는 **RDP Wrapper(rdpwrap)** 를 통해 그 제한을 풀어 여러 사용자가 동시에 접속해 사용할 수 있게 합니다.

### 기능

- 원클릭 설치 / 제거, 다중 세션 활성화
- 최대 세션 수, 사용자당 단일 세션, 보안(NLA / 보안 계층), 표시, 시간 초과, 포트 설정
- Windows 빌드를 자동 감지하고 업데이트 후 오프셋 자동 복구
- 자가 복구 워치독(시작 시 + 매일 확인)
- 8개 언어 지원

### 빠른 시작

```powershell
powershell -c "(irm https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

**UAC** 창이 뜨면 **예**를 클릭하고 **1** 을 선택해 설치하세요. 장기간 / 오프라인 사용은 아래에서 다운로드하세요.

### Release에서 다운로드

**[Releases](https://github.com/lcxxjmsg-cyber/rdp_warp_ps/releases)** 에서 `rdp_warp_ps-vX.Y.Z.zip` 을 다운로드하고 압축을 푼 뒤 **`start.bat`** 을 더블클릭(자동 상승)하세요. 또는:

```powershell
.\rdpwarps.ps1 -Install    # 자동 설치
.\rdpwarps.ps1 -Uninstall  # 정리 제거
```

### 자주 묻는 질문

**Q1: 설치 후에도 TermService가 멈춰 있나요?**
아마 **Smart App Control / 메모리 무결성(코드 무결성)** 이 서명되지 않은 rdpwrap을 차단한 것입니다. "Smart App Control"과 "메모리 무결성"을 끄고 **재부팅**하세요. `C:\Program Files\rdpwarp`, `C:\rdpwarp` 를 Defender 제외에 추가하세요.

**Q2: 다른 사용자의 세션을 섀도잉할 수 있나요?**
클라이언트 버전은 **자신의** 세션만 섀도잉할 수 있습니다. 사용자 간 섀도잉은 **Windows Server + RDS** 필요(관리자 + "원격 제어 규칙 설정" 정책 + 재부팅).

**Q3: 관리자 권한 필요?**
스크립트가 자동 상승합니다. UAC가 거부되면 "관리자 권한으로 실행"을 우클릭하거나 `start.bat` 을 사용하세요.

### 제거

`.\rdpwarps.ps1 -Uninstall` 을 실행하면 설정을 복원하고 배포 파일, 워치독, Defender 제외 항목을 제거합니다.

### 요구 사항

- Windows 8.1 / 10 / 11, Windows Server 2008 ~ 2025
- PowerShell 5.1, 관리자 권한
- 실제 지원은 `termsrv.dll` 버전이 엄격한 검증을 통과하는지에 달려 있습니다

### 라이선스

소유하거나 관리 권한이 있는 기기에서만 사용하세요. [stascorp/rdpwrap](https://github.com/stascorp/rdpwrap), RDPWrapOffsetFinder 등 커뮤니티 프로젝트 기반.

---

# Français

## rdpwarp — Bureau à distance multi-session pour Windows

> Permettez à un PC Windows d'accepter **plusieurs utilisateurs connectés à distance en même temps**. Simple à utiliser.

### Qu'est-ce que c'est ?

Le Bureau à distance de Windows n'autorise normalement qu'une seule session à la fois. Cet outil utilise **RDP Wrapper (rdpwrap)** pour lever cette limite et permettre à plusieurs utilisateurs de se connecter et d'utiliser le même PC simultanément.

### Fonctionnalités

- Installation / désinstallation en un clic, activer la multi-session
- Configurer le nombre max de sessions, une session par utilisateur, la sécurité (NLA / couche de sécurité), l'affichage, les délais et le port
- Détecte automatiquement votre build Windows et répare les offsets après les mises à jour
- Gardien auto-réparateur (démarrage + vérification quotidienne)
- 8 langues

### Démarrage rapide

```powershell
powershell -c "(irm https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

Quand l'invite **UAC** apparaît, cliquez sur **Oui**, puis choisissez **1** pour installer. Pour un usage à long terme ou hors ligne, téléchargez ci-dessous.

### Télécharger depuis les Releases

Allez dans **[Releases](https://github.com/lcxxjmsg-cyber/rdp_warp_ps/releases)**, téléchargez `rdp_warp_ps-vX.Y.Z.zip`, décompressez, puis double-cliquez sur **`start.bat`** (élévation auto). Ou :

```powershell
.\rdpwarps.ps1 -Install    # installation silencieuse
.\rdpwarps.ps1 -Uninstall  # désinstallation propre
```

### FAQ

**Q1 : TermService reste arrêté après l'installation ?**
Il s'agit probablement de **Smart App Control / Intégrité de la mémoire** (code integrity) qui bloque le rdpwrap non signé. Désactivez « Smart App Control » et « Intégrité de la mémoire », **redémarrez**, et ajoutez `C:\Program Files\rdpwarp` et `C:\rdpwarp` aux exclusions de Defender.

**Q2 : Puis-je surveiller la session d'un autre utilisateur ?**
Les éditions client ne permettent que de surveiller **vos propres** sessions. La surveillance entre utilisateurs nécessite **Windows Server + RDS** (admin + la règle « Définir les règles de contrôle à distance » + redémarrage).

**Q3 : « Droits administrateur requis » ?**
Le script s'élève automatiquement. Si l'UAC est refusé, faites un clic droit « Exécuter en tant qu'administrateur » ou utilisez `start.bat`.

### Désinstallation

Exécutez `.\rdpwarps.ps1 -Uninstall` : restaure les paramètres, supprime les fichiers déployés, le gardien et les exclusions Defender.

### Configuration requise

- Windows 8.1 / 10 / 11, Windows Server 2008 ~ 2025
- PowerShell 5.1, privilèges administrateur
- La prise en charge réelle dépend de la validation stricte de votre version `termsrv.dll`

### Licence

À utiliser uniquement sur des appareils que vous possédez ou que vous êtes autorisé à gérer. Construit sur des projets communautaires comme [stascorp/rdpwrap](https://github.com/stascorp/rdpwrap) et RDPWrapOffsetFinder.

---

# Deutsch

## rdpwarp — Multisession-Remotedesktop für Windows

> Ermöglicht, dass sich **mehrere Benutzer gleichzeitig remote an einem Windows-PC anmelden**. Einfach zu bedienen.

### Was ist das?

Das Windows-Remotedesktop erlaubt normalerweise nur eine Sitzung gleichzeitig. Dieses Tool nutzt **RDP Wrapper (rdpwrap)**, um diese Grenze aufzuheben, sodass mehrere Benutzer gleichzeitig auf denselben PC zugreifen können.

### Funktionen

- Ein-Klick-Installation / Deinstallation, Multisession aktivieren
- Max. Sitzungen, Einzelsitzung pro Benutzer, Sicherheit (NLA / Sicherheitsebene), Anzeige, Timeouts und Port konfigurieren
- Erkennt Ihren Windows-Build automatisch und repariert Offsets nach Updates
- Selbstheilender Watchdog (Start + tägliche Prüfung)
- 8 Sprachen

### Schnellstart

```powershell
powershell -c "(irm https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

Wenn die **UAC**-Abfrage erscheint, klicken Sie auf **Ja**, dann wählen Sie **1** für die Installation. Für langfristige oder Offline-Nutzung laden Sie es unten herunter.

### Von den Releases herunterladen

Öffnen Sie **[Releases](https://github.com/lcxxjmsg-cyber/rdp_warp_ps/releases)**, laden Sie `rdp_warp_ps-vX.Y.Z.zip` herunter, entpacken Sie es und doppelklicken Sie dann auf **`start.bat`** (automatische Höherstufung). Oder:

```powershell
.\rdpwarps.ps1 -Install    # stille Installation
.\rdpwarps.ps1 -Uninstall  # saubere Deinstallation
```

### FAQ

**F1: TermService bleibt nach der Installation gestoppt?**
Wahrscheinlich blockiert **Smart App Control / Speicher-Integrität** (Code-Integrität) das unsignierte rdpwrap. Deaktivieren Sie „Smart App Control" und „Speicher-Integrität", **starten Sie neu** und fügen Sie `C:\Program Files\rdpwarp` und `C:\rdpwarp` zu den Defender-Ausschlüssen hinzu.

**F2: Kann ich die Sitzung eines anderen Benutzers mitverfolgen?**
Client-Editionen erlauben nur das Mitverfolgen **Ihrer eigenen** Sitzungen. Benutzerübergreifendes Mitverfolgen erfordert **Windows Server + RDS** (Admin + die Richtlinie „Regeln zur Fernsteuerung festlegen" + Neustart).

**F3: „Administratorrechte erforderlich"?**
Das Skript stuft sich automatisch hoch. Wird UAC abgelehnt, rechtsklicken Sie auf „Als Administrator ausführen" oder verwenden Sie `start.bat`.

### Deinstallation

Führen Sie `.\rdpwarps.ps1 -Uninstall` aus: stellt die Einstellungen wieder her und entfernt bereitgestellte Dateien, Watchdog und Defender-Ausschlüsse.

### Systemanforderungen

- Windows 8.1 / 10 / 11, Windows Server 2008 ~ 2025
- PowerShell 5.1, Administratorrechte
- Die tatsächliche Unterstützung hängt davon ab, ob Ihre `termsrv.dll`-Version die strenge Prüfung besteht

### Lizenz

Nur auf Geräten verwenden, die Sie besitzen oder verwalten dürfen. Basiert auf Community-Projekten wie [stascorp/rdpwrap](https://github.com/stascorp/rdpwrap) und RDPWrapOffsetFinder.

---

# Español

## rdpwarp — Escritorio remoto multisesión para Windows

> Permite que una PC con Windows acepte **varios usuarios conectados de forma remota a la vez**. Fácil de usar.

### ¿Qué es?

El Escritorio remoto de Windows normalmente permite solo una sesión a la vez. Esta herramienta usa **RDP Wrapper (rdpwrap)** para eliminar ese límite y permitir que varios usuarios se conecten y usen la misma PC simultáneamente.

### Funciones

- Instalación / desinstalación con un clic, activar la multisesión
- Configurar máx. sesiones, una sesión por usuario, seguridad (NLA / capa de seguridad), pantalla, tiempos de espera y puerto
- Detecta automáticamente tu compilación de Windows y repara los offsets tras las actualizaciones
- Vigilante auto-reparable (inicio + revisión diaria)
- 8 idiomas

### Inicio rápido

```powershell
powershell -c "(irm https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

Cuando aparezca el aviso **UAC**, haz clic en **Sí** y luego elige **1** para instalar. Para uso a largo plazo u offline, descarga a continuación.

### Descargar desde Releases

Ve a **[Releases](https://github.com/lcxxjmsg-cyber/rdp_warp_ps/releases)**, descarga `rdp_warp_ps-vX.Y.Z.zip`, descomprímelo y haz doble clic en **`start.bat`** (elevación automática). O ejecuta:

```powershell
.\rdpwarps.ps1 -Install    # instalación silenciosa
.\rdpwarps.ps1 -Uninstall  # desinstalación limpia
```

### Preguntas frecuentes

**P1: ¿TermService queda detenido tras la instalación?**
Lo más probable es que **Smart App Control / Integridad de la memoria** (code integrity) bloquee el rdpwrap sin firmar. Desactiva «Smart App Control» e «Integridad de la memoria», **reinicia** y añade `C:\Program Files\rdpwarp` y `C:\rdpwarp` a las exclusiones de Defender.

**P2: ¿Puedo ver la sesión de otro usuario?**
Las ediciones de cliente solo permiten ver **tus propias** sesiones. La visualización entre usuarios requiere **Windows Server + RDS** (admin + la política «Establecer reglas para el control remoto» + reinicio).

**P3: ¿«Se requieren privilegios de administrador»?**
El script se eleva automáticamente. Si se rechaza el UAC, haz clic derecho en «Ejecutar como administrador» o usa `start.bat`.

### Desinstalación

Ejecuta `.\rdpwarps.ps1 -Uninstall`: restaura la configuración y elimina los archivos desplegados, el vigilante y las exclusiones de Defender.

### Requisitos

- Windows 8.1 / 10 / 11, Windows Server 2008 ~ 2025
- PowerShell 5.1, privilegios de administrador
- El soporte real depende de que tu versión de `termsrv.dll` pase una validación estricta

### Licencia

Úsalo solo en dispositivos que poseas o que tengas permiso de administrar. Se basa en proyectos comunitarios como [stascorp/rdpwrap](https://github.com/stascorp/rdpwrap) y RDPWrapOffsetFinder.

---

# Русский

## rdpwarp — Многосеансовый удалённый рабочий стол для Windows

> Позволяет одному ПК с Windows принимать **несколько пользователей одновременно** по удалённому доступу. Просто в использовании.

### Что это?

Удалённый рабочий стол Windows обычно допускает только одну сессию одновременно. Этот инструмент использует **RDP Wrapper (rdpwrap)**, чтобы снять это ограничение и позволить нескольким пользователям одновременно подключаться и использовать один ПК.

### Возможности

- Установка / удаление в один клик, включение многосеансового режима
- Настройка макс. числа сессий, одной сессии на пользователя, безопасности (NLA / уровень безопасности), отображения, тайм-аутов и порта
- Автоматически определяет вашу сборку Windows и чинит смещения после обновлений
- Самовосстанавливающийся сторож (при старте + ежедневная проверка)
- 8 языков

### Быстрый старт

```powershell
powershell -c "(irm https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

Когда появится запрос **UAC**, нажмите **Да**, затем выберите **1** для установки. Для длительного или офлайн-использования скачайте ниже.

### Скачать из Release

Откройте **[Releases](https://github.com/lcxxjmsg-cyber/rdp_warp_ps/releases)**, скачайте `rdp_warp_ps-vX.Y.Z.zip`, распакуйте и дважды щёлкните **`start.bat`** (автоповышение). Или выполните:

```powershell
.\rdpwarps.ps1 -Install    # тихая установка
.\rdpwarps.ps1 -Uninstall  # чистое удаление
```

### Частые вопросы

**В1: TermService остаётся остановленным после установки?**
Скорее всего **Smart App Control / Целостность памяти** (целостность кода) блокирует неподписанный rdpwrap. Отключите «Smart App Control» и «Целостность памяти», **перезагрузитесь** и добавьте `C:\Program Files\rdpwarp` и `C:\rdpwarp` в исключения Defender.

**В2: Могу ли я наблюдать сессию другого пользователя?**
Клиентские издания позволяют наблюдать только **свои** сессии. Наблюдение между пользователями требует **Windows Server + RDS** (админ + политика «Задать правила удалённого управления» + перезагрузка).

**В3: «Требуются права администратора»?**
Скрипт повышает права автоматически. Если UAC отклонён, щёлкните правой кнопкой «Запуск от имени администратора» или используйте `start.bat`.

### Удаление

Запустите `.\rdpwarps.ps1 -Uninstall`: восстановит настройки и удалит развёрнутые файлы, сторожа и исключения Defender.

### Требования

- Windows 8.1 / 10 / 11, Windows Server 2008 ~ 2025
- PowerShell 5.1, права администратора
- Реальная поддержка зависит от прохождения строгой проверки вашей версией `termsrv.dll`

### Лицензия

Используйте только на устройствах, которыми владеете или управляете. Основано на общественных проектах, таких как [stascorp/rdpwrap](https://github.com/stascorp/rdpwrap) и RDPWrapOffsetFinder.
