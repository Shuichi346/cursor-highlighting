import Foundation

// ローカライズ文字列を取得するヘルパー関数（英語のみ）
func L(_ key: String) -> String {
    NSLocalizedString(key, bundle: .module, comment: "")
}
