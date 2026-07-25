import SwiftUI

/// DL-reading-history.png used directly. bg_history_blank is the comp with the sample
/// rows melted out; real rows (hist_row slices with live dates) scroll in that region,
/// and the baked NEW READING button and tab bar get hotspots.
struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(ReadingStore.self) private var readingStore
    @Environment(\.dismiss) private var dismiss

    /// List region of the art (between header divider and NEW READING plate).
    private let list = (top: 0.202, bottom: 0.838)

    var body: some View {
        ArtScreen(image: "bg_history_blank") { art in
            let listRect = art.rect(0.045, list.top, 0.91, list.bottom - list.top)

            ScrollView(showsIndicators: false) {
                VStack(spacing: art.frame.height * 0.012) {
                    if readingStore.readings.isEmpty {
                        emptyRow
                    } else {
                        ForEach(readingStore.readings) { reading in
                            row(reading)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(width: listRect.width, height: listRect.height)
            .position(x: listRect.midX, y: listRect.midY)

            // Baked NEW READING plate
            ArtHotspot(rect: art.rect(0.07, 0.848, 0.86, 0.075), label: "New Reading",
                       debug: ArtDebug.showHotspots) {
                appState.popToRoot()
                appState.navigate(.capture)
            }

            // Baked tab bar: HOME / READ / HISTORY / INSIGHTS / SETTINGS
            tabHotspots(art)
        }
        .task { await refreshFromServer() }
    }

    // MARK: - Rows

    private func row(_ reading: Reading) -> some View {
        Button {
            appState.navigate(.reading(reading))
        } label: {
            rowArt(
                title: reading.createdAt.formatted(date: .abbreviated, time: .omitted).uppercased(),
                subtitle: reading.tier == .premium ? "In-Depth Reading" : "Overview"
            )
        }
        .buttonStyle(ArtPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(reading.createdAt.formatted(date: .long, time: .omitted)), \(reading.tier == .premium ? "In-Depth Reading" : "Overview")")
    }

    private var emptyRow: some View {
        rowArt(title: "NO READINGS YET", subtitle: "Your destiny awaits its first telling.")
            .accessibilityLabel("No readings yet. Your destiny awaits its first telling.")
    }

    private func rowArt(title: String, subtitle: String) -> some View {
        Image("hist_row")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .overlay(
                GeometryReader { proxy in
                    VStack(alignment: .leading, spacing: proxy.size.height * 0.04) {
                        Text(title)
                            .font(.custom("Rye-Regular", size: proxy.size.height * 0.21))
                            .foregroundStyle(Theme.gold)
                        Text(subtitle)
                            .font(.custom("AlegreyaSans-Regular", size: proxy.size.height * 0.15))
                            .foregroundStyle(Theme.goldLight.opacity(0.9))
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                    .offset(x: proxy.size.width * 0.30)
                }
            )
    }

    // MARK: - Tab bar

    @ViewBuilder
    private func tabHotspots(_ art: ArtGeometry) -> some View {
        let bar = art.rect(0, 0.940, 1, 0.060)
        let items: [(String, () -> Void)] = [
            ("Home", { appState.popToRoot() }),
            ("Read. New reading.", { appState.popToRoot(); appState.navigate(.capture) }),
            ("History", {}),
            ("Insights. Coming soon.", {}),
            ("Settings", { appState.popToRoot(); appState.navigate(.settings) }),
        ]
        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
            ArtHotspot(
                rect: CGRect(
                    x: bar.minX + bar.width * 0.2 * CGFloat(index),
                    y: bar.minY,
                    width: bar.width * 0.2,
                    height: bar.height
                ),
                label: item.0,
                debug: ArtDebug.showHotspots,
                action: item.1
            )
        }
    }

    // MARK: - Data

    private func refreshFromServer() async {
        guard SupabaseConfig.isConfigured else { return }
        if let server = try? await SupabaseService.shared.fetchReadings() {
            readingStore.replaceAll(server)
        }
    }
}
