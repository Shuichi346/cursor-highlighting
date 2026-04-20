import Defaults
import LaunchAtLogin
import SwiftUI

// 一般設定コンテンツ
struct GeneralSettingsContentView: View {
    @Default(.appLanguage) private var appLanguage
    @State private var showRestartAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageHeader(
                title: L("settings.others.title"),
                subtitle: L("settings.others.subtitle")
            )

            SectionHeader(title: L("settings.others.startup"))
            SettingsCard {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("settings.others.launchAtLogin"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                        Text(L("settings.others.launchAtLoginDescription"))
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    LaunchAtLogin.Toggle("")
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .tint(Color(red: 0.40, green: 0.56, blue: 0.90))
                }
            }

            SectionHeader(title: L("settings.others.language"))
            SettingsCard {
                SettingsRow(
                    label: L("settings.others.language"),
                    subtitle: L("settings.others.languageDescription")
                ) {
                    Picker("", selection: $appLanguage) {
                        Text(L("settings.others.language.en")).tag("en")
                        Text(L("settings.others.language.ja")).tag("ja")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                    .labelsHidden()
                    .onChange(of: appLanguage) { _, _ in
                        Localization.applySavedLanguage()
                        showRestartAlert = true
                    }
                }
            }

            SectionHeader(title: L("settings.others.about"))
            SettingsCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cursor Highlighting")
                            .font(.system(size: 13, weight: .semibold))
                        Text("v1.0.2 · MIT License")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .alert(L("settings.others.language"), isPresented: $showRestartAlert) {
            Button("OK") { showRestartAlert = false }
        } message: {
            Text(L("settings.others.restartRequired"))
        }
    }
}
