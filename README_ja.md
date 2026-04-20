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
- [動作要件](#動作要件)
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

Cursor Highlightingは、プレゼンテーション、画面録画、ライブストリーミング向けに設計された軽量なメニューバー専用macOSユーティリティです。マウススポットライト、クリックリングアニメーション、画面上のキーストロークHUDという3つのコア視覚フィードバック機能を提供し、すべてカスタマイズ可能なグローバルホットキーで制御できます。

アプリはメニューバーから完全に実行され、Dockアイコンはなく、視聴者に明確な視覚的手がかりを提供しながら邪魔になりません。

---

## 機能

- **マウススポットライト** — カーソルを追従する設定可能な円を除いて画面全体を暗くし、ポイントしている場所に注意を向けます。

- **クリックエフェクト** — 左右のマウスクリックで色分けされたアニメーション付きの拡大リングを表示し、すべてのクリックを視聴者に見せます。

- **キーストローク表示** — 押されたキーを画面下部中央のHUDオーバーレイでネイティブmacOS修飾記号（`⌘` `⌥` `⇧` `⌃` `⇪` `fn`）と共に表示し、キーボードショートカットのデモンストレーションに最適です。

- **グローバルホットキー** — すべての機能は、他のアプリがフォアグラウンドにある時でも動作する完全にカスタマイズ可能なグローバルキーボードショートカットで切り替え可能です。

- **リアルタイム設定** — すべての設定（色、サイズ、不透明度、ブラー）は機能がアクティブな間に即座に適用されます—再起動不要です。

- **デフォルトにリセット** — 設定でワンクリックリセットによりすべての設定を元の値に復元します。

- **ログイン時に起動** — ログイン時にアプリを自動的に開始するオプション。

---

## スクリーンショット

> [!NOTE]
> [実際に動作するアプリのスクリーンショット（スポットライト効果、クリックリング、キーストロークHUD、設定ウィンドウ）をここに追加してください。]

---

## 動作要件

| 要件 | バージョン |
|---|---|
| **macOS** | 26.0 (Tahoe) 以降 |
| **Xcode** | 26.4+ (Swift 6.3ツールチェーンとmacOS 26 SDKを提供) |

> [!IMPORTANT]
> このアプリは**サンドボックス化されていません**。`CGEventTap`を介してマウスとキーボードイベントを監視するためにアクセシビリティ権限が必要です。

---

## ビルドと実行

リポジトリをクローンして提供されているMakefileを使用してください：

```bash
git clone https://github.com/Shuichi346/cursor-highlighting.git
cd cursor-highlighting
```

### 利用可能なMakeターゲット

| コマンド | 説明 |
|---|---|
| `make run` | アプリを直接ビルドして実行 |
| `make app` | `build/CursorHighlighting.app`に`.app`バンドルを作成 |
| `make build-release` | バンドル化せずにリリースバイナリをビルド |
| `make clean` | すべてのビルド生成物を削除 |

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

初回起動時にアクセスを許可するよう促されます。プロンプトが表示されない場合や手動で許可する必要がある場合：

1. **システム設定**を開く
2. **プライバシーとセキュリティ → アクセシビリティ**に移動
3. **Cursor Highlighting**を有効にする

アプリは権限ステータスをポーリングし、アクセスが許可されると自動的に機能を有効化します。

---

## 設定

メニューバーのドロップダウンから設定ウィンドウを開きます。設定は4つのタブに整理されています：

### スポットライト

| 設定 | 説明 | デフォルト |
|---|---|---|
| スポットライトを有効 | スポットライト効果を切り替え | オフ |
| 有効化ホットキー | 切り替え用グローバルショートカット | `⇧1` |
| スポットライト半径 | 明るい領域のサイズ | 150 px |
| エッジブラー | 円のエッジの柔らかさ | 30 px |
| 背景の不透明度 | 周囲の画面の暗さ | 50% |
| スポットライト色 | スポットライト円のティント色 | 白 |

### クリックエフェクト

| 設定 | 説明 | デフォルト |
|---|---|---|
| クリックリングを有効 | クリックの視覚化を切り替え | オン |
| ホットキー | 切り替え用グローバルショートカット | なし |
| 左クリック色 | 左クリックリングの色 | 青 (`#007AFF`) |
| 右クリック色 | 右クリックリングの色 | 赤 (`#FF3B30`) |
| リングサイズ | 拡大リングの最大半径 | 30 px |

### キーストローク

| 設定 | 説明 | デフォルト |
|---|---|---|
| キーストロークを表示 | キーストロークHUDを切り替え | オン |
| ホットキー | 切り替え用グローバルショートカット | なし |
| フォントサイズ | 表示キーテキストのサイズ | 48 pt |
| テーマ | HUD背景のライトまたはダーク | ダーク |

### 一般

| 設定 | 説明 |
|---|---|
| ログイン時に起動 | ログイン時に自動開始 |
| デフォルトにリセット | すべての設定を元の値に復元 |

---

## キーボードショートカット

| 機能 | デフォルトショートカット | カスタマイズ可能 |
|---|---|---|
| マウススポットライト | `⇧1` | ✅ |
| クリックエフェクト | *(なし)* | ✅ |
| キーストローク表示 | *(なし)* | ✅ |

すべてのショートカットはグローバルで、どのアプリケーションがフォアグラウンドにあっても動作します。それぞれの設定タブで内蔵のホットキーレコーダーを使用してカスタマイズできます。

---

## アーキテクチャ

**Swift 6.3言語モード**（厳密な並行性）でビルドされています。アプリは慎重に設計されたアーキテクチャを通じて構築によってデータ競合ゼロを実現しています：

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
│   └── KeyStroke/              # 押されたキー用画面下部中央HUD
├── Settings/                   # サイドバーナビゲーション付きSwiftUI設定ウィンドウ
├── Overlay/                    # 透明オーバーレイ用共有NSPanelサブクラス
├── Utilities/                  # 色のシリアル化、キーシンボルマッピング、ローカライゼーション
└── Resources/                  # Info.plist、Localizable.strings
```

### 並行性モデル

中心的な技術的課題は、`CGEventTapCallBack`（任意のスレッドで呼ばれるC規約関数ポインタ）をSwiftの構造化並行性に安全にブリッジすることです。解決策は`AsyncStream.Continuation`（`yield`呼び出しにスレッドセーフ）を使用してCコールバックから`@MainActor`で実行される`for await`ループにイベントを渡すことです。コンパイラはすべてのUI更新がメインアクター上で発生することを静的に検証し、スレッド化バグのクラス全体を排除します。

- コードベース全体で**`DispatchQueue.main.async`なし** — すべてのメインスレッドディスパッチは`@MainActor`隔離を使用
- プロジェクト全体で**`@unchecked Sendable`は1つだけ**（`CGEventBridge.swift`の最小限のCブリッジラッパー）
- すべての機能はイベント処理に`AsyncStream`を、リアクティブ設定監視に`Defaults.updates()`を使用

---

## 技術スタック

| カテゴリ | 技術 |
|---|---|
| **言語** | Swift 6.3 (Swift 6言語モード) |
| **UIフレームワーク** | SwiftUI + AppKit相互運用 |
| **グラフィック** | Core Graphics、Core Animation |
| **並行性** | Swift構造化並行性、AsyncStream |
| **ビルドシステム** | Swift Package Manager + Makefile |
| **プラットフォーム** | macOS 26.0 (Tahoe) |

### 依存関係

| パッケージ | 目的 |
|---|---|
| [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) | グローバルホットキー録画とリスニング |
| [LaunchAtLogin-Modern](https://github.com/sindresorhus/LaunchAtLogin-Modern) | ログイン時起動統合 |
| [Defaults](https://github.com/sindresorhus/Defaults) | リアクティブ監視付きタイプセーフUserDefaults |

---

## クレジット

このプロジェクトは[Sindre Sorhus](https://github.com/sindresorhus)による素晴らしいオープンソースライブラリに依存しています：

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)
- [LaunchAtLogin-Modern](https://github.com/sindresorhus/LaunchAtLogin-Modern)
- [Defaults](https://github.com/sindresorhus/Defaults)

---

## ライセンス

このプロジェクトは**MITライセンス**の下でライセンスされています。詳細については[LICENSE](LICENSE)ファイルをご覧ください。

このツールで使用される外部モデルとライブラリは、それぞれ独自のライセンスを持っています。
