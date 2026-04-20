import Defaults
import KeyboardShortcuts

// アプリ全体の設定キー定義
extension Defaults.Keys {
    // スポットライト設定
    static let spotlightEnabled = Key<Bool>("spotlightEnabled", default: false)
    static let spotlightRadius = Key<Double>("spotlightRadius", default: 150.0)
    static let spotlightBlur = Key<Double>("spotlightBlur", default: 30.0)
    static let spotlightOpacity = Key<Double>("spotlightOpacity", default: 0.5)
    static let spotlightColor = Key<CodableColor>("spotlightColor", default: .spotlightDefault)

    // クリック可視化設定
    static let clickEnabled = Key<Bool>("clickEnabled", default: true)
    static let leftClickColor = Key<CodableColor>("leftClickColor", default: .blue)
    static let rightClickColor = Key<CodableColor>("rightClickColor", default: .red)
    static let clickRingMaxRadius = Key<Double>("clickRingMaxRadius", default: 30.0)

    // キーストローク設定
    static let keyStrokeEnabled = Key<Bool>("keyStrokeEnabled", default: true)
    static let keyStrokeFontSize = Key<Double>("keyStrokeFontSize", default: 48.0)
    static let keyStrokeTheme = Key<String>("keyStrokeTheme", default: "dark")
}

// グローバルホットキー名の定義
extension KeyboardShortcuts.Name {
    static let toggleSpotlight = Self("toggleSpotlight", default: .init(.one, modifiers: [.shift]))
    static let toggleClicks = Self("toggleClicks")
    static let toggleKeyStrokes = Self("toggleKeyStrokes")
}
