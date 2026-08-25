🌐 **语言 / Language**: [English](README.md) | [简体中文](README.zh-CN.md)

# rdpwarp — Windows 多会话远程桌面一键工具

> 让一台 Windows 电脑**同时支持多个用户远程桌面登录**，简单易用。

## 目录

- [这是什么？](#这是什么)
- [它能做什么？](#它能做什么)
- [快速开始](#快速开始)
- [从 Release 下载使用](#从-release-下载使用)
- [常见问题](#常见问题)
- [卸载](#卸载)
- [系统要求](#系统要求)
- [许可](#许可)

## 这是什么？

Windows 的「远程桌面」默认一次只允许一个用户登录。本工具借助 **RDP Wrapper（rdpwrap）** 解锁该限制，让多人可同时连接并使用同一台电脑。

## 它能做什么？

- 一键安装 / 卸载，开启多会话远程桌面
- 设置最大会话数、每用户单会话、安全级别（NLA / 安全层）、显示、超时、端口等
- 自动匹配当前系统版本，Windows 更新后自动修复偏移
- 看门狗自愈（开机自启 + 每日检查）
- 支持 8 种语言

## 快速开始

**方式一：能直连**

```powershell
powershell -c "(irm https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

**方式二：走代理（仅国内被 ISP 封锁时用）**

```powershell
powershell -c "$env:GH_MIRROR='https://gh-proxy.com/';(irm https://gh-proxy.com/https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

出现 **UAC** 提示点「是」，运行后选 **1** 一键安装。想长期 / 离线使用，请看下方下载。

## 从 Release 下载使用

前往 **[Releases](https://github.com/lcxxjmsg-cyber/rdp_warp_ps/releases)**，下载 `rdp_warp_ps-vX.Y.Z.zip`，解压后双击 **`start.bat`**（自动提权）。或运行：

```powershell
.\rdpwarps.ps1 -Install    # 静默安装
.\rdpwarps.ps1 -Uninstall  # 干净卸载
```

## 常见问题

**Q1：装完 TermService 还是停的？**
多半是 **Smart App Control / 内存完整性（代码完整性）** 拦了未签名的 rdpwrap。关闭「智能应用控制」和「内存完整性」，**重启**，并把 `C:\Program Files\rdpwarp`、`C:\rdpwarp` 加入 Defender 排除项。

**Q2：能影子别人的会话吗？**
客户端版只支持影子「自己」的会话；跨用户影子需 **Windows Server + RDS**（管理员 + 「设置远程控制的规则」策略 + 重启）。

**Q3：提示需要管理员权限？**
脚本会自动提权；若 UAC 被取消，请右键「以管理员身份运行」或双击 `start.bat`。

## 卸载

运行 `.\rdpwarps.ps1 -Uninstall`：恢复设置、删除已部署文件、移除看门狗与 Defender 排除项。

## 系统要求

- Windows 8.1 / 10 / 11，Windows Server 2008 ~ 2025
- PowerShell 5.1、管理员权限
- 实际支持取决于当前 `termsrv.dll` 版本能否通过严格校验

## 许可

请仅在你拥有或获准管理的设备上使用。基于 [stascorp/rdpwrap](https://github.com/stascorp/rdpwrap)、RDPWrapOffsetFinder 等社区项目构建。
