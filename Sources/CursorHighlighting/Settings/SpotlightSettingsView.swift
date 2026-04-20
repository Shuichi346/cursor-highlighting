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

    private var colorBinding: Binding<Color> {
        Binding(
            get: { spotlightColor.color },
            set: { spotlightColor = CodableColor(nsColor: NSColor($0)) }
        )
    }

    var body: some View {
        Settings.Container(contentWidth: 450.0) {
            Settings.Section(title: L("settings.spotlight.hotkey")) {
                KeyboardShortcuts.Recorder(for: .toggleSpotlight)
            }
            Settings.Section(title: L("settings.spotlight.radius")) {
                HStack(spacing: 12) {
                    Slider(value: $radius, in: 0...400, step: 10)
                        .frame(width: 250)
                    Text("\(Int(radius)) px")
                        .monospacedDigit()
                        .frame(width: 64, alignment: .leading)
                }
            }
            Settings.Section(title: L("settings.spotlight.blur")) {
                HStack(spacing: 12) {
                    Slider(value: $blur, in: 0...100, step: 5)
                        .frame(width: 250)
                    Text("\(Int(blur)) px")
                        .monospacedDigit()
                        .frame(width: 64, alignment: .leading)
                }
            }
            Settings.Section(title: L("settings.spotlight.opacity")) {
                HStack(spacing: 12) {
                    Slider(value: $opacity, in: 0...1.0, step: 0.05)
                        .frame(width: 250)
                    Text(String(format: "%.0f%%", opacity * 100))
                        .monospacedDigit()
                        .frame(width: 64, alignment: .leading)
                }
            }
            Settings.Section(title: L("settings.spotlight.color")) {
                ColorPicker(L("settings.spotlight.color"), selection: colorBinding, supportsOpacity: true)
            }
        }
    }
}
