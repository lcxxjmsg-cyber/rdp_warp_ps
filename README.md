# rdpwarp

Windows 多会话 RDP 一键部署工具。在任意 Windows 版本上启用多用户同时远程桌面登录。

## 一键启动

以管理员身份打开 PowerShell，粘贴以下命令：

```powershell
powershell "$env:GH_MIRROR = 'https://gh-proxy.com/';& ([scriptblock]::Create((irm 'https://gh-proxy.com/https://raw.githubusercontent.com/lcxxjmsg-cyber/GitHub-Script-Entrance/main/launch.ps1'))) -r 'https://github.com/lcxxjmsg-cyber/rdp_warp_ps/blob/main/rdpwarps.ps1'"
```

脚本会自动提权到管理员，进入交互菜单。选 **1** 即可一键安装。

> 如果所在网络能直连 GitHub，去掉 `GH_MIRROR`：
> ```powershell
> powershell "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/lcxxjmsg-cyber/GitHub-Script-Entrance/main/launch.ps1'))) -r 'https://github.com/lcxxjmsg-cyber/rdp_warp_ps/blob/main/rdpwarps.ps1'"
> ```

## 功能

- 一键安装/卸载 rdpwrap，启用多会话 RDP
- 会话设置（最大并发数、每用户单会话）
- 安全设置（NLA、安全层）
- 影子模式（远程协助控制）
- 显示选项（多显示器、自动重连）
- 会话超时设置
- RDP 端口更改
- 看门狗（开机自启 + 每日自动更新 INI 偏移）
- RemoteApp 连接文件生成
- 支持 8 种语言（中文、English、日本語、한국어、Français、Deutsch、Español、Русский）
- 系统语言自动检测，启动时选择

## 本地运行

```powershell
# 1. 克隆仓库
git clone https://github.com/lcxxjmsg-cyber/rdp_warp_ps.git
cd rdp_warp_ps

# 2. 以管理员身份运行
.\rdpwarps.ps1
```

本地运行时 `bin/` 目录中的二进制文件会被优先使用，无需联网下载。

## 静默安装

```powershell
.\rdpwarps.ps1 -Install
```

## 静默卸载

```powershell
.\rdpwarps.ps1 -Uninstall
```

## 依赖与致谢

本项目使用了以下开源项目：

| 项目 | 用途 |
|------|------|
| [stascorp/rdpwrap](https://github.com/stascorp/rdpwrap) | RDP Wrapper Library，核心的多会话 RDP 支持 |
| [llccd/RDPWrapOffsetFinder](https://github.com/llccd/RDPWrapOffsetFinder) | 自动计算 termsrv.dll 偏移，生成 rdpwrap.ini |
| [lcxxjmsg-cyber/GitHub-Script-Entrance](https://github.com/lcxxjmsg-cyber/GitHub-Script-Entrance) | 一键远程启动脚本，支持管理员提权和网络加速 |

## 系统要求

- Windows Vista / 7 / 8 / 8.1 / 10 / 11
- Windows Server 2008 ~ 2025
- 管理员权限

## 注意事项

- 安装后会自动注册看门狗（开机启动 + 每日 3AM 更新），确保 Windows 更新后 RDP 功能正常
- 支持 GFW 网络环境，通过 `GH_MIRROR` 环境变量配置代理镜像
- RemoteApp 功能需要 Windows Enterprise 或 Server 版本
