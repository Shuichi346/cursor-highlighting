import SwiftUI

// セクションヘッダー
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .tracking(0.8)
            .padding(.bottom, 8)
    }
}

// ページタイトルとサブタイトル
struct PageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 24)
    }
}

// カード風セクションコンテナ
struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

// 設定行（ラベル＋コントロール）
struct SettingsRow<Content: View>: View {
    let label: String
    let subtitle: String?
    @ViewBuilder let content: Content

    init(label: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            content
        }
    }
}

// 数値付きスライダー
struct ValueSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let formatAsPercent: Bool

    init(
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 1,
        unit: String = "px",
        formatAsPercent: Bool = false
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.unit = unit
        self.formatAsPercent = formatAsPercent
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(formattedMin)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .frame(width: 32, alignment: .trailing)
                .monospacedDigit()

            Slider(value: $value, in: range, step: step)
                .tint(Color(red: 0.40, green: 0.56, blue: 0.90))
                .frame(width: 180)

            Text(formattedMax)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .frame(width: 36, alignment: .leading)
                .monospacedDigit()

            Text(formattedValue)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.05))
                )
                .frame(width: 64, alignment: .center)
        }
    }

    private var formattedValue: String {
        if formatAsPercent {
            return String(format: "%.0f%%", value * 100)
        }
        return "\(Int(value))\(unit)"
    }

    private var formattedMin: String {
        if formatAsPercent {
            return String(format: "%.0f%%", range.lowerBound * 100)
        }
        return "\(Int(range.lowerBound))"
    }

    private var formattedMax: String {
        if formatAsPercent {
            return String(format: "%.0f%%", range.upperBound * 100)
        }
        return "\(Int(range.upperBound))"
    }
}

// トグル行
struct ToggleRow: View {
    let label: String
    let subtitle: String?
    @Binding var isOn: Bool

    init(label: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.label = label
        self.subtitle = subtitle
        self._isOn = isOn
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(Color(red: 0.40, green: 0.56, blue: 0.90))
        }
    }
}

// カラーピッカー行
struct ColorRow: View {
    let label: String
    @Binding var color: Color
    let hexString: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
            Spacer()
            Text(hexString)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
                .padding(.trailing, 8)
            ColorPicker("", selection: $color, supportsOpacity: false)
                .labelsHidden()
        }
    }
}
