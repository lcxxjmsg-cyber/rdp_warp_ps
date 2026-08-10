<#
.SYNOPSIS
    rdpwarp - Windows RDP Multi-Session Controller
.DESCRIPTION
    Enables multiple concurrent RDP sessions on Windows via rdpwrap.
    One-click install, full RDP configuration, auto-healing watchdog.
.LINK
    https://github.com/stascorp/rdpwrap
.EXAMPLE
    .\rdpwarps.ps1             # Interactive menu with live status
    .\rdpwarps.ps1 -Install    # One-click silent install
    .\rdpwarps.ps1 -Uninstall  # Clean removal
    irm <url> | iex             # Remote execution
#>
param([switch]$Install,[switch]$Uninstall,[switch]$Help,[string]$GHMirror = "",[switch]$ExperimentalNoSym)

if ($GHMirror) { $env:GH_MIRROR = $GHMirror }

$script:VERSION = "2.6.7"

$culture = [System.Globalization.CultureInfo]::CurrentCulture.Name
$langMap = @{
    'zh'='zh';'zh-CN'='zh';'zh-TW'='zh';'zh-HK'='zh'
    'ja'='ja';'ja-JP'='ja'
    'ko'='ko';'ko-KR'='ko'
    'fr'='fr';'fr-FR'='fr'
    'de'='de';'de-DE'='de'
    'es'='es';'es-ES'='es'
    'ru'='ru';'ru-RU'='ru'
}
$script:DEFAULT_LANG = if ($langMap.ContainsKey($culture)) { $langMap[$culture] } else { 'en' }
$script:LANG = $script:DEFAULT_LANG

$script:LANG_NAMES = @{zh='中文';en='English';ja='日本語';ko='한국어';fr='Français';de='Deutsch';es='Español';ru='Русский'}
$script:LANGS = @('zh','en','ja','ko','fr','de','es','ru')

$script:UI = @{}

$script:UI['zh'] = @{
    title         = "多会话 RDP 管理器"
    sys_status    = "系统状态"
    service       = "服务"
    port          = "端口"
    listening     = "监听中"
    closed        = "已关闭"
    wrapper       = "状态"
    installed     = "[Y] 已安装"
    not_installed = "[X] 未安装"
    ini_support   = "INI 支持"
    ini_ok        = "[Y] 已支持"
    ini_patched   = "[+P] 补丁生效"
    ini_not_patched = "[!P] 补丁异常"
    ini_bad       = "[X] 不支持"
    watchdog      = "看门狗"
    active        = "[Y] 运行中"
    inactive      = "[X] 未运行"
    sessions      = "会话数"
    session       = "会话"
    admin_required = "需要管理员权限 - 请以管理员身份运行"
    press_any_key = "按任意键继续..."
    menu_install      = "安装 rdpwarp"
    menu_install_desc = "一键部署 rdpwrap 多会话 RDP"
    menu_exit         = "退出"
    menu_update       = "更新偏移"
    menu_update_desc  = "Windows 更新后修复 RDP 支持"
    menu_session_title  = "会话设置"
    menu_session_desc   = "配置最大并发会话数和每用户限制"
    menu_session_s      = "最大并发会话"
    menu_session_u      = "每用户单会话"
    menu_session_m      = "修改最大会话数"
    menu_session_t      = "切换每用户单会话"
    menu_session_r      = "恢复默认"
    menu_security_title  = "安全设置"
    menu_security_desc   = "NLA、安全层等安全选项"
    menu_security_nla    = "网络级身份验证 (NLA)"
    menu_security_sl     = "安全层"
    menu_security_tn     = "切换 NLA"
    menu_security_ss     = "设置安全层"
    menu_shadow_title  = "远程控制 / 影子模式"
    menu_shadow_desc   = "设置远程协助的权限级别"
    menu_shadow_cur    = "当前模式"
    menu_shadow_off    = "关闭"
    menu_shadow_fwp    = "完全控制（需许可）"
    menu_shadow_fwo    = "完全控制（无需许可）"
    menu_shadow_vwp    = "仅查看（需许可）"
    menu_shadow_vwo    = "仅查看（无需许可）"
    menu_display_title  = "显示与会话选项"
    menu_display_desc   = "多显示器、隐藏用户、自动重连"
    menu_display_mm     = "多显示器支持"
    menu_display_hide   = "登录页隐藏用户"
    menu_display_ar     = "自动重连"
    menu_display_tm     = "切换多显示器"
    menu_display_th     = "切换隐藏用户"
    menu_display_ta     = "切换自动重连"
    menu_timeout_title  = "会话超时"
    menu_timeout_desc   = "设置断开/空闲/活动超时时间"
    menu_timeout_disc   = "已断开会话超时"
    menu_timeout_idle   = "空闲会话超时"
    menu_timeout_active = "活动会话限制"
    menu_timeout_sd     = "设置断开超时（分钟）"
    menu_timeout_si     = "设置空闲超时（分钟）"
    menu_timeout_sa     = "设置活动限制（分钟）"
    menu_timeout_reset  = "全部重置（永不断开）"
    menu_port_title  = "更改 RDP 端口"
    menu_port_desc   = "修改远程桌面监听端口号"
    menu_port_cur    = "当前端口"
    menu_port_prompt = "输入新端口号 (1024-65535)："
    menu_port_done   = "端口已更改，请连接："
    menu_watchdog_title   = "看门狗管理"
    menu_watchdog_desc    = "开机自启，自动更新 INI 偏移"
    menu_watchdog_reg     = "注册 / 重新注册"
    menu_watchdog_unr     = "注销"
    menu_restart      = "重启服务"
    menu_restart_desc = "重启 Remote Desktop 服务"
    menu_uninstall      = "卸载 rdpwarp"
    menu_uninstall_desc = "完全移除 rdpwarp 并恢复设置"
    install_header      = "rdpwarp - 一键安装"
    install_step1       = "部署二进制文件"
    install_step2       = "停止服务"
    install_step3       = "配置服务"
    install_step4       = "检查 INI 支持"
    install_step5       = "启用 RDP"
    install_step6       = "启动服务"
    install_ok          = "rdpwarp 安装成功！多会话 RDP 已在端口 {Port} 就绪"
    install_warn        = "安装完成但有警告："
    install_ini_warn    = "INI 可能需要更新（版本 {Ver}）"
    install_svc_not_run = "TermService 未运行"
    install_port_not_listen = "端口 {Port} 未监听"
    install_wd          = "看门狗已自动注册用于自愈"
    uninstall_header   = "rdpwarp - 卸载"
    uninstall_confirm  = "这将卸载 rdpwarp 并恢复原始设置。继续？[Y/N] "
    uninstall_cancelled = "已取消"
    uninstall_done     = "rdpwarp 已移除"
    sel_opt           = "请选择操作"
    inv_opt           = "无效选项"
    back_main         = "返回主菜单"
    unlimited         = "无限制"
    on                = "开"
    off               = "关"
    dflt              = "默认"
    never             = "永不过期"
    min               = "分钟"
    yes               = "是"
    no                = "否"
    cancel            = "已取消"
    continue_prompt   = "按 Enter 继续..."
    confirm_uninstall = "这将卸载 rdpwarp 并恢复原始设置。是否继续？[Y/N] "
    select_lang       = "请选择语言 / Select Language"
    session_state_active = "活动"
    session_state_disc   = "断开"
    session_state_conn   = "连接"
    wd_title          = "看门狗管理"
    wd_reg            = "注册 / 重新注册"
    wd_unr            = "注销"
    wd_done           = "看门狗已注册（开机启动 + 每日 3AM 更新）"
    restart_done      = "TermService 已重启"
    menu_remoteapp      = "生成 RemoteApp"
    menu_remoteapp_desc = "发布单个程序到客户端桌面"
    remoteapp_header    = "生成 RemoteApp 连接文件"
    remoteapp_server    = "服务器地址"
    remoteapp_presets   = "选择要发布的程序"
    remoteapp_custom    = "手动输入路径"
    remoteapp_name      = "程序名称"
    remoteapp_args      = "命令行参数（留空跳过）"
    remoteapp_optional  = "可选设置"
    remoteapp_clipboard = "启用剪贴板"
    remoteapp_drives    = "启用驱动器映射"
    remoteapp_audio     = "音频模式：0=本机 1=服务端 2=关闭"
    remoteapp_username  = "用户名（留空连接时输入）"
    remoteapp_done      = "RemoteApp 文件已创建："
}

$script:UI['en'] = @{
    title         = "Multi-Session RDP Manager"
    sys_status    = "System Status"
    service       = "Service"
    port          = "Port"
    listening     = "Listening"
    closed        = "Closed"
    wrapper       = "Wrapper"
    installed     = "[Y] Installed"
    not_installed = "[X] Not Installed"
    ini_support   = "INI Support"
    ini_ok        = "[Y] Supported"
    ini_patched   = "[+P] Patch OK"
    ini_not_patched = "[!P] Patch FAILED"
    ini_bad       = "[X] Not Supported"
    watchdog      = "Watchdog"
    active        = "[Y] Running"
    inactive      = "[X] Not Running"
    sessions      = "Sessions"
    session       = "Session"
    admin_required = "Administrator privileges required"
    press_any_key = "Press any key to continue..."
    menu_install      = "Install rdpwarp"
    menu_install_desc = "One-click deploy multi-session RDP"
    menu_exit         = "Exit"
    menu_update       = "Update Offsets"
    menu_update_desc  = "Fix RDP after Windows update"
    menu_session_title  = "Session Settings"
    menu_session_desc   = "Configure max sessions & per-user limit"
    menu_session_s      = "Max Concurrent Sessions"
    menu_session_u      = "Single Session Per User"
    menu_session_m      = "Change Max Sessions"
    menu_session_t      = "Toggle Single Session Per User"
    menu_session_r      = "Reset to Default"
    menu_security_title  = "Security Settings"
    menu_security_desc   = "NLA, Security Layer & more"
    menu_security_nla    = "Network Level Auth (NLA)"
    menu_security_sl     = "Security Layer"
    menu_security_tn     = "Toggle NLA"
    menu_security_ss     = "Set Security Layer"
    menu_shadow_title  = "Remote Control / Shadow"
    menu_shadow_desc   = "Set remote assistance permission level"
    menu_shadow_cur    = "Current Mode"
    menu_shadow_off    = "Off"
    menu_shadow_fwp    = "Full Control (w/ permission)"
    menu_shadow_fwo    = "Full Control (w/o permission)"
    menu_shadow_vwp    = "View Only (w/ permission)"
    menu_shadow_vwo    = "View Only (w/o permission)"
    menu_display_title  = "Display & Session Options"
    menu_display_desc   = "Multi-monitor, hide users, auto-reconnect"
    menu_display_mm     = "Multi-Monitor Support"
    menu_display_hide   = "Hide Users on Login"
    menu_display_ar     = "Auto Reconnect"
    menu_display_tm     = "Toggle Multi-Monitor"
    menu_display_th     = "Toggle Hide Users"
    menu_display_ta     = "Toggle Auto Reconnect"
    menu_timeout_title  = "Session Timeouts"
    menu_timeout_desc   = "Set disconnect/idle/active time limits"
    menu_timeout_disc   = "Disconnected Timeout"
    menu_timeout_idle   = "Idle Timeout"
    menu_timeout_active = "Active Session Limit"
    menu_timeout_sd     = "Set Disconnect Timeout (min)"
    menu_timeout_si     = "Set Idle Timeout (min)"
    menu_timeout_sa     = "Set Active Limit (min)"
    menu_timeout_reset  = "Reset All (Never Disconnect)"
    menu_port_title  = "Change RDP Port"
    menu_port_desc   = "Modify Remote Desktop listening port"
    menu_port_cur    = "Current Port"
    menu_port_prompt = "Enter new port number (1024-65535): "
    menu_port_done   = "Port changed, connect to: "
    menu_watchdog_title   = "Watchdog Management"
    menu_watchdog_desc    = "Auto-start, auto-update INI offsets"
    menu_watchdog_reg     = "Register / Re-register"
    menu_watchdog_unr     = "Unregister"
    menu_restart      = "Restart Service"
    menu_restart_desc = "Restart Remote Desktop service"
    menu_uninstall      = "Uninstall rdpwarp"
    menu_uninstall_desc = "Fully remove rdpwarp and restore settings"
    install_header      = "rdpwarp - One-Click Install"
    install_step1       = "Deploying binaries"
    install_step2       = "Stopping services"
    install_step3       = "Configuring service"
    install_step4       = "Checking INI support"
    install_step5       = "Enabling RDP"
    install_step6       = "Starting service"
    install_ok          = "rdpwarp installed successfully!`nMulti-session RDP is ready on port {Port}"
    install_warn        = "Install completed with warnings:"
    install_ini_warn    = "INI may need update (version {Ver})"
    install_svc_not_run = "TermService not running"
    install_port_not_listen = "Port {Port} not listening"
    install_wd          = "Watchdog auto-registered for self-healing"
    uninstall_header   = "rdpwarp - Uninstall"
    uninstall_confirm  = "This will remove rdpwarp and restore original settings. Continue? [Y/N] "
    uninstall_cancelled = "Cancelled"
    uninstall_done     = "rdpwarp removed"
    sel_opt           = "Select an option"
    inv_opt           = "Invalid option"
    back_main         = "Back to main menu"
    unlimited         = "Unlimited"
    on                = "ON"
    off               = "OFF"
    dflt              = "Default"
    never             = "Never"
    min               = "min"
    yes               = "Yes"
    no                = "No"
    cancel            = "Cancelled"
    continue_prompt   = "Press Enter to continue..."
    confirm_uninstall = "This will remove rdpwarp and restore original settings. Continue? [Y/N] "
    select_lang       = "Select Language / 选择语言"
    session_state_active = "Active"
    session_state_disc   = "Disc"
    session_state_conn   = "Conn"
    wd_title          = "Watchdog Management"
    wd_reg            = "Register / Re-register"
    wd_unr            = "Unregister"
    wd_done           = "Watchdog registered (startup + daily 3AM)"
    restart_done      = "TermService restarted"
    menu_remoteapp      = "RemoteApp"
    menu_remoteapp_desc = "Publish a single app to client desktop"
    remoteapp_header    = "Generate RemoteApp Connection File"
    remoteapp_server    = "Server address"
    remoteapp_presets   = "Select program to publish"
    remoteapp_custom    = "Enter custom path"
    remoteapp_name      = "Display name"
    remoteapp_args      = "Command line args (leave blank to skip)"
    remoteapp_optional  = "Optional settings"
    remoteapp_clipboard = "Enable clipboard"
    remoteapp_drives    = "Enable drive mapping"
    remoteapp_audio     = "Audio mode: 0=local 1=server 2=none"
    remoteapp_username  = "Username (leave blank to enter on connect)"
    remoteapp_done      = "RemoteApp file created: "
}

$script:UI['ja'] = @{
    title         = "マルチセッション RDP マネージャー"
    sys_status    = "システム状態"
    service       = "サービス"
    port          = "ポート"
    listening     = "リッスン中"
    closed        = "閉じています"
    wrapper       = "状態"
    installed     = "[Y] インストール済み"
    not_installed = "[X] 未インストール"
    ini_support   = "INI サポート"
    ini_ok        = "[Y] 対応済み"
    ini_patched   = "[+P] パッチ正常"
    ini_not_patched = "[!P] パッチ異常"
    ini_bad       = "[X] 未対応"
    watchdog      = "ウォッチドッグ"
    active        = "[Y] 実行中"
    inactive      = "[X] 停止中"
    sessions      = "セッション数"
    session       = "セッション"
    admin_required = "管理者権限が必要です - 管理者として実行してください"
    press_any_key = "任意のキーを押して続行..."
    menu_install      = "rdpwarp をインストール"
    menu_install_desc = "ワンクリックでマルチセッション RDP を展開"
    menu_exit         = "終了"
    menu_update       = "オフセットを更新"
    menu_update_desc  = "Windows 更新後に RDP を修復"
    menu_session_title  = "セッション設定"
    menu_session_desc   = "最大セッション数とユーザー制限を設定"
    menu_session_s      = "最大同時セッション数"
    menu_session_u      = "ユーザーあたり 1 セッション"
    menu_session_m      = "最大セッション数を変更"
    menu_session_t      = "ユーザーあたり 1 セッションを切替"
    menu_session_r      = "デフォルトに戻す"
    menu_security_title  = "セキュリティ設定"
    menu_security_desc   = "NLA、セキュリティ層などの設定"
    menu_security_nla    = "ネットワークレベル認証 (NLA)"
    menu_security_sl     = "セキュリティ層"
    menu_security_tn     = "NLA を切替"
    menu_security_ss     = "セキュリティ層を設定"
    menu_shadow_title  = "リモート制御 / シャドウモード"
    menu_shadow_desc   = "リモートアシスタンスのアクセス権限を設定"
    menu_shadow_cur    = "現在のモード"
    menu_shadow_off    = "オフ"
    menu_shadow_fwp    = "フルコントロール（許可が必要）"
    menu_shadow_fwo    = "フルコントロール（許可不要）"
    menu_shadow_vwp    = "表示のみ（許可が必要）"
    menu_shadow_vwo    = "表示のみ（許可不要）"
    menu_display_title  = "表示とセッションオプション"
    menu_display_desc   = "マルチモニター、ユーザー非表示、自動再接続"
    menu_display_mm     = "マルチモニター対応"
    menu_display_hide   = "ログイン画面でユーザーを非表示"
    menu_display_ar     = "自動再接続"
    menu_display_tm     = "マルチモニターを切替"
    menu_display_th     = "ユーザー非表示を切替"
    menu_display_ta     = "自動再接続を切替"
    menu_timeout_title  = "セッションタイムアウト"
    menu_timeout_desc   = "切断/アイドル/アクティブの制限時間を設定"
    menu_timeout_disc   = "切断済みセッションのタイムアウト"
    menu_timeout_idle   = "アイドルセッションのタイムアウト"
    menu_timeout_active = "アクティブセッションの制限"
    menu_timeout_sd     = "切断タイムアウトを設定（分）"
    menu_timeout_si     = "アイドルタイムアウトを設定（分）"
    menu_timeout_sa     = "アクティブ制限を設定（分）"
    menu_timeout_reset  = "すべてリセット（切断しない）"
    menu_port_title  = "RDP ポートを変更"
    menu_port_desc   = "リモートデスクトップのリスニングポートを変更"
    menu_port_cur    = "現在のポート"
    menu_port_prompt = "新しいポート番号を入力 (1024-65535)："
    menu_port_done   = "ポートを変更しました。接続先："
    menu_watchdog_title   = "ウォッチドッグ管理"
    menu_watchdog_desc    = "自動起動、INI オフセットを自動更新"
    menu_watchdog_reg     = "登録 / 再登録"
    menu_watchdog_unr     = "登録解除"
    menu_restart      = "サービスを再起動"
    menu_restart_desc = "Remote Desktop サービスを再起動"
    menu_uninstall      = "rdpwarp をアンインストール"
    menu_uninstall_desc = "rdpwarp を完全に削除して設定を復元"
    install_header      = "rdpwarp - ワンクリックインストール"
    install_step1       = "バイナリを展開中"
    install_step2       = "サービスを停止中"
    install_step3       = "サービスを設定中"
    install_step4       = "INI サポートを確認中"
    install_step5       = "RDP を有効化中"
    install_step6       = "サービスを起動中"
    install_ok          = "rdpwarp のインストールが完了しました！`nマルチセッション RDP がポート {Port} で利用可能です"
    install_warn        = "インストールは完了しましたが、警告があります："
    install_ini_warn    = "INI の更新が必要かもしれません（バージョン {Ver}）"
    install_svc_not_run = "TermService が実行されていません"
    install_port_not_listen = "ポート {Port} がリッスンしていません"
    install_wd          = "ウォッチドッグが自動登録されました"
    uninstall_header   = "rdpwarp - アンインストール"
    uninstall_confirm  = "rdpwarp を削除し、元の設定に戻します。続行しますか？[Y/N] "
    uninstall_cancelled = "キャンセルしました"
    uninstall_done     = "rdpwarp を削除しました"
    sel_opt           = "操作を選択してください"
    inv_opt           = "無効なオプション"
    back_main         = "メインメニューに戻る"
    unlimited         = "無制限"
    on                = "オン"
    off               = "オフ"
    dflt              = "デフォルト"
    never             = "無期限"
    min               = "分"
    yes               = "はい"
    no                = "いいえ"
    cancel            = "キャンセル"
    continue_prompt   = "Enter キーを押して続行..."
    confirm_uninstall = "rdpwarp を削除し、元の設定に戻します。続行しますか？[Y/N] "
    select_lang       = "言語を選択してください / Select Language"
    session_state_active = "アクティブ"
    session_state_disc   = "切断"
    session_state_conn   = "接続"
    wd_title          = "ウォッチドッグ管理"
    wd_reg            = "登録 / 再登録"
    wd_unr            = "登録解除"
    wd_done           = "ウォッチドッグを登録しました（起動時 + 毎日 3AM）"
    restart_done      = "TermService を再起動しました"
    menu_remoteapp      = "RemoteApp 生成"
    menu_remoteapp_desc = "アプリをクライアントデスクトップに公開"
    remoteapp_header    = "RemoteApp 接続ファイルを生成"
    remoteapp_server    = "サーバーアドレス"
    remoteapp_presets   = "公開するプログラムを選択"
    remoteapp_custom    = "パスを手動入力"
    remoteapp_name      = "プログラム名"
    remoteapp_args      = "コマンドライン引数（省略可）"
    remoteapp_optional  = "オプション設定"
    remoteapp_clipboard = "クリップボードを有効化"
    remoteapp_drives    = "ドライブマッピングを有効化"
    remoteapp_audio     = "音声モード: 0=ローカル 1=サーバー 2=なし"
    remoteapp_username  = "ユーザー名（省略時は接続時に入力）"
    remoteapp_done      = "RemoteApp ファイルを作成しました: "
}

$script:UI['ko'] = @{
    title         = "다중 세션 RDP 관리자"
    sys_status    = "시스템 상태"
    service       = "서비스"
    port          = "포트"
    listening     = "수신 중"
    closed        = "닫힘"
    wrapper       = "상태"
    installed     = "[Y] 설치됨"
    not_installed = "[X] 설치되지 않음"
    ini_support   = "INI 지원"
    ini_ok        = "[Y] 지원됨"
    ini_patched   = "[+P] 패치 정상"
    ini_not_patched = "[!P] 패치 실패"
    ini_bad       = "[X] 지원되지 않음"
    watchdog      = "와치독"
    active        = "[Y] 실행 중"
    inactive      = "[X] 실행 중 아님"
    sessions      = "세션 수"
    session       = "세션"
    admin_required = "관리자 권한이 필요합니다 - 관리자로 실행하세요"
    press_any_key = "계속하려면 아무 키나 누르세요..."
    menu_install      = "rdpwarp 설치"
    menu_install_desc = "원클릭 다중 세션 RDP 배포"
    menu_exit         = "종료"
    menu_update       = "오프셋 업데이트"
    menu_update_desc  = "Windows 업데이트 후 RDP 복구"
    menu_session_title  = "세션 설정"
    menu_session_desc   = "최대 세션 수 및 사용자 제한 구성"
    menu_session_s      = "최대 동시 세션 수"
    menu_session_u      = "사용자당 단일 세션"
    menu_session_m      = "최대 세션 수 변경"
    menu_session_t      = "사용자당 단일 세션 전환"
    menu_session_r      = "기본값으로 초기화"
    menu_security_title  = "보안 설정"
    menu_security_desc   = "NLA, 보안 계층 등 설정"
    menu_security_nla    = "네트워크 수준 인증 (NLA)"
    menu_security_sl     = "보안 계층"
    menu_security_tn     = "NLA 전환"
    menu_security_ss     = "보안 계층 설정"
    menu_shadow_title  = "원격 제어 / 섀도우 모드"
    menu_shadow_desc   = "원격 지원 권한 수준 설정"
    menu_shadow_cur    = "현재 모드"
    menu_shadow_off    = "끄기"
    menu_shadow_fwp    = "전체 제어 (권한 필요)"
    menu_shadow_fwo    = "전체 제어 (권한 불필요)"
    menu_shadow_vwp    = "보기 전용 (권한 필요)"
    menu_shadow_vwo    = "보기 전용 (권한 불필요)"
    menu_display_title  = "디스플레이 및 세션 옵션"
    menu_display_desc   = "다중 모니터, 사용자 숨기기, 자동 재연결"
    menu_display_mm     = "다중 모니터 지원"
    menu_display_hide   = "로그인 화면에서 사용자 숨기기"
    menu_display_ar     = "자동 재연결"
    menu_display_tm     = "다중 모니터 전환"
    menu_display_th     = "사용자 숨기기 전환"
    menu_display_ta     = "자동 재연결 전환"
    menu_timeout_title  = "세션 시간 제한"
    menu_timeout_desc   = "연결 끊김/유휴/활성 시간 제한 설정"
    menu_timeout_disc   = "연결 끊김 시간 제한"
    menu_timeout_idle   = "유휴 시간 제한"
    menu_timeout_active = "활성 세션 제한"
    menu_timeout_sd     = "연결 끊김 시간 제한 설정 (분)"
    menu_timeout_si     = "유휴 시간 제한 설정 (분)"
    menu_timeout_sa     = "활성 제한 설정 (분)"
    menu_timeout_reset  = "모두 초기화 (연결 끊지 않음)"
    menu_port_title  = "RDP 포트 변경"
    menu_port_desc   = "원격 데스크톱 수신 포트 변경"
    menu_port_cur    = "현재 포트"
    menu_port_prompt = "새 포트 번호 입력 (1024-65535)："
    menu_port_done   = "포트가 변경되었습니다. 연결: "
    menu_watchdog_title   = "와치독 관리"
    menu_watchdog_desc    = "자동 시작, INI 오프셋 자동 업데이트"
    menu_watchdog_reg     = "등록 / 재등록"
    menu_watchdog_unr     = "등록 해제"
    menu_restart      = "서비스 다시 시작"
    menu_restart_desc = "Remote Desktop 서비스 다시 시작"
    menu_uninstall      = "rdpwarp 제거"
    menu_uninstall_desc = "rdpwarp 완전 제거 및 설정 복원"
    install_header      = "rdpwarp - 원클릭 설치"
    install_step1       = "바이너리 배포 중"
    install_step2       = "서비스 중지 중"
    install_step3       = "서비스 구성 중"
    install_step4       = "INI 지원 확인 중"
    install_step5       = "RDP 활성화 중"
    install_step6       = "서비스 시작 중"
    install_ok          = "rdpwarp 설치 성공！`n포트 {Port}에서 다중 세션 RDP 사용 가능"
    install_warn        = "설치 완료되었으나 경고가 있습니다："
    install_ini_warn    = "INI 업데이트가 필요할 수 있습니다（버전 {Ver}）"
    install_svc_not_run = "TermService가 실행 중이 아닙니다"
    install_port_not_listen = "포트 {Port}가 수신 중이 아닙니다"
    install_wd          = "와치독이 자동 등록되었습니다"
    uninstall_header   = "rdpwarp - 제거"
    uninstall_confirm  = "rdpwarp를 제거하고 원래 설정으로 복원합니다. 계속하시겠습니까？[Y/N] "
    uninstall_cancelled = "취소되었습니다"
    uninstall_done     = "rdpwarp가 제거되었습니다"
    sel_opt           = "작업을 선택하세요"
    inv_opt           = "잘못된 옵션"
    back_main         = "메인 메뉴로 돌아가기"
    unlimited         = "무제한"
    on                = "켜짐"
    off               = "꺼짐"
    dflt              = "기본값"
    never             = "만료 없음"
    min               = "분"
    yes               = "예"
    no                = "아니오"
    cancel            = "취소됨"
    continue_prompt   = "Enter 키를 눌러 계속..."
    confirm_uninstall = "rdpwarp를 제거하고 원래 설정으로 복원합니다. 계속하시겠습니까？[Y/N] "
    select_lang       = "언어를 선택하세요 / Select Language"
    session_state_active = "활성"
    session_state_disc   = "끊김"
    session_state_conn   = "연결"
    wd_title          = "와치독 관리"
    wd_reg            = "등록 / 재등록"
    wd_unr            = "등록 해제"
    wd_done           = "와치독이 등록되었습니다（시작 시 + 매일 3AM）"
    restart_done      = "TermService가 다시 시작되었습니다"
    menu_remoteapp      = "RemoteApp 생성"
    menu_remoteapp_desc = "클라이언트 데스크톱에 앱 게시"
    remoteapp_header    = "RemoteApp 연결 파일 생성"
    remoteapp_server    = "서버 주소"
    remoteapp_presets   = "게시할 프로그램 선택"
    remoteapp_custom    = "경로 직접 입력"
    remoteapp_name      = "프로그램 이름"
    remoteapp_args      = "명령줄 인수 (생략 가능)"
    remoteapp_optional  = "선택 설정"
    remoteapp_clipboard = "클립보드 사용"
    remoteapp_drives    = "드라이브 매핑 사용"
    remoteapp_audio     = "오디오 모드: 0=로컬 1=서버 2=없음"
    remoteapp_username  = "사용자 이름 (생략 시 연결 시 입력)"
    remoteapp_done      = "RemoteApp 파일을 생성했습니다: "
}

$script:UI['fr'] = @{
    title         = "Gestionnaire RDP Multi-Session"
    sys_status    = "État du système"
    service       = "Service"
    port          = "Port"
    listening     = "Écoute"
    closed        = "Fermé"
    wrapper       = "État"
    installed     = "[Y] Installé"
    not_installed = "[X] Non installé"
    ini_support   = "Support INI"
    ini_ok        = "[Y] Pris en charge"
    ini_patched   = "[+P] Patch OK"
    ini_not_patched = "[!P] Patch failed"
    ini_bad       = "[X] Non pris en charge"
    watchdog      = "Watchdog"
    active        = "[Y] Actif"
    inactive      = "[X] Inactif"
    sessions      = "Sessions"
    session       = "Session"
    admin_required = "Privilèges administrateur requis"
    press_any_key = "Appuyez sur une touche pour continuer..."
    menu_install      = "Installer rdpwarp"
    menu_install_desc = "Déploiement en un clic du RDP multi-session"
    menu_exit         = "Quitter"
    menu_update       = "Mettre à jour les offsets"
    menu_update_desc  = "Réparer RDP après une mise à jour Windows"
    menu_session_title  = "Paramètres de session"
    menu_session_desc   = "Configurer le max de sessions et limites"
    menu_session_s      = "Sessions simultanées max"
    menu_session_u      = "Session unique par utilisateur"
    menu_session_m      = "Modifier le max de sessions"
    menu_session_t      = "Basculer session unique"
    menu_session_r      = "Réinitialiser"
    menu_security_title  = "Paramètres de sécurité"
    menu_security_desc   = "NLA, couche de sécurité, etc."
    menu_security_nla    = "Authentification niveau réseau (NLA)"
    menu_security_sl     = "Couche de sécurité"
    menu_security_tn     = "Basculer NLA"
    menu_security_ss     = "Définir couche de sécurité"
    menu_shadow_title  = "Contrôle à distance / Shadow"
    menu_shadow_desc   = "Définir le niveau d'accès d'assistance"
    menu_shadow_cur    = "Mode actuel"
    menu_shadow_off    = "Désactivé"
    menu_shadow_fwp    = "Contrôle total (avec permission)"
    menu_shadow_fwo    = "Contrôle total (sans permission)"
    menu_shadow_vwp    = "Affichage seul (avec permission)"
    menu_shadow_vwo    = "Affichage seul (sans permission)"
    menu_display_title  = "Affichage et options de session"
    menu_display_desc   = "Multi-écran, masquer utilisateurs, reconnexion"
    menu_display_mm     = "Support multi-écran"
    menu_display_hide   = "Masquer les utilisateur à la connexion"
    menu_display_ar     = "Reconnexion automatique"
    menu_display_tm     = "Basculer multi-écran"
    menu_display_th     = "Basculer masquer utilisateurs"
    menu_display_ta     = "Basculer reconnexion auto"
    menu_timeout_title  = "Expiration des sessions"
    menu_timeout_desc   = "Définir les limites de temps"
    menu_timeout_disc   = "Expiration déconnexion"
    menu_timeout_idle   = "Expiration inactivité"
    menu_timeout_active = "Limite session active"
    menu_timeout_sd     = "Délai déconnexion (min)"
    menu_timeout_si     = "Délai inactivité (min)"
    menu_timeout_sa     = "Limite active (min)"
    menu_timeout_reset  = "Tout réinitialiser"
    menu_port_title  = "Changer le port RDP"
    menu_port_desc   = "Modifier le port d'écoute du bureau à distance"
    menu_port_cur    = "Port actuel"
    menu_port_prompt = "Entrez le nouveau port (1024-65535)："
    menu_port_done   = "Port changé, connectez-vous à : "
    menu_watchdog_title   = "Gestion du Watchdog"
    menu_watchdog_desc    = "Démarrage auto, mise à jour INI auto"
    menu_watchdog_reg     = "Enregistrer / Ré-enregistrer"
    menu_watchdog_unr     = "Désenregistrer"
    menu_restart      = "Redémarrer le service"
    menu_restart_desc = "Redémarrer le service Bureau à distance"
    menu_uninstall      = "Désinstaller rdpwarp"
    menu_uninstall_desc = "Supprimer rdpwarp et restaurer les paramètres"
    install_header      = "rdpwarp - Installation rapide"
    install_step1       = "Déploiement des binaires"
    install_step2       = "Arrêt des services"
    install_step3       = "Configuration du service"
    install_step4       = "Vérification support INI"
    install_step5       = "Activation RDP"
    install_step6       = "Démarrage du service"
    install_ok          = "rdpwarp installé avec succès !`nRDP multi-session prêt sur le port {Port}"
    install_warn        = "Installation terminée avec des avertissements :"
    install_ini_warn    = "L'INI doit être mise à jour (version {Ver})"
    install_svc_not_run = "TermService ne tourne pas"
    install_port_not_listen = "Port {Port} n'écoute pas"
    install_wd          = "Watchdog auto-enregistré pour l'auto-guérison"
    uninstall_header   = "rdpwarp - Désinstallation"
    uninstall_confirm  = "Cela supprimera rdpwarp et restaurera les paramètres. Continuer ? [Y/N] "
    uninstall_cancelled = "Annulé"
    uninstall_done     = "rdpwarp supprimé"
    sel_opt           = "Choisissez une option"
    inv_opt           = "Option invalide"
    back_main         = "Retour au menu principal"
    unlimited         = "Illimité"
    on                = "ON"
    off               = "OFF"
    dflt              = "Défaut"
    never             = "Jamais"
    min               = "min"
    yes               = "Oui"
    no                = "Non"
    cancel            = "Annulé"
    continue_prompt   = "Appuyez sur Entrée pour continuer..."
    confirm_uninstall = "Cela supprimera rdpwarp et restaurera les paramètres. Continuer ? [Y/N] "
    select_lang       = "Choisissez la langue / Select Language"
    session_state_active = "Actif"
    session_state_disc   = "Déconn."
    session_state_conn   = "Conn."
    wd_title          = "Gestion du Watchdog"
    wd_reg            = "Enregistrer / Ré-enregistrer"
    wd_unr            = "Désenregistrer"
    wd_done           = "Watchdog enregistré (démarrage + 3h quotidien)"
    restart_done      = "TermService redémarré"
    menu_remoteapp      = "RemoteApp"
    menu_remoteapp_desc = "Publier une app sur le bureau client"
    remoteapp_header    = "Générer un fichier de connexion RemoteApp"
    remoteapp_server    = "Adresse du serveur"
    remoteapp_presets   = "Choisir le programme à publier"
    remoteapp_custom    = "Saisir le chemin manuellement"
    remoteapp_name      = "Nom du programme"
    remoteapp_args      = "Arguments (laisser vide pour ignorer)"
    remoteapp_optional  = "Paramètres optionnels"
    remoteapp_clipboard = "Activer le presse-papiers"
    remoteapp_drives    = "Activer le mappage de lecteurs"
    remoteapp_audio     = "Mode audio: 0=local 1=serveur 2=aucun"
    remoteapp_username  = "Nom d'utilisateur (laisser vide pour saisir à la connexion)"
    remoteapp_done      = "Fichier RemoteApp créé : "
}

$script:UI['de'] = @{
    title         = "Multi-Session RDP Manager"
    sys_status    = "Systemstatus"
    service       = "Dienst"
    port          = "Port"
    listening     = "Hört zu"
    closed        = "Geschlossen"
    wrapper       = "Status"
    installed     = "[Y] Installiert"
    not_installed = "[X] Nicht installiert"
    ini_support   = "INI-Unterstützung"
    ini_ok        = "[Y] Unterstützt"
    ini_patched   = "[+P] Patch OK"
    ini_not_patched = "[!P] Patch fehlgeschlagen"
    ini_bad       = "[X] Nicht unterstützt"
    watchdog      = "Watchdog"
    active        = "[Y] Aktiv"
    inactive      = "[X] Inaktiv"
    sessions      = "Sitzungen"
    session       = "Sitzung"
    admin_required = "Administratorrechte erforderlich"
    press_any_key = "Drücken Sie eine Taste zum Fortfahren..."
    menu_install      = "rdpwarp installieren"
    menu_install_desc = "Multi-Session RDP mit einem Klick bereitstellen"
    menu_exit         = "Beenden"
    menu_update       = "Offsets aktualisieren"
    menu_update_desc  = "RDP nach Windows-Update reparieren"
    menu_session_title  = "Sitzungseinstellungen"
    menu_session_desc   = "Max. Sitzungen und Benutzerlimit konfigurieren"
    menu_session_s      = "Max. gleichzeitige Sitzungen"
    menu_session_u      = "Einzelsitzung pro Benutzer"
    menu_session_m      = "Max. Sitzungen ändern"
    menu_session_t      = "Einzelsitzung umschalten"
    menu_session_r      = "Zurücksetzen"
    menu_security_title  = "Sicherheitseinstellungen"
    menu_security_desc   = "NLA, Sicherheitsebene u.a."
    menu_security_nla    = "Netzwerkauthentifizierung (NLA)"
    menu_security_sl     = "Sicherheitsebene"
    menu_security_tn     = "NLA umschalten"
    menu_security_ss     = "Sicherheitsebene setzen"
    menu_shadow_title  = "Remote-Steuerung / Shadow"
    menu_shadow_desc   = "Zugriffsberechtigungen für Remote-Assistenz"
    menu_shadow_cur    = "Aktueller Modus"
    menu_shadow_off    = "Aus"
    menu_shadow_fwp    = "Vollzugriff (mit Erlaubnis)"
    menu_shadow_fwo    = "Vollzugriff (ohne Erlaubnis)"
    menu_shadow_vwp    = "Nur Anzeigen (mit Erlaubnis)"
    menu_shadow_vwo    = "Nur Anzeigen (ohne Erlaubnis)"
    menu_display_title  = "Anzeige- und Sitzungsoptionen"
    menu_display_desc   = "Mehrere Monitore, Benutzer ausblenden, Auto-Wiederverb."
    menu_display_mm     = "Mehrfachmonitor-Unterstützung"
    menu_display_hide   = "Benutzer auf Anmeldeseite ausblenden"
    menu_display_ar     = "Automatische Wiederverbindung"
    menu_display_tm     = "Mehrfachmonitor umschalten"
    menu_display_th     = "Benutzer ausblenden umschalten"
    menu_display_ta     = "Auto-Wiederverb. umschalten"
    menu_timeout_title  = "Sitzungs-Timeouts"
    menu_timeout_desc   = "Zeitlimits für getrennte/untätige/aktive Sitzungen"
    menu_timeout_disc   = "Timeout getrennte Sitzung"
    menu_timeout_idle   = "Timeout untätige Sitzung"
    menu_timeout_active = "Limit aktive Sitzung"
    menu_timeout_sd     = "Timeout Trennung (Min.)"
    menu_timeout_si     = "Timeout Untätigkeit (Min.)"
    menu_timeout_sa     = "Limit aktiv (Min.)"
    menu_timeout_reset  = "Alles zurücksetzen"
    menu_port_title  = "RDP-Port ändern"
    menu_port_desc   = "Listening-Port der Remotedesktop ändern"
    menu_port_cur    = "Aktueller Port"
    menu_port_prompt = "Neue Portnummer eingeben (1024-65535)："
    menu_port_done   = "Port geändert, verbinden mit: "
    menu_watchdog_title   = "Watchdog-Verwaltung"
    menu_watchdog_desc    = "Autostart, automatische INI-Offset-Aktualisierung"
    menu_watchdog_reg     = "Registrieren / Erneut registrieren"
    menu_watchdog_unr     = "Registrierung aufheben"
    menu_restart      = "Dienst neu starten"
    menu_restart_desc = "Remotedesktop-Dienst neu starten"
    menu_uninstall      = "rdpwarp deinstallieren"
    menu_uninstall_desc = "rdpwarp vollständig entfernen und Einstellungen wiederherstellen"
    install_header      = "rdpwarp - Ein-Klick-Installation"
    install_step1       = "Binärdateien bereitstellen"
    install_step2       = "Dienste anhalten"
    install_step3       = "Dienst konfigurieren"
    install_step4       = "INI-Unterstützung prüfen"
    install_step5       = "RDP aktivieren"
    install_step6       = "Dienst starten"
    install_ok          = "rdpwarp erfolgreich installiert!`nMulti-Session RDP bereit auf Port {Port}"
    install_warn        = "Installation mit Warnungen abgeschlossen:"
    install_ini_warn    = "INI muss möglicherweise aktualisiert werden (Version {Ver})"
    install_svc_not_run = "TermService läuft nicht"
    install_port_not_listen = "Port {Port} hört nicht zu"
    install_wd          = "Watchdog zur Selbstheilung auto-registriert"
    uninstall_header   = "rdpwarp - Deinstallieren"
    uninstall_confirm  = "Dies entfernt rdpwarp und stellt die ursprünglichen Einstellungen wieder her. Fortfahren? [Y/N] "
    uninstall_cancelled = "Abgebrochen"
    uninstall_done     = "rdpwarp entfernt"
    sel_opt           = "Wählen Sie eine Option"
    inv_opt           = "Ungültige Option"
    back_main         = "Zurück zum Hauptmenü"
    unlimited         = "Unbegrenzt"
    on                = "EIN"
    off               = "AUS"
    dflt              = "Standard"
    never             = "Nie"
    min               = "Min."
    yes               = "Ja"
    no                = "Nein"
    cancel            = "Abgebrochen"
    continue_prompt   = "Drücken Sie Enter zum Fortfahren..."
    confirm_uninstall = "Dies entfernt rdpwarp und stellt die ursprünglichen Einstellungen wieder her. Fortfahren? [Y/N] "
    select_lang       = "Sprache auswählen / Select Language"
    session_state_active = "Aktiv"
    session_state_disc   = "Getr."
    session_state_conn   = "Verb."
    wd_title          = "Watchdog-Verwaltung"
    wd_reg            = "Registrieren / Erneut registrieren"
    wd_unr            = "Registrierung aufheben"
    wd_done           = "Watchdog registriert (Start + tägl. 3 Uhr)"
    restart_done      = "TermService neu gestartet"
    menu_remoteapp      = "RemoteApp erstellen"
    menu_remoteapp_desc = "Ein Programm auf dem Client-Desktop veröffentlichen"
    remoteapp_header    = "RemoteApp-Verbindungsdatei erstellen"
    remoteapp_server    = "Serveradresse"
    remoteapp_presets   = "Zu veröffentlichendes Programm wählen"
    remoteapp_custom    = "Pfad manuell eingeben"
    remoteapp_name      = "Programmname"
    remoteapp_args      = "Befehlszeilenargumente (leer lassen)"
    remoteapp_optional  = "Optionale Einstellungen"
    remoteapp_clipboard = "Zwischenablage aktivieren"
    remoteapp_drives    = "Laufwerkszuordnung aktivieren"
    remoteapp_audio     = "Audiomodus: 0=lokal 1=Server 2=aus"
    remoteapp_username  = "Benutzername (leer für Eingabe bei Verbindung)"
    remoteapp_done      = "RemoteApp-Datei erstellt: "
}

$script:UI['es'] = @{
    title         = "Administrador RDP Multisesión"
    sys_status    = "Estado del sistema"
    service       = "Servicio"
    port          = "Puerto"
    listening     = "Escuchando"
    closed        = "Cerrado"
    wrapper       = "Estado"
    installed     = "[Y] Instalado"
    not_installed = "[X] No instalado"
    ini_support   = "Soporte INI"
    ini_ok        = "[Y] Compatible"
    ini_patched   = "[+P] Parche OK"
    ini_not_patched = "[!P] Parche falló"
    ini_bad       = "[X] No compatible"
    watchdog      = "Watchdog"
    active        = "[Y] Activo"
    inactive      = "[X] Inactivo"
    sessions      = "Sesiones"
    session       = "Sesión"
    admin_required = "Se requieren privilegios de administrador"
    press_any_key = "Presione cualquier tecla para continuar..."
    menu_install      = "Instalar rdpwarp"
    menu_install_desc = "Despliegue con un clic de RDP multisesión"
    menu_exit         = "Salir"
    menu_update       = "Actualizar offsets"
    menu_update_desc  = "Reparar RDP tras actualización de Windows"
    menu_session_title  = "Configuración de sesión"
    menu_session_desc   = "Configurar sesiones máx. y límites por usuario"
    menu_session_s      = "Sesiones simultáneas máx."
    menu_session_u      = "Sesión única por usuario"
    menu_session_m      = "Cambiar sesiones máx."
    menu_session_t      = "Alternar sesión única"
    menu_session_r      = "Restablecer valores"
    menu_security_title  = "Configuración de seguridad"
    menu_security_desc   = "NLA, capa de seguridad, etc."
    menu_security_nla    = "Autenticación de nivel de red (NLA)"
    menu_security_sl     = "Capa de seguridad"
    menu_security_tn     = "Alternar NLA"
    menu_security_ss     = "Establecer capa de seguridad"
    menu_shadow_title  = "Control remoto / Modo sombra"
    menu_shadow_desc   = "Configurar nivel de permisos de asistencia remota"
    menu_shadow_cur    = "Modo actual"
    menu_shadow_off    = "Desactivado"
    menu_shadow_fwp    = "Control total (con permiso)"
    menu_shadow_fwo    = "Control total (sin permiso)"
    menu_shadow_vwp    = "Solo ver (con permiso)"
    menu_shadow_vwo    = "Solo ver (sin permiso)"
    menu_display_title  = "Opciones de pantalla y sesión"
    menu_display_desc   = "Varios monitores, ocultar usuarios, reconexión"
    menu_display_mm     = "Soporte multi-monitor"
    menu_display_hide   = "Ocultar usuarios al iniciar sesión"
    menu_display_ar     = "Reconexión automática"
    menu_display_tm     = "Alternar multi-monitor"
    menu_display_th     = "Alternar ocultar usuarios"
    menu_display_ta     = "Alternar reconexión automática"
    menu_timeout_title  = "Tiempos de espera de sesión"
    menu_timeout_desc   = "Establecer límites de desconexión/inactividad/actividad"
    menu_timeout_disc   = "Tiempo de espera por desconexión"
    menu_timeout_idle   = "Tiempo de espera por inactividad"
    menu_timeout_active = "Límite de sesión activa"
    menu_timeout_sd     = "Establecer tiempo de desconexión (min)"
    menu_timeout_si     = "Establecer tiempo de inactividad (min)"
    menu_timeout_sa     = "Establecer límite activo (min)"
    menu_timeout_reset  = "Restablecer todo (nunca desconectar)"
    menu_port_title  = "Cambiar puerto RDP"
    menu_port_desc   = "Modificar el puerto de escucha de escritorio remoto"
    menu_port_cur    = "Puerto actual"
    menu_port_prompt = "Ingrese nuevo número de puerto (1024-65535)："
    menu_port_done   = "Puerto cambiado, conéctese a: "
    menu_watchdog_title   = "Gestión del Watchdog"
    menu_watchdog_desc    = "Inicio automático, actualización automática de INI"
    menu_watchdog_reg     = "Registrar / Volver a registrar"
    menu_watchdog_unr     = "Anular registro"
    menu_restart      = "Reiniciar servicio"
    menu_restart_desc = "Reiniciar el servicio de escritorio remoto"
    menu_uninstall      = "Desinstalar rdpwarp"
    menu_uninstall_desc = "Eliminar rdpwarp y restaurar configuración"
    install_header      = "rdpwarp - Instalación con un clic"
    install_step1       = "Implementando binarios"
    install_step2       = "Deteniendo servicios"
    install_step3       = "Configurando servicio"
    install_step4       = "Verificando soporte INI"
    install_step5       = "Habilitando RDP"
    install_step6       = "Iniciando servicio"
    install_ok          = "rdpwarp instalado correctamente!`nRDP multisesión listo en el puerto {Port}"
    install_warn        = "Instalación completada con advertencias:"
    install_ini_warn    = "El INI podría necesitar actualización (versión {Ver})"
    install_svc_not_run = "TermService no se está ejecutando"
    install_port_not_listen = "Puerto {Port} no está escuchando"
    install_wd          = "Watchdog auto-registrado para autocuración"
    uninstall_header   = "rdpwarp - Desinstalación"
    uninstall_confirm  = "Esto eliminará rdpwarp y restaurará la configuración original. Continuar? [Y/N] "
    uninstall_cancelled = "Cancelado"
    uninstall_done     = "rdpwarp eliminado"
    sel_opt           = "Seleccione una opción"
    inv_opt           = "Opción inválida"
    back_main         = "Volver al menú principal"
    unlimited         = "Ilimitado"
    on                = "SÍ"
    off               = "NO"
    dflt              = "Predet."
    never             = "Nunca"
    min               = "min"
    yes               = "Sí"
    no                = "No"
    cancel            = "Cancelado"
    continue_prompt   = "Presione Enter para continuar..."
    confirm_uninstall = "Esto eliminará rdpwarp y restaurará la configuración original. Continuar? [Y/N] "
    select_lang       = "Seleccione idioma / Select Language"
    session_state_active = "Activo"
    session_state_disc   = "Descon."
    session_state_conn   = "Conex."
    wd_title          = "Gestión del Watchdog"
    wd_reg            = "Registrar / Volver a registrar"
    wd_unr            = "Anular registro"
    wd_done           = "Watchdog registrado (inicio + 3 AM diario)"
    restart_done      = "TermService reiniciado"
    menu_remoteapp      = "RemoteApp"
    menu_remoteapp_desc = "Publicar una app en el escritorio del cliente"
    remoteapp_header    = "Generar archivo de conexión RemoteApp"
    remoteapp_server    = "Dirección del servidor"
    remoteapp_presets   = "Seleccionar programa a publicar"
    remoteapp_custom    = "Ingresar ruta manualmente"
    remoteapp_name      = "Nombre del programa"
    remoteapp_args      = "Argumentos (dejar vacío para omitir)"
    remoteapp_optional  = "Configuración opcional"
    remoteapp_clipboard = "Habilitar portapapeles"
    remoteapp_drives    = "Habilitar asignación de unidades"
    remoteapp_audio     = "Modo audio: 0=local 1=servidor 2=ninguno"
    remoteapp_username  = "Usuario (dejar vacío para ingresar al conectar)"
    remoteapp_done      = "Archivo RemoteApp creado: "
}

$script:UI['ru'] = @{
    title         = "Менеджер RDP с несколькими сессиями"
    sys_status    = "Состояние системы"
    service       = "Служба"
    port          = "Порт"
    listening     = "Слушает"
    closed        = "Закрыт"
    wrapper       = "Состояние"
    installed     = "[Y] Установлен"
    not_installed = "[X] Не установлен"
    ini_support   = "Поддержка INI"
    ini_ok        = "[Y] Поддерживается"
    ini_patched   = "[+P] Патч ОК"
    ini_not_patched = "[!P] Патч ошибка"
    ini_bad       = "[X] Не поддерживается"
    watchdog      = "Watchdog"
    active        = "[Y] Работает"
    inactive      = "[X] Не работает"
    sessions      = "Сессии"
    session       = "Сессия"
    admin_required = "Требуются права администратора"
    press_any_key = "Нажмите любую клавишу для продолжения..."
    menu_install      = "Установить rdpwarp"
    menu_install_desc = "Развертывание многопользовательского RDP в один клик"
    menu_exit         = "Выйти"
    menu_update       = "Обновить смещения"
    menu_update_desc  = "Исправить RDP после обновления Windows"
    menu_session_title  = "Настройки сессий"
    menu_session_desc   = "Настроить макс. сессий и ограничения"
    menu_session_s      = "Макс. одновременных сессий"
    menu_session_u      = "Одна сессия на пользователя"
    menu_session_m      = "Изменить макс. сессий"
    menu_session_t      = "Переключить одну сессию"
    menu_session_r      = "Сбросить"
    menu_security_title  = "Настройки безопасности"
    menu_security_desc   = "NLA, уровень безопасности и др."
    menu_security_nla    = "Сетевая аутентификация (NLA)"
    menu_security_sl     = "Уровень безопасности"
    menu_security_tn     = "Переключить NLA"
    menu_security_ss     = "Установить уровень безопасности"
    menu_shadow_title  = "Удаленное управление / Тень"
    menu_shadow_desc   = "Уровень разрешений удаленной помощи"
    menu_shadow_cur    = "Текущий режим"
    menu_shadow_off    = "Выкл."
    menu_shadow_fwp    = "Полный доступ (с разрешения)"
    menu_shadow_fwo    = "Полный доступ (без разрешения)"
    menu_shadow_vwp    = "Только просмотр (с разрешения)"
    menu_shadow_vwo    = "Только просмотр (без разрешения)"
    menu_display_title  = "Дисплей и параметры сессий"
    menu_display_desc   = "Несколько мониторов, скрыть пользователей"
    menu_display_mm     = "Поддержка нескольких мониторов"
    menu_display_hide   = "Скрыть пользователей при входе"
    menu_display_ar     = "Автоматическое переподключение"
    menu_display_tm     = "Переключить несколько мониторов"
    menu_display_th     = "Переключить скрытие пользователей"
    menu_display_ta     = "Переключить автопереподключение"
    menu_timeout_title  = "Тайм-ауты сессий"
    menu_timeout_desc   = "Лимиты для отключенных/неактивных/активных"
    menu_timeout_disc   = "Тайм-аут отключенной сессии"
    menu_timeout_idle   = "Тайм-аут неактивной сессии"
    menu_timeout_active = "Лимит активной сессии"
    menu_timeout_sd     = "Тайм-аут отключения (мин)"
    menu_timeout_si     = "Тайм-аут бездействия (мин)"
    menu_timeout_sa     = "Лимит активности (мин)"
    menu_timeout_reset  = "Сбросить всё (никогда не отключать)"
    menu_port_title  = "Изменить порт RDP"
    menu_port_desc   = "Изменить порт прослушивания удаленного рабочего стола"
    menu_port_cur    = "Текущий порт"
    menu_port_prompt = "Введите номер нового порта (1024-65535)："
    menu_port_done   = "Порт изменен, подключайтесь к: "
    menu_watchdog_title   = "Управление Watchdog"
    menu_watchdog_desc    = "Автозапуск, автообновление смещений INI"
    menu_watchdog_reg     = "Зарегистрировать / Перерегистрировать"
    menu_watchdog_unr     = "Отменить регистрацию"
    menu_restart      = "Перезапустить службу"
    menu_restart_desc = "Перезапустить службу удаленного рабочего стола"
    menu_uninstall      = "Удалить rdpwarp"
    menu_uninstall_desc = "Полностью удалить rdpwarp и восстановить настройки"
    install_header      = "rdpwarp - Установка в один клик"
    install_step1       = "Развертывание файлов"
    install_step2       = "Остановка служб"
    install_step3       = "Настройка службы"
    install_step4       = "Проверка поддержки INI"
    install_step5       = "Включение RDP"
    install_step6       = "Запуск службы"
    install_ok          = "rdpwarp успешно установлен!`nМногопользовательский RDP готов на порту {Port}"
    install_warn        = "Установка завершена с предупреждениями:"
    install_ini_warn    = "INI может потребовать обновления (версия {Ver})"
    install_svc_not_run = "TermService не запущена"
    install_port_not_listen = "Порт {Port} не слушает"
    install_wd          = "Watchdog автоматически зарегистрирован для самовосстановления"
    uninstall_header   = "rdpwarp - Удаление"
    uninstall_confirm  = "Это удалит rdpwarp и восстановит исходные настройки. Продолжить? [Y/N] "
    uninstall_cancelled = "Отменено"
    uninstall_done     = "rdpwarp удален"
    sel_opt           = "Выберите действие"
    inv_opt           = "Неверный выбор"
    back_main         = "Вернуться в главное меню"
    unlimited         = "Безлимитно"
    on                = "ВКЛ"
    off               = "ВЫКЛ"
    dflt              = "По умолч."
    never             = "Никогда"
    min               = "мин"
    yes               = "Да"
    no                = "Нет"
    cancel            = "Отменено"
    continue_prompt   = "Нажмите Enter для продолжения..."
    confirm_uninstall = "Это удалит rdpwarp и восстановит исходные настройки. Продолжить? [Y/N] "
    select_lang       = "Выберите язык / Select Language"
    session_state_active = "Активна"
    session_state_disc   = "Откл."
    session_state_conn   = "Подкл."
    wd_title          = "Управление Watchdog"
    wd_reg            = "Зарегистрировать / Перерегистрировать"
    wd_unr            = "Отменить регистрацию"
    wd_done           = "Watchdog зарегистрирован (запуск + ежедневно в 3:00)"
    restart_done      = "TermService перезапущена"
    menu_remoteapp      = "RemoteApp"
    menu_remoteapp_desc = "Публикация приложения на рабочем столе клиента"
    remoteapp_header    = "Создать файл подключения RemoteApp"
    remoteapp_server    = "Адрес сервера"
    remoteapp_presets   = "Выберите программу для публикации"
    remoteapp_custom    = "Ввести путь вручную"
    remoteapp_name      = "Имя программы"
    remoteapp_args      = "Аргументы командной строки (пропустите)"
    remoteapp_optional  = "Дополнительные настройки"
    remoteapp_clipboard = "Включить буфер обмена"
    remoteapp_drives    = "Включить сопоставление дисков"
    remoteapp_audio     = "Режим аудио: 0=локально 1=сервер 2=нет"
    remoteapp_username  = "Имя пользователя (оставьте пустым для ввода при подключении)"
    remoteapp_done      = "Файл RemoteApp создан: "
}

function T($k, $f = @{}) {
    $v = $script:UI[$script:LANG][$k]
    if (-not $v) { $v = $script:UI['en'][$k] }
    if (-not $v) { return $k }
    foreach ($key in $f.Keys) { $v = $v.Replace("{$key}", $f[$key]) }
    return $v
}

function Select-Language {
    Clear-Host
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host "       $(T 'select_lang')" -ForegroundColor Cyan
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host ""
    for ($i = 0; $i -lt $script:LANGS.Count; $i++) {
        $tag = $script:LANGS[$i]
        $mark = if ($tag -eq $script:LANG) { " *" } else { "  " }
        Write-Host "  $($i+1).$mark $($script:LANG_NAMES[$tag])" -ForegroundColor Yellow
    }
    Write-Host ""
    $choice = Read-Host "> $(T 'sel_opt')"
    $num = 0
    if ([int]::TryParse($choice, [ref]$num) -and $num -ge 1 -and $num -le $script:LANGS.Count) {
        $script:LANG = $script:LANGS[$num - 1]
    }
}

$script:GH_MIRROR = if ($env:GH_MIRROR) { $env:GH_MIRROR.TrimEnd('/') + '/' } else { "" }
$script:RDPWRAP_DIR = "$env:ProgramFiles\rdpwarp"
$script:RDPWRAP_DLL = "$script:RDPWRAP_DIR\rdpwrap.dll"
$script:RDPWRAP_INI = "$script:RDPWRAP_DIR\rdpwrap.ini"
$script:TEMPLATE_INI = "$script:RDPWRAP_DIR\rdpwrap_templete.ini"
$script:WATCHDOG_TASK = "rdpwarp-Watchdog"
$script:WATCHDOG_SCRIPT = "$env:SystemRoot\Temp\rdpwarp-Watchdog.ps1"
$script:WINST_EXE = "$script:RDPWRAP_DIR\RDPWInst.exe"
$script:STATE_FILE = "$env:ProgramData\rdpwarp\install-state.json"

$script:OFFSET_DLL = if ([Environment]::Is64BitProcess) { "RDPWrapOffsetFinder_x64.dll" } else { "RDPWrapOffsetFinder_x86.dll" }

$script:SCRIPT_DIR = if ($PSScriptRoot) { $PSScriptRoot } else { "" }
$script:BIN_DIR = if ($script:SCRIPT_DIR -and (Test-Path "$script:SCRIPT_DIR\bin")) { "$script:SCRIPT_DIR\bin" } else { "" }
$script:FALLBACK_DIR = "$env:ProgramData\rdpwarp\bin"
$script:GH_REPO = "lcxxjmsg-cyber/rdp_warp_ps"
$script:GH_RAW = "https://raw.githubusercontent.com/$script:GH_REPO/main"
$script:GH_RELEASE = "https://github.com/stascorp/rdpwrap/releases/download/v1.6.2/RDPWrap-v1.6.2.zip"
$script:GH_RELEASE_SHA256 = '35A9481DDBED5177431A9EA4BD09468FE987797D7B1231D64942D17EB54EC269'
$script:BINARY_SHA256 = @{
    'rdpwrap.dll'='798AF20DB39280F90A1D35F2AC2C1D62124D1F5218A2A0FA29D87A13340BD3E4'
    'RDPWrapOffsetFinder_x64.dll'='00786951BA92EE7932E155CF465F01C484A7111CDAD5F15FC5B8C2239497EDC0'
    'RDPWrapOffsetFinder_x86.dll'='C8EB8CA716E3F4399AB30C7611DCD4CCE2242DAAEEEE078681FFF8E32DA6A50C'
}

$REG_TS = "HKLM:\SYSTEM\CurrentControlSet\Services\TermService\Parameters"
$REG_RDP = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
$REG_RDP_WS = "$REG_RDP\WinStations\RDP-Tcp"
$REG_RDP_LIC = "$REG_RDP\Licensing Core"
$REG_WINLOGON = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$REG_POLICY = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
$REG_POLICY_LOCAL = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"

function Write-I { param([Parameter(Position=0,ValueFromRemainingArguments=$true)][object[]]$Message,[switch]$NoNewline) Write-Host "  $($Message -join ' ')" -ForegroundColor Gray -NoNewline:$NoNewline }
function Write-S { param([Parameter(Position=0,ValueFromRemainingArguments=$true)][object[]]$Message,[switch]$NoNewline) Write-Host "  [+] $($Message -join ' ')" -ForegroundColor Green -NoNewline:$NoNewline }
function Write-W { param([Parameter(Position=0,ValueFromRemainingArguments=$true)][object[]]$Message,[switch]$NoNewline) Write-Host "  [!] $($Message -join ' ')" -ForegroundColor Yellow -NoNewline:$NoNewline }
function Write-E { param([Parameter(Position=0,ValueFromRemainingArguments=$true)][object[]]$Message,[switch]$NoNewline) Write-Host "  [-] $($Message -join ' ')" -ForegroundColor Red -NoNewline:$NoNewline }

function Get-GitHubDownloadUrls {
    param([string]$Uri)
    $urls = New-Object System.Collections.Generic.List[string]
    if ($script:GH_MIRROR -and $Uri -match '^https://(raw\.githubusercontent\.com|github\.com)/') {
        $urls.Add("$($script:GH_MIRROR)$Uri")
    }
    if ($Uri) { $urls.Add($Uri) }
    return @($urls | Select-Object -Unique)
}

function Invoke-GitHubDownload {
    param([string]$Uri,[string]$OutFile,[int]$TimeoutSec=30)
    $failures = New-Object System.Collections.Generic.List[string]
    foreach ($candidate in (Get-GitHubDownloadUrls $Uri)) {
        try {
            $params = @{Uri=$candidate;UseBasicParsing=$true;TimeoutSec=$TimeoutSec;ErrorAction='Stop'}
            if ($OutFile) { $params.OutFile = $OutFile }
            $response = Invoke-WebRequest @params
            if ($OutFile -and -not (Test-Path $OutFile)) { throw 'Download completed without creating the output file' }
            return [PSCustomObject]@{Success=$true;Uri=$candidate;Response=$response}
        } catch {
            $failures.Add("$candidate => $($_.Exception.Message)")
            if ($OutFile) { Remove-Item $OutFile -Force -ErrorAction SilentlyContinue }
        }
    }
    throw "All download routes failed: $($failures -join ' | ')"
}

function Test-FileSha256 {
    param([string]$Path,[string]$Expected,[string]$Label='file')
    if (-not $Expected) { return $true }
    if (-not (Test-Path $Path)) { Write-W "$Label is missing: $Path"; return $false }
    $actual = (Get-FileHash $Path -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
    if ($actual -ne $Expected) { Write-E "$Label SHA256 mismatch (expected $Expected, got $actual)"; return $false }
    return $true
}

function Test-BinaryIntegrity {
    param([string]$Filename,[string]$Path)
    return Test-FileSha256 -Path $Path -Expected $script:BINARY_SHA256[$Filename] -Label $Filename
}

function Resolve-Binary {
    param($Filename)
    $local = if ($script:BIN_DIR) { Join-Path $script:BIN_DIR $Filename } else { $null }
    if ($local -and (Test-Path $local)) {
        if (Test-FileSha256 -Path $local -Expected $script:BINARY_SHA256[$Filename] -Label "$Filename local candidate") { return $local }
        Write-W "Rejected local binary; checking the verified cache and download source"
    }
    $fallback = Join-Path $script:FALLBACK_DIR $Filename
    if (Test-Path $fallback) {
        if (Test-FileSha256 -Path $fallback -Expected $script:BINARY_SHA256[$Filename] -Label "$Filename cached candidate") {
            Write-I "Using verified cached binary: $fallback"
            return $fallback
        }
        Remove-Item $fallback -Force -ErrorAction SilentlyContinue
    }
    try {
        New-Item $script:FALLBACK_DIR -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        $url = "$script:GH_RAW/bin/$Filename"
        $out = Join-Path $script:FALLBACK_DIR $Filename
        Invoke-GitHubDownload -Uri $url -OutFile $out | Out-Null
        if ((Test-Path $out) -and (Test-FileSha256 -Path $out -Expected $script:BINARY_SHA256[$Filename] -Label "$Filename downloaded candidate")) {
            Write-I "Using verified downloaded binary via $($script:GH_RAW)"
            return $out
        }
        Remove-Item $out -Force -ErrorAction SilentlyContinue
    } catch { }
    return $null
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-TermsrvVersion {
    $path = "$env:SystemRoot\System32\termsrv.dll"
    if (-not (Test-Path $path)) { return $null }
    $vi = (Get-Item $path).VersionInfo
    return "$($vi.FileMajorPart).$($vi.FileMinorPart).$($vi.FileBuildPart).$($vi.FilePrivatePart)"
}

function Get-IniSectionBody {
    param([string]$Content,[string]$Section)
    if (-not $Content -or -not $Section) { return $null }
    $pattern = '(?ms)^\s*\[' + [regex]::Escape($Section) + '\]\s*\r?\n(?<body>.*?)(?=^\s*\[|\z)'
    $match = [regex]::Match($Content, $pattern)
    if (-not $match.Success) { return $null }
    return $match.Groups['body'].Value
}

function ConvertFrom-IniSection {
    param([string]$Body)
    $values = @{}
    if (-not $Body) { return $values }
    foreach ($line in ($Body -split "`r?`n")) {
        if ($line -match '^\s*([^;#][^=]*?)\s*=\s*(.*?)\s*$') {
            $values[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
    return $values
}

function Remove-IniSection {
    param([string]$Content,[string]$Section)
    if (-not $Content) { return $Content }
    $pattern = '(?ms)^\s*\[' + [regex]::Escape($Section) + '\]\s*\r?\n.*?(?=^\s*\[|\z)'
    return [regex]::Replace($Content, $pattern, '')
}

function Set-IniSection {
    param([string]$Content,[string]$Section,[string]$Body)
    $without = Remove-IniSection -Content $Content -Section $Section
    if ($null -eq $Body) { return $without }
    return "$($without.TrimEnd())`r`n`r`n[$Section]`r`n$($Body.Trim())`r`n"
}

function Merge-RdpIniCandidate {
    param([string]$BaseContent,[string]$SourceContent,[string]$Version)
    if (-not $BaseContent) { $BaseContent = Get-Content $script:TEMPLATE_INI -Raw -ErrorAction SilentlyContinue }
    $sourceVersion = Get-IniSectionBody -Content $SourceContent -Section $Version
    if ($null -eq $sourceVersion) { return $null }
    $baseCodes = ConvertFrom-IniSection (Get-IniSectionBody -Content $BaseContent -Section 'PatchCodes')
    $sourceCodes = ConvertFrom-IniSection (Get-IniSectionBody -Content $SourceContent -Section 'PatchCodes')
    foreach ($key in $sourceCodes.Keys) { $baseCodes[$key] = $sourceCodes[$key] }
    $codeBody = (($baseCodes.Keys | Sort-Object | ForEach-Object { "$_=$($baseCodes[$_])" }) -join "`r`n")
    $merged = Set-IniSection -Content $BaseContent -Section 'PatchCodes' -Body $codeBody
    $merged = Set-IniSection -Content $merged -Section $Version -Body $sourceVersion
    $sourceSlInit = Get-IniSectionBody -Content $SourceContent -Section "$Version-SLInit"
    $merged = Set-IniSection -Content $merged -Section "$Version-SLInit" -Body $sourceSlInit
    return $merged
}

function Test-RdpIniCandidate {
    param(
        [string]$Content,
        [string]$Version,
        [string]$Architecture = $(if ([Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' })
    )
    $result = [ordered]@{Exists=$false;Valid=$false;State='Unsupported';Message='Version section not found';Missing=@();Version=$Version;Architecture=$Architecture}
    $body = Get-IniSectionBody -Content $Content -Section $Version
    if ($null -eq $body) { return [PSCustomObject]$result }
    $result.Exists = $true
    $values = ConvertFrom-IniSection $body
    $missing = New-Object System.Collections.Generic.List[string]

    foreach ($group in @('LocalOnly','SingleUser','DefPolicy')) {
        $patchKey = "$($group)Patch.$Architecture"
        if (-not $values.ContainsKey($patchKey) -or $values[$patchKey] -ne '1') {
            $missing.Add($patchKey)
            continue
        }
        foreach ($suffix in @('Offset','Code')) {
            $key = "$group$suffix.$Architecture"
            if (-not $values.ContainsKey($key) -or -not $values[$key]) { $missing.Add($key) }
        }
    }

    $slPolicy = "SLPolicyInternal.$Architecture"
    $slInit = "SLInitHook.$Architecture"
    if ($values.ContainsKey($slPolicy) -and $values[$slPolicy] -eq '1') {
        foreach ($name in @('SLPolicyOffset','SLPolicyFunc')) {
            $key = "$name.$Architecture"
            if (-not $values.ContainsKey($key) -or -not $values[$key]) { $missing.Add($key) }
        }
    } elseif ($values.ContainsKey($slInit) -and $values[$slInit] -eq '1') {
        foreach ($name in @('SLInitOffset','SLInitFunc')) {
            $key = "$name.$Architecture"
            if (-not $values.ContainsKey($key) -or -not $values[$key]) { $missing.Add($key) }
        }
        $slBody = Get-IniSectionBody -Content $Content -Section "$Version-SLInit"
        $slValues = ConvertFrom-IniSection $slBody
        foreach ($name in @('bInitialized','bServerSku','lMaxUserSessions','bAppServerAllowed','bRemoteConnAllowed','bMultimonAllowed','ulMaxDebugSessions','bFUSEnabled')) {
            $key = "$name.$Architecture"
            if (-not $slValues.ContainsKey($key) -or $slValues[$key] -notmatch '^[0-9A-Fa-f]+$') { $missing.Add("$Version-SLInit/$key") }
        }
    } else {
        $missing.Add("$slPolicy or $slInit")
    }

    foreach ($key in @("LocalOnlyOffset.$Architecture","SingleUserOffset.$Architecture","DefPolicyOffset.$Architecture","SLPolicyOffset.$Architecture","SLInitOffset.$Architecture")) {
        if ($values.ContainsKey($key) -and $values[$key] -notmatch '^[0-9A-Fa-f]+$') { $missing.Add("$key (invalid hex offset)") }
    }

    $patchCodes = ConvertFrom-IniSection (Get-IniSectionBody -Content $Content -Section 'PatchCodes')
    foreach ($key in @("LocalOnlyCode.$Architecture","SingleUserCode.$Architecture","DefPolicyCode.$Architecture")) {
        if ($values.ContainsKey($key) -and $values[$key] -and -not $patchCodes.ContainsKey($values[$key])) {
            $missing.Add("PatchCodes/$($values[$key])")
        }
    }

    $result.Missing = @($missing | Select-Object -Unique)
    if ($result.Missing.Count -gt 0) {
        $result.State = 'InvalidConfig'
        $result.Message = "Version section is incomplete: $($result.Missing -join ', ')"
    } else {
        $result.Valid = $true
        $result.State = 'Configured'
        $result.Message = "Complete $Architecture configuration found; runtime verification required"
    }
    return [PSCustomObject]$result
}

function Test-RdpwrapHealth { param([string]$LogPath,[string]$Version)
    if (-not $LogPath) {
        $ini = Get-Content $script:RDPWRAP_INI -Raw -ErrorAction SilentlyContinue
        $LogPath = 'C:\rdpwarp\rdpwrap.log'
        if ($ini -match 'LogFile\s*=\s*(.+)') {
            $raw = $matches[1].Trim()
            if ($raw -match '^[A-Za-z]:\\') { $LogPath = $raw }
            else { $LogPath = "C:$raw" }
        }
    }
    if (-not $Version) { $Version = Get-TermsrvVersion }
    if (-not $Version) { return [PSCustomObject]@{Healthy=$false;Message='Cannot determine termsrv version';LogExists=$false;LogPath=$LogPath;Patches=@()} }
    $result = [PSCustomObject]@{Healthy=$false;Message='';LogExists=$false;LogPath=$LogPath;Version=$Version;Patches=@()}
    if (-not (Test-Path $LogPath)) {
        $result.Message = "rdpwrap log not found at $LogPath; checking runtime process evidence instead"
        return $result
    }
    $result.LogExists = $true
    $lines = Get-Content $LogPath -ErrorAction SilentlyContinue
    if (-not $lines) {
        $result.Message = 'Log file empty'
        return $result
    }
    $versionPattern = '\bVersion:\s*' + [regex]::Escape($Version)
    $versionIndexes = @(for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match $versionPattern) { $i } })
    if ($versionIndexes.Count -eq 0) {
        $result.Message = "Version line not found in log (expected $Version)"
        return $result
    }
    # Logs can survive service restarts. Only the latest initialization block is
    # authoritative; older successful or failed patch lines must not affect it.
    $lines = @($lines[$versionIndexes[-1]..($lines.Count - 1)])
    $patchLines = @($lines | Where-Object { $_ -match '^(Patch|Hook)\s' })
    $errLines = @($lines | Where-Object { $_ -match '(FAILED|ERROR|\[!\]|not found|NOT FOUND)' })
    $slInitLines = @($lines | Where-Object { $_ -match 'SLInit.*bServerSku' })
    foreach ($p in $patchLines) {
        $pName = if ($p -match '^Patch\s+(.+)$') { $matches[1] } elseif ($p -match '^Hook\s+(.+)$') { $matches[1] } else { 'Unknown' }
        $result.Patches += [PSCustomObject]@{Name=$pName;Detail=$p.Trim()}
    }
    if ($errLines.Count -gt 0) {
        $result.Message = "Patch errors in log: $($errLines -join ' | ')"
        return $result
    }
    if ($patchLines.Count -eq 0) {
        $result.Message = 'No Patch/Hook lines in log - patches may not have applied'
        return $result
    }
    $hasSingleUser = ($patchLines | Where-Object { $_ -match 'SingleSession|CEnforcement|CSession' }).Count -gt 0
    $hasDefPolicy = ($patchLines | Where-Object { $_ -match 'DefPolicy|CDefPolicy' }).Count -gt 0
    $hasSLInit = $slInitLines.Count -gt 0
    if (-not $hasSingleUser -or -not $hasDefPolicy) {
        $result.Message = 'Critical patches missing in log'
        return $result
    }
    $result.Healthy = $true
    $msg = "$($patchLines.Count) patches applied"
    if ($hasSLInit) { $msg += ', SLInit OK' }
    $result.Message = $msg
    return $result
}

function Reset-RdpwrapLogForVerification {
    $logPath = 'C:\rdpwarp\rdpwrap.log'
    $ini = Get-Content $script:RDPWRAP_INI -Raw -ErrorAction SilentlyContinue
    if ($ini -match 'LogFile\s*=\s*(.+)') {
        $raw = $matches[1].Trim()
        $logPath = if ($raw -match '^[A-Za-z]:\\') { $raw } else { "C:$raw" }
    }
    if (Test-Path $logPath) {
        $archive = "$logPath.$(Get-Date -Format 'yyyyMMdd-HHmmss').previous"
        Move-Item $logPath $archive -Force -ErrorAction SilentlyContinue
    }
    return $logPath
}

function Test-RdpProtocolHandshake {
    param([int]$Port,[int]$TimeoutMs=2500)
    $client = $null
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $connect = $client.BeginConnect('127.0.0.1',$Port,$null,$null)
        if (-not $connect.AsyncWaitHandle.WaitOne($TimeoutMs)) { return $false }
        $client.EndConnect($connect)
        $stream = $client.GetStream(); $stream.ReadTimeout = $TimeoutMs; $stream.WriteTimeout = $TimeoutMs
        [byte[]]$request = 0x03,0x00,0x00,0x13,0x0e,0xe0,0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x08,0x00,0x03,0x00,0x00,0x00
        $stream.Write($request,0,$request.Length)
        $buffer = New-Object byte[] 64
        $count = $stream.Read($buffer,0,$buffer.Length)
        return ($count -ge 11 -and $buffer[0] -eq 3)
    } catch { return $false } finally { if ($client) { $client.Close() } }
}

function Get-RdpStatus {
    $s = @{Admin=Test-Admin}
    $s.TermsrvVersion = Get-TermsrvVersion
    $svcDll = Get-ItemProperty -Path $REG_TS -Name ServiceDll -ErrorAction SilentlyContinue
    $s.ServiceDll = if ($svcDll) { $svcDll.ServiceDll } else { $null }
    $s.Installed = ($s.ServiceDll -like '*rdpwrap*')
    $svc = Get-Service -Name TermService -ErrorAction SilentlyContinue
    $s.ServiceStatus = if ($svc) { $svc.Status } else { 'Missing' }
    $port = Get-ItemProperty -Path $REG_RDP_WS -Name PortNumber -ErrorAction SilentlyContinue
    $s.Port = if ($port) { $port.PortNumber } else { 3389 }
    $conn = Get-NetTCPConnection -LocalPort $s.Port -State Listen -ErrorAction SilentlyContinue
    $s.Listener = ($null -ne $conn)
    $s.WrapperLoaded = $false
    $s.LoadedModules = ''
    if ($s.ServiceStatus -eq 'Running') {
        $tsSvc = Get-CimInstance Win32_Service -Filter "Name='TermService'" -ErrorAction SilentlyContinue
        if ($tsSvc -and $tsSvc.ProcessId -gt 0) {
            try {
                $loaded = @((Get-Process -Id $tsSvc.ProcessId -Module -ErrorAction Stop | Where-Object { $_.ModuleName -match '^(rdpwrap|termsrv)\.dll$' }).ModuleName | Sort-Object -Unique)
                $s.WrapperLoaded = ($loaded -contains 'rdpwrap.dll' -and $loaded -contains 'termsrv.dll')
                $s.LoadedModules = ($loaded -join ',')
            } catch { $s.LoadedModules = "read error: $($_.Exception.Message)" }
        }
    }
    $s.IniOk = $false; $s.Healthy = $false; $s.HealthMessage = ''; $s.SupportState = 'Unsupported'
    if ($s.Installed -and $s.TermsrvVersion -and (Test-Path $script:RDPWRAP_INI)) {
        $ini = Get-Content $script:RDPWRAP_INI -Raw -ErrorAction SilentlyContinue
        $check = Test-RdpIniCandidate -Content $ini -Version $s.TermsrvVersion
        $s.IniOk = $check.Valid
        $s.SupportState = $check.State
        if ($s.IniOk) {
            $health = Test-RdpwrapHealth -Version $s.TermsrvVersion
            $s.Healthy = $health.Healthy
            $s.HealthMessage = $health.Message
            $s.LogExists = $health.LogExists
            $s.PatchCount = $health.Patches.Count
            $s.Handshake = if ($s.Listener -and $s.ServiceStatus -eq 'Running') { Test-RdpProtocolHandshake -Port $s.Port } else { $false }
            if ($s.Healthy -and $s.Listener -and $s.Handshake) { $s.SupportState = 'Supported' }
            elseif ($s.WrapperLoaded -and $s.Listener -and $s.Handshake) {
                # The DLL's own logging is silent best-effort: a missing log file does
                # not mean the wrapper crashed. Both modules being loaded proves the
                # initialization ran, so accept the wrapper and warn about the log.
                $s.Healthy = $true
                $s.SupportState = 'Supported'
                $s.HealthMessage = "Wrapper active (rdpwrap.dll + termsrv.dll loaded); log unavailable: $($health.Message)"
            }
            elseif ($s.Healthy -and -not $s.Handshake) { $s.HealthMessage = 'Patches loaded, but the RDP protocol handshake failed' }
        } else { $s.HealthMessage = $check.Message }
    }
    try {
        $raw = @(qwinsta /SERVER:localhost 2>$null)
        $s.Sessions = @()
        $inData = $false
        foreach ($line in $raw) {
            if ($line -match '^\s*([\w\.\-]+)\s+(\w+)\s+(\w+)\s+(\d+)') {
                $s.Sessions += [PSCustomObject]@{User=$matches[1];ID=$matches[4];State=$matches[3]}
                $inData = $true
            } elseif ($inData -and $line -match '^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\d+)') {
                $s.Sessions += [PSCustomObject]@{User=$matches[1];ID=$matches[4];State=$matches[3]}
            }
        }
    } catch { $s.Sessions = @() }
    $wd = Get-ScheduledTask -TaskName $script:WATCHDOG_TASK -ErrorAction SilentlyContinue
    $s.Watchdog = ($null -ne $wd)
    return $s
}

function Stop-RdpService {
    Write-I "Stopping Remote Desktop services..."
    Stop-Service -Name UmRdpService -Force -ErrorAction SilentlyContinue
    Stop-Service -Name TermService -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800
}
function Start-RdpService {
    Write-I "Starting TermService..."
    Start-Service -Name TermService -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    $svc = Get-Service -Name TermService -ErrorAction SilentlyContinue
    if ($svc.Status -eq 'Running') { Write-S "TermService running" }
    else { Write-E "TermService: $($svc.Status)" }
}
function Restart-RdpService { Stop-RdpService; Start-RdpService; Start-Sleep -Seconds 1; Start-Service -Name UmRdpService -ErrorAction SilentlyContinue }

function Add-RdpwrapDefenderExclusions {
    $addMp = Get-Command Add-MpPreference -ErrorAction SilentlyContinue
    if (-not $addMp) { return }
    $paths = @(
        $script:RDPWRAP_DIR,
        'C:\rdpwarp',
        $script:FALLBACK_DIR,
        "$env:ProgramFiles\RDP Wrapper"
    ) | Where-Object { $_ } | Select-Object -Unique
    foreach ($path in $paths) {
        try {
            Add-MpPreference -ExclusionPath $path -ErrorAction Stop
            Write-S "Defender exclusion: $path"
        } catch {
            Write-W "Defender exclusion failed: $path ($($_.Exception.Message))"
        }
    }
}

function Deploy-RdpwrapDll {
    $dllPath = Resolve-Binary "rdpwrap.dll"
    if ($dllPath) { Copy-Item $dllPath $script:RDPWRAP_DLL -Force; Write-S "rdpwrap.dll deployed"; return $true }

    $winst = Resolve-Binary "RDPWInst.exe"
    if ($winst) {
        Copy-Item $winst $script:WINST_EXE -Force
        Write-I "Running RDPWInst.exe silently..."
        $p = Start-Process -FilePath $script:WINST_EXE -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES" -Wait -PassThru -NoNewWindow
        if ($p.ExitCode -eq 0 -and (Test-BinaryIntegrity 'rdpwrap.dll' "$env:ProgramFiles\RDP Wrapper\rdpwrap.dll")) {
            Copy-Item "$env:ProgramFiles\RDP Wrapper\rdpwrap.dll" $script:RDPWRAP_DLL -Force
            Write-S "rdpwrap.dll extracted via RDPWInst"
            return $true
        }
    }

    Write-I "Downloading rdpwrap from GitHub..."
    try {
        $zip = "$env:TEMP\rdpw_install.zip"
        $extract = "$env:TEMP\rdpw_install_ext"
        $download = Invoke-GitHubDownload -Uri $script:GH_RELEASE -OutFile $zip -TimeoutSec 60
        Write-I "RDP Wrapper downloaded via $($download.Uri)"
        if (-not (Test-FileSha256 -Path $zip -Expected $script:GH_RELEASE_SHA256 -Label 'RDPWrap v1.6.2 release')) { throw 'Downloaded release failed integrity verification' }
        Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
        New-Item $extract -ItemType Directory -Force | Out-Null
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $extract)
        $instExe = Get-ChildItem $extract -Recurse -Filter RDPWInst.exe | Select-Object -First 1
        if ($instExe) {
            Copy-Item $instExe.FullName $script:WINST_EXE -Force
            $p = Start-Process -FilePath $script:WINST_EXE -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES" -Wait -PassThru -NoNewWindow
            if ($p.ExitCode -eq 0 -and (Test-BinaryIntegrity 'rdpwrap.dll' "$env:ProgramFiles\RDP Wrapper\rdpwrap.dll")) {
                Copy-Item "$env:ProgramFiles\RDP Wrapper\rdpwrap.dll" $script:RDPWRAP_DLL -Force
                Write-S "rdpwrap.dll deployed via downloaded installer"
                Remove-Item $zip -Force -ErrorAction SilentlyContinue
                Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
                return $true
            }
        }
        Remove-Item $zip -Force -ErrorAction SilentlyContinue
        Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
    } catch { Write-E "Download failed: $_" }
    return $false
}

function Install-RdpWrapperBinaries {
    try {
        New-Item -ItemType Directory -Path $script:RDPWRAP_DIR -Force | Out-Null
        icacls $script:RDPWRAP_DIR /grant "SYSTEM:(OI)(CI)F" /grant "S-1-5-6:(OI)(CI)F" /q 2>$null
        $logDir = 'C:\rdpwarp'
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        icacls $logDir /grant "SYSTEM:(OI)(CI)F" /q 2>$null
        Add-RdpwrapDefenderExclusions

        if (-not (Deploy-RdpwrapDll)) { throw "Failed to deploy rdpwrap.dll" }

        $iniContent = @"
[Main]
Updated=2024-01-01
LogFile=__LOG_PATH__
SLPolicyHookNT60=1
SLPolicyHookNT61=1

[PatchCodes]
nop=90
Zero=00
jmpshort=EB
nopjmp=90E9
CDefPolicy_Query_edx_ecx=BA000100008991200300005E90
CDefPolicy_Query_eax_rcx_jmp=B80001000089813806000090EB
CDefPolicy_Query_eax_esi=B80001000089862003000090
CDefPolicy_Query_eax_rdi=B80001000089873806000090
CDefPolicy_Query_eax_ecx=B80001000089812403000090
CDefPolicy_Query_eax_ecx_jmp=B800010000898120030000EB0E
CDefPolicy_Query_eax_rcx=B80001000089813806000090
CDefPolicy_Query_edi_rcx=BF0001000089B938060000909090
nop_3=909090
nop_7=90909090909090
mov_eax_1_nop_1=B80100000090
mov_eax_1_nop_2=B8010000009090
nop_4=90909090
pop_eax_add_esp_12_nop_2=5883C40C9090
CDefPolicy_Query_eax_rdi_jmp=B80001000089873806000090EB
CDefPolicy_Query_r9d_rdi_jmp=C7873806000000010000EB

[SLInit]
bServerSku=1
bRemoteConnAllowed=1
bFUSEnabled=1
bAppServerAllowed=1
bMultimonAllowed=1
lMaxUserSessions=0
ulMaxDebugSessions=0
bInitialized=1

[SLPolicy]
TerminalServices-RemoteConnectionManager-AllowRemoteConnections=1
TerminalServices-RemoteConnectionManager-AllowMultipleSessions=1
TerminalServices-RemoteConnectionManager-AllowAppServerMode=1
TerminalServices-RemoteConnectionManager-AllowMultimon=1
TerminalServices-RemoteConnectionManager-MaxUserSessions=0
TerminalServices-RemoteConnectionManager-ce0ad219-4670-4988-98fb-89b14c2f072b-MaxSessions=0
TerminalServices-RemoteConnectionManager-45344fe7-00e6-4ac6-9f01-d01fd4ffadfb-MaxSessions=2
TerminalServices-RDP-7-Advanced-Compression-Allowed=1
TerminalServices-RemoteConnectionManager-45344fe7-00e6-4ac6-9f01-d01fd4ffadfb-LocalOnly=0
TerminalServices-RemoteConnectionManager-8dc86f1d-9969-4379-91c1-06fe1dc60575-MaxSessions=1000
TerminalServices-DeviceRedirection-Licenses-TSEasyPrintAllowed=1
TerminalServices-DeviceRedirection-Licenses-PnpRedirectionAllowed=1
TerminalServices-DeviceRedirection-Licenses-TSMFPluginAllowed=1
TerminalServices-RemoteConnectionManager-UiEffects-DWMRemotingAllowed=1
"@
        $iniContent = $iniContent.Replace('__LOG_PATH__', 'C:\rdpwarp\rdpwrap.log')
        $iniContent | Out-File $script:TEMPLATE_INI -Encoding ASCII
        $existingIni = Get-Content $script:RDPWRAP_INI -Raw -ErrorAction SilentlyContinue
        if (-not $existingIni -or -not $existingIni.Contains('[PatchCodes]')) { Copy-Item $script:TEMPLATE_INI $script:RDPWRAP_INI -Force }
        Write-S "INI template deployed"

        $ofl = Resolve-Binary $script:OFFSET_DLL
        if ($ofl) {
            Copy-Item $ofl "$script:RDPWRAP_DIR\$script:OFFSET_DLL" -Force
            Write-S "OffsetFinder DLL deployed ($script:OFFSET_DLL)"
        } else {
            Write-W "Compatible OffsetFinder DLL not found for this PowerShell process; incompatible architecture fallback is disabled"
        }

        return (Test-Path $script:RDPWRAP_DLL)
    } catch { Write-E "Deploy failed: $_"; return $false }
}

function Update-RdpwrapIni {
    $termsrv = "$env:SystemRoot\System32\termsrv.dll"
    $ver = Get-TermsrvVersion
    if (-not $ver -or -not (Test-Path $termsrv)) { Write-E "termsrv.dll not found"; return $false }
    $ini = Get-Content $script:RDPWRAP_INI -Raw -ErrorAction SilentlyContinue
    $current = Test-RdpIniCandidate -Content $ini -Version $ver
    if ($current.Valid) {
        $service = Get-Service TermService -ErrorAction SilentlyContinue
        if (-not $service -or $service.Status -ne 'Running') {
            Write-S "INI has a complete configuration for $ver (runtime verification will run after service start)"
            return $true
        }
        $health = Test-RdpwrapHealth -Version $ver
        if ($health.Healthy) {
            Write-S "INI configuration for $ver passed runtime verification"
            return $true
        }
        Write-W "INI is structurally complete but runtime verification failed: $($health.Message)"
        Write-I 'Continuing with community refresh and OffsetFinder fallback...'
    }
    if ($current.Exists) { Write-W $current.Message }

    $sources = @(
        @{Name='asmtron';Url='https://raw.githubusercontent.com/asmtron/rdpwrap/master/res/rdpwrap.ini'},
        @{Name='sebaxakerhtc';Url='https://raw.githubusercontent.com/sebaxakerhtc/rdpwrap.ini/master/rdpwrap.ini'},
        @{Name='affinityv';Url='https://raw.githubusercontent.com/affinityv/INI-RDPWRAP/master/rdpwrap.ini'}
    )
    foreach ($source in $sources) {
        Write-I "Checking $($source.Name) INI..."
        try {
            $download = Invoke-GitHubDownload -Uri $source.Url -TimeoutSec 30
            $sourceContent = $download.Response.Content
            $content = Merge-RdpIniCandidate -BaseContent $ini -SourceContent $sourceContent -Version $ver
            $check = Test-RdpIniCandidate -Content $content -Version $ver
            if ($check.Valid) {
                if (Test-Path $script:RDPWRAP_INI) { Copy-Item $script:RDPWRAP_INI "$script:RDPWRAP_INI.bak" -Force }
                $content | Out-File $script:RDPWRAP_INI -Encoding ASCII
                Write-S "$($source.Name) version sections merged for $ver via $($download.Uri)"
                return $true
            }
            if ($check.Exists) { Write-W "$($source.Name) entry rejected: $($check.Message)" }
        } catch { Write-W "$($source.Name) download failed: $_" }
    }

    $dllPath = "$script:RDPWRAP_DIR\$script:OFFSET_DLL"
    if (Test-Path $dllPath) {
        Write-I "No validated community entry; trying OffsetFinder as a candidate generator..."
        try {
            $dllEscaped = $dllPath -replace '\\','\\\\'
            if (-not ('RDPOffsetFinderNative' -as [type])) {
                $code = @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class RDPOffsetFinderNative {
    [DllImport("$dllEscaped", CharSet=CharSet.Unicode)]
    public static extern int FindRDPOffsets(string path, StringBuilder output, int bufSize, int flags);
    [DllImport("$dllEscaped", CharSet=CharSet.Unicode)]
    public static extern int FindRDPOffsetsNoSym(string path, StringBuilder output, int bufSize, int flags);
}
"@
                Add-Type $code -ErrorAction Stop
            }
            $strategies = @('Symbols')
            if ($ExperimentalNoSym) { $strategies += 'NoSym' }
            foreach ($strategy in $strategies) {
                if ($strategy -eq 'NoSym') { Write-W 'Experimental NoSym scanning explicitly enabled; VM testing is strongly recommended' }
                $sb = New-Object Text.StringBuilder 131072
                $hr = if ($strategy -eq 'NoSym') {
                    [RDPOffsetFinderNative]::FindRDPOffsetsNoSym($termsrv, $sb, $sb.Capacity, 0)
                } else {
                    [RDPOffsetFinderNative]::FindRDPOffsets($termsrv, $sb, $sb.Capacity, 0)
                }
                $generated = $sb.ToString()
                if ($hr -ge 0 -and $generated -and -not $generated.Contains("ERROR:")) {
                    $base = Remove-IniSection -Content $ini -Section $ver
                    $base = Remove-IniSection -Content $base -Section "$ver-SLInit"
                    $candidate = "$($base.TrimEnd())`r`n`r`n$generated`r`n"
                    $check = Test-RdpIniCandidate -Content $candidate -Version $ver
                    if ($check.Valid) {
                        if (Test-Path $script:RDPWRAP_INI) { Copy-Item $script:RDPWRAP_INI "$script:RDPWRAP_INI.bak" -Force }
                        $candidate | Out-File $script:RDPWRAP_INI -Encoding ASCII
                        Write-S "OffsetFinder $strategy generated a complete candidate for $ver; runtime verification pending"
                        return $true
                    }
                    Write-W "OffsetFinder $strategy output rejected: $($check.Message)"
                } else {
                    Write-W "OffsetFinder $strategy did not produce a clean result (HRESULT=$hr)"
                }
            }
        } catch { Write-W "DLL failed: $_" }
    }
    Write-W "No source produced a valid configuration for $ver; status remains Unsupported"
    return $false
}

function Get-RegDword { param($Path,$Name) $v = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue; if ($v) { $v.$Name } else { $null } }
function Set-RegDword {
    param($Path,$Name,$Value,$Type='DWord')
    try {
        if (-not (Test-Path -LiteralPath $Path)) {
            New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
        }
        $existing = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction SilentlyContinue
        if ($null -ne $existing) {
            Set-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -ErrorAction Stop
        } else {
            New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null
        }
        return $true
    } catch { Write-W "Registry write failed: $Path\$Name ($($_.Exception.Message))"; return $false }
}

function Get-RdpStateRegistrySpecs {
    return @(
        @{Path=$REG_TS;Name='ServiceDll';Type='ExpandString'}, @{Path=$REG_TS;Name='ServiceDllUnloadOnStop';Type='DWord'},
        @{Path='HKLM:\SYSTEM\CurrentControlSet\Services\TermService';Name='Type';Type='DWord'},
        @{Path=$REG_RDP_WS;Name='PortNumber';Type='DWord'},
        @{Path=$REG_RDP;Name='fDenyTSConnections';Type='DWord'}, @{Path='HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations';Name='DWMFRAMEINTERVAL';Type='DWord'},
        @{Path=$REG_RDP_LIC;Name='EnableConcurrentSessions';Type='DWord'}, @{Path=$REG_WINLOGON;Name='AllowMultipleTSSessions';Type='DWord'},
        @{Path=$REG_POLICY;Name='MaxInstanceCount';Type='DWord'}, @{Path=$REG_POLICY;Name='fSingleSessionPerUser';Type='DWord'},
        @{Path=$REG_RDP_WS;Name='UserAuthentication';Type='DWord'}, @{Path=$REG_RDP_WS;Name='SecurityLayer';Type='DWord'},
        @{Path=$REG_POLICY_LOCAL;Name='Shadow';Type='DWord'}, @{Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services';Name='Shadow';Type='DWord'}, @{Path=$REG_POLICY;Name='fEnableRemoteFX';Type='DWord'},
        @{Path=$REG_WINLOGON;Name='HideConsoleUsers';Type='DWord'}, @{Path=$REG_POLICY;Name='fDisableAutoReconnect';Type='DWord'},
        @{Path=$REG_POLICY;Name='MaxDisconnectionTime';Type='DWord'}, @{Path=$REG_POLICY;Name='MaxIdleTime';Type='DWord'},
        @{Path=$REG_POLICY;Name='MaxSessionTime';Type='DWord'}, @{Path=$REG_POLICY;Name='KeepAliveEnable';Type='DWord'},
        @{Path=$REG_POLICY;Name='KeepAliveInterval';Type='DWord'},
        @{Path='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList';Name='fDisabledAllowList';Type='DWord'}
    )
}

function Save-RdpInstallState {
    try {
        $registry = @()
        foreach ($spec in (Get-RdpStateRegistrySpecs)) {
            $item = Get-ItemProperty -Path $spec.Path -Name $spec.Name -ErrorAction SilentlyContinue
            $registry += [PSCustomObject]@{Path=$spec.Path;Name=$spec.Name;Type=$spec.Type;Exists=($null-ne$item);Value=$(if($item){$item.($spec.Name)}else{$null})}
        }
        $svc = Get-Service TermService -ErrorAction SilentlyContinue
        $defenderTargets = @($script:RDPWRAP_DIR,'C:\rdpwarp',$script:FALLBACK_DIR,"$env:ProgramFiles\RDP Wrapper") | Where-Object { $_ } | Select-Object -Unique
        $existingExclusions = @()
        if (Get-Command Get-MpPreference -ErrorAction SilentlyContinue) { $existingExclusions = @((Get-MpPreference -ErrorAction SilentlyContinue).ExclusionPath) }
        $state = [PSCustomObject]@{
            Schema=1;SavedAt=(Get-Date).ToString('o');Registry=$registry
            TermServiceStatus=$(if($svc){[string]$svc.Status}else{'Missing'});TermServiceStartType=$(if($svc){[string]$svc.StartType}else{$null})
            WrapperDirExisted=(Test-Path $script:RDPWRAP_DIR)
            DefenderAdded=@($defenderTargets | Where-Object { $existingExclusions -notcontains $_ })
        }
        New-Item (Split-Path $script:STATE_FILE -Parent) -ItemType Directory -Force -ErrorAction Stop | Out-Null
        $state | ConvertTo-Json -Depth 6 | Out-File $script:STATE_FILE -Encoding UTF8 -Force
        return $true
    } catch { Write-E "Failed to save installation state: $_"; return $false }
}

function Restore-RdpInstallState {
    param([switch]$KeepState,[switch]$CleanupFiles)
    if (-not (Test-Path $script:STATE_FILE)) { Write-W 'Installation state snapshot not found'; return $false }
    try {
        $state = Get-Content $script:STATE_FILE -Raw -Encoding UTF8 | ConvertFrom-Json
        $currentPort = Get-RegDword $REG_RDP_WS PortNumber
        if ($currentPort) { Remove-RdpFirewallPort ([int]$currentPort) }
        Stop-RdpService
        foreach ($entry in $state.Registry) {
            if ($entry.Exists) {
                if (-not (Test-Path -LiteralPath $entry.Path)) {
                    New-Item -Path $entry.Path -Force -ErrorAction Stop | Out-Null
                }
                $currentValue = Get-ItemProperty -LiteralPath $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue
                if ($null -ne $currentValue) {
                    Set-ItemProperty -LiteralPath $entry.Path -Name $entry.Name -Value $entry.Value -ErrorAction Stop
                } else {
                    New-ItemProperty -LiteralPath $entry.Path -Name $entry.Name -Value $entry.Value -PropertyType $entry.Type -Force -ErrorAction Stop | Out-Null
                }
            } else { Remove-ItemProperty -Path $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue }
        }
        if ($state.TermServiceStartType -and $state.TermServiceStartType -ne 'Missing') {
            Set-Service TermService -StartupType $state.TermServiceStartType -ErrorAction SilentlyContinue
        }
        if ($state.TermServiceStatus -eq 'Running') { Start-RdpService } else { Stop-RdpService }
        if (Get-Command Remove-MpPreference -ErrorAction SilentlyContinue) {
            foreach ($path in @($state.DefenderAdded)) { Remove-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue }
        }
        if ($CleanupFiles -and -not $state.WrapperDirExisted -and (Test-Path $script:RDPWRAP_DIR)) { Remove-Item $script:RDPWRAP_DIR -Recurse -Force }
        if (-not $KeepState) { Remove-Item $script:STATE_FILE -Force -ErrorAction SilentlyContinue }
        return $true
    } catch { Write-E "State restoration failed: $_"; return $false }
}

function Invoke-RdpInstallRollback {
    param([string]$Reason)
    Write-E $Reason
    if (-not (Restore-RdpInstallState -KeepState -CleanupFiles)) { Write-E 'Automatic rollback was incomplete; inspect ServiceDll and TermService before rebooting' }
}

function Test-RdpHostCapability {
    $edition = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).EditionID
    $nativeUnsupported = @('Core','CoreSingleLanguage','CoreCountrySpecific','Starter') -contains $edition
    $checks = [ordered]@{
        TermsrvDll = Test-Path "$env:SystemRoot\System32\termsrv.dll"
        TermService = $null -ne (Get-Service TermService -ErrorAction SilentlyContinue)
        RdpTcpRegistry = Test-Path $REG_RDP_WS
    }
    $missing = @($checks.Keys | Where-Object { -not $checks[$_] })
    return [PSCustomObject]@{
        CanInstall = $missing.Count -eq 0
        NativeHostSupported = -not $nativeUnsupported
        Edition = $edition
        Missing = $missing
        Message = if ($missing.Count) { "Missing RDP components: $($missing -join ', ')" } elseif ($nativeUnsupported) { "Windows edition $edition has no native RDP host; RDP Wrapper support is required" } else { "Native RDP host components detected ($edition)" }
    }
}

function Test-RdpTcpRegistryHealth {
    $result = [ordered]@{Healthy=$true;Port=$null;Missing=@();Message=''}
    if (-not (Test-Path -LiteralPath $REG_RDP_WS)) {
        $result.Healthy = $false
        $result.Missing = @('RDP-Tcp registry key')
    } else {
        $properties = Get-ItemProperty -LiteralPath $REG_RDP_WS -ErrorAction SilentlyContinue
        $port = 0
        if ($properties) { [void][int]::TryParse([string]$properties.PortNumber,[ref]$port) }
        if ($port -lt 1 -or $port -gt 65535) { $result.Missing += 'PortNumber' } else { $result.Port = $port }
        if ($null -eq $properties.fEnableWinStation) { $result.Missing += 'fEnableWinStation' }
        if ([string]::IsNullOrWhiteSpace([string]$properties.WdName)) { $result.Missing += 'WdName' }
        # NOTE: WinStationName must NOT be required here. Windows does not create
        # it under ...\WinStations\RDP-Tcp by default (fresh Win10/11 keys lack
        # it), so requiring it blocks clean installations. A listener key stripped
        # by an old uninstall is still caught by the key, PortNumber,
        # fEnableWinStation and WdName checks above.
        if ($result.Missing.Count -gt 0) { $result.Healthy = $false }
    }
    $result.Message = if ($result.Healthy) {
        "Native RDP-Tcp listener configuration is complete (port $($result.Port))"
    } else {
        "Native RDP-Tcp listener configuration is incomplete: $($result.Missing -join ', ')"
    }
    return [PSCustomObject]$result
}

function Get-RdpFirewallRuleNames {
    param([int]$Port)
    return @("rdpwarp-RDP-TCP-$Port-In","rdpwarp-RDP-UDP-$Port-In")
}

function Add-RdpFirewallPort {
    param([int]$Port)
    if ($Port -lt 1 -or $Port -gt 65535) { return $false }
    $names = Get-RdpFirewallRuleNames $Port
    try {
        if (Get-Command New-NetFirewallRule -ErrorAction SilentlyContinue) {
            Remove-NetFirewallRule -DisplayName $names[0] -ErrorAction SilentlyContinue
            Remove-NetFirewallRule -DisplayName $names[1] -ErrorAction SilentlyContinue
            New-NetFirewallRule -DisplayName $names[0] -Direction Inbound -Action Allow -Protocol TCP -LocalPort $Port -Profile Any -ErrorAction Stop | Out-Null
            New-NetFirewallRule -DisplayName $names[1] -Direction Inbound -Action Allow -Protocol UDP -LocalPort $Port -Profile Any -ErrorAction Stop | Out-Null
            $tcp = Get-NetFirewallRule -DisplayName $names[0] -ErrorAction Stop
            $udp = Get-NetFirewallRule -DisplayName $names[1] -ErrorAction Stop
            $tcpFilter = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $tcp -ErrorAction Stop
            $udpFilter = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $udp -ErrorAction Stop
            return ($tcp.Enabled -eq 'True' -and $udp.Enabled -eq 'True' -and
                [string]$tcpFilter.LocalPort -eq [string]$Port -and [string]$tcpFilter.Protocol -eq 'TCP' -and
                [string]$udpFilter.LocalPort -eq [string]$Port -and [string]$udpFilter.Protocol -eq 'UDP')
        }
        & netsh advfirewall firewall delete rule name="$($names[0])" 2>$null | Out-Null
        & netsh advfirewall firewall delete rule name="$($names[1])" 2>$null | Out-Null
        & netsh advfirewall firewall add rule name="$($names[0])" dir=in protocol=tcp localport=$Port profile=any action=allow 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) { return $false }
        & netsh advfirewall firewall add rule name="$($names[1])" dir=in protocol=udp localport=$Port profile=any action=allow 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    } catch { Write-W "Firewall rule creation failed for port $Port`: $_"; return $false }
}

function Remove-RdpFirewallPort {
    param([int]$Port)
    $names = Get-RdpFirewallRuleNames $Port
    if (Get-Command Remove-NetFirewallRule -ErrorAction SilentlyContinue) {
        Remove-NetFirewallRule -DisplayName $names[0] -ErrorAction SilentlyContinue
        Remove-NetFirewallRule -DisplayName $names[1] -ErrorAction SilentlyContinue
    } else {
        & netsh advfirewall firewall delete rule name="$($names[0])" 2>$null | Out-Null
        & netsh advfirewall firewall delete rule name="$($names[1])" 2>$null | Out-Null
    }
}

function Enable-RdpHostAccess {
    param([int]$Port=3389)
    if (-not (Set-RegDword $REG_RDP fDenyTSConnections 0)) { throw 'Failed to enable Remote Desktop in the registry' }
    $svc = Get-Service TermService -ErrorAction SilentlyContinue
    if ($svc -and $svc.StartType -eq 'Disabled') { Set-Service TermService -StartupType Manual -ErrorAction SilentlyContinue }
    if (-not (Add-RdpFirewallPort $Port)) { throw "Failed to create validated TCP/UDP firewall rules for RDP port $Port" }
    $deny = Get-RegDword $REG_RDP fDenyTSConnections
    if ($deny -ne 0) { throw 'Remote Desktop remained disabled after registry update' }
    return $true
}

function Enable-Rdp60FpsLimit {
    $winStations = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations'
    if (-not (Set-RegDword $winStations DWMFRAMEINTERVAL 15)) { return $false }
    return (Get-RegDword $winStations DWMFRAMEINTERVAL) -eq 15
}

function Invoke-Install {
    Clear-Host
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host "          $(T 'install_header')" -ForegroundColor Cyan
    Write-Host "=======================================================" -ForegroundColor Cyan

    if (-not (Test-Admin)) { Write-E "Admin required"; return }
    $capability = Test-RdpHostCapability
    if (-not $capability.CanInstall) { Write-E $capability.Message; return }
    if ($capability.NativeHostSupported) { Write-S $capability.Message } else { Write-W $capability.Message }
    $rdpTcpHealth = Test-RdpTcpRegistryHealth
    if (-not $rdpTcpHealth.Healthy) {
        Write-E $rdpTcpHealth.Message
        Write-E 'Installation stopped because an old uninstall or registry tool damaged the native listener configuration'
        return
    }
    if ((Get-RdpStatus).Installed) {
        Write-W "rdpwarp already installed."
        Write-I "Run the script again for menu options, or use -Uninstall to remove."
        return
    }
    if (-not (Save-RdpInstallState)) { Write-E 'Installation cancelled because the original system state could not be saved'; return }

    Write-I "[1/6] $(T 'install_step1')..."
    if (-not (Install-RdpWrapperBinaries)) { Invoke-RdpInstallRollback 'Binary deployment failed'; return }
    Write-I "[2/6] $(T 'install_step2')..."
    Stop-RdpService
    Write-I "[3/6] $(T 'install_step3')..."
    try {
        & sc.exe config TermService type= own | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "sc.exe failed to isolate TermService (exit $LASTEXITCODE)" }
        $serviceType = (Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\TermService' -Name Type -ErrorAction Stop).Type
        if ([int]$serviceType -ne 16) { throw "TermService isolation readback failed (Type=$serviceType, expected 16)" }
        if (-not (Set-RegDword $REG_TS ServiceDllUnloadOnStop 1)) { throw 'Failed to configure ServiceDllUnloadOnStop' }
        Write-S 'TermService isolated in its own service host'
        Set-ItemProperty -Path $REG_TS -Name ServiceDll -Value $script:RDPWRAP_DLL -Type ExpandString -ErrorAction Stop
        $configuredServiceDll = (Get-ItemProperty -LiteralPath $REG_TS -Name ServiceDll -ErrorAction Stop).ServiceDll
        $configuredServiceDllPath = [Environment]::ExpandEnvironmentVariables([string]$configuredServiceDll)
        if (-not [string]::Equals(
            [IO.Path]::GetFullPath($configuredServiceDllPath),
            [IO.Path]::GetFullPath($script:RDPWRAP_DLL),
            [StringComparison]::OrdinalIgnoreCase
        )) {
            throw "ServiceDll readback mismatch (expected $script:RDPWRAP_DLL, got $configuredServiceDll)"
        }
        if (-not (Test-BinaryIntegrity 'rdpwrap.dll' $configuredServiceDllPath)) {
            throw "Configured ServiceDll failed integrity verification: $configuredServiceDllPath"
        }
        Write-S "ServiceDll verified: $configuredServiceDllPath"
    }
    catch { Invoke-RdpInstallRollback "Failed to configure ServiceDll: $_"; return }
    Write-I "[4/6] $(T 'install_step4')..."
    $iniReady = Update-RdpwrapIni
    if (-not $iniReady) {
        Invoke-RdpInstallRollback 'No valid configuration exists for this termsrv.dll; installation was safely aborted'
        return
    }
    Write-I "[5/6] $(T 'install_step5')..."
    $configuredPort = Get-RegDword $REG_RDP_WS PortNumber
    $installPort = 0
    if ($null -ne $configuredPort) { [void][int]::TryParse([string]$configuredPort, [ref]$installPort) }
    if ($installPort -lt 1 -or $installPort -gt 65535) {
        $installPort = 3389
        Write-W 'No valid existing RDP port was found; using the Windows default port 3389'
        if (-not (Set-RegDword $REG_RDP_WS PortNumber $installPort)) {
            Invoke-RdpInstallRollback 'Failed to configure fallback RDP port 3389'
            return
        }
    } else {
        Write-I "Preserving the existing system RDP port: $installPort"
    }
    $portReadback = Get-RegDword $REG_RDP_WS PortNumber
    if ([int]$portReadback -ne $installPort) { Invoke-RdpInstallRollback "RDP port verification failed (expected $installPort, got $portReadback)"; return }
    try { Enable-RdpHostAccess -Port $installPort | Out-Null } catch { Invoke-RdpInstallRollback ("RDP host activation failed on port {0}: {1}" -f $installPort,$_); return }
    Set-RegDword $REG_RDP_LIC EnableConcurrentSessions 1 | Out-Null
    Set-RegDword $REG_WINLOGON AllowMultipleTSSessions 1 | Out-Null
    New-Item "$REG_RDP\AddIns" -Force -ErrorAction SilentlyContinue | Out-Null
    if (Enable-Rdp60FpsLimit) { Write-S 'RDP maximum frame-rate limit configured for 60 FPS (reboot required)' }
    else { Write-W 'Failed to configure the RDP 60 FPS maximum frame-rate limit' }
    Set-RegDword "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList" fDisabledAllowList 1 | Out-Null
    Get-Service -Name CertPropSvc,SessionEnv -ErrorAction SilentlyContinue | Where-Object StartType -eq Disabled | ForEach-Object { sc.exe config $_.Name start=demand 2>$null }
    Write-I "[6/6] $(T 'install_step6')..."
    Reset-RdpwrapLogForVerification | Out-Null
    Start-RdpService

    $s = $null
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        $s = Get-RdpStatus
        if ($s.SupportState -eq 'Supported') { break }
        Start-Sleep -Milliseconds 500
    }
    Write-Host "-------------------------------------------------------" -ForegroundColor Cyan
    if ($s.SupportState -eq 'Supported') {
        Register-RdpWatchdog -Quiet
        Write-S $(T 'install_ok' @{Port=$s.Port})
    } else {
        $configuredDll = (Get-ItemProperty -LiteralPath $REG_TS -Name ServiceDll -ErrorAction SilentlyContinue).ServiceDll
        $expandedDll = [Environment]::ExpandEnvironmentVariables([string]$configuredDll)
        $processArch = if ([Environment]::Is64BitProcess) { 'x64' } else { 'x86' }
        Write-E "Runtime diagnostic: ServiceDll=$configuredDll; expanded=$expandedDll; exists=$(Test-Path -LiteralPath $expandedDll); process=$processArch"
        $termServiceRuntime = Get-CimInstance Win32_Service -Filter "Name='TermService'" -ErrorAction SilentlyContinue
        $loadedRdpModules = @()
        $moduleReadError = $null
        if ($termServiceRuntime.ProcessId -gt 0) {
            try {
                $loadedRdpModules = @((Get-Process -Id $termServiceRuntime.ProcessId -Module -ErrorAction Stop | Where-Object { $_.ModuleName -match '^(rdpwrap|termsrv)\.dll$' }).ModuleName)
            } catch { $moduleReadError = $_.Exception.Message }
        }
        $wrapperLoaded = ($loadedRdpModules -contains 'rdpwrap.dll' -and $loadedRdpModules -contains 'termsrv.dll')
        Write-E "Runtime process: pid=$($termServiceRuntime.ProcessId); loadedRdpModules=$($loadedRdpModules -join ','); wrapperLoaded=$wrapperLoaded; moduleReadError=$moduleReadError"
        $ciEvents = @(Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-CodeIntegrity/Operational';StartTime=(Get-Date).AddMinutes(-10)} -MaxEvents 100 -ErrorAction SilentlyContinue | Where-Object { $_.Message -match 'rdpwrap|TermService' } | Select-Object -First 10)
        if ($ciEvents.Count -gt 0) {
            foreach ($ciEvent in $ciEvents) { Write-E "CodeIntegrity event $($ciEvent.Id): $($ciEvent.Message -replace '[\r\n]+',' ')" }
        } else {
            Write-I 'No matching Code Integrity event was found in the last 10 minutes'
        }
        $logCandidates = @(
            'C:\rdpwrap.txt','C:\rdpwrap.log',
            "$script:RDPWRAP_DIR\rdpwrap.txt","$script:RDPWRAP_DIR\rdpwrap.log",
            'C:\rdpwarp\rdpwrap.txt','C:\rdpwarp\rdpwrap.log',
            "$env:SystemRoot\System32\rdpwrap.txt","$env:SystemRoot\System32\rdpwrap.log",
            "$env:ProgramFiles\RDP Wrapper\rdpwrap.txt","$env:ProgramFiles\RDP Wrapper\rdpwrap.log"
        )
        $iniLog = Get-Content $script:RDPWRAP_INI -Raw -ErrorAction SilentlyContinue
        if ($iniLog -match 'LogFile\s*=\s*(.+)') {
            $rawLog = $matches[1].Trim()
            $logCandidates += $(if ($rawLog -match '^[A-Za-z]:\\') { $rawLog } else { "C:$rawLog" })
        }
        foreach ($candidateLog in ($logCandidates | Select-Object -Unique)) {
            Write-I "Log probe: $candidateLog exists=$(Test-Path -LiteralPath $candidateLog)"
        }
        foreach ($logRoot in @('C:\rdpwarp',$script:RDPWRAP_DIR,"$env:ProgramFiles\RDP Wrapper") | Where-Object { $_ } | Select-Object -Unique) {
            if (-not (Test-Path -LiteralPath $logRoot)) { continue }
            $foundLogs = @(Get-ChildItem -LiteralPath $logRoot -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^rdpwrap.*\.(log|txt)(\..*)?$' })
            foreach ($fl in $foundLogs) { Write-I "Log file found: $($fl.FullName) ($($fl.Length) bytes, $($fl.LastWriteTime))" }
        }
        $failure = "Runtime verification failed ($($s.SupportState)): $($s.HealthMessage)"
        Invoke-RdpInstallRollback $failure
        Write-E 'Installation was rolled back; multi-session RDP was not declared supported'
        if (-not $Install) { [void](Read-Host 'Press Enter to return to the menu') }
        return
    }
    Write-I $(T 'install_wd')
}

function Invoke-Uninstall {
    Clear-Host
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host "          $(T 'uninstall_header')" -ForegroundColor Cyan
    Write-Host "=======================================================" -ForegroundColor Cyan
    if (-not (Test-Admin)) { Write-E "Admin required"; return }
    Write-W "$(T 'uninstall_confirm')" -NoNewline
    if ((Read-Host).ToUpper() -ne 'Y') { Write-I $(T 'uninstall_cancelled'); return }
    Unregister-RdpWatchdog
    if (Restore-RdpInstallState -CleanupFiles) { Write-S "$(T 'uninstall_done') Original registry, port, service, FPS and Defender state restored" }
    else {
        Write-W 'State snapshot unavailable; performing an old-version compatible uninstall'
        $legacyPort = 0
        $legacyPortValue = Get-RegDword $REG_RDP_WS PortNumber
        if ($null -ne $legacyPortValue) { [void][int]::TryParse([string]$legacyPortValue,[ref]$legacyPort) }
        if ($legacyPort -lt 1 -or $legacyPort -gt 65535) {
            $legacyPort = 3389
            Set-RegDword $REG_RDP_WS PortNumber $legacyPort | Out-Null
            Write-W 'Legacy installation had no valid RDP port; restored the Windows default port 3389'
        } else {
            Write-I "Preserving legacy/system RDP port: $legacyPort"
        }
        Stop-RdpService
        Set-ItemProperty -Path $REG_TS -Name ServiceDll -Value "%SystemRoot%\System32\termsrv.dll" -Type ExpandString -ErrorAction Stop
        Remove-ItemProperty -LiteralPath $REG_TS -Name ServiceDllUnloadOnStop -ErrorAction SilentlyContinue
        if (-not (Set-RegDword $REG_RDP fDenyTSConnections 0)) { Write-W 'Could not keep native Remote Desktop enabled during legacy cleanup' }
        if (-not (Add-RdpFirewallPort $legacyPort)) { Write-W "Could not restore TCP/UDP firewall rules for native RDP port $legacyPort" }
        Start-RdpService
        $legacyListener = $false
        for ($attempt=0; $attempt -lt 20; $attempt++) {
            if (Get-NetTCPConnection -State Listen -LocalPort $legacyPort -ErrorAction SilentlyContinue) { $legacyListener=$true;break }
            Start-Sleep -Milliseconds 500
        }
        if ($legacyListener -and (Test-RdpProtocolHandshake -Port $legacyPort)) {
            Write-S "Native RDP restored and verified on port $legacyPort"
        } else {
            Write-E "Native RDP did not recover on port $legacyPort; the legacy uninstall may have damaged RDP-Tcp registry configuration"
        }
        if (Test-Path $script:RDPWRAP_DIR) { Remove-Item $script:RDPWRAP_DIR -Recurse -Force }
        Write-S $(T 'uninstall_done')
    }
}

function Register-RdpWatchdog { param([switch]$Quiet)
    if (-not $Quiet) { Clear-Host; Write-Host "=======================================================" -ForegroundColor Cyan; Write-Host "          $(T 'wd_title')" -ForegroundColor Cyan; Write-Host "=======================================================" -ForegroundColor Cyan }
    $wdMirror = $script:GH_MIRROR
    $validatorFunctions = @(
        "function Get-IniSectionBody { $(${function:Get-IniSectionBody}) }",
        "function ConvertFrom-IniSection { $(${function:ConvertFrom-IniSection}) }",
        "function Remove-IniSection { $(${function:Remove-IniSection}) }",
        "function Set-IniSection { $(${function:Set-IniSection}) }",
        "function Merge-RdpIniCandidate { $(${function:Merge-RdpIniCandidate}) }",
        "function Test-RdpIniCandidate { $(${function:Test-RdpIniCandidate}) }"
    ) -join "`r`n`r`n"
    $scriptBody = $validatorFunctions + "`r`n`r`n" + @'
$l="$env:ProgramFiles\rdpwarp\watchdog.log";$i="$env:ProgramFiles\rdpwarp\rdpwrap.ini";$t="$env:SystemRoot\System32\termsrv.dll"
$v=(Get-Item $t).VersionInfo;$k="$($v.FileMajorPart).$($v.FileMinorPart).$($v.FileBuildPart).$($v.FilePrivatePart)"
function w{param($m)"$(Get-Date -F 'yyyy-MM-dd HH:mm:ss') $m"|Out-File $l -Append}
function rh{
$svc=Get-Service TermService -EA 0
if(!$svc-or$svc.Status-ne'Running'){return $false}
$p=(Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name PortNumber -EA 0).PortNumber
if(!(Get-NetTCPConnection -State Listen -LocalPort $p -EA 0)){return $false}
$log='C:\rdpwarp\rdpwrap.log';$z=@(Get-Content $log -EA 0)
if($z.Count){
$start=-1
for($j=0;$j-lt$z.Count;$j++){if($z[$j]-match('\bVersion:\s*'+[regex]::Escape($k))){$start=$j}}
if($start-ge0){
$tail=@($z[$start..($z.Count-1)])
if(-not($tail|Where-Object{$_-match'(FAILED|ERROR|\[!\]|not found|NOT FOUND)'})){
$patch=@($tail|Where-Object{$_-match'^(Patch|Hook)\s'})
if(($patch|Where-Object{$_-match'SingleSession|CEnforcement|CSession'}).Count-gt0-and($patch|Where-Object{$_-match'DefPolicy|CDefPolicy'}).Count-gt0){return $true}
}}}
$ci=Get-CimInstance Win32_Service -Filter "Name='TermService'" -EA 0
if($ci-and$ci.ProcessId-gt0){
try{$m=@((Get-Process -Id $ci.ProcessId -Module -EA Stop|Where-Object{$_.ModuleName-match'^(rdpwrap|termsrv)\.dll$'}).ModuleName|Sort-Object -Unique);return($m-contains'rdpwrap.dll'-and$m-contains'termsrv.dll')}catch{return $false}}
return $false}
$c=Get-Content $i -Raw -EA 0;$q=Test-RdpIniCandidate -Content $c -Version $k
if($q.Valid){if(rh){exit 0};w"Static configuration exists but runtime health failed; restarting";Restart-Service TermService -Force -EA 0;Start-Sleep 3;if(rh){w"Runtime recovered after restart";exit 0}}elseif($q.Exists){w"Invalid local entry for $k`: $($q.Message)"}
w"Need update for $k"
$ok=$false;$m='MIRRORPLACEHOLDER'
foreach($u in @('INI_ASMTRON','INI_SEBAX','INI_AFFINITY')){foreach($route in @($(if($m){"$m$u"}),$u)|Where-Object{$_}|Select-Object -Unique){try{$n=Invoke-WebRequest $route -UseBasicParsing -TimeoutSec 20;$x=Merge-RdpIniCandidate -BaseContent $c -SourceContent $n.Content -Version $k;$q=Test-RdpIniCandidate -Content $x -Version $k;if($q.Valid){Copy-Item $i "$i.bak" -Force -EA 0;$x|Out-File $i -Encoding ASCII;$ok=$true;w"Validated and merged online configuration: $route";break}elseif($q.Exists){w"Rejected online entry: $($q.Message)"}}catch{w"Online failure ($route): $_"}};if($ok){break}}
$a=if([Environment]::Is64BitProcess){'x64'}else{'x86'};$d="$env:ProgramFiles\rdpwarp\RDPWrapOffsetFinder_$a.dll";$dh=if($a-eq'x64'){'00786951BA92EE7932E155CF465F01C484A7111CDAD5F15FC5B8C2239497EDC0'}else{'C8EB8CA716E3F4399AB30C7611DCD4CCE2242DAAEEEE078681FFF8E32DA6A50C'}
if((Test-Path $d)-and(Get-FileHash $d -Algorithm SHA256 -EA 0).Hash-ne$dh){w"OffsetFinder integrity check failed";$d=$null}
if(!$ok-and$d-and(Test-Path $d)){try{Add-Type @"
using System;using System.Runtime.InteropServices;using System.Text;
public class F{[DllImport("$($d-replace'\\','\\\\')",CharSet=CharSet.Unicode)]public static extern int FindRDPOffsets(string p,StringBuilder o,int s,int f);}
"@;$b=New-Object Text.StringBuilder 131072;$h=[F]::FindRDPOffsets($t,$b,$b.Capacity,0);$g=$b.ToString();if($h-ge0-and$g-and!$g.Contains("ERROR:")){$base=Remove-IniSection $c $k;$base=Remove-IniSection $base "$k-SLInit";$x="$($base.TrimEnd())`r`n`r`n$g`r`n";$q=Test-RdpIniCandidate -Content $x -Version $k;if($q.Valid){Copy-Item $i "$i.bak" -Force -EA 0;$x|Out-File $i -Encoding ASCII;$ok=$true;w"Validated OffsetFinder candidate"}else{w"Rejected OffsetFinder output: $($q.Message)"}}}catch{w"OffsetFinder failure: $_"}}
if($ok){Stop-Service TermService -Force -EA 0;Start-Sleep 1;Start-Service TermService -EA 0;Start-Sleep 3;if(rh){w"Configuration installed and runtime verified"}else{w"Runtime verification failed; restoring previous INI";if(Test-Path "$i.bak"){Copy-Item "$i.bak" $i -Force;Restart-Service TermService -Force -EA 0}}}else{w"Unsupported: no valid configuration found"}
'@
    $scriptBody = $scriptBody.Replace('MIRRORPLACEHOLDER', $wdMirror)
    $scriptBody = $scriptBody.Replace('INI_ASMTRON', 'https://raw.githubusercontent.com/asmtron/rdpwrap/master/res/rdpwrap.ini')
    $scriptBody = $scriptBody.Replace('INI_SEBAX', 'https://raw.githubusercontent.com/sebaxakerhtc/rdpwrap.ini/master/rdpwrap.ini')
    $scriptBody = $scriptBody.Replace('INI_AFFINITY', 'https://raw.githubusercontent.com/affinityv/INI-RDPWRAP/master/rdpwrap.ini')
    try {
        $scriptBody | Out-File $script:WATCHDOG_SCRIPT -Encoding ASCII -Force
        $a = New-ScheduledTaskAction -Execute powershell.exe -Argument "-NoP -W Hidden -Exec Bypass -File `"$($script:WATCHDOG_SCRIPT)`""
        $t1 = New-ScheduledTaskTrigger -AtStartup
        $t2 = New-ScheduledTaskTrigger -Daily -At 03:00
        $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden
        Unregister-ScheduledTask -TaskName $script:WATCHDOG_TASK -Confirm:$false -ErrorAction SilentlyContinue
        Register-ScheduledTask -TaskName $script:WATCHDOG_TASK -Action $a -Trigger $t1,$t2 -Settings $set -User "NT AUTHORITY\SYSTEM" -RunLevel Highest -Force | Out-Null
        if (-not $Quiet) { Write-S $(T 'wd_done') }
    } catch { if (-not $Quiet) { Write-E "Watchdog failed: $_" } }
}
function Unregister-RdpWatchdog {
    Unregister-ScheduledTask -TaskName $script:WATCHDOG_TASK -Confirm:$false -ErrorAction SilentlyContinue
    if (Test-Path $script:WATCHDOG_SCRIPT) { Remove-Item $script:WATCHDOG_SCRIPT -Force -ErrorAction SilentlyContinue }
}

function Show-ConfigMenu { param($Title,$Items)
    Clear-Host
    Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "| $($Title.PadRight(50))|" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
    $idx = 0
    foreach ($item in $Items) {
        $idx++
        if ($item -is [string]) {
            if ($item -eq '-') { Write-Host "|  $(''.PadRight(48))|" -ForegroundColor DarkGray }
            else { Write-Host "|  $item" -ForegroundColor DarkGray }
        } else {
            $val = if ($null -ne $item.Value) { "[$($item.Value)]" } else { "" }
            $color = if ($item.Color) { $item.Color } else { 'White' }
            Write-Host "|  " -NoNewline; Write-Host "$idx." -NoNewline -ForegroundColor Yellow
            Write-Host " $($item.Label.PadRight(20)) $val" -ForegroundColor $color
        }
    }
    Write-Host "|                                                    |" -ForegroundColor DarkGray
    Write-Host "|  0. $(T 'back_main')                                    |" -ForegroundColor Green
    Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
}

function Set-RdpPort {
    if (-not (Test-Admin)) { Write-E "$(T 'admin_required')"; Write-Host ""; cmd /c pause 2>&1 | Out-Null; return }
    $s = Get-RdpStatus
    Show-ConfigMenu (T 'menu_port_title') @("$(T 'menu_port_cur'): $($s.Port)","-","$(T 'menu_port_prompt')")
    $p = Read-Host "> "
    if ($p -match '^\d+$' -and [int]$p -ge 1024 -and [int]$p -le 65535) {
        $port = [int]$p
        $oldPort = [int]$s.Port
        if ($port -eq $oldPort) { Write-S "RDP is already configured for port $port"; Write-Host ""; cmd /c pause 2>&1 | Out-Null; return }
        if ($env:SESSIONNAME -match '^RDP-') {
            Write-E 'Changing and restarting the RDP listener from an active RDP session is unsafe. Run this option from the local console.'
            Write-Host ""; cmd /c pause 2>&1 | Out-Null; return
        }
        $tcpConflict = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue
        $udpConflict = Get-NetUDPEndpoint -LocalPort $port -ErrorAction SilentlyContinue
        if ($tcpConflict -or $udpConflict) { Write-E "Port $port is already in use"; Write-Host ""; cmd /c pause 2>&1 | Out-Null; return }
        if (-not (Add-RdpFirewallPort $port)) { Write-E "Failed to open TCP/UDP firewall rules for port $port"; Write-Host ""; cmd /c pause 2>&1 | Out-Null; return }
        Set-RegDword $REG_RDP_WS PortNumber $port | Out-Null
        $readback = Get-ItemProperty -Path $REG_RDP_WS -Name PortNumber -ErrorAction SilentlyContinue
        if (-not $readback -or $readback.PortNumber -ne $port) {
            Remove-RdpFirewallPort $port
            Write-E "Failed to write port to registry"; Write-Host ""; cmd /c pause 2>&1 | Out-Null; return
        }
        Restart-RdpService
        $listenerReady = $false
        for ($attempt=0; $attempt -lt 10; $attempt++) {
            if (Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue) { $listenerReady = $true; break }
            Start-Sleep -Milliseconds 500
        }
        if ($listenerReady -and -not (Test-RdpProtocolHandshake -Port $port)) {
            Write-W "A TCP listener appeared on $port, but it did not complete an RDP protocol handshake"
            $listenerReady = $false
        }
        if (-not $listenerReady) {
            Write-W "No listener appeared on $port; rolling back to $oldPort"
            Set-RegDword $REG_RDP_WS PortNumber $oldPort | Out-Null
            Add-RdpFirewallPort $oldPort | Out-Null
            Restart-RdpService
            Remove-RdpFirewallPort $port
            Write-E "Port change failed and was rolled back to $oldPort"
            Write-Host ""; cmd /c pause 2>&1 | Out-Null; return
        }
        Remove-RdpFirewallPort $oldPort
        Write-S "$(T 'menu_port_done') $($env:COMPUTERNAME):$port"
        Write-S "TCP/UDP firewall rules migrated from $oldPort to $port and the RDP protocol handshake was verified"
    } else { Write-W "Invalid port. Use a value from 1024 to 65535." }
    Write-Host ""; cmd /c pause 2>&1 | Out-Null
}

function Set-RdpSessions {
    do {
        $s = Get-RegDword $REG_POLICY "MaxInstanceCount"
        $sspu = Get-RegDword $REG_POLICY "fSingleSessionPerUser"
        Show-ConfigMenu (T 'menu_session_title') @(
            @{Label=(T 'menu_session_s');Value=if($null -ne $s){$s}else{(T 'unlimited')}}
            @{Label=(T 'menu_session_u');Value=if($sspu -eq 1){T 'on'}elseif($sspu -eq 0){T 'off'}else{T 'dflt'}}
            "-"
            @{Label="1. $(T 'menu_session_m')"}
            @{Label="2. $(T 'menu_session_t')"}
            @{Label="3. $(T 'menu_session_r')"}
        )
        $c = Read-Host "> "
        switch ($c) {
            "1" { Write-I "$(T 'menu_session_m') (0=$(T 'unlimited')):" -NoNewline; $v = Read-Host; if ($v -match '^\d+$') { Set-RegDword $REG_POLICY MaxInstanceCount [int]$v } }
            "2" { $cur = Get-RegDword $REG_POLICY fSingleSessionPerUser; Set-RegDword $REG_POLICY fSingleSessionPerUser $(if($cur -eq 1){0}else{1}) }
            "3" { Remove-Item "$REG_POLICY\MaxInstanceCount" -Force -EA 0; Remove-Item "$REG_POLICY\fSingleSessionPerUser" -Force -EA 0 }
            default { if ($c -ne '0') { Write-W "$(T 'inv_opt')"; Start-Sleep -Milliseconds 800 } }
        }
        if ($c -eq '1' -or $c -eq '2' -or $c -eq '3') { Restart-RdpService }
    } while ($c -ne '0')
}

function Set-RdpSecurity {
    do {
        $nla = Get-RegDword $REG_RDP_WS "UserAuthentication"
        $sl = Get-RegDword $REG_RDP_WS "SecurityLayer"
        $nlaStr = if ($nla -eq 1) { T 'on' } elseif ($nla -eq 0) { T 'off' } else { T 'dflt' }
        $slStr = @{0="RDP";1="Negotiate";2="TLS"}[[int]$sl]
        Show-ConfigMenu (T 'menu_security_title') @(
            @{Label=(T 'menu_security_nla');Value=$nlaStr}
            @{Label=(T 'menu_security_sl');Value=$slStr}
            "-"
            @{Label="1. $(T 'menu_security_tn')"}
            @{Label="2. $(T 'menu_security_ss')"}
        )
        $c = Read-Host "> "
        switch ($c) {
            "1" { $cur = Get-RegDword $REG_RDP_WS UserAuthentication; Set-RegDword $REG_RDP_WS UserAuthentication $(if($cur -eq 1){0}else{1}) }
            "2" { Write-I "$(T 'menu_security_ss'): 0=RDP 1=Negotiate 2=TLS:" -NoNewline; $v = Read-Host; if($v -match '^[0-2]$'){Set-RegDword $REG_RDP_WS SecurityLayer [int]$v} }
            default { if ($c -ne '0') { Write-W "$(T 'inv_opt')"; Start-Sleep -Milliseconds 800 } }
        }
        if ($c -eq '1' -or $c -eq '2') { Restart-RdpService }
    } while ($c -ne '0')
}

# ============================================================
# Shadow (Remote Control) - global policy + per-user policy
# Precedence: per-user policy (HKCU\...\Terminal Services\Shadow)
# > machine policy (HKLM\SOFTWARE\Policies\...\Shadow)
# > legacy local value (HKLM\...\RDP-Tcp\Shadow, written by old
#   versions) > system default (full control with permission).
# ============================================================

$script:SHADOW_UI = @{
    zh = @{ global='全局策略'; user='用户级策略'; notcfg='未配置'; eff='生效值'; legacy='本地遗留 (RDP-Tcp)'; note='用户级策略优先于全局策略'; cur='当前值'; seluser='选择要设置的用户'; nousers='未找到本地用户'; apply='已应用：{0} = {1}'; cleared='已清除：{0}'; clear_global='清除（未配置）'; clear_legacy='清除本地遗留值 (RDP-Tcp)'; gclear='全局策略已清除'; legcleared='本地遗留值已清除'; err_hive='无法访问 {0} 的配置文件（可能未登录过或权限不足）'; err_write='写入验证失败：{0}'; apply_note='对用户的新会话生效；已登录会话需注销重登' }
    en = @{ global='Global Policy'; user='Per-User Policy'; notcfg='Not Configured'; eff='Effective'; legacy='Legacy Local (RDP-Tcp)'; note='Per-user policy overrides global policy'; cur='Current value'; seluser='Select a user to configure'; nousers='No local users found'; apply='Applied: {0} = {1}'; cleared='Cleared: {0}'; clear_global='Clear (Not Configured)'; clear_legacy='Clear legacy local value (RDP-Tcp)'; gclear='Global policy cleared'; legcleared='Legacy local value cleared'; err_hive='Cannot access the profile for {0} (never logged in or insufficient permission)'; err_write='Write verification failed: {0}'; apply_note='Takes effect for new sessions; logged-on sessions need a re-logon' }
    ja = @{ global='グローバルポリシー'; user='ユーザー別ポリシー'; notcfg='未設定'; eff='有効値'; legacy='ローカル残存 (RDP-Tcp)'; note='ユーザー別ポリシーはグローバルポリシーより優先されます'; cur='現在の値'; seluser='設定するユーザーを選択'; nousers='ローカルユーザーが見つかりません'; apply='適用しました：{0} = {1}'; cleared='クリアしました：{0}'; clear_global='クリア（未設定）'; clear_legacy='ローカル残存値をクリア (RDP-Tcp)'; gclear='グローバルポリシーをクリアしました'; legcleared='ローカル残存値をクリアしました'; err_hive='{0} のプロファイルにアクセスできません（未ログオンまたは権限不足）'; err_write='書き込み検証に失敗：{0}'; apply_note='新しいセッションに適用されます。ログオン中のセッションは再ログオンが必要です' }
    ko = @{ global='글로벌 정책'; user='사용자별 정책'; notcfg='미설정'; eff='적용 값'; legacy='로컬 레거시 (RDP-Tcp)'; note='사용자별 정책이 글로벌 정책보다 우선합니다'; cur='현재 값'; seluser='설정할 사용자 선택'; nousers='로컬 사용자를 찾을 수 없습니다'; apply='적용됨: {0} = {1}'; cleared='해제됨: {0}'; clear_global='해제 (미설정)'; clear_legacy='로컬 레거시 값 해제 (RDP-Tcp)'; gclear='글로벌 정책이 해제되었습니다'; legcleared='로컬 레거시 값이 해제되었습니다'; err_hive='{0}의 프로필에 접근할 수 없습니다 (로그인 이력 없음 또는 권한 부족)'; err_write='쓰기 검증 실패: {0}'; apply_note='새 세션부터 적용됩니다. 로그인 중인 세션은 다시 로그인해야 합니다' }
    fr = @{ global='Politique globale'; user='Politique par utilisateur'; notcfg='Non configuré'; eff='Valeur effective'; legacy='Héritage local (RDP-Tcp)'; note='La politique utilisateur prime sur la politique globale'; cur='Valeur actuelle'; seluser='Choisir un utilisateur à configurer'; nousers='Aucun utilisateur local trouvé'; apply='Appliqué : {0} = {1}'; cleared='Effacé : {0}'; clear_global='Effacer (non configuré)'; clear_legacy='Effacer la valeur héritée locale (RDP-Tcp)'; gclear='Politique globale effacée'; legcleared='Valeur héritée locale effacée'; err_hive='Impossible d''accéder au profil de {0} (jamais connecté ou permissions insuffisantes)'; err_write='Échec de vérification de l''écriture : {0}'; apply_note='Effectif pour les nouvelles sessions ; une reconnexion est requise pour les sessions actives' }
    de = @{ global='Globale Richtlinie'; user='Richtlinie pro Benutzer'; notcfg='Nicht konfiguriert'; eff='Effektiv'; legacy='Lokaler Alt-Wert (RDP-Tcp)'; note='Die Benutzerrichtlinie hat Vorrang vor der globalen Richtlinie'; cur='Aktueller Wert'; seluser='Benutzer zum Konfigurieren wählen'; nousers='Keine lokalen Benutzer gefunden'; apply='Angewendet: {0} = {1}'; cleared='Gelöscht: {0}'; clear_global='Löschen (nicht konfiguriert)'; clear_legacy='Lokalen Alt-Wert löschen (RDP-Tcp)'; gclear='Globale Richtlinie gelöscht'; legcleared='Lokaler Alt-Wert gelöscht'; err_hive='Profil von {0} nicht zugänglich (nie angemeldet oder unzureichende Rechte)'; err_write='Schreibverifikation fehlgeschlagen: {0}'; apply_note='Gilt für neue Sitzungen; aktive Sitzungen erfordern eine erneute Anmeldung' }
    es = @{ global='Política global'; user='Política por usuario'; notcfg='No configurado'; eff='Efectivo'; legacy='Local heredado (RDP-Tcp)'; note='La política por usuario prevalece sobre la global'; cur='Valor actual'; seluser='Seleccionar un usuario para configurar'; nousers='No se encontraron usuarios locales'; apply='Aplicado: {0} = {1}'; cleared='Borrado: {0}'; clear_global='Borrar (no configurado)'; clear_legacy='Borrar valor local heredado (RDP-Tcp)'; gclear='Política global borrada'; legcleared='Valor local heredado borrado'; err_hive='No se puede acceder al perfil de {0} (nunca inició sesión o permisos insuficientes)'; err_write='Error de verificación de escritura: {0}'; apply_note='Aplica para nuevas sesiones; las sesiones activas requieren un nuevo inicio de sesión' }
    ru = @{ global='Глобальная политика'; user='Политика пользователя'; notcfg='Не настроено'; eff='Действующее значение'; legacy='Локальный устаревший (RDP-Tcp)'; note='Политика пользователя имеет приоритет над глобальной'; cur='Текущее значение'; seluser='Выберите пользователя для настройки'; nousers='Локальные пользователи не найдены'; apply='Применено: {0} = {1}'; cleared='Очищено: {0}'; clear_global='Очистить (не настроено)'; clear_legacy='Очистить локальный устаревший параметр (RDP-Tcp)'; gclear='Глобальная политика очищена'; legcleared='Локальный устаревший параметр очищен'; err_hive='Нет доступа к профилю {0} (нет входа в систему или недостаточно прав)'; err_write='Не удалось проверить запись: {0}'; apply_note='Действует для новых сессий; активным сессиям требуется повторный вход' }
}

function Get-ShadowUi {
    $u = $script:SHADOW_UI[$script:LANG]
    if (-not $u) { $u = $script:SHADOW_UI['en'] }
    return $u
}

function S($k, $f = @()) {
    $v = (Get-ShadowUi)[$k]
    if (-not $v) { $v = $script:SHADOW_UI['en'][$k] }
    if (-not $v) { return $k }
    for ($i = 0; $i -lt $f.Count; $i++) { $v = $v.Replace("{$i}", [string]$f[$i]) }
    return $v
}

function Get-ShadowModeMap {
    return @{0=(T 'menu_shadow_off');1=(T 'menu_shadow_fwp');2=(T 'menu_shadow_fwo');3=(T 'menu_shadow_vwp');4=(T 'menu_shadow_vwo')}
}

function Format-ShadowValue {
    param($Value,[hashtable]$Map,[string]$NotConfigured)
    try {
        if ($null -ne $Value -and $Map.ContainsKey([int]$Value)) { return "$Value = $($Map[[int]$Value])" }
    } catch { }
    return $NotConfigured
}

function Get-ShadowUsers {
    $users = @()
    try {
        if (Get-Command Get-LocalUser -ErrorAction SilentlyContinue) {
            $users = @(Get-LocalUser -ErrorAction Stop)
        }
    } catch { $users = @() }
    if ($users.Count -eq 0) {
        try { $users = @(Get-CimInstance Win32_UserAccount -Filter 'LocalAccount=True' -ErrorAction Stop) } catch { $users = @() }
    }
    $exclude = @('DefaultAccount','WDAGUtilityAccount')
    $result = @()
    foreach ($u in $users) {
        $name = if ($u.PSObject.Properties['Name']) { [string]$u.Name } else { '' }
        if (-not $name -or $exclude -contains $name) { continue }
        $sid = if ($u.PSObject.Properties['SID']) { [string]$u.SID } elseif ($u.PSObject.Properties['Sid']) { [string]$u.Sid } else { '' }
        if (-not $sid -or -not $sid.StartsWith('S-1-5')) { continue }
        $result += [PSCustomObject]@{ Name=$name; Sid=$sid }
    }
    return @($result | Sort-Object Name)
}

function Get-ShadowUserValue {
    param([string]$Sid)
    $ts = 'SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
    try {
        if ([Microsoft.Win32.Registry]::Users.GetSubKeyNames() -contains $Sid) {
            $k = [Microsoft.Win32.Registry]::Users.OpenSubKey("$Sid\$ts")
            if (-not $k) { return $null }
            try { return $k.GetValue('Shadow', $null) } finally { $k.Close() }
        }
        $profile = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$Sid" -Name ProfileImagePath -ErrorAction SilentlyContinue).ProfileImagePath
        if (-not $profile) { return $null }
        $ntuser = Join-Path $profile 'NTUSER.DAT'
        if (-not (Test-Path -LiteralPath $ntuser -ErrorAction SilentlyContinue)) { return $null }
        $mount = "rdpwarp_shadow_$Sid"
        & reg.exe unload "HKU\$mount" 2>&1 | Out-Null
        & reg.exe load "HKU\$mount" $ntuser 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { return $null }
        try {
            $k = [Microsoft.Win32.Registry]::Users.OpenSubKey("$mount\$ts")
            if (-not $k) { return $null }
            try { return $k.GetValue('Shadow', $null) } finally { $k.Close() }
        } finally { & reg.exe unload "HKU\$mount" 2>&1 | Out-Null }
    } catch { return $null }
}

function Set-ShadowUserValue {
    param([string]$Sid,[int]$Value,[switch]$Clear)
    $ts = 'SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
    $mount = ''
    try {
        if ([Microsoft.Win32.Registry]::Users.GetSubKeyNames() -contains $Sid) {
            $root = $Sid
        } else {
            $profile = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$Sid" -Name ProfileImagePath -ErrorAction SilentlyContinue).ProfileImagePath
            if (-not $profile) { return $null }
            $ntuser = Join-Path $profile 'NTUSER.DAT'
            if (-not (Test-Path -LiteralPath $ntuser -ErrorAction SilentlyContinue)) { return $null }
            $mount = "rdpwarp_shadow_$Sid"
            & reg.exe unload "HKU\$mount" 2>&1 | Out-Null
            & reg.exe load "HKU\$mount" $ntuser 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { return $null }
            $root = $mount
        }
        $k = [Microsoft.Win32.Registry]::Users.CreateSubKey("$root\$ts")
        try {
            if ($Clear) {
                if ($k.GetValueNames() -contains 'Shadow') { $k.DeleteValue('Shadow', $false) }
                return ($k.GetValueNames() -notcontains 'Shadow')
            }
            $k.SetValue('Shadow', $Value, [Microsoft.Win32.RegistryValueKind]::DWord)
            return ([int]$k.GetValue('Shadow', -1) -eq $Value)
        } finally { $k.Close() }
    } catch { return $false } finally {
        if ($mount) { & reg.exe unload "HKU\$mount" 2>&1 | Out-Null }
    }
}

function Get-ShadowGlobal {
    $policy = Get-RegDword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' 'Shadow'
    $legacy = Get-RegDword $REG_POLICY_LOCAL 'Shadow'
    $eff = $policy
    if ($null -eq $eff) { $eff = $legacy }
    return [PSCustomObject]@{ Policy = $policy; Legacy = $legacy; Effective = $eff }
}

function Set-ShadowGlobal {
    param([int]$Value,[switch]$Clear)
    $policy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
    if ($Clear) {
        Remove-ItemProperty -LiteralPath $policy -Name 'Shadow' -ErrorAction SilentlyContinue
        return ($null -eq (Get-RegDword $policy 'Shadow'))
    }
    if (-not (Set-RegDword $policy 'Shadow' $Value)) { return $false }
    return ((Get-RegDword $policy 'Shadow') -eq $Value)
}

function Set-ShadowGlobalMenu {
    $su = Get-ShadowUi
    $sv = Get-ShadowModeMap
    do {
        $g = Get-ShadowGlobal
        Show-ConfigMenu (S 'global') @(
            @{Label=(S 'cur');Value=(Format-ShadowValue -Value $g.Policy -Map $sv -NotConfigured $su.notcfg)}
            @{Label=(S 'eff');Value=(Format-ShadowValue -Value $g.Effective -Map $sv -NotConfigured $su.notcfg)}
            @{Label=(S 'legacy');Value=(Format-ShadowValue -Value $g.Legacy -Map $sv -NotConfigured $su.notcfg)}
            "-"
            @{Label="1. $(T 'menu_shadow_off')"}
            @{Label="2. $(T 'menu_shadow_fwp')"}
            @{Label="3. $(T 'menu_shadow_fwo')"}
            @{Label="4. $(T 'menu_shadow_vwp')"}
            @{Label="5. $(T 'menu_shadow_vwo')"}
            @{Label="6. $(S 'clear_global')"}
            @{Label="7. $(S 'clear_legacy')"}
        )
        $c = Read-Host "> "
        switch -Regex ($c) {
            '^[1-5]$' { if (Set-ShadowGlobal -Value ([int]$c - 1)) { Write-S (S 'apply' @((S 'global'), $sv[([int]$c - 1)])); Write-I $su.apply_note } else { Write-E (S 'err_write' @((S 'global'))) } }
            '^6$' { if (Set-ShadowGlobal -Clear) { Write-S $su.gclear } else { Write-E (S 'err_write' @((S 'global'))) } }
            '^7$' { Remove-ItemProperty -LiteralPath $REG_POLICY_LOCAL -Name 'Shadow' -ErrorAction SilentlyContinue; Write-S $su.legcleared }
            '^0$' { }
            default { Write-W (T 'inv_opt'); Start-Sleep -Milliseconds 800 }
        }
    } while ($c -ne '0')
}

function Set-ShadowUserMenu {
    $su = Get-ShadowUi
    $sv = Get-ShadowModeMap
    $users = Get-ShadowUsers
    if ($users.Count -eq 0) { Write-W $su.nousers; Start-Sleep -Milliseconds 800; return }
    $target = $null
    $exit = $false
    do {
        Clear-Host
        Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
        Write-Host "|  $(S 'seluser')" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
        for ($i = 0; $i -lt $users.Count; $i++) {
            $cur = Get-ShadowUserValue -Sid $users[$i].Sid
            $v = Format-ShadowValue -Value $cur -Map $sv -NotConfigured $su.notcfg
            Write-Host "|  $($i+1). $($users[$i].Name.PadRight(20)) [$v]" -ForegroundColor Yellow
        }
        Write-Host "|  0. $(T 'back_main')" -ForegroundColor Green
        Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
        $c = Read-Host "> "
        if ($c -eq '0') { $exit = $true }
        elseif ($c -match '^\d+$' -and [int]$c -ge 1 -and [int]$c -le $users.Count) { $target = $users[([int]$c - 1)] }
        else { Write-W (T 'inv_opt'); Start-Sleep -Milliseconds 800 }
    } while (-not $exit -and -not $target)
    if (-not $target) { return }

    do {
        $cur = Get-ShadowUserValue -Sid $target.Sid
        Show-ConfigMenu "$(S 'user'): $($target.Name)" @(
            @{Label=(S 'cur');Value=(Format-ShadowValue -Value $cur -Map $sv -NotConfigured $su.notcfg)}
            "-"
            @{Label="1. $(T 'menu_shadow_off')"}
            @{Label="2. $(T 'menu_shadow_fwp')"}
            @{Label="3. $(T 'menu_shadow_fwo')"}
            @{Label="4. $(T 'menu_shadow_vwp')"}
            @{Label="5. $(T 'menu_shadow_vwo')"}
            @{Label="6. $(S 'clear_global')"}
        )
        $c = Read-Host "> "
        switch -Regex ($c) {
            '^[1-5]$' {
                $r = Set-ShadowUserValue -Sid $target.Sid -Value ([int]$c - 1)
                if ($r -eq $true) { Write-S (S 'apply' @($target.Name, $sv[([int]$c - 1)])); Write-I $su.apply_note }
                elseif ($r -eq $false) { Write-E (S 'err_write' @($target.Name)) }
                else { Write-E (S 'err_hive' @($target.Name)) }
            }
            '^6$' {
                $r = Set-ShadowUserValue -Sid $target.Sid -Clear
                if ($r -eq $true) { Write-S (S 'cleared' @($target.Name)) }
                elseif ($r -eq $false) { Write-E (S 'err_write' @($target.Name)) }
                else { Write-E (S 'err_hive' @($target.Name)) }
            }
            '^0$' { }
            default { Write-W (T 'inv_opt'); Start-Sleep -Milliseconds 800 }
        }
    } while ($c -ne '0')
}

function Set-RdpShadowing {
    do {
        $su = Get-ShadowUi
        $sv = Get-ShadowModeMap
        $g = Get-ShadowGlobal
        $users = Get-ShadowUsers
        Clear-Host
        Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
        Write-Host "|  $(T 'menu_shadow_title')" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
        Write-Host "|  $(S 'global'): " -NoNewline -ForegroundColor White
        Write-Host (Format-ShadowValue -Value $g.Policy -Map $sv -NotConfigured $su.notcfg) -ForegroundColor DarkGray
        Write-Host "|  $(S 'legacy'): " -NoNewline -ForegroundColor DarkGray
        Write-Host (Format-ShadowValue -Value $g.Legacy -Map $sv -NotConfigured $su.notcfg) -ForegroundColor DarkGray
        Write-Host "|  $(S 'note')" -ForegroundColor DarkGray
        Write-Host "|  $(S 'user'):" -ForegroundColor White
        foreach ($u in $users) {
            $uv = Get-ShadowUserValue -Sid $u.Sid
            $line = "    $($u.Name.PadRight(22)) $(Format-ShadowValue -Value $uv -Map $sv -NotConfigured $su.notcfg)"
            if ($null -eq $uv -and $null -ne $g.Effective) { $line += "   ->  $(Format-ShadowValue -Value $g.Effective -Map $sv -NotConfigured $su.notcfg)" }
            Write-Host "|$line" -ForegroundColor DarkGray
        }
        Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
        Write-Host "|  1. $(S 'global')" -ForegroundColor Yellow
        Write-Host "|  2. $(S 'user')" -ForegroundColor Yellow
        Write-Host "|  0. $(T 'back_main')" -ForegroundColor Green
        Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
        $c = Read-Host "> "
        switch ($c) {
            "1" { Set-ShadowGlobalMenu }
            "2" { Set-ShadowUserMenu }
            default { if ($c -ne '0') { Write-W (T 'inv_opt'); Start-Sleep -Milliseconds 800 } }
        }
    } while ($c -ne '0')
}

function Set-RdpDisplay {
    do {
        $hide = Get-RegDword $REG_WINLOGON "HideConsoleUsers"
        Show-ConfigMenu (T 'menu_display_title') @(
            @{Label=(T 'menu_display_mm');Value=if((Get-RegDword $REG_POLICY "fEnableRemoteFX")-eq1){T 'on'}else{T 'dflt'}}
            @{Label=(T 'menu_display_hide');Value=if($hide -eq 1){T 'on'}else{T 'off'}}
            @{Label=(T 'menu_display_ar');Value=if((Get-RegDword $REG_POLICY "fDisableAutoReconnect")-eq1){T 'off'}else{T 'dflt'}}
            "-"
            @{Label="1. $(T 'menu_display_tm')"}
            @{Label="2. $(T 'menu_display_th')"}
            @{Label="3. $(T 'menu_display_ta')"}
        )
        $c = Read-Host "> "
        switch ($c) {
            "1" { $cur = Get-RegDword $REG_POLICY fEnableRemoteFX; Set-RegDword $REG_POLICY fEnableRemoteFX $(if($cur -eq 1){0}else{1}) }
            "2" { $cur = Get-RegDword $REG_WINLOGON HideConsoleUsers; Set-RegDword $REG_WINLOGON HideConsoleUsers $(if($cur -eq 1){0}else{1}) }
            "3" { $cur = Get-RegDword $REG_POLICY fDisableAutoReconnect; Set-RegDword $REG_POLICY fDisableAutoReconnect $(if($cur -eq 1){0}else{1}) }
            default { if ($c -ne '0') { Write-W "$(T 'inv_opt')"; Start-Sleep -Milliseconds 800 } }
        }
        if ($c -eq '1' -or $c -eq '2' -or $c -eq '3') { Restart-RdpService }
    } while ($c -ne '0')
}

function Set-RdpTimeouts {
    do {
        $disc = Get-RegDword $REG_POLICY "MaxDisconnectionTime"
        $idle = Get-RegDword $REG_POLICY "MaxIdleTime"
        $sess = Get-RegDword $REG_POLICY "MaxSessionTime"
        $discStr = if ($disc -and $disc -ne 0) { "$($disc/60000)$(T 'min')" } else { T 'never' }
        $idleStr = if ($idle -and $idle -ne 0) { "$($idle/60000)$(T 'min')" } else { T 'never' }
        $sessStr = if ($sess -and $sess -ne 0) { "$($sess/60000)$(T 'min')" } else { T 'never' }
        Show-ConfigMenu (T 'menu_timeout_title') @(
            @{Label=(T 'menu_timeout_disc');Value=$discStr}
            @{Label=(T 'menu_timeout_idle');Value=$idleStr}
            @{Label=(T 'menu_timeout_active');Value=$sessStr}
            "-"
            @{Label="1. $(T 'menu_timeout_sd')"}
            @{Label="2. $(T 'menu_timeout_si')"}
            @{Label="3. $(T 'menu_timeout_sa')"}
            @{Label="4. $(T 'menu_timeout_reset')"}
        )
        $c = Read-Host "> "
        $matched = $false
        switch -Regex ($c) {
            "^1$" { Write-I "$(T 'menu_timeout_sd') (0=$(T 'never')):" -NoNewline; $v=Read-Host; if($v-match'^\d+$'){Set-RegDword $REG_POLICY MaxDisconnectionTime ([int]$v*60000)}; $matched=$true }
            "^2$" { Write-I "$(T 'menu_timeout_si') (0=$(T 'never')):" -NoNewline; $v=Read-Host; if($v-match'^\d+$'){Set-RegDword $REG_POLICY MaxIdleTime ([int]$v*60000)}; $matched=$true }
            "^3$" { Write-I "$(T 'menu_timeout_sa') (0=$(T 'never')):" -NoNewline; $v=Read-Host; if($v-match'^\d+$'){Set-RegDword $REG_POLICY MaxSessionTime ([int]$v*60000)}; $matched=$true }
            "^4$" { Set-RegDword $REG_POLICY MaxDisconnectionTime 0;Set-RegDword $REG_POLICY MaxIdleTime 0;Set-RegDword $REG_POLICY MaxSessionTime 0; $matched=$true }
        }
        if (-not $matched -and $c -ne '0') { Write-W "$(T 'inv_opt')"; Start-Sleep -Milliseconds 800 }
        if ($matched) { Restart-RdpService }
    } while ($c -ne '0')
}

function New-RemoteAppFile {
    Clear-Host
    Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "|  $(T 'remoteapp_header')" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan

    $server = Read-Host "$(T 'remoteapp_server')"
    if (-not $server) { Write-W "$(T 'cancel')"; return }

    Write-Host "`n$(T 'remoteapp_presets'):" -ForegroundColor White
    $presets = @("cmd.exe","explorer.exe","iexplore.exe","notepad.exe","powershell.exe","$(T 'remoteapp_custom')")
    for ($i = 0; $i -lt $presets.Count; $i++) {
        Write-Host "  $($i+1). $($presets[$i])" -ForegroundColor Yellow
    }
    $pc = Read-Host "> $(T 'sel_opt')"
    $program = ""
    if ($pc -match '^[1-5]$') {
        $program = "C:\Windows\System32\$($presets[[int]$pc-1])"
    } elseif ($pc -eq '6') {
        $program = Read-Host "$(T 'remoteapp_custom')"
    } else { Write-W "$(T 'inv_opt')"; return }
    if (-not $program) { Write-W "$(T 'cancel')"; return }

    $name = Read-Host "$(T 'remoteapp_name') ($([System.IO.Path]::GetFileNameWithoutExtension($program)))"
    if (-not $name) { $name = [System.IO.Path]::GetFileNameWithoutExtension($program) }

    $args = Read-Host "$(T 'remoteapp_args')"

    Write-Host "`n$(T 'remoteapp_optional'):" -ForegroundColor White
    $clip = Read-Host "$(T 'remoteapp_clipboard') (Y/n)"
    $clip = if ($clip -eq 'n' -or $clip -eq 'N') { 0 } else { 1 }
    $drv = Read-Host "$(T 'remoteapp_drives') (Y/n)"
    $drv = if ($drv -eq 'n' -or $drv -eq 'N') { 0 } else { 1 }
    $audio = Read-Host "$(T 'remoteapp_audio') (0)"
    if ($audio -notmatch '^[0-2]$') { $audio = '0' }

    $width = Read-Host "Desktop width (default 1024)"
    if (-not $width -or $width -notmatch '^\d+$') { $width = '1024' }
    $height = Read-Host "Desktop height (default 768)"
    if (-not $height -or $height -notmatch '^\d+$') { $height = '768' }

    $username = Read-Host "$(T 'remoteapp_username')"

    $desktop = [Environment]::GetFolderPath('Desktop')
    $filename = "$desktop\$name.rdp"
    $content = @"
remoteapplicationmode:i:1
remoteapplicationprogram:s:$program
remoteapplicationname:s:$name
remoteapplicationcmdline:s:$args
full address:s:$server
promptcredentialonce:i:1
authentication level:i:0
session bpp:i:32
desktopwidth:i:$width
desktopheight:i:$height
redirectclipboard:i:$clip
redirectprinters:i:0
redirectcomports:i:0
redirectsmartcards:i:0
redirectdrives:i:$drv
audiomode:i:$audio
connection type:i:2
networkautodetect:i:1
"@
    if ($username) { $content += "username:s:$username`r`n" }
    $content | Out-File $filename -Encoding ASCII
    Write-S "$(T 'remoteapp_done') $filename"
    Write-Host ""; cmd /c pause 2>&1 | Out-Null
}

function Show-MainMenu {
    param([switch]$ForceRefresh)
    if (-not (Test-Admin)) {
        Clear-Host
        Write-Host "+----------------------------------------------------+" -ForegroundColor Red
        Write-Host "|     $(T 'admin_required')" -ForegroundColor Red
        Write-Host "+----------------------------------------------------+" -ForegroundColor Red
        Write-Host ""
        Write-Host "  $(T 'press_any_key')"; $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); return
    }

    $s = Get-RdpStatus
    Clear-Host
    Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "|          rdpwarp v$($script:VERSION)                    |" -ForegroundColor Cyan
    Write-Host "|     $(T 'title')" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "|  $(T 'sys_status')" -ForegroundColor White
    Write-Host "|  termsrv.dll : $($s.TermsrvVersion.PadRight(37))" -ForegroundColor DarkGray
    $svcColor = if ($s.ServiceStatus -eq 'Running') { 'Green' } elseif ($s.ServiceStatus -eq 'Stopped') { 'Red' } else { 'DarkGray' }
    Write-Host "|  $(T 'service') : " -NoNewline -ForegroundColor DarkGray; Write-Host "$("$($s.ServiceStatus)".PadRight(12)) " -NoNewline -ForegroundColor $svcColor
    Write-Host "  $(T 'port'): $($s.Port)" -NoNewline -ForegroundColor DarkGray; Write-Host "  " -NoNewline
    if ($s.Listener) { Write-Host "$(T 'listening') " -NoNewline -ForegroundColor Green } else { Write-Host "$(T 'closed') " -NoNewline -ForegroundColor Red }
    $wrapColor = if ($s.Installed) { 'Green' } else { 'DarkGray' }
    Write-Host "  $(T 'wrapper'): " -NoNewline -ForegroundColor DarkGray; Write-Host $(if($s.Installed){T 'installed'}else{T 'not_installed'}) -ForegroundColor $wrapColor
    if ($s.Installed) {
        $iniColor = if ($s.SupportState -eq 'Supported') { 'Green' } elseif ($s.SupportState -eq 'Configured') { 'Yellow' } else { 'Red' }
        $iniText = switch ($s.SupportState) {
            'Supported'     { "Supported - $(T 'ini_patched')" }
            'Configured'    { "Configured - $($s.HealthMessage)" }
            'InvalidConfig' { "InvalidConfig - $($s.HealthMessage)" }
            default         { "Unsupported - $($s.HealthMessage)" }
        }
        Write-Host "|  $(T 'ini_support') : " -NoNewline -ForegroundColor DarkGray; Write-Host $iniText -ForegroundColor $iniColor
        Write-Host "  $(T 'watchdog'): " -NoNewline -ForegroundColor DarkGray; Write-Host $(if($s.Watchdog){T 'active'}else{T 'inactive'}) -NoNewline -ForegroundColor $(if($s.Watchdog){'Green'}else{'Yellow'})
        Write-Host "  $(T 'sessions'): $($s.Sessions.Count)" -ForegroundColor DarkGray
        if ($s.Sessions.Count -gt 0) {
            foreach ($se in $s.Sessions) {
                $sc = if ($se.State -eq 'Active') { 'Green' } elseif ($se.State -eq 'Disc') { 'Yellow' } else { 'DarkGray' }
                $stateLabel = @{Active=(T 'session_state_active');Disc=(T 'session_state_disc');Conn=(T 'session_state_conn')}[$se.State]
                if (-not $stateLabel) { $stateLabel = $se.State }
                Write-Host "|    $($se.User.PadRight(20)) $($stateLabel.PadRight(7)) $(T 'session') $($se.ID)" -ForegroundColor $sc
            }
        }
    }
    Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan

    Write-Host ""
    if (-not $s.Installed) {
        Write-Host "  " -NoNewline; Write-Host "1." -NoNewline -ForegroundColor Yellow
        Write-Host " $(T 'menu_install')" -ForegroundColor Green
        Write-Host "     $(T 'menu_install_desc')" -ForegroundColor DarkGray
        Write-Host "  " -NoNewline; Write-Host "2." -NoNewline -ForegroundColor Yellow
        Write-Host " $(T 'menu_exit')" -ForegroundColor Gray
    } else {
        Write-Host "  " -NoNewline; Write-Host "1." -NoNewline -ForegroundColor Yellow
        Write-Host " $(T 'menu_update')" -ForegroundColor Green
        Write-Host "     $(T 'menu_update_desc')" -ForegroundColor DarkGray
        Write-Host "  " -NoNewline; Write-Host "2." -NoNewline -ForegroundColor Yellow
        Write-Host " $(T 'menu_session_title')" -ForegroundColor White
        Write-Host "     $(T 'menu_session_desc')" -ForegroundColor DarkGray
        Write-Host "  " -NoNewline; Write-Host "3." -NoNewline -ForegroundColor Yellow
        Write-Host " $(T 'menu_security_title')" -ForegroundColor White
        Write-Host "     $(T 'menu_security_desc')" -ForegroundColor DarkGray
        Write-Host "  " -NoNewline; Write-Host "4." -NoNewline -ForegroundColor Yellow
        Write-Host " $(T 'menu_shadow_title')" -ForegroundColor White
        Write-Host "     $(T 'menu_shadow_desc')" -ForegroundColor DarkGray
        Write-Host "  " -NoNewline; Write-Host "5." -NoNewline -ForegroundColor Yellow
        Write-Host " $(T 'menu_display_title')" -ForegroundColor White
        Write-Host "     $(T 'menu_display_desc')" -ForegroundColor DarkGray
        Write-Host "  " -NoNewline; Write-Host "6." -NoNewline -ForegroundColor Yellow
        Write-Host " $(T 'menu_timeout_title')" -ForegroundColor White
        Write-Host "     $(T 'menu_timeout_desc')" -ForegroundColor DarkGray
        Write-Host "  " -NoNewline; Write-Host "7." -NoNewline -ForegroundColor Yellow
        Write-Host " $(T 'menu_port_title')" -ForegroundColor White
        Write-Host "     $(T 'menu_port_desc')" -ForegroundColor DarkGray
        Write-Host "  " -NoNewline; Write-Host "8." -NoNewline -ForegroundColor Yellow
        Write-Host " $(T 'menu_watchdog_title')" -ForegroundColor White
        Write-Host "     $(T 'menu_watchdog_desc')" -ForegroundColor DarkGray
        Write-Host "  " -NoNewline; Write-Host "9." -NoNewline -ForegroundColor Yellow
        Write-Host " $(T 'menu_restart')" -ForegroundColor White
        Write-Host "     $(T 'menu_restart_desc')" -ForegroundColor DarkGray
        Write-Host "  " -NoNewline; Write-Host "R." -NoNewline -ForegroundColor Magenta
        Write-Host " $(T 'menu_remoteapp')" -ForegroundColor White
        Write-Host "     $(T 'menu_remoteapp_desc')" -ForegroundColor DarkGray
        Write-Host "  " -NoNewline; Write-Host "0." -NoNewline -ForegroundColor Red
        Write-Host " $(T 'menu_uninstall')" -ForegroundColor Red
        Write-Host "     $(T 'menu_uninstall_desc')" -ForegroundColor DarkGray
        Write-Host "  " -NoNewline; Write-Host "E." -NoNewline -ForegroundColor Gray
        Write-Host " $(T 'menu_exit')" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "-----------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  $($script:LANG_NAMES[$script:LANG])" -ForegroundColor Cyan
}

function Invoke-InteractiveMenu {
    Select-Language
    do {
        Show-MainMenu
        $choice = Read-Host "> $(T 'sel_opt')"
        $s = Get-RdpStatus
        if (-not $s.Installed) {
            switch ($choice) {
                "1" { Invoke-Install }
                "2" { return }
                default { Write-E "$(T 'inv_opt')"; Start-Sleep 1 }
            }
        } else {
            switch ($choice) {
                "1" { Clear-Host; Update-RdpwrapIni; Write-Host ""; cmd /c pause 2>&1 | Out-Null }
                "2" { Set-RdpSessions }
                "3" { Set-RdpSecurity }
                "4" { Set-RdpShadowing }
                "5" { Set-RdpDisplay }
                "6" { Set-RdpTimeouts }
                "7" { Set-RdpPort }
                "8" {
                    Clear-Host
                    Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
                    $wdStatus = if($s.Watchdog){T 'active'}else{T 'inactive'}
                    Write-Host "|  $(T 'wd_title'): $wdStatus" -ForegroundColor Cyan
                    Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
                    Write-Host "|  1. $(T 'wd_reg')                          |" -ForegroundColor Yellow
                    Write-Host "|  2. $(T 'wd_unr')                              |" -ForegroundColor Red
                    Write-Host "|  0. $(T 'back_main')                                      |" -ForegroundColor Green
                    Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
                    $wc = Read-Host "> "
                    if ($wc -eq '1') { Register-RdpWatchdog }
                    elseif ($wc -eq '2') { Unregister-RdpWatchdog }
                    Write-Host ""; cmd /c pause 2>&1 | Out-Null
                }
                "9" { Clear-Host; Restart-RdpService; Write-S $(T 'restart_done'); Write-Host ""; cmd /c pause 2>&1 | Out-Null }
                "r" { New-RemoteAppFile }
                "R" { New-RemoteAppFile }
                "e" { return }
                "E" { return }
                "0" { Invoke-Uninstall; Write-Host ""; cmd /c pause 2>&1 | Out-Null }
                default { Write-E "$(T 'inv_opt')"; Start-Sleep 1 }
            }
        }
    } while ($true)
}

function Show-Help {
    Clear-Host
    Write-Host "rdpwarp v$($script:VERSION)" -ForegroundColor Cyan
    Write-Host "Enables multiple concurrent RDP sessions on Windows."
    Write-Host ""
    Write-Host "USAGE:"
    Write-Host "  .\rdpwarps.ps1           Interactive menu (with live status)"
    Write-Host "  .\rdpwarps.ps1 -Install  One-click silent install + watchdog"
    Write-Host "  .\rdpwarps.ps1 -Uninstall  Clean removal"
    Write-Host "  .\rdpwarps.ps1 -GHMirror https://gh-proxy.com/"
    Write-Host "                              Proxy first, GitHub direct fallback"
    Write-Host "  .\rdpwarps.ps1 -ExperimentalNoSym"
    Write-Host "                              Enable experimental pattern scanning"
    Write-Host "  irm <url> | iex              Remote execution"
}

if ($Help) { Show-Help; return }
if ($Install) { Invoke-Install; return }
if ($Uninstall) { Invoke-Uninstall; return }
Invoke-InteractiveMenu
