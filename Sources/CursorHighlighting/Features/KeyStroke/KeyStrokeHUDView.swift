import SwiftUI

// キーストロークの表示エントリ
struct KeyStrokeEntry: Identifiable, Sendable {
    let id = UUID()
    let text: String
    let timestamp: Date
}

// キーストロークHUD表示用SwiftUIビュー
struct KeyStrokeHUDView: View {
    var entries: [KeyStrokeEntry]
    var fontSize: Double
    var theme: String

    // テーマに基づくスタイル
    private var textColor: Color {
        theme == "light" ? .primary : .white
    }

    private var backgroundColor: Color {
        theme == "light"
            ? Color.white.opacity(0.85)
            : Color.black.opacity(0.7)
    }

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                ForEach(entries.suffix(8)) { entry in
                    Text(entry.text)
                        .font(.system(size: fontSize, weight: .medium, design: .rounded))
                        .foregroundStyle(textColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(backgroundColor)
                        )
                }
            }
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .animation(.easeInOut(duration: 0.2), value: entries.map(\.id))
    }
}
