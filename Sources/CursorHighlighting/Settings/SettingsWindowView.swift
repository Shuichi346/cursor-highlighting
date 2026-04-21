import Defaults
import SwiftUI

// 設定ウィンドウのタブ定義
enum SettingsTab: String, CaseIterable, Identifiable {
    case spotlight
    case clicks
    case keystrokes
    case general

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spotlight: L("settings.spotlight.title")
        case .clicks: L("settings.clicks.title")
        case .keystrokes: L("settings.keystrokes.title")
        case .general: L("settings.others.title")
        }
    }

    var iconName: String {
        switch self {
        case .spotlight: "light.max"
        case .clicks: "cursorarrow.click.2"
        case .keystrokes: "keyboard"
        case .general: "gearshape"
        }
    }

    var iconColor: Color {
        switch self {
        case .spotlight: Color(red: 0.40, green: 0.56, blue: 0.90)
        case .clicks: Color(red: 0.55, green: 0.70, blue: 0.95)
        case .keystrokes: Color(red: 0.60, green: 0.50, blue: 0.85)
        case .general: Color(red: 0.55, green: 0.60, blue: 0.70)
        }
    }
}

// サイドバー＋コンテンツ構成のメインビュー
struct SettingsWindowView: View {
    @State private var selectedTab: SettingsTab = .spotlight

    // Info.plistからバージョン文字列を動的に取得
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.6"
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            contentArea
        }
        .frame(width: 720, height: 520)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: "cursorarrow.rays")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.40, green: 0.56, blue: 0.90),
                                Color(red: 0.55, green: 0.70, blue: 0.95),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                VStack(alignment: .leading, spacing: 1) {
                    Text("Cursor Highlighting")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("v\(appVersion)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 16)

            ForEach(SettingsTab.allCases) { tab in
                SidebarButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = tab
                    }
                }
            }

            Spacer()
        }
        .frame(width: 200)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }

    @ViewBuilder
    private var contentArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                switch selectedTab {
                case .spotlight:
                    SpotlightSettingsContentView()
                case .clicks:
                    ClickSettingsContentView()
                case .keystrokes:
                    KeyStrokeSettingsContentView()
                case .general:
                    GeneralSettingsContentView()
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// サイドバーのナビゲーションボタン
struct SidebarButton: View {
    let tab: SettingsTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? .white : tab.iconColor)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(isSelected ? tab.iconColor : tab.iconColor.opacity(0.12))
                    )
                Text(tab.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.10) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }
}
