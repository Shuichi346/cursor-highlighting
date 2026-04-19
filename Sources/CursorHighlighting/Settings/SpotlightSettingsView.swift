import Defaults
import KeyboardShortcuts
import Settings
import SwiftUI

// スポットライト設定タブ
struct SpotlightSettingsView: View {
    @Default(.spotlightRadius) private var radius
    @Default(.spotlightBlur) private var blur
    @Default(.spotlightOpacity) private var opacity
    @Default(.spotlightColor) private var spotlightColor
    @State private var selectedColor: Color = .white

    var body: some View {
        Settings.Container(contentWidth: 450.0) {
            Settings.Section(title: L("settings.spotlight.hotkey")) {
                KeyboardShortcuts.Recorder(for: .toggleSpotlight)
            }
            Settings.Section(title: L("settings.spotlight.radius")) {
                Slider(value: $radius, in: 50...400, step: 10) {
                    Text("\(Int(radius)) px")
                }
            }
            Settings.Section(title: L("settings.spotlight.blur")) {
                Slider(value: $blur, in: 0...100, step: 5) {
                    Text("\(Int(blur)) px")
                }
            }
            Settings.Section(title: L("settings.spotlight.opacity")) {
                Slider(value: $opacity, in: 0.1...1.0, step: 0.05) {
                    Text(String(format: "%.0f%%", opacity * 100))
                }
            }
            Settings.Section(title: L("settings.spotlight.color")) {
                ColorPicker(
                    L("settings.spotlight.color"), selection: $selectedColor, supportsOpacity: false
                )
                .onAppear {
                    selectedColor = spotlightColor.color
                }
                .onChange(of: selectedColor) { _, newValue in
                    spotlightColor = CodableColor(nsColor: NSColor(newValue))
                }
            }
        }
    }
}
