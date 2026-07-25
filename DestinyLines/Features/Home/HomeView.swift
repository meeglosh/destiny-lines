import SwiftUI

/// DL-main-menu.png used directly. Everything visual is baked into the art; this view
/// adds tap targets over the baked controls and the live readings-count badge.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(ReadingStore.self) private var readingStore
    @Environment(AudioPlayer.self) private var audio

    var body: some View {
        ArtScreen(image: "bg_home") { art in
            // The comp's two top medallions were decorative; they've been erased from the
            // art and replaced with these working controls in the same style and place.
            MuteButton(isMuted: audio.isMuted) {
                audio.toggleMute()
            }
            .artFrame(art.rect(0.052, 0.048, 0.115, 0.056))

            ArtMedallionButton(systemName: "gearshape.fill", label: "Settings") {
                appState.navigate(.settings)
            }
            .artFrame(art.rect(0.840, 0.048, 0.115, 0.056))

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

        }
    }
}
