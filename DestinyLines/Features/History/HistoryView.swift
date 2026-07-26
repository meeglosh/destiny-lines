import SwiftUI

/// History tab: ribbon header, reading rows in sliced card frames, NEW READING pinned
/// above the global tab bar.
struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(ReadingStore.self) private var readingStore

    var body: some View {
        VStack(spacing: 12) {
            RibbonBanner(text: "MY READINGS")
                .padding(.horizontal, 64)
                .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.cardSpacing) {
                    if readingStore.readings.isEmpty {
                        emptyState
                    } else {
                        ForEach(readingStore.readings) { reading in
                            row(reading)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 6)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }

            ArtPlateButton(style: .marqueeRed, text: "NEW READING") {
                appState.navigate(.capture)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: 460)
            .padding(.bottom, 6)
        }
        .boothBackground()
        .task { await refreshFromServer() }
    }

    private func row(_ reading: Reading) -> some View {
        Button {
            appState.navigate(.reading(reading))
        } label: {
            ArtCard(contentPadding: 12) {
                HStack(spacing: 14) {
                    ArtMedallionView(kind: .life, diameter: 54)
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
        .accessibilityLabel("\(reading.createdAt.formatted(date: .long, time: .omitted)), \(reading.tier == .premium ? "In-Depth Reading" : "Overview")")
    }

    private var emptyState: some View {
        ArtCard {
            VStack(spacing: 10) {
                Image("crystal_ball_small")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84)
                    .accessibilityHidden(true)
                Text("No readings yet.")
                    .font(Typography.bodyEmphasis)
                    .foregroundStyle(Theme.goldLight)
                Text("Your destiny awaits its first telling.")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.goldLight.opacity(0.75))
            }
        }
    }

    private func refreshFromServer() async {
        #if DEBUG
        // Screenshot/debug runs seed a local sample; a server refresh for the fresh
        // anonymous user would wipe it.
        guard ProcessInfo.processInfo.environment["DEBUG_ROUTE"] == nil else { return }
        #endif
        guard SupabaseConfig.isConfigured else { return }
        if let server = try? await SupabaseService.shared.fetchReadings() {
            readingStore.replaceAll(server)
        }
    }
}
