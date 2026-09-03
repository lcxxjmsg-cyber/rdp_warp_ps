🌐 **语言 / Language**: [English](Shadow-README.md) | [简体中文](Shadow-README.zh-CN.md)

# Shadow（远程控制 / 会话影子）使用说明

> 影子（Session Shadow / Remote Control）指用一个会话**查看 / 控制另一个会话**。本工具把它做成一条可靠链路：**本机影子** 和 **跨机远程影子** 都支持。

## 两种影子方式

| 方式 | 命令 | 适用 |
|---|---|---|
| **本机影子** | `mstsc /shadow:<会话ID> /control [/noConsentPrompt]` | 同一台机器上影另一个会话 |
| **跨机远程影子** | `mstsc /v:<主机> /shadow:<会话ID> /control /noConsentPrompt /prompt` | 从另一台机器影目标机会话 |

## Windows 影子机制（官方行为）

- **端口**：影子不走 3389，而是 **139/TCP、445/TCP + 动态 RPC(49152~65535)**。需放行防火墙规则：
  `File and Printer Sharing (SMB-In)`（文件和打印机共享）+ `Remote Desktop - Shadow (TCP-In)`（后者放行 `RdpSa.exe`）。
- **权限**：你的账户须是**目标机本地管理员**；调用方需拥有目标 `WINSTATION_SHADOW`(0x10)。
- **模式**：由「远程控制」策略(此 `Shadow` 值)决定：`0=禁用` `1=完全/需同意` `2=完全/免同意` `3=查看/需同意` `4=查看/免同意`。
- **凭据**：`mstsc /v` 跨机时，**加 `/prompt` 用你输入的凭据**；**不加 `/prompt` 则用当前用户凭据**。
- **同意**：即使模式=免同意，目标也可弹「`PC\admin` 请求查看您的会话，是否接受」；`/noConsentPrompt` 关闭该提示。
- **交互**：`/control` 才能控制鼠标键盘；不带为**仅查看**。
- **限制**：目标会话锁屏 / 有 UAC 安全桌面弹窗时，影子会**黑屏/暂停**；**同一会话只能被影一次**(RDP 协议限制)。注：**`console` 会话其实能被影**（实测；部分微软文档称不能，本机行为并非如此）。

## ⚠ 关键实操差异（实测）

- **本机**：只要有管理员权限，**A 账户可任意影 B 账户**的会话。
- **跨机（测试场景）**：**必须使用「对应目标会话(SID)的账户」的凭证**才有效——用其它管理员账户跨机影会被拒。这是实战观察（rdpwrap 客户端场景），行为可能因 build 而异；遇到请改用目标会话用户的凭据（`-User/-Password` 或 `/prompt`）。

## 用本工具发起影子

交互菜单：**影子 → 3（本机）/ 4（远程）/ 5（诊断）**。或直接调用：

```powershell
# 本机影子（按目标用户每用户->全局策略自动定 /control 与 /noConsentPrompt）
Invoke-RdpShadow -SessionId 7

# 跨机远程影子（自动 /v；提供 -User 则先 cmdkey 缓存凭据，否则 /prompt 弹窗输入）
Invoke-RdpShadow -Remote <主机> -SessionId 7 -User <目标授权账户> -Password '<密码>'
Invoke-RdpShadow -Remote <主机> -SessionId 7        # 连接时弹窗输凭据
```

参数：`-SessionId` / `-Remote <主机>` / `-User/-Password`（cmdkey 缓存）/ `-ForceConsent`、`-ForceNoConsent`、`-ViewOnly`。

## 影子防火墙（工具菜单「影子 → 6 启用影子防火墙」）

- 影子经 **SMB/RPC(139/445 + 动态 RPC)** 建立，**与 RDP 监听端口无关**。工具会自动放行：
  `Remote Desktop - Shadow (TCP-In)`(放行 RdpSa.exe) + `文件和打印机共享 SMB(445)/NB-Session(139)/RPC-EPMAP(135)`。
- ⚠ **端口固定，无法像 RDP PortNumber 那样改**：影子固定用 **445/139 + 动态 RPC(49152-65535)**。
- ⚠ **运营商通常在公网封 445/139/RPC**（安全原因）→ 影子适合**局域网**；**公网**请用 **VPN / 隧道**（把 SMB/RPC 包起来，如 WireGuard/OpenVPN/ZeroTier）或改用远程协助工具（Remote Assistance / 第三方）。
- 菜单「4」流程：输入主机 → 账户/密码 → **自动列出目标会话** → 选择或手动输入会话 ID（列不出时才手动输入）。

## 手动跨机影子（与工具等价）

```powershell
cmdkey /add:<主机> /user:目标会话账户 /pass:密码   # 缓存凭据
query session /server:<主机>                        # 远程列会话(依赖 cmdkey 凭据)
mstsc /v:<主机> /shadow:7 /control /noConsentPrompt /prompt
```

## 常见问题

| 现象 | 原因 | 解决 |
|---|---|---|
| 此计算机名无效 | 在 `/v` 里带了自定义端口(`/v:主机:端口`)——mstsc /shadow 无法解析端口 | 用 `/v:主机`(不带端口)；影子走 SMB/RPC，与 RDP 端口无关 |
| 未连接指定的会话 | 目标会话不在可影的 Active 状态 | 确保目标是**活动**会话（console 会话也可以） |
| 拒绝访问（跨机） | 未 `/prompt`/凭据；或账户在目标机未被授权；或目标会话(SID)账户不符 | 加 `/prompt` 输入**目标机授权账户**；跨机优先用**该会话账户**的凭据 |
| 拒绝访问（本机） | 目标会话建立于旧 Shadow 值；或目标被要求同意 | 目标用户重登；按需 `-ForceNoConsent` |
| 为什么开了 445 SMB 还需 RPC | 影子用 139/445+RPC(49152-65535) | 放行「文件和打印机共享」+「远程桌面-影子」+ 动态 RPC 段 |
| 影子黑屏/暂停 | 目标会话锁屏或有 UAC 安全桌面 | 让目标解锁/处理 UAC 后恢复 |

## 凭据与安全

- `cmdkey` 会把凭据存到当前用户凭据管理器；测试后可 `cmdkey /delete:<主机>` 清除。
- 跨机影子本质是「目标机授权 + 凭据」，建议只给影子专用授权账户，测完删除。
- 完整 RDP/RDS 说明见主 README 与 [Microsoft mstsc 文档](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/mstsc)。
