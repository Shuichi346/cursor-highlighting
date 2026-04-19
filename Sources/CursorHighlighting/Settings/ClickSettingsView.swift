import Defaults
import KeyboardShortcuts
import Settings
import SwiftUI

// クリック可視化設定タブ
struct ClickSettingsView: View {
    @Default(.leftClickColor) private var leftClickColor
    @Default(.rightClickColor) private var rightClickColor
    @Default(.clickRingMaxRadius) private var ringMaxRadius
    @State private var leftColor: Color = .blue
    @State private var rightColor: Color = .red

    var body: some View {
        Settings.Container(contentWidth: 450.0) {
            Settings.Section(title: L("settings.clicks.hotkey")) {
                KeyboardShortcuts.Recorder(for: .toggleClicks)
            }
            Settings.Section(title: L("settings.clicks.leftColor")) {
                ColorPicker(
                    L("settings.clicks.leftColor"), selection: $leftColor, supportsOpacity: false
                )
                .onAppear {
                    leftColor = leftClickColor.color
                }
                .onChange(of: leftColor) { _, newValue in
                    leftClickColor = CodableColor(nsColor: NSColor(newValue))
                }
            }
            Settings.Section(title: L("settings.clicks.rightColor")) {
                ColorPicker(
                    L("settings.clicks.rightColor"), selection: $rightColor, supportsOpacity: false
                )
                .onAppear {
                    rightColor = rightClickColor.color
                }
                .onChange(of: rightColor) { _, newValue in
                    rightClickColor = CodableColor(nsColor: NSColor(newValue))
                }
            }
            Settings.Section(title: L("settings.clicks.ringSize")) {
                Slider(value: $ringMaxRadius, in: 15...80, step: 5) {
                    Text("\(Int(ringMaxRadius)) px")
                }
            }
        }
    }
}
