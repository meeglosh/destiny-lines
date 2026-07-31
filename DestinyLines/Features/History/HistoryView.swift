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
                            ArtHistoryRow(
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
            // The empty framed panel in bg_history_list runs from its top border
            // (~0.198) down toward its bottom border (~0.833), but the global nav bar
            // overlays the screen's own bottom ~92pt without shrinking this box, which
            // covers this art below roughly 0.808. The frame's own baked bottom border
            // and NEW READING plate sit lower than that and are never actually visible,
            // so both the row list and the live button below stop well short of them.
            .artFrame(art.rect(0.115, 0.210, 0.77, 0.50))

            // NEW READING, positioned to clear the nav bar rather than matching the
            // (permanently hidden) baked plate lower on this art.
            ArtButton(style: .primary, title: "NEW READING") {
                appState.navigate(.capture)
            }
            .artFrame(art.rect(0.135, 0.735, 0.73, 0.062))
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
