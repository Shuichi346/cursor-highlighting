import Defaults
import KeyboardShortcuts
import SwiftUI

// クリック可視化設定コンテンツ
struct ClickSettingsContentView: View {
    @Default(.clickEnabled) private var clickEnabled
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
        VStack(alignment: .leading, spacing: 24) {
            PageHeader(
                title: L("settings.clicks.title"),
                subtitle: L("settings.clicks.subtitle")
            )

            SettingsCard {
                ToggleRow(
                    label: L("settings.clicks.enable"),
                    subtitle: L("settings.clicks.enableDescription"),
                    isOn: $clickEnabled
                )

                Divider().opacity(0.5)

                SettingsRow(label: L("settings.clicks.hotkey")) {
                    KeyboardShortcuts.Recorder(for: .toggleClicks)
                        .frame(maxWidth: 180)
                }
            }

            SectionHeader(title: L("settings.appearance"))
            SettingsCard {
                ColorRow(
                    label: L("settings.clicks.leftColor"),
                    color: leftColorBinding,
                    hexString: leftClickColor.hexString
                )
                Divider().opacity(0.5)
                ColorRow(
                    label: L("settings.clicks.rightColor"),
                    color: rightColorBinding,
                    hexString: rightClickColor.hexString
                )
                Divider().opacity(0.5)
                SettingsRow(label: L("settings.clicks.ringSize")) {
                    ValueSlider(value: $ringMaxRadius, in: 5...80, step: 5, unit: "px")
                }
            }
        }
    }
}
