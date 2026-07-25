import SwiftUI

/// DL-main-menu.png used directly. Everything visual is baked into the art; this view
/// adds tap targets over the baked controls and the live readings-count badge.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(ReadingStore.self) private var readingStore

    var body: some View {
        ArtScreen(image: "bg_home") { art in
            // NEW READING marquee plate
            ArtHotspot(
                rect: art.rect(0.12, 0.560, 0.76, 0.098),
                label: "New Reading",
                debug: ArtDebug.showHotspots
            ) {
                appState.navigate(.capture)
            }

            // MY READINGS row
            ArtHotspot(
                rect: art.rect(0.09, 0.685, 0.82, 0.068),
                label: "My Readings. View your past readings.",
                debug: ArtDebug.showHotspots
            ) {
                appState.navigate(.history)
            }

            // SHARE row
            ArtHotspot(
                rect: art.rect(0.09, 0.762, 0.82, 0.062),
                label: "Share your reading",
                debug: ArtDebug.showHotspots
            ) {
                if let latest = readingStore.readings.first {
                    appState.navigate(.share(latest))
                } else {
                    appState.navigate(.capture)
                }
            }

            // SETTINGS row
            ArtHotspot(
                rect: art.rect(0.09, 0.832, 0.82, 0.062),
                label: "Settings. Customize your experience.",
                debug: ArtDebug.showHotspots
            ) {
                appState.navigate(.settings)
            }

            // Live badge over the baked top-right medallion.
            if !readingStore.readings.isEmpty {
                Text("\(readingStore.readings.count)")
                    .font(Typography.fine)
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Circle().fill(Color(red: 0.72, green: 0.20, blue: 0.10)))
                    .overlay(Circle().strokeBorder(Theme.gold.opacity(0.7), lineWidth: 1))
                    .artFrame(art.rect(0.905, 0.032, 0.10, 0.040))
                    .allowsHitTesting(false)
                    .accessibilityLabel("\(readingStore.readings.count) saved readings")
            }
        }
    }
}
