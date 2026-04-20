import Defaults
import SwiftUI

// 外観設定のコンテンツビュー（将来的にテーマやカスタマイズを追加可能）
struct AppearanceSettingsContentView: View {
    @Default(.spotlightColor) private var spotlightColor
    @Default(.leftClickColor) private var leftClickColor
    @Default(.rightClickColor) private var rightClickColor

    private var spotlightColorBinding: Binding<Color> {
        Binding(
            get: { spotlightColor.color },
            set: { spotlightColor = CodableColor(nsColor: NSColor($0)) }
        )
    }

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
                title: L("settings.appearance.title"),
                subtitle: L("settings.appearance.subtitle")
            )

            // カラーパレット概要
            SectionHeader(title: L("settings.appearance.colors"))
            SettingsCard {
                ColorRow(
                    label: L("settings.spotlight.color"),
                    color: spotlightColorBinding,
                    hexString: spotlightColor.hexString
                )
                Divider().opacity(0.5)
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
            }

            // プリセット（視覚的に美しいカラーセット）
            SectionHeader(title: L("settings.appearance.presets"))
            HStack(spacing: 12) {
                PresetButton(
                    name: L("settings.appearance.preset.default"),
                    colors: [
                        Color(red: 0.0, green: 0.48, blue: 1.0),
                        Color(red: 1.0, green: 0.23, blue: 0.19),
                    ]
                ) {
                    leftClickColor = .blue
                    rightClickColor = .red
                }
                PresetButton(
                    name: L("settings.appearance.preset.ocean"),
                    colors: [
                        Color(red: 0.20, green: 0.60, blue: 0.86),
                        Color(red: 0.30, green: 0.80, blue: 0.76),
                    ]
                ) {
                    leftClickColor = CodableColor.fromHex("#339ADB")
                    rightClickColor = CodableColor.fromHex("#4DCCC2")
                }
                PresetButton(
                    name: L("settings.appearance.preset.sunset"),
                    colors: [
                        Color(red: 0.95, green: 0.55, blue: 0.30),
                        Color(red: 0.90, green: 0.30, blue: 0.50),
                    ]
                ) {
                    leftClickColor = CodableColor.fromHex("#F28C4D")
                    rightClickColor = CodableColor.fromHex("#E64D80")
                }
                PresetButton(
                    name: L("settings.appearance.preset.forest"),
                    colors: [
                        Color(red: 0.30, green: 0.70, blue: 0.40),
                        Color(red: 0.55, green: 0.80, blue: 0.35),
                    ]
                ) {
                    leftClickColor = CodableColor.fromHex("#4DB366")
                    rightClickColor = CodableColor.fromHex("#8CCC59")
                }
            }
        }
    }
}

// カラープリセットボタン
struct PresetButton: View {
    let name: String
    let colors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                        Circle()
                            .fill(color)
                            .frame(width: 20, height: 20)
                    }
                }
                Text(name)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
