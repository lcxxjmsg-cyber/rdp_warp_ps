# rdpwarp

Windows 多会话 RDP 部署与维护脚本，集成 RDP Wrapper、社区 INI、OffsetFinder、运行时健康检查、端口与防火墙管理以及自动修复看门狗。

> 当前脚本版本：**2.6.7**
>
> 本项目不承诺支持所有 Windows 构建。只有配置校验、服务启动、端口监听、RDP 协议握手和补丁日志检查全部通过后，脚本才会报告 **Supported**；否则会明确报告不支持或配置无效。

## 一键启动

### 方式一：CMD / 管理员 PowerShell（推荐）

```powershell
powershell -c "$env:GH_MIRROR='https://gh-proxy.com/';irm https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1|iex"
```

> 能直连 GitHub 则更短：
> ```powershell
> powershell -c "irm https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1|iex"
> ```

### 方式二：Win+R 运行

Win+R 输入 `powershell`，按 `Ctrl+Shift+Enter`（以管理员身份运行），在弹出的蓝色窗口中粘贴方式一的命令。

### 方式三：自动提权（完整版）

从普通命令行启动，自动弹出 UAC 提权：

```powershell
powershell "$env:GH_MIRROR='https://gh-proxy.com/';& ([scriptblock]::Create((irm 'https://gh-proxy.com/https://raw.githubusercontent.com/lcxxjmsg-cyber/GitHub-Script-Entrance/main/launch.ps1'))) -r 'https://github.com/lcxxjmsg-cyber/rdp_warp_ps/blob/main/rdpwarps.ps1'"
```

进入菜单后选 **1** 即可一键安装。

## 功能

- 一键安装/卸载 rdpwrap，启用多会话 RDP
- 安装前检查 termsrv.dll、TermService 和 RDP-Tcp 组件；保留系统当前有效 RDP 端口并开放对应 TCP/UDP 防火墙规则，仅在端口缺失或无效时回退到 3389
- 会话设置（最大并发数、每用户单会话）
- 安全设置（NLA、安全层）
- 影子模式（远程协助控制）
- 显示选项（多显示器、自动重连）
- 会话超时设置
- 可靠的 RDP 端口迁移：占用检查、先开新防火墙、监听验证、失败回滚、关闭旧端口规则
- 默认将远程会话最大帧率上限配置为 60 FPS（实际帧率取决于系统、客户端、硬件和网络，需重启）
- 看门狗（开机自启 + 每日自动更新 INI 偏移）
- 严格区分 Unsupported、InvalidConfig、Configured 和经运行验证的 Supported
- 依次验证 asmtron、sebaxakerhtc、affinityv 社区 INI，拒绝不完整或损坏的版本段
- 社区 INI 按当前版本区块安全合并，保留其他版本和用户自定义内容
- 社区没有有效配置时使用匹配当前 PowerShell 架构的 x64/x86 OffsetFinder 生成候选，校验通过后才写入
- 对官方发布包、rdpwrap.dll 和 OffsetFinder 执行 SHA-256 完整性校验
- 安装前保存系统状态；关键步骤失败自动回滚，卸载时恢复原始配置
- 安装时将 TermService 隔离到独立服务宿主，确保停止/启动后重新加载 rdpwrap.dll；卸载时恢复原服务类型
- 修改端口后验证 TCP 监听和 RDP X.224 协议握手，失败自动恢复旧端口
- RemoteApp 连接文件生成
- 支持 8 种语言（中文、English、日本語、한국어、Français、Deutsch、Español、Русский）
- 系统语言自动检测，启动时选择

## 本地运行

```powershell
git clone https://github.com/lcxxjmsg-cyber/rdp_warp_ps.git
cd rdp_warp_ps
.\rdpwarps.ps1
```

本地运行时 `bin/` 目录中的文件被优先使用，无需联网下载。

## 静默安装 / 卸载

```powershell
.\rdpwarps.ps1 -Install
.\rdpwarps.ps1 -Uninstall
```

国内网络可指定 GitHub 代理。脚本优先使用代理，代理失败后自动尝试 GitHub 直连：

```powershell
.\rdpwarps.ps1 -GHMirror 'https://gh-proxy.com/'
```

只有在社区 INI 和符号版 OffsetFinder 均失败、并且已准备在虚拟机测试时，才建议显式启用无符号模式扫描：

```powershell
.\rdpwarps.ps1 -ExperimentalNoSym
```

`ExperimentalNoSym` 默认关闭，也不会被无人值守 watchdog 自动启用。

## 严格支持判定

脚本不会仅因为 INI 中存在当前版本号就判断支持。

| 状态 | 含义 |
|------|------|
| Unsupported | 没有适用于当前 termsrv.dll 的完整配置，或无法生成有效候选 |
| InvalidConfig | 找到了版本段，但字段、补丁码或结构不完整 |
| Configured | 静态配置完整，但尚未通过运行时验证 |
| Supported | 服务、监听、RDP 协议握手和最新 DLL 初始化日志均验证成功 |

运行时检查只读取当前版本日志中的**最新一次初始化块**，旧日志里的成功记录不会掩盖当前失败。协议握手能证明目标端口运行的是 RDP 服务，但不等于真实账号登录；正式部署后仍建议从另一台设备实际登录测试。

## 安装回滚与卸载恢复

安装前会保存 ServiceDll、RDP 开关和端口、会话与安全策略、60 FPS 设置、TermService 状态以及本次新增的 Defender 排除项。

二进制部署、INI 获取、注册表写入、服务启动或运行时验证失败时，安装会自动回滚，并且不会报告安装成功。正常卸载会根据安装快照恢复原始设置。快照位于 %ProgramData%\rdpwarp\install-state.json，请不要在卸载前手动删除。

如果没有新版本状态快照，卸载会进入旧版兼容模式：恢复系统 termsrv.dll，保留当前有效 RDP 端口，保持原生远程桌面开启，重建该端口的 TCP/UDP 防火墙规则，并验证原生监听与协议握手。安装前也会检查 RDP-Tcp 核心注册表项，防止在旧脚本已经破坏监听器配置时继续覆盖。

## OffsetFinder 与手工适配

配置查找顺序为：本地 INI、三个社区 INI、匹配架构的 OffsetFinder。所有方法均失败时会明确报告 Unsupported。

OffsetFinder 无法保证覆盖所有 Windows 构建。微软符号不可用、扫描规则未覆盖新代码结构或输出不完整时，仍需人工分析 termsrv.dll。人工适配应记录 DLL 四段版本和 SHA-256，在 IDA、Ghidra 或 x64dbg 中确认补丁位置，并在隔离虚拟机中验证服务、日志、监听、并发会话和重连。不能把“服务没有崩溃”当成兼容性验证通过。

## 看门狗行为

看门狗检查服务、端口监听和最新补丁日志，先尝试重启 TermService 自愈，再依次尝试社区 INI 和 OffsetFinder；新配置运行失败时恢复备份。它只能修复已有来源能够覆盖的版本，不会把未知版本强行标记为支持。

## 依赖与致谢

本项目使用了以下开源项目：

| 项目 | 用途 |
|------|------|
| [stascorp/rdpwrap](https://github.com/stascorp/rdpwrap) | RDP Wrapper Library，核心的多会话 RDP 支持 |
| [llccd/RDPWrapOffsetFinder](https://github.com/llccd/RDPWrapOffsetFinder) | 自动计算 termsrv.dll 偏移，生成 rdpwrap.ini |
| [asmtron/rdpwrap](https://github.com/asmtron/rdpwrap) | 社区 INI 与自动更新机制参考 |
| [sebaxakerhtc/rdpwrap.ini](https://github.com/sebaxakerhtc/rdpwrap.ini) | 社区 INI 来源 |
| [affinityv/INI-RDPWRAP](https://github.com/affinityv/INI-RDPWRAP) | 社区 INI 备用来源 |
| [lcxxjmsg-cyber/GitHub-Script-Entrance](https://github.com/lcxxjmsg-cyber/GitHub-Script-Entrance) | 一键远程启动脚本，支持管理员提权和网络加速 |

## 系统要求

- 主要面向 Windows 8.1 / 10 / 11；Vista / 7 / 8 的旧式 INI 结构仍需单独验证
- Windows Server 2008 ~ 2025
- Windows PowerShell 5.1
- 管理员权限

以上范围表示脚本能够识别和尝试部署，并不表示每一个累积更新版本都已有偏移配置。实际支持取决于当前 termsrv.dll 精确版本能否通过严格运行时验证。

## 注意事项

- 安装后自动注册看门狗（开机启动 + 每日 3AM 更新），Windows 更新后自动修复 RDP
- 不支持网络直连 GitHub 时，通过 `GH_MIRROR` 环境变量或 `-GHMirror` 配置代理镜像；代理失败会自动回退直连
- RemoteApp 功能需要 Windows Enterprise 或 Server 版本
- 修改端口或重启 TermService 会中断现有连接，脚本禁止在活动 RDP 会话中执行危险的端口迁移
- Windows 累积更新可能更换 termsrv.dll，更新后必须重新检查，不能沿用旧支持结论
- 建议在虚拟机或具备本地控制台、带外管理能力的设备上首次测试

## 免责声明

请仅在你拥有或获准管理的设备上使用，并自行确认 Microsoft 授权条款及当地法规。本项目与 Microsoft 及所引用的社区项目不存在隶属关系。
