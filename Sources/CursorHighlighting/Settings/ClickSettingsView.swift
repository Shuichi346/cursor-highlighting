import Defaults
import KeyboardShortcuts
import Settings
import SwiftUI

// クリック可視化設定タブ
struct ClickSettingsView: View {
    @Default(.leftClickColor) private var leftClickColor
    @Default(.rightClickColor) private var rightClickColor
    @Default(.clickRingMaxRadius) private var ringMaxRadius

    private var leftColorBinding: Binding<Color> {
        Binding(
            get: { leftClickColor.color },
            set: { leftClickColor = CodableColor(nsColor: NSColor($0)) }
        )
    }

    private var rightColorBinding: Binding<Color> {
        Binding(
            get: { rightClickColor.color },
            set: { rightClickColor = CodableColor(nsColor: NSColor($0)) }
        )
    }

    var body: some View {
        Settings.Container(contentWidth: 450.0) {
            Settings.Section(title: L("settings.clicks.hotkey")) {
                KeyboardShortcuts.Recorder(for: .toggleClicks)
            }
            Settings.Section(title: L("settings.clicks.leftColor")) {
                ColorPicker(
                    L("settings.clicks.leftColor"),
                    selection: leftColorBinding,
                    supportsOpacity: false
                )
            }
            Settings.Section(title: L("settings.clicks.rightColor")) {
                ColorPicker(
                    L("settings.clicks.rightColor"),
                    selection: rightColorBinding,
                    supportsOpacity: false
                )
            }
            Settings.Section(title: L("settings.clicks.ringSize")) {
                HStack(spacing: 12) {
                    Slider(value: $ringMaxRadius, in: 0...80, step: 5)
                        .frame(width: 250)
                    Text("\(Int(ringMaxRadius)) px")
                        .monospacedDigit()
                        .frame(width: 64, alignment: .leading)
                }
            }
        }
    }
}
