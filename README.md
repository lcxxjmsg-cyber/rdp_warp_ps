# rdpwarp — Windows 多会话远程桌面一键工具

> 一句话：让一台 Windows 电脑**同时支持多个用户远程桌面登录**。小白也能用。

## 目录

- [这是什么？](#这是什么)
- [它能做什么？](#它能做什么)
- [快速开始](#快速开始)
- [从 Release 下载使用](#从-release-下载使用)
- [命令行参数](#命令行参数)
- [常见问题](#常见问题)
- [卸载](#卸载)
- [系统要求](#系统要求)
- [进阶 / 技术说明](#进阶--技术说明)
- [致谢与免责声明](#致谢与免责声明)

## 这是什么？

Windows 的「远程桌面」默认一次只允许一个用户登录。这个工具借助 **RDP Wrapper（rdpwrap）** 解锁系统限制，让同一台电脑可以多人同时远程登录、各自使用。

## 它能做什么？

- 一键安装 / 卸载，开启多会话远程桌面
- 设置最大会话数、每用户单会话、安全级别（NLA / 安全层）、显示、超时、端口等
- 自动匹配当前系统版本，Windows 更新后自动修复偏移
- 看门狗自愈（开机自启 + 每日检查）
- 支持 8 种语言

## 快速开始

### 方法一：本地运行（最推荐）

1. **方式 a**：双击 **`start.bat`**。
2. **方式 b**：打开 PowerShell，进入脚本所在文件夹，运行：

```powershell
.\rdpwarps.ps1
```

> - 脚本会自动弹出 **UAC 提权**。若被取消，请右键「以管理员身份运行」。
> - 进入菜单选 **1** = 一键安装；选 **0** = 卸载。

### 方法二：远程执行（不下载，先体验）

```powershell
powershell -c "irm https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1|iex"
```

> 国内网络可加代理前缀：`$env:GH_MIRROR='https://gh-proxy.com/';`
> ⚠ 这种运行方式**无法自动提权**；需要管理员权限请用「方法一」。选 **1** 一键安装。

### 方法三：静默安装 / 卸载

```powershell
.\rdpwarps.ps1 -Install      # 静默一键安装
.\rdpwarps.ps1 -Uninstall    # 干净卸载
```

## 从 Release 下载使用

直接下载打包好的版本最省事（内含 `rdpwarps.ps1`、`start.bat`、`bin/`、`README.md`，解压即用）：

> 前往 **[Releases](https://github.com/lcxxjmsg-cyber/rdp_warp_ps/releases)**，下载最新的 `rdp_warp_ps-vX.Y.Z.zip`，**解压后双击 `start.bat`** 即可。

## 命令行参数

| 参数 | 作用 |
|---|---|
| `-Install` | 静默一键安装 |
| `-Uninstall` | 干净卸载 |
| `-Help` | 查看帮助 |
| `-GHMirror <url>` | 指定 GitHub 代理镜像 |
| `-ExperimentalNoSym` | 启用无符号模式扫描（测试用，默认关闭） |

## 常见问题

**Q1：装完提示 TermService 停了？**
多半是系统「智能应用控制 / 内存完整性 / 代码完整性」拦了未签名的 rdpwrap（日志有 `did not meet the Enterprise signing level requirements`）。
→ 关闭「智能应用控制」和「内存完整性」，**重启**；并把 `C:\Program Files\rdpwarp`、`C:\rdpwarp` 加入 Defender 排除项。

**Q2：能多人同时登录了，但要影子别人的会话会提示拒绝访问？**
客户端版只支持影子「自己」的会话；跨用户影子需要 **Windows Server + RDS**，且要管理员 + 启用组策略「设置远程控制的规则」+ 重启。

**Q3：提示需要管理员权限？**
脚本会自动提权；若被 UAC 取消，请右键「以管理员身份运行」或直接双击 `start.bat`。

**Q4：我的 Windows 版本支持吗？**
只有配置、服务、监听、协议握手全部通过，脚本才报 **Supported**；否则明确报 **Unsupported / InvalidConfig**，未知版本不会假装支持。

## 卸载

运行 `.\rdpwarps.ps1 -Uninstall`，脚本会恢复安装前的系统设置、删除已部署文件、移除看门狗与 Defender 排除项。

## 系统要求

- Windows 8.1 / 10 / 11，Windows Server 2008 ~ 2025
- PowerShell 5.1、管理员权限
- 实际支持取决于当前 `termsrv.dll` 版本能否通过严格校验

## 进阶 / 技术说明

> 以下供维护者与进阶用户参考，普通用户无需关心。

- **配置查找顺序**：本地 INI → 三个社区 INI（asmtron / sebaxakerhtc / affinityv）→ OffsetFinder 自动生成。
- **安全性**：安装前保存系统状态，关键步骤失败自动回滚；卸载恢复原配置并对二进制/INI 做 SHA-256 校验。
- **看门狗**：开机自启 + 每日 03:00，自动更新偏移并自愈。
- **影子 / 远程控制**：客户端版仅同用户会话可用；跨用户需 Server + RDS。

## 致谢与免责声明

借鉴并感谢 [stascorp/rdpwrap](https://github.com/stascorp/rdpwrap)、[llccd/RDPWrapOffsetFinder](https://github.com/llccd/RDPWrapOffsetFinder) 及 asmtron / sebaxakerhtc / affinityv 等社区项目。

请仅在你拥有或获准管理的设备上使用，并自行确认 Microsoft 授权条款及当地法规。本项目与 Microsoft 及所引用的社区项目无隶属关系。
