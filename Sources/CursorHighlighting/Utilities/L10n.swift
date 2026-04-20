import Defaults
import Foundation

enum Localization {
    static func applySavedLanguage() {
        let language = Defaults[.appLanguage]
        let currentLanguages = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String]

        if currentLanguages?.first != language || currentLanguages?.count != 1 {
            UserDefaults.standard.set([language], forKey: "AppleLanguages")
        }
    }

    static var currentBundle: Bundle {
        let language = Defaults[.appLanguage]

        guard
            let bundlePath = Bundle.module.path(forResource: language, ofType: "lproj"),
            let bundle = Bundle(path: bundlePath)
        else {
            return .module
        }

        return bundle
    }
}

// ローカライズ文字列を取得するヘルパー関数
func L(_ key: String) -> String {
    NSLocalizedString(key, bundle: Localization.currentBundle, comment: "")
}
