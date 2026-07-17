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
param([switch]$Install,[switch]$Uninstall,[switch]$Help)

$script:VERSION = "2.1.0"
$script:RDPWRAP_DIR = "$env:ProgramFiles\rdpwarp"
$script:RDPWRAP_DLL = "$script:RDPWRAP_DIR\rdpwrap.dll"
$script:RDPWRAP_INI = "$script:RDPWRAP_DIR\rdpwrap.ini"
$script:TEMPLATE_INI = "$script:RDPWRAP_DIR\rdpwrap_templete.ini"
$script:WATCHDOG_TASK = "rdpwarp-Watchdog"
$script:WATCHDOG_SCRIPT = "$env:SystemRoot\Temp\rdpwarp-Watchdog.ps1"
$script:WINST_EXE = "$script:RDPWRAP_DIR\RDPWInst.exe"

# DLL selection by arch
$script:OFFSET_DLL = if ([Environment]::Is64BitProcess) { "RDPWrapOffsetFinder_x64.dll" } else { "RDPWrapOffsetFinder_x86.dll" }

# Binary resolution: local bin/ -> C:\ProgramData fallback -> GitHub download
$script:SCRIPT_DIR = if ($PSScriptRoot) { $PSScriptRoot } else { "" }
$script:BIN_DIR = if ($script:SCRIPT_DIR -and (Test-Path "$script:SCRIPT_DIR\bin")) { "$script:SCRIPT_DIR\bin" } else { "" }
$script:FALLBACK_DIR = "$env:ProgramData\rdpwarp\bin"
$script:GH_REPO = "lcxxjmsg-cyber/rdp_warp_ps"
$script:GH_RAW = "https://raw.githubusercontent.com/$script:GH_REPO/main"
$script:GH_RELEASE = "https://github.com/stascorp/rdpwrap/releases/download/v1.6.2/RDPWrap-v1.6.2.zip"

$REG_TS = "HKLM:\SYSTEM\CurrentControlSet\Services\TermService\Parameters"
$REG_RDP = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
$REG_RDP_WS = "$REG_RDP\WinStations\RDP-Tcp"
$REG_RDP_LIC = "$REG_RDP\Licensing Core"
$REG_WINLOGON = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$REG_POLICY = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
$REG_POLICY_LOCAL = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"

function Write-I   { Write-Host "  $($args -join ' ')" -ForegroundColor Gray }
function Write-S   { Write-Host "  [+] $($args -join ' ')" -ForegroundColor Green }
function Write-W   { Write-Host "  [!] $($args -join ' ')" -ForegroundColor Yellow }
function Write-E   { Write-Host "  [-] $($args -join ' ')" -ForegroundColor Red }

# Resolve a binary file: local bin -> fallback dir -> GitHub raw
function Resolve-Binary {
    param($Filename)
    $local = if ($script:BIN_DIR) { Join-Path $script:BIN_DIR $Filename } else { $null }
    if ($local -and (Test-Path $local)) { return $local }
    $fallback = Join-Path $script:FALLBACK_DIR $Filename
    if (Test-Path $fallback) { return $fallback }
    # Download from GitHub raw
    try {
        New-Item $script:FALLBACK_DIR -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        $url = "$script:GH_RAW/bin/$Filename"
        $out = Join-Path $script:FALLBACK_DIR $Filename
        Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -ErrorAction Stop
        if (Test-Path $out) { return $out }
    } catch { }
    return $null
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ============================================================
# Status detection
# ============================================================
function Get-TermsrvVersion {
    $path = "$env:SystemRoot\System32\termsrv.dll"
    if (-not (Test-Path $path)) { return $null }
    $vi = (Get-Item $path).VersionInfo
    return "$($vi.FileMajorPart).$($vi.FileMinorPart).$($vi.FileBuildPart).$($vi.FilePrivatePart)"
}

function Get-RdpStatus {
    $s = @{Admin=Test-Admin}
    $s.TermsrvVersion = Get-TermsrvVersion
    $svcDll = Get-ItemProperty -Path $REG_TS -Name ServiceDll -ErrorAction SilentlyContinue
    $s.ServiceDll = if ($svcDll) { $svcDll.ServiceDll } else { $null }
    $s.Installed = ($s.ServiceDll -like '*rdpwrap*')
    $svc = Get-Service -Name TermService -ErrorAction SilentlyContinue
    $s.ServiceStatus = if ($svc) { $svc.Status } else { 'Missing' }
    $conn = Get-NetTCPConnection -LocalPort 3389 -State Listen -ErrorAction SilentlyContinue
    $s.Listener = ($null -ne $conn)
    if ($s.Installed -and $s.TermsrvVersion -and (Test-Path $script:RDPWRAP_INI)) {
        $ini = Get-Content $script:RDPWRAP_INI -Raw -ErrorAction SilentlyContinue
        $s.IniOk = $ini -and $ini.Contains("[$($s.TermsrvVersion)]")
    } else { $s.IniOk = $false }
    $port = Get-ItemProperty -Path $REG_RDP_WS -Name PortNumber -ErrorAction SilentlyContinue
    $s.Port = if ($port) { $port.PortNumber } else { 3389 }
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
function Restart-RdpService { Stop-RdpService; Start-RdpService }

# ============================================================
# Binary deployment
# ============================================================
function Deploy-RdpwrapDll {
    # Look for the DLL directly first
    $dllPath = Resolve-Binary "rdpwrap.dll"
    if ($dllPath) { Copy-Item $dllPath $script:RDPWRAP_DLL -Force; Write-S "rdpwrap.dll deployed"; return $true }

    # Fallback: use RDPWInst.exe
    $winst = Resolve-Binary "RDPWInst.exe"
    if ($winst) {
        Copy-Item $winst $script:WINST_EXE -Force
        Write-I "Running RDPWInst.exe silently..."
        $p = Start-Process -FilePath $script:WINST_EXE -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES" -Wait -PassThru -NoNewWindow
        if ($p.ExitCode -eq 0 -and (Test-Path "$env:ProgramFiles\RDP Wrapper\rdpwrap.dll")) {
            Copy-Item "$env:ProgramFiles\RDP Wrapper\rdpwrap.dll" $script:RDPWRAP_DLL -Force
            Write-S "rdpwrap.dll extracted via RDPWInst"
            return $true
        }
    }

    # Last resort: download from stascorp
    Write-I "Downloading rdpwrap from GitHub..."
    try {
        $zip = "$env:TEMP\rdpw_install.zip"
        $extract = "$env:TEMP\rdpw_install_ext"
        Invoke-WebRequest -Uri $script:GH_RELEASE -OutFile $zip -UseBasicParsing -ErrorAction Stop
        Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
        New-Item $extract -ItemType Directory -Force | Out-Null
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $extract)
        $instExe = Get-ChildItem $extract -Recurse -Filter RDPWInst.exe | Select-Object -First 1
        if ($instExe) {
            Copy-Item $instExe.FullName $script:WINST_EXE -Force
            $p = Start-Process -FilePath $script:WINST_EXE -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES" -Wait -PassThru -NoNewWindow
            if ($p.ExitCode -eq 0 -and (Test-Path "$env:ProgramFiles\RDP Wrapper\rdpwrap.dll")) {
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

        # Deploy rdpwrap.dll
        if (-not (Deploy-RdpwrapDll)) { throw "Failed to deploy rdpwrap.dll" }

        # Template INI
        $iniContent = @"
[Main]
Updated=2024-01-01
LogFile=\rdpwrap.txt
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
        $iniContent | Out-File $script:TEMPLATE_INI -Encoding ASCII
        if (-not (Test-Path $script:RDPWRAP_INI)) { Copy-Item $script:TEMPLATE_INI $script:RDPWRAP_INI }
        Write-S "INI template deployed"

        # Deploy OffsetFinder DLL
        $ofl = Resolve-Binary $script:OFFSET_DLL
        if ($ofl) {
            Copy-Item $ofl "$script:RDPWRAP_DIR\$script:OFFSET_DLL" -Force
            Write-S "OffsetFinder DLL deployed ($script:OFFSET_DLL)"
        } else {
            # Try the other arch as fallback
            $otherArch = if ($script:OFFSET_DLL -like '*x64*') { $script:OFFSET_DLL -replace 'x64','x86' } else { $script:OFFSET_DLL -replace 'x86','x64' }
            $ofl2 = Resolve-Binary $otherArch
            if ($ofl2) {
                Copy-Item $ofl2 "$script:RDPWRAP_DIR\$script:OFFSET_DLL" -Force
                Write-S "OffsetFinder DLL deployed (arch fallback: $otherArch)"
            } else {
                Write-W "OffsetFinder DLL not found - will rely on online INI fallback"
            }
        }

        return (Test-Path $script:RDPWRAP_DLL)
    } catch { Write-E "Deploy failed: $_"; return $false }
}

# ============================================================
# INI update (OffsetFinder)
# ============================================================
function Update-RdpwrapIni {
    $termsrv = "$env:SystemRoot\System32\termsrv.dll"
    $ver = Get-TermsrvVersion
    if (-not $ver -or -not (Test-Path $termsrv)) { Write-E "termsrv.dll not found"; return $false }
    $ini = Get-Content $script:RDPWRAP_INI -Raw -ErrorAction SilentlyContinue
    if ($ini -and $ini.Contains("[$ver]")) { Write-S "INI already supports $ver"; return $true }

    # Try OffsetFinder DLL (P/Invoke)
    $dllPath = "$script:RDPWRAP_DIR\$script:OFFSET_DLL"
    if (Test-Path $dllPath) {
        Write-I "Using OffsetFinder DLL..."
        try {
            $dllEscaped = $dllPath -replace '\\','\\\\'
            $code = @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class RDPOffsetFinder {
    [DllImport("$dllEscaped", CharSet=CharSet.Unicode)]
    public static extern int FindRDPOffsets(string path, StringBuilder output, int bufSize, int flags);
}
"@
            Add-Type $code -ErrorAction Stop
            $sb = New-Object Text.StringBuilder 131072
            $hr = [RDPOffsetFinder]::FindRDPOffsets($termsrv, $sb, $sb.Capacity, 0)
            if ($hr -ge 0 -and $sb.Length -gt 20 -and -not $sb.ToString().Contains("ERROR:")) {
                Add-Content $script:RDPWRAP_INI -Value "`r`n$($sb.ToString())" -Encoding ASCII
                Write-S "Offsets updated via DLL"; return $true
            }
        } catch { Write-W "DLL failed: $_" }
    }

    # Fallback: download INI from GitHub
    Write-I "Downloading latest INI from GitHub..."
    try {
        $new = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/stascorp/rdpwrap/master/res/rdpwrap.ini" -UseBasicParsing -TimeoutSec 30
        if ($new.Content.Contains("[$ver]")) {
            Copy-Item $script:RDPWRAP_INI "$script:RDPWRAP_INI.bak" -Force
            $new.Content | Out-File $script:RDPWRAP_INI -Encoding ASCII
            Write-S "Downloaded INI supports $ver"; return $true
        }
        Write-W "Online INI doesn't support $ver yet"
        return $false
    } catch { Write-W "Download failed: $_" }
    return $false
}

function Get-RegDword { param($Path,$Name) $v = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue; if ($v) { $v.$Name } else { $null } }
function Set-RegDword { param($Path,$Name,$Value,$Type='DWord') try { New-Item -Path (Split-Path $Path -Parent) -Force | Out-Null; New-Item -Path $Path -Force | Out-Null; Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type } catch { } }

# ============================================================
# ONE-CLICK INSTALL
# ============================================================
function Invoke-Install {
    Clear-Host
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host "          rdpwarp - One-Click Install" -ForegroundColor Cyan
    Write-Host "=======================================================" -ForegroundColor Cyan

    if (-not (Test-Admin)) { Write-E "Admin required"; return }
    if ((Get-RdpStatus).Installed) {
        Write-W "rdpwarp already installed."
        Write-I "Run the script again for menu options, or use -Uninstall to remove."
        return
    }

    Write-I "[1/6] Deploying binaries..."
    if (-not (Install-RdpWrapperBinaries)) { return }
    Write-I "[2/6] Stopping services..."
    Stop-RdpService
    Write-I "[3/6] Configuring service..."
    Set-ItemProperty -Path $REG_TS -Name ServiceDll -Value "%ProgramFiles%\rdpwarp\rdpwrap.dll" -Type ExpandString
    Write-I "[4/6] Checking INI support..."
    Update-RdpwrapIni | Out-Null
    Write-I "[5/6] Enabling RDP..."
    Set-RegDword $REG_RDP fDenyTSConnections 0
    Set-RegDword $REG_RDP_LIC EnableConcurrentSessions 1
    Set-RegDword $REG_WINLOGON AllowMultipleTSSessions 1
    New-Item "$REG_RDP\AddIns" -Force | Out-Null
    & netsh advfirewall firewall add rule name="Remote Desktop" dir=in protocol=tcp localport=3389 profile=any action=allow 2>$null
    & netsh advfirewall firewall add rule name="Remote Desktop (UDP)" dir=in protocol=udp localport=3389 profile=any action=allow 2>$null
    Get-Service -Name CertPropSvc,SessionEnv -ErrorAction SilentlyContinue | Where-Object StartType -eq Disabled | ForEach-Object { sc.exe config $_.Name start=demand 2>$null }
    Write-I "[6/6] Starting service..."
    Start-RdpService
    Register-RdpWatchdog -Quiet

    $s = Get-RdpStatus
    Write-Host "-------------------------------------------------------" -ForegroundColor Cyan
    if ($s.ServiceStatus -eq 'Running' -and $s.Listener) {
        Write-S "rdpwarp installed successfully!"
        Write-S "Multi-session RDP is ready on port $($s.Port)"
        if (-not $s.IniOk) { Write-W "INI may need update (version $($s.TermsrvVersion))" }
    } else {
        Write-W "Install completed with warnings:"
        if ($s.ServiceStatus -ne 'Running') { Write-E "  TermService not running" }
        if (-not $s.Listener) { Write-E "  Port $($s.Port) not listening" }
    }
    Write-I "Watchdog auto-registered for self-healing"
}

# ============================================================
# UNINSTALL
# ============================================================
function Invoke-Uninstall {
    Clear-Host
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host "          rdpwarp - Uninstall" -ForegroundColor Cyan
    Write-Host "=======================================================" -ForegroundColor Cyan
    if (-not (Test-Admin)) { Write-E "Admin required"; return }
    Write-W "This will remove rdpwarp and restore original settings."
    Write-I "Continue? [Y/N] " -NoNewline
    if ((Read-Host).ToUpper() -ne 'Y') { Write-I "Cancelled"; return }
    Unregister-RdpWatchdog
    Stop-RdpService
    Set-ItemProperty -Path $REG_TS -Name ServiceDll -Value "%SystemRoot%\System32\termsrv.dll" -Type ExpandString
    Start-RdpService
    if (Test-Path $script:RDPWRAP_DIR) { Remove-Item $script:RDPWRAP_DIR -Recurse -Force }
    Write-S "rdpwarp removed"
}

# ============================================================
# Watchdog
# ============================================================
function Register-RdpWatchdog { param([switch]$Quiet)
    if (-not $Quiet) { Clear-Host; Write-Host "=======================================================" -ForegroundColor Cyan; Write-Host "          Watchdog Management" -ForegroundColor Cyan; Write-Host "=======================================================" -ForegroundColor Cyan }
    $scriptBody = @'
$l="$env:ProgramFiles\rdpwarp\watchdog.log";$i="$env:ProgramFiles\rdpwarp\rdpwrap.ini";$t="$env:SystemRoot\System32\termsrv.dll"
$v=(Get-Item $t).VersionInfo;$k="$($v.FileMajorPart).$($v.FileMinorPart).$($v.FileBuildPart).$($v.FilePrivatePart)"
$c=Get-Content $i -Raw -EA 0;if($c-and$c.Contains("[$k]")){exit 0}
function w{param($m)"$(Get-Date -F 'yyyy-MM-dd HH:mm:ss') $m"|Out-File $l -Append}
w"Need update for $k"
$d="$env:ProgramFiles\rdpwarp\RDPWrapOffsetFinder_x64.dll";$ok=$false
if(Test-Path $d){try{Add-Type @"
using System;using System.Runtime.InteropServices;using System.Text;
public class F{[DllImport("$($d-replace'\\','\\\\')",CharSet=CharSet.Unicode)]public static extern int FindRDPOffsets(string p,StringBuilder o,int s,int f);}
"@;$b=New-Object Text.StringBuilder 131072;$h=[F]::FindRDPOffsets($t,$b,$b.Capacity,0);if($h-ge0-and$b.Length-gt20-and!$b.ToString().Contains("ERROR:")){Copy-Item $i "$i.bak"-Force;Add-Content $i "`r`n$($b.ToString())"-Encoding ASCII;w"DLL updated";$ok=$true}}catch{w"DLL: $_"}}
if(!$ok){try{$n=Invoke-WebRequest "https://raw.githubusercontent.com/stascorp/rdpwrap/master/res/rdpwrap.ini" -UseBasicParsing -TimeoutSec 15;if($n.Content.Contains("[$k]")){Copy-Item $i "$i.bak"-Force;$n.Content|Out-File $i -Encoding ASCII;w"Downloaded new INI";$ok=$true}}catch{w"Online: $_"}}
if($ok){Stop-Service TermService -Force -EA 0;Start-Sleep 1;Start-Service TermService -EA 0;w"TermService restarted"}else{w"Failed to update"}
'@
    try {
        $scriptBody | Out-File $script:WATCHDOG_SCRIPT -Encoding ASCII -Force
        $a = New-ScheduledTaskAction -Execute powershell.exe -Argument "-NoP -W Hidden -Exec Bypass -File `"$($script:WATCHDOG_SCRIPT)`""
        $t1 = New-ScheduledTaskTrigger -AtStartup
        $t2 = New-ScheduledTaskTrigger -Daily -At 03:00
        $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden
        Unregister-ScheduledTask -TaskName $script:WATCHDOG_TASK -Confirm:$false -ErrorAction SilentlyContinue
        Register-ScheduledTask -TaskName $script:WATCHDOG_TASK -Action $a -Trigger $t1,$t2 -Settings $set -User "NT AUTHORITY\SYSTEM" -RunLevel Highest -Force | Out-Null
        if (-not $Quiet) { Write-S "Watchdog registered (startup + daily 3AM)" }
    } catch { if (-not $Quiet) { Write-E "Watchdog failed: $_" } }
}
function Unregister-RdpWatchdog {
    Unregister-ScheduledTask -TaskName $script:WATCHDOG_TASK -Confirm:$false -ErrorAction SilentlyContinue
    if (Test-Path $script:WATCHDOG_SCRIPT) { Remove-Item $script:WATCHDOG_SCRIPT -Force -ErrorAction SilentlyContinue }
}

# ============================================================
# RDP Configuration functions
# ============================================================
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
    Write-Host "|  0. Back to main menu                               |" -ForegroundColor Green
    Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
}

function Set-RdpPort {
    $s = Get-RdpStatus
    Show-ConfigMenu "Change RDP Port" @("Current: $($s.Port)","-","Enter new port number (1-65535):")
    $p = Read-Host "> "
    if ($p -match '^\d+$' -and [int]$p -gt 0 -and [int]$p -le 65535) {
        $port = [int]$p
        & reg add $REG_RDP_WS /v PortNumber /t REG_DWORD /d $port /f 2>$null
        & netsh advfirewall firewall delete rule name="Remote Desktop" 2>$null
        & netsh advfirewall firewall add rule name="Remote Desktop" dir=in protocol=tcp localport=$port profile=any action=allow 2>$null
        Restart-RdpService
        Write-S "Port changed to $port. Connect with: $($env:COMPUTERNAME):$port"
    } else { Write-W "Invalid port" }
    Pause
}

function Set-RdpSessions {
    do {
        $s = Get-RegDword $REG_POLICY "MaxInstanceCount"
        $sspu = Get-RegDword $REG_POLICY "fSingleSessionPerUser"
        Show-ConfigMenu "Session Settings" @(
            @{Label="Max concurrent sessions";Value=if($null -ne $s){$s}else{"unlimited"}}
            @{Label="Single session per user";Value=if($sspu -eq 1){"ON"}elseif($sspu -eq 0){"OFF"}else{"default"}}
            "-"
            @{Label="1. Change max sessions"}
            @{Label="2. Toggle single session per user"}
            @{Label="3. Reset to defaults"}
        )
        $c = Read-Host "> "
        switch ($c) {
            "1" { Write-I "Enter max sessions (0=unlimited):" -NoNewline; $v = Read-Host; if ($v -match '^\d+$') { Set-RegDword $REG_POLICY MaxInstanceCount [int]$v } }
            "2" { $cur = Get-RegDword $REG_POLICY fSingleSessionPerUser; Set-RegDword $REG_POLICY fSingleSessionPerUser $(if($cur -eq 1){0}else{1}) }
            "3" { Remove-Item "$REG_POLICY\MaxInstanceCount" -Force -EA 0; Remove-Item "$REG_POLICY\fSingleSessionPerUser" -Force -EA 0 }
        }
        if ($c -ne '0' -and $c -ne '') { Restart-RdpService }
    } while ($c -ne '0')
}

function Set-RdpSecurity {
    do {
        $nla = Get-RegDword $REG_RDP_WS "UserAuthentication"
        $sl = Get-RegDword $REG_RDP_WS "SecurityLayer"
        $nlaStr = if ($nla -eq 1) { "ON" } elseif ($nla -eq 0) { "OFF" } else { "default" }
        $slStr = @{0="RDP";1="Negotiate";2="TLS"}[[int]$sl]
        Show-ConfigMenu "Security Settings" @(
            @{Label="Network Level Auth (NLA)";Value=$nlaStr}
            @{Label="Security Layer";Value=$slStr}
            "-"
            @{Label="1. Toggle NLA on/off"}
            @{Label="2. Set security layer"}
        )
        $c = Read-Host "> "
        switch ($c) {
            "1" { $cur = Get-RegDword $REG_RDP_WS UserAuthentication; Set-RegDword $REG_RDP_WS UserAuthentication $(if($cur -eq 1){0}else{1}) }
            "2" { Write-I "Security: 0=RDP 1=Negotiate 2=TLS:" -NoNewline; $v = Read-Host; if($v -match '^[0-2]$'){Set-RegDword $REG_RDP_WS SecurityLayer [int]$v} }
        }
        if ($c -ne '0') { Restart-RdpService }
    } while ($c -ne '0')
}

function Set-RdpShadowing {
    do {
        $sh = Get-RegDword $REG_POLICY_LOCAL "Shadow"
        $shStr = @{0="Off";1="Full w/ permission";2="Full w/o permission";3="View w/ permission";4="View w/o permission"}[[int]$sh]
        Show-ConfigMenu "Session Shadowing (Remote Control)" @(
            @{Label="Current mode";Value=$shStr}
            "-"
            @{Label="1. Off"}
            @{Label="2. Full control (with permission)"}
            @{Label="3. Full control (no permission)"}
            @{Label="4. View only (with permission)"}
            @{Label="5. View only (no permission)"}
        )
        $c = Read-Host "> "
        if ($c -match '^[1-5]$') { Set-RegDword $REG_POLICY_LOCAL Shadow ([int]$c-1); Restart-RdpService }
    } while ($c -ne '0')
}

function Set-RdpDisplay {
    do {
        $hide = Get-RegDword $REG_WINLOGON "HideConsoleUsers"
        Show-ConfigMenu "Display and Session Options" @(
            @{Label="Multi-monitor support";Value=if((Get-RegDword $REG_POLICY "fEnableRemoteFX")-eq1){"ON"}else{"default"}}
            @{Label="Hide users from login";Value=if($hide -eq 1){"ON"}else{"OFF"}}
            @{Label="Auto-reconnect";Value=if((Get-RegDword $REG_POLICY "fDisableAutoReconnect")-eq1){"OFF"}else{"default"}}
            "-"
            @{Label="1. Toggle multi-monitor"}
            @{Label="2. Toggle hide users on login"}
            @{Label="3. Toggle auto-reconnect"}
        )
        $c = Read-Host "> "
        switch ($c) {
            "1" { $cur = Get-RegDword $REG_POLICY fEnableRemoteFX; Set-RegDword $REG_POLICY fEnableRemoteFX $(if($cur -eq 1){0}else{1}) }
            "2" { $cur = Get-RegDword $REG_WINLOGON HideConsoleUsers; Set-RegDword $REG_WINLOGON HideConsoleUsers $(if($cur -eq 1){0}else{1}) }
            "3" { $cur = Get-RegDword $REG_POLICY fDisableAutoReconnect; Set-RegDword $REG_POLICY fDisableAutoReconnect $(if($cur -eq 1){0}else{1}) }
        }
        if ($c -ne '0') { Restart-RdpService }
    } while ($c -ne '0')
}

function Set-RdpTimeouts {
    do {
        $disc = Get-RegDword $REG_POLICY "MaxDisconnectionTime"
        $idle = Get-RegDword $REG_POLICY "MaxIdleTime"
        $sess = Get-RegDword $REG_POLICY "MaxSessionTime"
        $discStr = if ($disc -and $disc -ne 0) { "$($disc/60000)min" } else { "never" }
        $idleStr = if ($idle -and $idle -ne 0) { "$($idle/60000)min" } else { "never" }
        $sessStr = if ($sess -and $sess -ne 0) { "$($sess/60000)min" } else { "never" }
        Show-ConfigMenu "Session Timeouts" @(
            @{Label="Disconnected session timeout";Value=$discStr}
            @{Label="Idle session timeout";Value=$idleStr}
            @{Label="Active session limit";Value=$sessStr}
            "-"
            @{Label="1. Set disconnected timeout (minutes)"}
            @{Label="2. Set idle timeout (minutes)"}
            @{Label="3. Set active session limit (minutes)"}
            @{Label="4. Reset all to default (never disconnect)"}
        )
        $c = Read-Host "> "
        switch -Regex ($c) {
            "^1$" { Write-I "Minutes (0=never):" -NoNewline; $v=Read-Host; if($v-match'^\d+$'){Set-RegDword $REG_POLICY MaxDisconnectionTime ([int]$v*60000)} }
            "^2$" { Write-I "Minutes (0=never):" -NoNewline; $v=Read-Host; if($v-match'^\d+$'){Set-RegDword $REG_POLICY MaxIdleTime ([int]$v*60000)} }
            "^3$" { Write-I "Minutes (0=never):" -NoNewline; $v=Read-Host; if($v-match'^\d+$'){Set-RegDword $REG_POLICY MaxSessionTime ([int]$v*60000)} }
            "^4$" { Set-RegDword $REG_POLICY MaxDisconnectionTime 0;Set-RegDword $REG_POLICY MaxIdleTime 0;Set-RegDword $REG_POLICY MaxSessionTime 0 }
        }
        if ($c -ne '0' -and $c -ne '') { Restart-RdpService }
    } while ($c -ne '0')
}

# ============================================================
# MAIN MENU
# ============================================================
function Show-MainMenu {
    param([switch]$ForceRefresh)
    if (-not (Test-Admin)) {
        Clear-Host
        Write-Host "+----------------------------------------------------+" -ForegroundColor Red
        Write-Host "|     Admin required - Run as Administrator          |" -ForegroundColor Red
        Write-Host "+----------------------------------------------------+" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Press any key..."; $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); return
    }

    $s = Get-RdpStatus
    Clear-Host
    Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "|          rdpwarp v$($script:VERSION)                    |" -ForegroundColor Cyan
    Write-Host "|     Multi-Session RDP Controller                    |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "|  System Status" -ForegroundColor White
    Write-Host "|  termsrv.dll : $($s.TermsrvVersion.PadRight(37))" -ForegroundColor DarkGray
    $svcColor = if ($s.ServiceStatus -eq 'Running') { 'Green' } elseif ($s.ServiceStatus -eq 'Stopped') { 'Red' } else { 'DarkGray' }
    Write-Host "|  Service     : " -NoNewline -ForegroundColor DarkGray; Write-Host "$($s.ServiceStatus.PadRight(12)) " -NoNewline -ForegroundColor $svcColor
    Write-Host "  Port: $($s.Port)" -NoNewline -ForegroundColor DarkGray; Write-Host "  " -NoNewline
    if ($s.Listener) { Write-Host "LISTENING " -NoNewline -ForegroundColor Green } else { Write-Host "CLOSED    " -NoNewline -ForegroundColor Red }
    $wrapColor = if ($s.Installed) { 'Green' } else { 'DarkGray' }
    Write-Host "  Wrapper: " -NoNewline -ForegroundColor DarkGray; Write-Host $(if($s.Installed){"[Y] Installed"}else{"[X] Not Installed"}) -ForegroundColor $wrapColor
    if ($s.Installed) {
        $iniColor = if ($s.IniOk) { 'Green' } else { 'Yellow' }
        Write-Host "|  INI support : " -NoNewline -ForegroundColor DarkGray; Write-Host $(if($s.IniOk){"[Y] Supported  "}else{"[X] Unsupported"} ) -NoNewline -ForegroundColor $iniColor
        Write-Host "  Watchdog: " -NoNewline -ForegroundColor DarkGray; Write-Host $(if($s.Watchdog){"[Y] Active"}else{"[X] Inactive"}) -NoNewline -ForegroundColor $(if($s.Watchdog){'Green'}else{'Yellow'})
        Write-Host "  Sessions: $($s.Sessions.Count)" -ForegroundColor DarkGray
        if ($s.Sessions.Count -gt 0) {
            foreach ($se in $s.Sessions) {
                $sc = if ($se.State -eq 'Active') { 'Green' } elseif ($se.State -eq 'Disc') { 'Yellow' } else { 'DarkGray' }
                Write-Host "|    $($se.User.PadRight(20)) $($se.State.PadRight(7)) Session $($se.ID)" -ForegroundColor $sc
            }
        }
    }
    Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan

    if (-not $s.Installed) {
        Write-Host ""
        Write-Host "  " -NoNewline; Write-Host "1." -NoNewline -ForegroundColor Yellow
        Write-Host " Install rdpwarp (one-click)" -ForegroundColor Green
        Write-Host "  " -NoNewline; Write-Host "2." -NoNewline -ForegroundColor Yellow
        Write-Host " Exit" -ForegroundColor Gray
    } else {
        Write-Host ""
        Write-Host "  " -NoNewline; Write-Host "1." -NoNewline -ForegroundColor Yellow
        Write-Host " Update offsets" -ForegroundColor Green -NoNewline; Write-Host " (fix after Windows Update)"
        Write-Host "  " -NoNewline; Write-Host "2." -NoNewline -ForegroundColor Yellow
        Write-Host " Session settings" -ForegroundColor White -NoNewline; Write-Host " (max sessions, single session)"
        Write-Host "  " -NoNewline; Write-Host "3." -NoNewline -ForegroundColor Yellow
        Write-Host " Security" -ForegroundColor White -NoNewline; Write-Host " (NLA, encryption level)"
        Write-Host "  " -NoNewline; Write-Host "4." -NoNewline -ForegroundColor Yellow
        Write-Host " Remote control / Shadowing" -ForegroundColor White
        Write-Host "  " -NoNewline; Write-Host "5." -NoNewline -ForegroundColor Yellow
        Write-Host " Display and Session options" -ForegroundColor White -NoNewline; Write-Host " (multi-mon, auto-reconnect)"
        Write-Host "  " -NoNewline; Write-Host "6." -NoNewline -ForegroundColor Yellow
        Write-Host " Session timeouts" -ForegroundColor White -NoNewline; Write-Host " (disconnect/idle limits)"
        Write-Host "  " -NoNewline; Write-Host "7." -NoNewline -ForegroundColor Yellow
        Write-Host " Change RDP port" -ForegroundColor White
        Write-Host "  " -NoNewline; Write-Host "8." -NoNewline -ForegroundColor Yellow
        Write-Host " Watchdog" -ForegroundColor White -NoNewline; Write-Host " (current: $(if($s.Watchdog){'active'}else{'inactive'}))"
        Write-Host "  " -NoNewline; Write-Host "9." -NoNewline -ForegroundColor Yellow
        Write-Host " Restart service" -ForegroundColor White
        Write-Host "  " -NoNewline; Write-Host "0." -NoNewline -ForegroundColor Red
        Write-Host " Uninstall rdpwarp" -ForegroundColor Red
    }
    Write-Host "  " -NoNewline
}

# ============================================================
# Interactive menu loop
# ============================================================
function Invoke-InteractiveMenu {
    do {
        Show-MainMenu
        $choice = Read-Host "Select option"
        $s = Get-RdpStatus
        if (-not $s.Installed) {
            switch ($choice) {
                "1" { Invoke-Install }
                "2" { return }
                default { Write-E "Invalid option"; Start-Sleep 300 }
            }
        } else {
            switch ($choice) {
                "1" { Clear-Host; Update-RdpwrapIni; Pause }
                "2" { Set-RdpSessions }
                "3" { Set-RdpSecurity }
                "4" { Set-RdpShadowing }
                "5" { Set-RdpDisplay }
                "6" { Set-RdpTimeouts }
                "7" { Set-RdpPort }
                "8" {
                    Clear-Host
                    Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
                    Write-Host "|  Watchdog: $(if($s.Watchdog){'Active'}else{'Inactive'})" -ForegroundColor Cyan
                    Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
                    Write-Host "|  1. Register / Re-register                         |" -ForegroundColor Yellow
                    Write-Host "|  2. Unregister                                     |" -ForegroundColor Red
                    Write-Host "|  0. Back                                           |" -ForegroundColor Green
                    Write-Host "+----------------------------------------------------+" -ForegroundColor Cyan
                    $wc = Read-Host "> "
                    if ($wc -eq '1') { Register-RdpWatchdog }
                    elseif ($wc -eq '2') { Unregister-RdpWatchdog }
                    Pause
                }
                "9" { Clear-Host; Restart-RdpService; Pause }
                "0" { Invoke-Uninstall; Pause }
                default { Write-E "Invalid option"; Start-Sleep 300 }
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
    Write-Host "  .\rdpwarps.ps1 -UninstallClean removal"
    Write-Host "  irm <url> | iex              Remote execution"
}

if ($Help) { Show-Help; return }
if ($Install) { Invoke-Install; return }
if ($Uninstall) { Invoke-Uninstall; return }
Invoke-InteractiveMenu