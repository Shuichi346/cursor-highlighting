import Defaults
import KeyboardShortcuts
import SwiftUI

// スポットライト設定コンテンツ
struct SpotlightSettingsContentView: View {
    @Default(.spotlightEnabled) private var spotlightEnabled
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
        VStack(alignment: .leading, spacing: 24) {
            PageHeader(
                title: L("settings.spotlight.title"),
                subtitle: L("settings.spotlight.subtitle")
            )

            SettingsCard {
                ToggleRow(
                    label: L("settings.spotlight.enable"),
                    subtitle: L("settings.spotlight.enableDescription"),
                    isOn: $spotlightEnabled
                )

                Divider().opacity(0.5)

                SettingsRow(
                    label: L("settings.spotlight.hotkey"),
                    subtitle: L("settings.spotlight.hotkeyDescription")
                ) {
                    KeyboardShortcuts.Recorder(for: .toggleSpotlight)
                        .frame(maxWidth: 180)
                }
            }

            SectionHeader(title: L("settings.appearance"))
            SettingsCard {
                SettingsRow(
                    label: L("settings.spotlight.radius"),
                    subtitle: L("settings.spotlight.radiusDescription")
                ) {
                    ValueSlider(value: $radius, in: 0...100, step: 10, unit: "px")
                }
                Divider().opacity(0.5)
                SettingsRow(
                    label: L("settings.spotlight.blur"),
                    subtitle: L("settings.spotlight.blurDescription")
                ) {
                    ValueSlider(value: $blur, in: 0...100, step: 5, unit: "px")
                }
                Divider().opacity(0.5)
                SettingsRow(
                    label: L("settings.spotlight.opacity"),
                    subtitle: L("settings.spotlight.opacityDescription")
                ) {
                    ValueSlider(value: $opacity, in: 0...0.5, step: 0.05, formatAsPercent: true)
                }
                Divider().opacity(0.5)
                SettingsRow(label: L("settings.spotlight.color")) {
                    HStack(spacing: 8) {
                        Text(spotlightColor.hexString)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.tertiary)
                        ColorPicker("", selection: colorBinding, supportsOpacity: true)
                            .labelsHidden()
                    }
                }
            }
        }
    }
}
