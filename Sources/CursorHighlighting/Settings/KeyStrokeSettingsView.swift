import Defaults
import KeyboardShortcuts
import Settings
import SwiftUI

// キーストローク設定タブ
struct KeyStrokeSettingsView: View {
    @Default(.keyStrokeEnabled) private var keyStrokeEnabled
    @Default(.keyStrokeFontSize) private var fontSize

    var body: some View {
        Settings.Container(contentWidth: 450.0) {
            Settings.Section(title: L("settings.keystrokes.hotkey")) {
                KeyboardShortcuts.Recorder(for: .toggleKeyStrokes)
            }
            Settings.Section(title: L("settings.keystrokes.enabled")) {
                Toggle(L("settings.keystrokes.enabled"), isOn: $keyStrokeEnabled)
            }
            Settings.Section(title: L("settings.keystrokes.fontSize")) {
                HStack(spacing: 12) {
                    Slider(value: $fontSize, in: 10...96, step: 4)
                        .frame(width: 250)
                    Text("\(Int(fontSize)) pt")
                        .monospacedDigit()
                        .frame(width: 64, alignment: .leading)
                }
            }
        }
    }
}
