import SwiftUI

/// History over the painted list background. The marquee title is painted; the rows are
/// variable in number, so they scroll as component plates inside the painted frame.
struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(ReadingStore.self) private var readingStore

    var body: some View {
        ArtScreen(image: "bg_history_list") { art in
            ScrollView(showsIndicators: false) {
                VStack(spacing: art.frame.height * 0.008) {
                    if readingStore.readings.isEmpty {
                        emptyState(art)
                    } else {
                        ForEach(readingStore.readings) { reading in
                            ArtRow(
                                icon: "hand.raised.fill",
                                title: reading.createdAt
                                    .formatted(date: .abbreviated, time: .omitted)
                                    .uppercased(),
                                subtitle: reading.tier == .premium ? "In-Depth Reading" : "Overview"
                            ) {
                                appState.navigate(.reading(reading))
                            }
                        }
                    }
                }
                .padding(.vertical, art.frame.height * 0.008)
            }
            .artFrame(art.rect(0.085, 0.200, 0.83, 0.540))

            // NEW READING plate above the nav bar.
            ArtButton(style: .primary, title: "NEW READING") {
                appState.navigate(.capture)
            }
            .artFrame(art.rect(0.115, 0.755, 0.77, 0.060))
        }
    }

    private func emptyState(_ art: ArtGeometry) -> some View {
        VStack(spacing: art.frame.height * 0.012) {
            IconMedallion(systemName: "hand.raised.fill", diameter: art.frame.width * 0.18)
            Text("NO READINGS YET")
                .font(.custom("Rye-Regular", size: art.fontSize(0.017)))
                .foregroundStyle(Theme.gold)
            Text("Your destiny awaits its first telling.")
                .font(.custom("AlegreyaSans-Regular", size: art.fontSize(0.0135)))
                .foregroundStyle(Theme.goldLight.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.top, art.frame.height * 0.06)
    }
}
