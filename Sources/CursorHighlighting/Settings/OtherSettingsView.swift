import SwiftUI
import Settings
import Defaults
import LaunchAtLogin

// その他設定タブ
struct OtherSettingsView: View {
    @Default(.appLanguage) private var appLanguage
    @State private var showRestartAlert = false

    var body: some View {
        Settings.Container(contentWidth: 450.0) {
            Settings.Section(title: L("settings.others.launchAtLogin")) {
                LaunchAtLogin.Toggle(L("settings.others.launchAtLogin"))
            }
            Settings.Section(title: L("settings.others.language")) {
                Picker(L("settings.others.language"), selection: $appLanguage) {
                    Text(L("settings.others.language.en")).tag("en")
                    Text(L("settings.others.language.ja")).tag("ja")
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .onChange(of: appLanguage) { _, newValue in
                    UserDefaults.standard.set([newValue], forKey: "AppleLanguages")
                    UserDefaults.standard.synchronize()
                    showRestartAlert = true
                }
                .alert(L("settings.others.language"), isPresented: $showRestartAlert) {
                    Button("OK") { showRestartAlert = false }
                } message: {
                    Text(L("settings.others.restartRequired"))
                }
            }
        }
    }
}
