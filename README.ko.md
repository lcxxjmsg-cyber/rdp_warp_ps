🌐 **언어 / Language**: [English](README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md) | [Русский](README.ru.md)

# rdpwarp — Windows 다중 세션 원격 데스크톱 도구

> Windows PC 한 대에서 **여러 사용자가 동시에 원격 로그인**할 수 있게 합니다. 간편합니다.

## 목차

- [이것은 무엇인가요?](#이것은-무엇인가요)
- [기능](#기능)
- [빠른 시작](#빠른-시작)
- [Release에서 다운로드](#release에서-다운로드)
- [자주 묻는 질문](#자주-묻는-질문)
- [제거](#제거)
- [요구 사항](#요구-사항)
- [라이선스](#라이선스)

## 이것은 무엇인가요?

Windows의 원격 데스크톱은 기본적으로 한 사용자만 로그인할 수 있습니다. 이 도구는 **RDP Wrapper(rdpwrap)** 를 통해 그 제한을 풀어 여러 사용자가 동시에 접속해 사용할 수 있게 합니다.

## 기능

- 원클릭 설치 / 제거, 다중 세션 활성화
- 최대 세션 수, 사용자당 단일 세션, 보안(NLA / 보안 계층), 표시, 시간 초과, 포트 설정
- Windows 빌드를 자동 감지하고 업데이트 후 오프셋 자동 복구
- 자가 복구 워치독(시작 시 + 매일 확인)
- 8개 언어 지원

## 빠른 시작

**방법 1: 직접 연결**

```powershell
powershell -c "(irm https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

**방법 2: 프록시 사용(중국에서 권장)**

```powershell
powershell -c "$env:GH_MIRROR='https://gh-proxy.com/';(irm https://gh-proxy.com/https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

**UAC** 창이 뜨면 **예**를 클릭하고 **1** 을 선택해 설치하세요. 장기간 / 오프라인 사용은 아래에서 다운로드하세요.

## Release에서 다운로드

**[Releases](https://github.com/lcxxjmsg-cyber/rdp_warp_ps/releases)** 에서 `rdp_warp_ps-vX.Y.Z.zip` 을 다운로드하고 압축을 푼 뒤 **`start.bat`** 을 더블클릭(자동 상승)하세요. 또는:

```powershell
.\rdpwarps.ps1 -Install    # 자동 설치
.\rdpwarps.ps1 -Uninstall  # 정리 제거
```

## 자주 묻는 질문

**Q1: 설치 후에도 TermService가 멈춰 있나요?**
아마 **Smart App Control / 메모리 무결성(코드 무결성)** 이 서명되지 않은 rdpwrap을 차단한 것입니다. "Smart App Control"과 "메모리 무결성"을 끄고 **재부팅**하세요. `C:\Program Files\rdpwarp`, `C:\rdpwarp` 를 Defender 제외에 추가하세요.

**Q2: 다른 사용자의 세션을 섀도잉할 수 있나요?**
클라이언트 버전은 **자신의** 세션만 섀도잉할 수 있습니다. 사용자 간 섀도잉은 **Windows Server + RDS** 필요(관리자 + "원격 제어 규칙 설정" 정책 + 재부팅).

**Q3: 관리자 권한 필요?**
스크립트가 자동 상승합니다. UAC가 거부되면 "관리자 권한으로 실행"을 우클릭하거나 `start.bat` 을 사용하세요.

## 제거

`.\rdpwarps.ps1 -Uninstall` 을 실행하면 설정을 복원하고 배포 파일, 워치독, Defender 제외 항목을 제거합니다.

## 요구 사항

- Windows 8.1 / 10 / 11, Windows Server 2008 ~ 2025
- PowerShell 5.1, 관리자 권한
- 실제 지원은 `termsrv.dll` 버전이 엄격한 검증을 통과하는지에 달려 있습니다

## 라이선스

소유하거나 관리 권한이 있는 기기에서만 사용하세요. [stascorp/rdpwrap](https://github.com/stascorp/rdpwrap), RDPWrapOffsetFinder 등 커뮤니티 프로젝트 기반.
