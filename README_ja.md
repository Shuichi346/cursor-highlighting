<table>
  <thead>
    <tr>
      <th style="text-align:center"><a href="README_ja.md">日本語</a></th>
      <th style="text-align:center"><a href="README.md">English</a></th>
    </tr>
  </thead>
</table>

<div align="center">

# Cursor Highlighting

**マウス操作とキーボード入力を視覚的にハイライトするmacOSメニューバーユーティリティ**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2026.0+-blue.svg)]()
[![Swift](https://img.shields.io/badge/Swift-6.3-orange.svg)]()

<img src="https://developer.apple.com/assets/elements/icons/swiftui/swiftui-96x96_2x.png" width="80" alt="SwiftUI">

</div>

---

## 目次

- [概要](#概要)
- [機能](#機能)
- [スクリーンショット](#スクリーンショット)
- [必要環境](#必要環境)
- [ビルドと実行](#ビルドと実行)
- [権限](#権限)
- [設定](#設定)
- [キーボードショートカット](#キーボードショートカット)
- [アーキテクチャ](#アーキテクチャ)
- [技術スタック](#技術スタック)
- [クレジット](#クレジット)
- [ライセンス](#ライセンス)

---

## 概要

Cursor Highlightingは、プレゼンテーション、画面録画、ライブストリーミング向けに設計された軽量でメニューバー専用のmacOSユーティリティです。マウススポットライト、クリックリングアニメーション、オンスクリーンキーストロークHUDという3つのコア視覚フィードバック機能を提供し、すべてカスタマイズ可能なグローバルホットキーで制御できます。

このアプリはDockアイコンなしでメニューバーからのみ動作し、視聴者に明確な視覚的手がかりを提供しながら邪魔になりません。

---

## 機能

- **マウススポットライト** — カーソルに追従する設定可能な円を除いて画面全体を暗くし、指している場所に注意を引きつけます。

- **クリック効果** — 左右のマウスクリックで色分けされた拡大リングアニメーションを表示し、すべてのクリックを視聴者に見やすくします。

- **キーストローク表示** — 押されたキーを、ネイティブmacOS修飾記号（`⌘` `⌥` `⇧` `⌃` `⇪` `fn`）とともに画面下中央のHUDオーバーレイに表示し、キーボードショートカットのデモに最適です。

- **グローバルホットキー** — すべての機能は、他のアプリがフォアグラウンドにあっても機能する、完全にカスタマイズ可能なグローバルキーボードショートカットで切り替え可能です。

- **リアルタイム設定** — すべての設定（色、サイズ、不透明度、ぼかし）は機能がアクティブな間に即座に適用され、再起動は不要です。

- **デフォルトにリセット** — 設定でワンクリックリセットにより、すべての設定を元の値に復元できます。

- **ログイン時に起動** — オプションでログイン時にアプリを自動起動できます。

---

## スクリーンショット

<div align="center">
  <img src="doc/hwoto.gif" alt="Cursor Highlighting Demo" width="854">
</div>


---

## 必要環境

| 必要項目 | バージョン |
|---|---|
| **macOS** | 26.0 (Tahoe) 以降 |
| **Xcode** | 26.4+ (Swift 6.3 toolchain と macOS 26 SDK を提供) |

> [!IMPORTANT]
> このアプリは**サンドボックス化されていません**。`CGEventTap`経由でマウスとキーボードイベントを監視するためにアクセシビリティ権限が必要です。

---

## ビルドと実行

リポジトリをクローンして、提供されているMakefileを使用してください：

```bash
git clone https://github.com/Shuichi346/cursor-highlighting.git
cd cursor-highlighting
```

### 利用可能なMakeターゲット

| コマンド | 説明 |
|---|---|
| `make run` | アプリをビルドして直接実行 |
| `make app` | `build/CursorHighlighting.app`に`.app`バンドルを作成 |
| `make build-release` | バンドル化せずにリリースバイナリをビルド |
| `make clean` | すべてのビルド成果物を削除 |

### クイックスタート

```bash
# ソースから直接実行
make run

# または.appバンドルをビルドして開く
make app
open build/CursorHighlighting.app
```

---

## 権限

このアプリはグローバルなマウスとキーボードイベントを監視するために**アクセシビリティ**権限が必要です。

初回起動時に、アクセスを許可するよう求められます。プロンプトが表示されない場合や手動で許可する必要がある場合：

1. **システム設定**を開く
2. **プライバシーとセキュリティ → アクセシビリティ**に移動
3. **Cursor Highlighting**を有効にする

アプリは権限ステータスをポーリングし、アクセスが許可されると自動的に機能がアクティブになります。

---

## アーキテクチャ

**Swift 6.3言語モード**（厳密な並行性）で構築。このアプリは、慎重に設計されたアーキテクチャを通じて、構造的にゼロデータ競合を実現しています：

```
Sources/CursorHighlighting/
├── App/                        # エントリーポイント、アプリ状態、権限管理
│   ├── CursorHighlightingApp.swift
│   ├── AppState.swift
│   └── PermissionManager.swift
├── Bridge/                     # Cコールバック → AsyncStreamブリッジ
│   ├── CGEventBridge.swift     # CGEventTap → AsyncStream<BridgedKeyEvent>
│   └── NSEventBridge.swift     # NSEventモニター → AsyncStream<BridgedMouseEvent>
├── Features/
│   ├── Spotlight/              # カーソル追従円付きフルスクリーン暗転オーバーレイ
│   ├── ClickVisualizer/        # マウスクリック時の拡大リングアニメーション
│   └── KeyStroke/              # 押されたキー用の画面下中央HUD
├── Settings/                   # サイドバーナビゲーション付きSwiftUI設定ウィンドウ
├── Overlay/                    # 透明オーバーレイ用の共有NSPanelサブクラス
├── Utilities/                  # 色のシリアライゼーション、キーシンボルマッピング、ローカライゼーション
└── Resources/                  # Info.plist、Localizable.strings
```

### 並行性モデル

中心的な技術的課題は、`CGEventTapCallBack`（任意のスレッドで呼び出されるC規約関数ポインター）をSwiftの構造化並行性に安全にブリッジすることです。解決策では`AsyncStream.Continuation`を使用し、これは`yield`呼び出しに対してスレッドセーフです。Cコールバックから`@MainActor`で実行される`for await`ループにイベントを渡します。コンパイラは、すべてのUI更新がメインアクター上で発生することを静的に検証し、スレッディングバグのクラス全体を排除します。

- コードベースのどこにも**`DispatchQueue.main.async`なし** — すべてのメインスレッドディスパッチは`@MainActor`隔離を使用
- プロジェクト全体で**`@unchecked Sendable`は1つのみ**（`CGEventBridge.swift`の最小Cブリッジラッパー）
- すべての機能は、イベント処理に`AsyncStream`、リアクティブ設定観察に`Defaults.updates()`を使用

---

## 技術スタック

| カテゴリ | 技術 |
|---|---|
| **言語** | Swift 6.3 (Swift 6言語モード) |
| **UIフレームワーク** | SwiftUI + AppKit相互運用 |
| **グラフィックス** | Core Graphics、Core Animation |
| **並行性** | Swift構造化並行性、AsyncStream |
| **ビルドシステム** | Swift Package Manager + Makefile |
| **プラットフォーム** | macOS 26.0 (Tahoe) |

### 依存関係

| パッケージ | 目的 |
|---|---|
| [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) | グローバルホットキーの記録とリスニング |
| [LaunchAtLogin-Modern](https://github.com/sindresorhus/LaunchAtLogin-Modern) | ログイン時起動の統合 |
| [Defaults](https://github.com/sindresorhus/Defaults) | リアクティブ観察付きタイプセーフUserDefaults |

---

## クレジット

このプロジェクトは、[Sindre Sorhus](https://github.com/sindresorhus)による優れたオープンソースライブラリに依存しています：

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)
- [LaunchAtLogin-Modern](https://github.com/sindresorhus/LaunchAtLogin-Modern)
- [Defaults](https://github.com/sindresorhus/Defaults)

---

## ライセンス

このプロジェクトは**MITライセンス**の下でライセンスされています。詳細については[LICENSE](LICENSE)ファイルを参照してください。

このツールが使用する外部モデルとライブラリは、それぞれ独自のライセンスを持っています。
