# 既知の問題と解決策

## SwiftPMリソースバンドルとmacOSアプリ配布

### 症状

- 手作業で構築した`.app`がソースフォルダへのアクセスを要求する
- 設定画面のローカライズ文字列が見つからない、またはアプリがクラッシュする
- `codesign --verify --deep --strict`が失敗する
- 再署名時に`unsealed contents present in the bundle root`と表示される

### 原因

SwiftPMで直接ビルドした依存パッケージの`Bundle.module`アクセサーは、`Bundle.main.bundleURL`直下のリソースバンドルを検索し、見つからない場合はビルドディレクトリの絶対パスへフォールバックします。

依存バンドルを`.app`ルートへコピーするとSwiftPM実行時の検索には一致しますが、標準的なmacOSバンドルレイアウトから外れるため、コード署名がルート直下の内容を封印できません。一方、手作業で`Contents/Resources`へ移すだけでは、SwiftPM生成アクセサーがバンドルを見つけられません。

### 採用した解決策

ソースコードと開発用テストには`Package.swift`を維持し、配布用`.app`の構築は`CursorHighlighting.xcodeproj`のmacOS Applicationターゲットへ移しました。

Xcodeはパッケージ依存のリソースを次の標準位置へ配置し、`Info.plist`、実行ファイル、リソースを一つの署名として封印します。

```text
CursorHighlighting.app/
└── Contents/
    ├── Info.plist
    ├── MacOS/CursorHighlighting
    ├── Resources/
    │   ├── Defaults_Defaults.bundle
    │   ├── KeyboardShortcuts_KeyboardShortcuts.bundle
    │   └── icon.icns
    └── _CodeSignature/
```

`project.yml`をXcodeプロジェクトの生成元として保持しています。通常のビルドではコミット済みの`CursorHighlighting.xcodeproj`を使用するため、XcodeGenのインストールは不要です。

### 検証方法

```bash
make verify
```

このターゲットはReleaseアプリを作成し、以下を確認します。

- `Info.plist`が有効である
- 厳格なコード署名検証に成功する
- `.app`ルート直下には`Contents`以外が存在しない

個別に確認する場合は次のコマンドを使用します。

```bash
plutil -lint build/CursorHighlighting.app/Contents/Info.plist
codesign --verify --deep --strict --verbose=4 build/CursorHighlighting.app
codesign -dvvv build/CursorHighlighting.app
```

ローカルの`make app`は、Hardened Runtimeを有効にしたアドホック署名済みアプリを生成します。一般配布にはDeveloper ID Application証明書とAppleの公証が別途必要です。

### 禁止事項

- 依存ライブラリの`.bundle`を`.app`ルート直下へコピーしない
- SwiftPMの生成済み`resource_bundle_accessor.swift`をビルド後に書き換えない
- 未封印の手作り`.app`へ`codesign --deep --force`を追加するだけで修復しようとしない
- `swift run`の成功を配布用`.app`の検証として扱わない

### 参考情報

- [SwiftPM issue #4372](https://github.com/swiftlang/swift-package-manager/issues/4372)
- [Apple Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/AboutCS/AboutCS.html)
- [Apple: Creating distribution-signed code for the Mac](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac)
