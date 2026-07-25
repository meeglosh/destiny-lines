import SwiftUI

/// DL-reading-history.png: "MY READINGS" marquee header, reading rows with hand
/// medallions, pinned NEW READING button, and the five-item tab bar (INSIGHTS is a
/// placeholder per the owner's decision).
struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(ReadingStore.self) private var readingStore
    @Environment(\.dismiss) private var dismiss

    enum Tab: Hashable { case home, read, history, insights, settings }
    @State private var tab: Tab = .history

    var body: some View {
        VStack(spacing: 0) {
            switch tab {
            case .history: historyContent
            case .insights: insightsPlaceholder
            default: historyContent // home/read/settings navigate away in onChange
            }

            tabBar
        }
        .screenBackground()
        .navigationBarBackButtonHidden()
        .task { await refreshFromServer() }
        .onChange(of: tab) { _, newTab in
            switch newTab {
            case .home:
                appState.popToRoot()
            case .read:
                appState.popToRoot()
                appState.navigate(.capture)
            case .settings:
                appState.popToRoot()
                appState.navigate(.settings)
            case .history, .insights:
                break
            }
        }
    }

    // MARK: - History list

    private var historyContent: some View {
        ScrollView {
            VStack(spacing: 14) {
                MarqueeFrame(cornerRadius: 22, bulbSpacing: 30, bulbSize: 5, animated: true) {
                    VStack(spacing: 4) {
                        Text("MY READINGS")
                            .font(Typography.title)
                            .foregroundStyle(Theme.goldBevel)
                        OrnamentDivider()
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .padding(.horizontal, 24)
                .accessibilityAddTraits(.isHeader)

                if readingStore.readings.isEmpty {
                    emptyState
                } else {
                    ForEach(readingStore.readings) { reading in
                        readingRow(reading)
                    }
                    .padding(.horizontal, 24)
                }

                PrimaryCTAButton(title: "NEW READING") {
                    appState.popToRoot()
                    appState.navigate(.capture)
                }
                .padding(.horizontal, 24)
                .padding(.top, 6)
            }
            .padding(.vertical, 10)
        }
    }

    private func readingRow(_ reading: Reading) -> some View {
        Button {
            appState.navigate(.reading(reading))
        } label: {
            OrnateCard(contentPadding: 12) {
                HStack(spacing: 14) {
                    IconMedallion(systemName: "hand.raised.fill", diameter: 54)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(reading.createdAt.formatted(date: .abbreviated, time: .omitted).uppercased())
                            .font(Typography.heading)
                            .foregroundStyle(Theme.gold)
                        Text(reading.tier == .premium ? "In-Depth Reading" : "Overview")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.goldLight.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        OrnateCard {
            VStack(spacing: 10) {
                IconMedallion(systemName: "hand.raised.fill", diameter: 64)
                Text("No readings yet.")
                    .font(Typography.bodyEmphasis)
                    .foregroundStyle(Theme.goldLight)
                Text("Your destiny awaits its first telling.")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.goldLight.opacity(0.75))
            }
        }
        .padding(.horizontal, 24)
    }

    private var insightsPlaceholder: some View {
        ScrollView {
            VStack(spacing: 14) {
                BannerHeader(title: "INSIGHTS")
                    .padding(.horizontal, 70)
                OrnateCard {
                    VStack(spacing: 10) {
                        IconMedallion(systemName: "star.circle", diameter: 64)
                        Text("The stars are still aligning.")
                            .font(Typography.bodyEmphasis)
                            .foregroundStyle(Theme.goldLight)
                        Text("Insights are coming in a future reading of the app itself.")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.goldLight.opacity(0.75))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 10)
        }
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        HStack {
            tabItem(.home, icon: "star.circle", label: "HOME")
            tabItem(.read, icon: "hand.raised.fill", label: "READ")
            tabItem(.history, icon: "book.fill", label: "HISTORY")
            tabItem(.insights, icon: "sparkles", label: "INSIGHTS")
            tabItem(.settings, icon: "gearshape.fill", label: "SETTINGS")
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.55))
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.goldDark), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabItem(_ value: Tab, icon: String, label: String) -> some View {
        let isSelected = tab == value
        return Button {
            tab = value
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 19))
                Text(label)
                    .font(Typography.fine)
                    .kerning(0.5)
            }
            .foregroundStyle(isSelected ? Theme.gold : Theme.goldDark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .overlay(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Theme.gold.opacity(0.7), lineWidth: 1)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label.capitalized)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Data

    private func refreshFromServer() async {
        guard SupabaseConfig.isConfigured else { return }
        if let server = try? await SupabaseService.shared.fetchReadings() {
            readingStore.replaceAll(server)
        }
    }
}
