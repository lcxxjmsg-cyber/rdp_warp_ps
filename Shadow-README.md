# Shadow（远程控制 / 会话影子）使用说明

> 影子（Session Shadow / Remote Control）指用一个会话**查看 / 控制另一个会话**。本工具把它做成了一条可靠链路：**本机影子** 和 **跨机远程影子** 都支持。

## 两种影子方式

| 方式 | 命令 |适用 |
|---|---|---|
| **本机影子** | `mstsc /shadow:<会话ID> /control [/noConsentPrompt]` | 在同一台机器上影另一个会话 |
| **跨机远程影子** | `mstsc /v:<主机> /shadow:<会话ID> /control /noConsentPrompt /prompt` | 从另一台机器影目标机的会话 |

## 权限模型（Windows）

- **会话影子**由 RDP-Tcp 监听器的「远程控制」设置（`Shadow` 值）决定行为：
  `0=禁用` `1=完全控制/需用户同意` `2=完全控制/免同意` `3=仅查看/需同意` `4=仅查看/免同意`
- **调用方必须在目标机上被授权**：拥有 `WINSTATION_SHADOW`(0x10) 权限（通常是 `Administrators` / `SYSTEM`）。跨机影子尤其需要「目标机上的账户」被授权，**建议用管理员账户**。
- **console 会话既不能影别人、也不能被影**（Windows 文档明确）。目标会话必须是 `rdp-tcp#N` 且为 Active。
- 已登录会话的权限在**会话建立时**固化；改了 `Shadow` 值后，**让目标用户重新登录**才能读到新值。

## 用本工具发起影子

交互菜单：**影子 → 3（本机）/ 4（远程）/ 5（诊断）**。或直接调用：

```powershell
# 本机影子（按目标用户的每用户->全局策略自动定 /control 与 /noConsentPrompt）
Invoke-RdpShadow -SessionId 7

# 跨机远程影子（自动 /v + /prompt；提供 -User 则先 cmdkey 缓存凭据）
Invoke-RdpShadow -Remote 192.168.1.12 -SessionId 7 -User 65633 -Password 'lengye521'
# 或不缓存凭据，连接时弹窗输入（-User 留空）
Invoke-RdpShadow -Remote 192.168.1.12 -SessionId 7
```

参数说明：
- `-SessionId`：目标会话 ID；缺省时列出可选会话（远程会列出目标机会话，需先有凭据）。
- `-Remote <主机>`：跨机阴影（加 `/v`）。
- `-User/-Password`：目标机**被授权的账户**；提供后自动 `cmdkey /add:<主机>` 缓存，避免每次弹窗（`query session /server:` 也依赖此凭据）。
- `-ForceConsent` / `-ForceNoConsent` / `-ViewOnly`：覆盖策略（本地）或默认设置（远程默认=完全控制/免同意）。
- **远程仅支持默认端口 3389**：`mstsc /shadow` 的 `/v` 不认自定义端口（`/v:主机:端口` 会报「此计算机名无效」）。请让目标机 RDP 端口 = 3389。

## 手动跨机影子（与工具等价）

```powershell
# 1) 缓存凭据（目标机授权账户）
cmdkey /add:192.168.1.12 /user:65633 /pass:lengye521
# 2) 远程列目标机会话
query session /server:192.168.1.12
# 3) 影子
mstsc /v:192.168.1.12 /shadow:<会话ID> /control /noConsentPrompt /prompt
```

## 常见问题

| 现象 | 原因 | 解决 |
|---|---|---|
| **此计算机名无效** | 目标机 RDP 用自定义端口（非 3389），`/v` 不认 | 目标机 RDP 端口设 **3389** |
| **未连接指定的会话** | `/v` 连到默认 3389，但目标会话不是 Active（或目标是 console） | 确保目标是 `rdp-tcp#N` Active |
| **拒绝访问（跨机）** | 未提供 `/prompt` / 凭据；或账户在目标机未被授权（非管理员/无 0x10）；或未提升 | 加 `/prompt` 并输入目标机**管理员**账户；或 `-User/-Password` 缓存；工具需以管理员运行 |
| **拒绝访问（本机跨用户）** | 目标会话是在旧 Shadow 值下建立的；或普通用户目标被要求同意 | 目标用户**重新登录**；按需 `-ForceNoConsent` |
| **弹「同意」提示** | Shadow 值为 1/3（需同意）；或普通用户目标 | 直接同意；或设 `Shadow=2`，并让其会话重登 |
| **同一会话只能被影一次** | RDP 协议限制（非版本/工具问题） | 无解（RDP 协议限制） |

## 凭据与安全

- `cmdkey` 会把凭据存到当前用户凭据管理器；测试后可 `cmdkey /delete:<主机>` 清除。
- 建议在目标机上**只给影子专用的管理员账户**，或按需开放，测试完删除。
- 跨机影子本质是「目标机授权 + 凭据」，工具默认 `-ForceNoConsent` 组合，但**普通用户目标仍可能被要求同意**（Windows 客户端行为）。

## 相关说明

- 本机影子见上一节；工具会按「目标用户每用户策略 → 全局策略」自动拼 `/control` / `/noConsentPrompt`。
- `Shadow=2`（完全控制/免同意）官方推荐用于「Full access without permission」的 TeamViewer 式场景。
- 完整 RDP/RDS 说明见主 README 与 [Microsoft mstsc 文档](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/mstsc)。
