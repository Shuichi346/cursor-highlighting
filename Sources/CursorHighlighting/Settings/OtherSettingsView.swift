import Defaults
import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

// 一般設定コンテンツ
struct GeneralSettingsContentView: View {
    @State private var showResetAlert = false

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

            SectionHeader(title: L("settings.others.reset"))
            SettingsCard {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("settings.others.resetTitle"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                        Text(L("settings.others.resetDescription"))
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Button(L("settings.others.resetButton")) {
                        showResetAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red.opacity(0.85))
                    .controlSize(.regular)
                }
            }

            SectionHeader(title: L("settings.others.about"))
            SettingsCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cursor Highlighting")
                            .font(.system(size: 13, weight: .semibold))
                        Text("v1.0.5 · MIT License")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .alert(L("settings.others.resetConfirmTitle"), isPresented: $showResetAlert) {
            Button(L("settings.others.resetButton"), role: .destructive) {
                resetAllSettings()
            }
            Button(L("settings.others.resetCancel"), role: .cancel) {}
        } message: {
            Text(L("settings.others.resetConfirmMessage"))
        }
    }

    // すべての設定をデフォルト値にリセット
    private func resetAllSettings() {
        // スポットライト設定
        Defaults.reset(.spotlightEnabled)
        Defaults.reset(.spotlightRadius)
        Defaults.reset(.spotlightBlur)
        Defaults.reset(.spotlightOpacity)
        Defaults.reset(.spotlightColor)

        // クリック可視化設定
        Defaults.reset(.clickEnabled)
        Defaults.reset(.leftClickColor)
        Defaults.reset(.rightClickColor)
        Defaults.reset(.clickRingMaxRadius)

        // キーストローク設定
        Defaults.reset(.keyStrokeEnabled)
        Defaults.reset(.keyStrokeFontSize)
        Defaults.reset(.keyStrokeTheme)

        // グローバルホットキーをリセット（未設定に戻す）
        KeyboardShortcuts.reset(.toggleSpotlight)
        KeyboardShortcuts.reset(.toggleClicks)
        KeyboardShortcuts.reset(.toggleKeyStrokes)
    }
}
