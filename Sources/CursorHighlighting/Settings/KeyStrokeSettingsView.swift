import Defaults
import KeyboardShortcuts
import SwiftUI

// キーストローク設定コンテンツ
struct KeyStrokeSettingsContentView: View {
    @Default(.keyStrokeEnabled) private var keyStrokeEnabled
    @Default(.keyStrokeFontSize) private var fontSize
    @Default(.keyStrokeTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageHeader(
                title: L("settings.keystrokes.title"),
                subtitle: L("settings.keystrokes.subtitle")
            )

            SettingsCard {
                ToggleRow(
                    label: L("settings.keystrokes.enabled"),
                    subtitle: L("settings.keystrokes.enabledDescription"),
                    isOn: $keyStrokeEnabled
                )

                Divider().opacity(0.5)

                SettingsRow(
                    label: L("settings.keystrokes.hotkey"),
                    subtitle: L("settings.keystrokes.hotkeyDescription")
                ) {
                    KeyboardShortcuts.Recorder(for: .toggleKeyStrokes)
                        .frame(maxWidth: 180)
                }
            }

            SectionHeader(title: L("settings.appearance"))
            SettingsCard {
                SettingsRow(label: L("settings.keystrokes.fontSize")) {
                    ValueSlider(value: $fontSize, in: 10...96, step: 4, unit: "pt")
                }
                Divider().opacity(0.5)
                SettingsRow(label: L("settings.keystrokes.theme")) {
                    Picker("", selection: $theme) {
                        Text(L("settings.keystrokes.theme.light")).tag("light")
                        Text(L("settings.keystrokes.theme.dark")).tag("dark")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                    .labelsHidden()
                }
            }
        }
    }
}
