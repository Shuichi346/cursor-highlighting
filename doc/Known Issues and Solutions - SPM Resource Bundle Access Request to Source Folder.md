# 既知の問題と解決策

## SPMリソースバンドルによるソースフォルダへのアクセス要求

### 症状
- ビルドした `.app` を `/Applications/` 等に配置して初回起動すると、**ソースコードが存在するフォルダ（例: 書類フォルダ内のGitリポジトリ）へのアクセス許可**を求められる
- アクセスを拒否するとアプリが正常に動作しない（UIの文字列が表示されない、クラッシュする等）
- `swift run` で直接実行した場合は問題なく動作する
- `.app` バンドルのサイズが不自然に小さい（リソースが実質的にバイナリ外部に依存している）

### 原因
**Swift Package Manager の `Bundle.module` の設計上の制約。** SPMのバージョンや Swift のバージョンに関わらない構造的な問題（SPM 5.3 でリソースバンドル機能が導入されて以来存在する）。

SPMでターゲットにリソースを宣言すると（`resources: [.process("Resources")]` 等）、ビルド時に `resource_bundle_accessor.swift` が自動生成される。このファイルの中で `Bundle.module` は以下の2つのパスを順番に探す：

```swift
static let module: Bundle = {
    // 1. Bundle.main.bundleURL 直下（.app/MyTarget_MyPackage.bundle）
    let mainPath = Bundle.main.bundleURL
        .appendingPathComponent("MyTarget_MyPackage.bundle").path
    // 2. ビルドディレクトリの絶対パス（ハードコード）
    let buildPath = "/Users/username/Documents/GitHub/my-project/.build/release/MyTarget_MyPackage.bundle"

    let preferredBundle = Bundle(path: mainPath)
    guard let bundle = preferredBundle ?? Bundle(path: buildPath) else {
        Swift.fatalError("could not load resource bundle: ...")
    }
    return bundle
}()
```

**ポイント:**
- `mainPath` は `Bundle.main.bundleURL` を使う。macOS の `.app` バンドルでは `MyApp.app/` を返す（`MyApp.app/Contents/Resources/` ではない）
- `mainPath` で見つからない場合、`buildPath`（ビルド時の絶対パス）にフォールバックする
- `buildPath` がソースコードのあるディレクトリを含むため、macOS がそのフォルダへのアクセス許可を要求する

**この問題が発生する条件:**
1. SPM で `resources` を宣言しているターゲットが存在する（自プロジェクト、または依存ライブラリ）
2. Makefile 等で手動で `.app` バンドルを構築している
3. リソースバンドル（`.bundle`）のコピー先が `Bundle.main.bundleURL` の返すパスと一致しない

**この問題は以下に該当しない:**
- Xcodeプロジェクト（`.xcodeproj`）でビルドした場合（Xcodeは自動的にバンドル配置を処理する）
- `swift run` で直接実行した場合（バイナリとバンドルが同じディレクトリに存在する）

### 影響範囲
自プロジェクトのリソースだけでなく、**依存ライブラリがリソースを持っている場合も同様に発生する。** 例えば以下のような広く使われているライブラリが該当する：
- `sindresorhus/KeyboardShortcuts`（ローカライゼーションファイル）
- `sindresorhus/Defaults`（PrivacyInfo.xcprivacy）
- その他 `Package.swift` で `resources:` を宣言しているSPMライブラリ全般

### 解決策

#### A. 依存ライブラリのリソースバンドル配置を修正する

Makefile でバンドルを `.app` 内にコピーする際、コピー先を **`.app` のルート直下** にする。`Contents/Resources/` ではない。

```makefile
# ❌ 間違い: Bundle.main.bundleURL はここを見ない
@find -L $(BUILD_DIR) -maxdepth 1 -type d -name '*.bundle' \
    -exec cp -R {} $(APP_BUNDLE)/Contents/Resources/ \;

# ✅ 正解: Bundle.main.bundleURL が返す .app/ 直下に配置
@find -L $(BUILD_DIR) -maxdepth 1 -type d -name '*.bundle' \
    -exec cp -R {} $(APP_BUNDLE)/ \;
```

`Bundle.main.bundleURL` は macOS の `.app` バンドルで `MyApp.app/` を返すため、SPM生成コードの `mainPath` が `MyApp.app/SomeLibrary_SomeLibrary.bundle` を正しく見つけられるようになる。

#### B. 自プロジェクトのリソースバンドルを廃止する（推奨）

自プロジェクトが SPM リソースバンドルを使っている場合（ローカライゼーション文字列、アセット等）、以下の変更で `Bundle.module` への依存を排除できる：

1. **`Package.swift`** から `resources` と `exclude` を削除する
2. **リソースの代替手段を使う:**
   - ローカライゼーション文字列 → Swift コード内の辞書で管理
   - アセット → `Info.plist` は Makefile で直接コピー、アイコンは `Resources/` ディレクトリに残して Makefile でコピー
3. **`Bundle.module` を参照しているコードを全て修正する**

これにより、SPM は自プロジェクト用の `resource_bundle_accessor.swift` を生成しなくなる。

#### C. A + B を組み合わせる（最も確実）

自プロジェクトのバンドルを廃止（B）しつつ、依存ライブラリのバンドルは `.app` ルートに正しく配置（A）する。

### 確認方法

修正後、以下を実行して問題が解消されたか確認する：

```bash
# クリーンビルド
make clean && make app

# 拡張属性を除去（macOS のセキュリティ警告対策）
xattr -cr build/MyApp.app

# /Applications にコピーして起動テスト
cp -r build/MyApp.app /Applications/
open /Applications/MyApp.app
```

起動時およびすべての機能使用時に、ソースフォルダへのアクセス許可ダイアログが表示されないことを確認する。

### 参考情報
- SPM Issue: [SR-15550 / swiftlang/swift-package-manager#4372](https://github.com/swiftlang/swift-package-manager/issues/4372) — `.app` バンドルでのリソース読み込み失敗
- SPM Issue: [swiftlang/swift-package-manager#9656](https://github.com/swiftlang/swift-package-manager/issues/9656) — 生成される `resource_bundle_accessor.swift` の内容が確認可能
- SPMソースコード: `SwiftModuleBuildDescription.swift` 内の `generateResourceAccessor()` メソッドがテンプレートを定義

### 補足: これは仕様か、バグか

**SPMの設計上の制約（仕様とバグの中間）。** SPM のリソースバンドル機能は元々ライブラリ向けに設計されており、Xcode プロジェクトに統合される前提で作られている。Makefile で手動構築する `.app` バンドルは SPM の想定外の使い方であり、`Bundle.main.bundleURL` が返すパスの違いに対応していない。Swift 5.3（SPM リソース機能の導入）から Swift 6.x まで一貫して存在する制約であり、Swift 6 固有の問題ではない。ただし、以前のSPMバージョンでは `Bundle.main.resourceURL`（macOS では `Contents/Resources/` を返す）も候補に含まれていた可能性があり、現行バージョンでは `bundleURL` のみ使用する実装に簡素化されたことで、この問題が顕在化しやすくなっている。

---

## 禁止事項

- SPMプロジェクトで Makefile を使って `.app` バンドルを構築する場合、依存ライブラリの `.bundle` を `Contents/Resources/` にコピーしない（`Bundle.main.bundleURL` が返すパスと一致しないため）
- `swift run` で動作確認できたからといって `.app` バンドルでも動作すると仮定しない（`Bundle.main` の挙動が異なる）