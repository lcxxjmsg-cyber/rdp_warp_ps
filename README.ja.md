🌐 **言語 / Language**: [English](README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md) | [Русский](README.ru.md)

# rdpwarp — Windows マルチセッション リモートデスクトップツール

> 1 台の Windows PC で**複数のユーザーが同時にリモートログイン**できるようにします。簡単に使えます。

## 目次

- [これは何？](#これは何)
- [できること](#できること)
- [クイックスタート](#クイックスタート)
- [リリースからダウンロード](#リリースからダウンロード)
- [よくある質問](#よくある質問)
- [アンインストール](#アンインストール)
- [動作環境](#動作環境)
- [ライセンス](#ライセンス)

## これは何？

Windows の「リモートデスクトップ」は通常 1 セッションしか同時に使えません。このツールは **RDP Wrapper（rdpwrap）** を使ってその制限を解除し、複数ユーザーが同時に接続・利用できるようにします。

## できること

- ワンクリックでインストール / アンインストール、マルチセッション有効化
- 最大セッション数、ユーザーごと 1 セッション、セキュリティ（NLA / セキュリティ層）、表示、タイムアウト、ポートを設定
- Windows のビルドを自動検出し、更新後のオフセットを自動修復
- 自己修復ウォッチドッグ（起動時 + 毎日チェック）
- 8 言語対応

## クイックスタート

**方法 1：直接接続**

```powershell
powershell -c "(irm https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

**方法 2：プロキシを使う（中国国内におすすめ）**

```powershell
powershell -c "$env:GH_MIRROR='https://gh-proxy.com/';(irm https://gh-proxy.com/https://raw.githubusercontent.com/lcxxjmsg-cyber/rdp_warp_ps/main/rdpwarps.ps1).TrimStart([char]0xFEFF)|iex"
```

**UAC** のプロンプトが出たら「はい」を選び、**1** でインストール。長期 / オフライン利用は下記からダウンロード。

## リリースからダウンロード

**[Releases](https://github.com/lcxxjmsg-cyber/rdp_warp_ps/releases)** から `rdp_warp_ps-vX.Y.Z.zip` をダウンロードし、解凍後 **`start.bat`** をダブルクリック（自動昇格）。あるいは：

```powershell
.\rdpwarps.ps1 -Install    # サイレントインストール
.\rdpwarps.ps1 -Uninstall  # アンインストール
```

## よくある質問

**Q1：インストール後も TermService が停止したまま？**
おそらく **Smart App Control / メモリ整合性（コード整合性）** が未署名の rdpwrap をブロックしています。「Smart App Control」と「メモリ整合性」をオフにし、**再起動**。さらに `C:\Program Files\rdpwarp`、`C:\rdpwarp` を Defender の除外に追加。

**Q2：他人のセッションをシャドウできますか？**
クライアント版では**自分の**セッションのみシャドウ可能。ユーザー間のシャドウは **Windows Server + RDS** が必要（管理者 + 「リモート制御の規則を設定」ポリシー + 再起動）。

**Q3：「管理者権限が必要」と出ますか？**
スクリプトが自動昇格します。UAC が拒否されたら「管理者として実行」を右クリック、または `start.bat` を使用。

## アンインストール

`.\rdpwarps.ps1 -Uninstall` を実行すると、設定を復元し、配置ファイル・ウォッチドッグ・Defender 除外を削除します。

## 動作環境

- Windows 8.1 / 10 / 11、Windows Server 2008 ~ 2025
- PowerShell 5.1、管理者権限
- 実際の対応は `termsrv.dll` のバージョンが厳密な検証を通るかによります

## ライセンス

所有または管理を許可されたデバイスでのみ使用してください。[stascorp/rdpwrap](https://github.com/stascorp/rdpwrap)、RDPWrapOffsetFinder などのコミュニティプロジェクトを基にしています。
